package com.kinetic.kinetic

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Build
import android.os.Handler
import android.os.HandlerThread
import android.util.Log
import org.json.JSONObject

/**
 * Live activity notification (Round 9).
 *
 * A low-importance ongoing notification with today's steps, energy burned
 * from walking and hydration — driven by the step-counter sensor so the
 * numbers keep moving with the app closed. Dart owns the settings; the only
 * channel between the two sides is SharedPreferences:
 *
 *   read  (Dart → Kotlin):  flutter.live_config        JSON {showSteps, showCalories, showHydration}
 *                           flutter.live_water_ml      water logged in the app today
 *                           flutter.live_water_target  settings.waterTargetMl
 *                           flutter.live_steps_target  settings.stepsTarget
 *                           flutter.live_weight_kg     latest bodyweight (kcal math)
 *   write (Kotlin → Dart):  flutter.live_steps         today's absorbed step count
 *                           flutter.live_steps_day     absorb's day key ('YYYY-MM-DD')
 *                           flutter.live_steps_base    absorb's baseline
 *
 * Dart reads those back on resume and merges into body_metrics via
 * setDaySteps, mirroring StepTrackerService's StepMath absorb rules:
 * day rollover wins over a sensor reboot, and a *shrinking* cumulative
 * counter is treated as a reboot (sensor reset), never as a rewind.
 *
 * The service runs under the `specialUse` FGS type: unlike `health`, a
 * specialUse service is not a while-in-use type, so the system does not
 * stop it when the app goes idle — it stays up all day by design.
 *
 * Everything is wrapped in try/catch — a missing sensor or malformed config
 * must never crash the app's process.
 */
class KineticLiveService : Service(), SensorEventListener {

    companion object {
        const val CHANNEL_ID = "live_activity"
        const val NOTIFICATION_ID = 0x2162 // past the FLN bases: rest 0x2154, weekly 0x2155, water 0x2160+i
        const val ACTION_UPDATE = "com.kinetic.kinetic.live.UPDATE"
        const val ACTION_STOP = "com.kinetic.kinetic.live.STOP"

        const val PREFS_NAME = "FlutterSharedPreferences"
        const val KEY_CONFIG = "flutter.live_config"
        const val KEY_WATER_ML = "flutter.live_water_ml"
        const val KEY_WATER_TARGET = "flutter.live_water_target"
        const val KEY_STEPS_TARGET = "flutter.live_steps_target"
        const val KEY_WEIGHT_KG = "flutter.live_weight_kg"
        const val KEY_STEPS = "flutter.live_steps"
        const val KEY_STEPS_DAY = "flutter.live_steps_day"
        const val KEY_STEPS_BASE = "flutter.live_steps_base"
        const val KEY_ENABLED = "flutter.live_enabled"

        private const val TAG = "KineticLive"
        private const val STEP_M = 0.000762 // meters per step, average stride
        private const val KCAL_PER_KG_KM = 1.036 // walking energy, kcal per kg per km
        private const val NOTIFY_MIN_INTERVAL_MS = 5000L
    }

    private var manager: NotificationManager? = null
    private var thread: HandlerThread? = null
    private var handler: Handler? = null
    private var lastShownSteps = -1
    private var lastNotifyAt = 0L
    private var failed = false
    private var registered = false

    override fun onCreate() {
        super.onCreate()
        // (a) Infrastructure — guarded; failures degrade to a service with
        // no channel/thread rather than a broken instrumented indicator.
        try {
            manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val channel = NotificationChannel(
                    CHANNEL_ID,
                    "Live activity",
                    NotificationManager.IMPORTANCE_LOW,
                ).apply {
                    description = "Today's steps, energy and hydration at a glance."
                    setShowBadge(false)
                }
                manager?.createNotificationChannel(channel)
            }
            thread = HandlerThread("kinetic-live").also { it.start() }
            handler = Handler(thread!!.looper)
        } catch (t: Throwable) {
            Log.w(TAG, "config degraded", t)
        }
        // (b) THE FGS CONTRACT — reach startForeground before anything of
        // substance. Once startForegroundService() is handed to the system,
        // the process must reach Service.startForeground() or Android kills
        // the app (ForegroundServiceDidNotStartInTimeException, seen live on
        // Android 16). Order: typed specialUse (API 34+) → plain fallback
        // (type-NONE foreground services are always permitted) → give up,
        // flag correctly failed so we are not respawned.
        if (!promote()) return
        // (c) The contract is now satisfied; from here a failure degrades to
        // a legal teardown instead of a process kill.
        try {
            registerSensor()
            pushNotification()
        } catch (t: Throwable) {
            Log.w(TAG, "service cannot serve — stopping", t)
            stopForegroundCompat()
            stopSelf()
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        try {
            when (intent?.action) {
                ACTION_STOP -> {
                    stopForegroundCompat()
                    stopSelf()
                    return START_NOT_STICKY
                }
                // Every startForegroundService() call owes its own
                // startForeground() within the time limit — including calls
                // that land on an already-running service (the ignored second
                // contract was exactly what crash-looped the app from the
                // Dart 'update' path on Android 16). Re-entering the
                // foreground here is idempotent and satisfies the fresh
                // contract.
                else -> {
                    if (promote()) {
                        handler?.post { refresh() }
                    }
                }
            }
        } catch (t: Throwable) {
            Log.w(TAG, "command failed", t)
        }
        // A service that could not satisfy the startForeground contract must
        // not be respawned by the system — it would crash-loop the app.
        return if (failed) START_NOT_STICKY else START_STICKY
    }

    override fun onBind(intent: Intent?) = null

    override fun onDestroy() {
        try {
            (getSystemService(Context.SENSOR_SERVICE) as? SensorManager)
                ?.unregisterListener(this)
        } catch (_: Exception) {
        }
        // When the SYSTEM stops the service (app-idle policy, crash, update)
        // there is no stopForeground call on this path — cancel the
        // notification here so no swipeable orphan stays in the shade.
        try {
            manager?.cancel(NOTIFICATION_ID)
        } catch (_: Exception) {
        }
        try {
            thread?.quitSafely()
        } catch (_: Exception) {
        }
        super.onDestroy()
    }

    // ----------------------------------------------------------- FGS promotion

    /**
     * Enters/exits the time-limited FGS state for the current start request.
     * Safe to call on an already-foreground service (idempotent for the OS,
     * and each fresh startForegroundService() request needs exactly this).
     * Returns false only when the process cannot become foreground at all —
     * [failed] then stops the system from respawning a dead-end service.
     */
    private fun promote(): Boolean {
        if (failed) return false
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                startForeground(
                    NOTIFICATION_ID,
                    placeholderNotification(),
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE,
                )
            } else {
                startForeground(NOTIFICATION_ID, placeholderNotification())
            }
            return true
        } catch (t: Throwable) {
            Log.w(TAG, "typed startForeground rejected — trying untyped", t)
        }
        try {
            startForeground(NOTIFICATION_ID, placeholderNotification())
            return true
        } catch (t2: Throwable) {
            Log.w(TAG, "startForeground unavailable — stopping", t2)
            failed = true
            return false
        }
    }

    private fun placeholderNotification(): Notification {
        val placeholder = Notification.Builder(this)
            .setContentTitle("Kinetic")
            .setContentText("Tracking your day")
            .setSmallIcon(iconRes())
            .setOngoing(true)
            .setOnlyAlertOnce(true)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) placeholder.setChannelId(CHANNEL_ID)
        return placeholder.build()
    }

    // ------------------------------------------------------------------ sensor

    private fun registerSensor() {
        if (registered) return
        val sm = getSystemService(Context.SENSOR_SERVICE) as? SensorManager ?: return
        val sensor = sm.getDefaultSensor(Sensor.TYPE_STEP_COUNTER) ?: return
        // Register exactly once — re-registering the same listener instance
        // logs "registerListener fail (2)" on Samsung every refresh.
        registered = try {
            sm.registerListener(this, sensor, SensorManager.SENSOR_DELAY_UI)
        } catch (t: Throwable) {
            Log.w(TAG, "SENSOR_DELAY_UI register failed", t)
            false
        }
        if (!registered) {
            registered = try {
                sm.registerListener(this, sensor, SensorManager.SENSOR_DELAY_FASTEST)
            } catch (t: Throwable) {
                false
            }
        }
        Log.i(TAG, "step sensor registered: $registered")
    }

    override fun onSensorChanged(event: SensorEvent) {
        try {
            if (event.values.isEmpty()) return
            val cumulative = event.values[0].toDouble()
            handler?.post { absorb(cumulative) }
        } catch (_: Exception) {
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}

    /** Same rules as Dart's [StepMath.absorb] — kept in lockstep on purpose. */
    private fun absorb(cumulative: Double) {
        try {
            val prefs = prefs()
            val today = todayKey()
            val storedDay = prefs.getString(KEY_STEPS_DAY, "") ?: ""
            val storedBase = prefs.getInt(KEY_STEPS_BASE, 0)
            val baseline: Int
            val todaySteps: Int
            if (today != storedDay) {
                baseline = cumulative.toInt()
                todaySteps = 0
            } else if (cumulative < storedBase) {
                baseline = cumulative.toInt()
                todaySteps = 0
            } else {
                baseline = storedBase
                todaySteps = (cumulative - storedBase).toInt().coerceAtLeast(0)
            }
            prefs.edit()
                .putString(KEY_STEPS_DAY, today)
                .putInt(KEY_STEPS_BASE, baseline)
                .putInt(KEY_STEPS, todaySteps)
                .apply()
            if (todaySteps != lastShownSteps) {
                lastShownSteps = todaySteps
                pushNotificationThrottled()
            }
        } catch (_: Exception) {
        }
    }

    // ------------------------------------------------------------------ rendering

    private fun prefs() = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    /**
     * Typed SharedPreferences getters throw ClassCastException when the
     * stored type disagrees — Dart's shared_preferences stores doubles as
     * raw long bits (native [Float]/[Int] reads blew up on such values, which
     * is how the notification got stuck on the placeholder while the real
     * content push failed inside the catch). `all` hands back each value
     * under its actual stored class, so reads survive both producers.
     */
    private fun numPref(key: String, default: Double): Double =
        try {
            (prefs().all[key] as? Number)?.toDouble() ?: default
        } catch (_: Exception) {
            default
        }

    private fun intPref(key: String, default: Int): Int =
        numPref(key, default.toDouble()).toInt()

    private fun refresh() {
        try {
            registerSensor()
            lastShownSteps = -1
            pushNotificationThrottled()
        } catch (_: Exception) {
        }
    }

    private fun config(): JSONObject = try {
        JSONObject(prefs().getString(KEY_CONFIG, "{}") ?: "{}")
    } catch (_: Exception) {
        JSONObject()
    }

    private fun stopForegroundCompat() {
        registered = false
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
    }

    private fun pushNotificationThrottled() {
        val now = android.os.SystemClock.elapsedRealtime()
        if (now - lastNotifyAt < NOTIFY_MIN_INTERVAL_MS) return
        lastNotifyAt = now
        pushNotification()
    }

    private fun pushNotification() {
        try {
            val notification = buildNotification()
            manager?.notify(NOTIFICATION_ID, notification)
        } catch (_: Exception) {
        }
    }

    private fun buildNotification(): Notification {
        val cfg = config()
        val showSteps = cfg.optBoolean("showSteps", true)
        val showCalories = cfg.optBoolean("showCalories", true)
        val showHydration = cfg.optBoolean("showHydration", true)

        val steps = intPref(KEY_STEPS, 0).coerceAtLeast(0)
        val stepsTarget = intPref(KEY_STEPS_TARGET, 8000)
        val weightKg = numPref(KEY_WEIGHT_KG, 0.0)
        val waterMl = intPref(KEY_WATER_ML, 0).coerceAtLeast(0)
        val waterTarget = intPref(KEY_WATER_TARGET, 2500)

        val lines = ArrayList<String>(3)
        if (showSteps) lines.add("Steps  $steps / $stepsTarget")
        if (showCalories && steps > 0 && weightKg > 0) {
            val km = steps * STEP_M / 1000.0
            val kcal = weightKg * km * KCAL_PER_KG_KM
            lines.add(String.format("%.0f kcal burned", kcal))
        }
        if (showHydration) {
            lines.add(
                String.format(
                    "Water  %.1f L of %.1f L",
                    waterMl / 1000.0,
                    waterTarget / 1000.0,
                ),
            )
        }

        val text = if (lines.isEmpty()) "Tracking your day" else lines.joinToString("\n")

        val open = Intent(this, MainActivity::class.java).setFlags(
            Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_NEW_TASK
        )
        val content = PendingIntent.getActivity(
            this,
            0,
            open,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        // Plain Notification.Builder keeps the app free of an androidx.core
        // compile-classpath dependency; the channel handles silence on O+ and
        // the pre-O variants stay quiet via PRIORITY_LOW + no defaults.
        val builder = Notification.Builder(this)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            builder.setChannelId(CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            builder.setPriority(Notification.PRIORITY_LOW)
        }
        builder
            .setContentTitle("Kinetic")
            .setContentText(text)
            .setStyle(Notification.BigTextStyle().bigText(text))
            .setSmallIcon(iconRes())
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setDefaults(0)
            .setAutoCancel(false)
            .setContentIntent(content)
        return builder.build()
    }

    private fun iconRes(): Int = try {
        applicationInfo.icon
    } catch (_: Exception) {
        android.R.drawable.ic_dialog_info
    }

    /** `'YYYY-MM-DD'` — DayKey on the Dart side (local calendar day). */
    private fun todayKey(): String {
        val c = java.util.Calendar.getInstance()
        val y = c.get(java.util.Calendar.YEAR).toString().padStart(4, '0')
        val m = (c.get(java.util.Calendar.MONTH) + 1).toString().padStart(2, '0')
        val d = c.get(java.util.Calendar.DAY_OF_MONTH).toString().padStart(2, '0')
        return "$y-$m-$d"
    }
}
