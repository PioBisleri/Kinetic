package com.kinetic.kinetic

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Registers the `kinetic/live_activity` MethodChannel — start / stop /
 * refresh the [KineticLiveService]. Method calls are fire-and-forget from
 * the Dart side (guards live there); errors here never crash the app.
 */
class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "kinetic/live_activity",
        ).setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "start" -> {
                        startLiveService()
                        result.success(true)
                    }
                    "update" -> {
                        startLiveService()
                        result.success(true)
                    }
                    "stop" -> {
                        // stopService (not startForegroundService): starting
                        // just to stop would owe the OS a startForeground.
                        stopService(liveIntent(KineticLiveService.ACTION_STOP))
                        result.success(true)
                    }
                    // Battery-exemption status + request (Round 9.1): OEMs
                    // stop even a specialUse foreground service when the app
                    // goes idle unless it is exempt from battery
                    // optimization — the request shows the system's own
                    // "Allow always running?" dialog.
                    "battery-exemption" ->
                        result.success(isIgnoringBattery())
                    "request-battery-exemption" -> {
                        requestBatteryExemption()
                        result.success(isIgnoringBattery())
                    }
                    else -> result.notImplemented()
                }
            } catch (_: Exception) {
                result.success(false)
            }
        }
    }

    private fun liveIntent(action: String): Intent =
        Intent(this, KineticLiveService::class.java).setAction(action)

    private fun isIgnoringBattery(): Boolean =
        (getSystemService(Context.POWER_SERVICE) as? PowerManager)
            ?.isIgnoringBatteryOptimizations(packageName) == true

    /** The direct request dialog, falling back to the optimization list. */
    private fun requestBatteryExemption() {
        try {
            startActivity(
                Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
                    .setData(Uri.parse("package:$packageName")),
            )
        } catch (t: Throwable) {
            try {
                startActivity(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS))
            } catch (_: Throwable) {
            }
        }
    }

    private fun startLiveService() {
        // Admission gate: the step-counter sensor requires the while-in-use
        // ACTIVITY_RECOGNITION permission on Q+ — without it the sensor HAL
        // rejects every read, so a live notification would sit at 0 steps
        // forever. Soft-fail: the live notification stays off; the in-app
        // step tracker keeps working under its own flow.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val granted = checkSelfPermission(
                Manifest.permission.ACTIVITY_RECOGNITION,
            ) == PackageManager.PERMISSION_GRANTED
            if (!granted) return
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(liveIntent(KineticLiveService.ACTION_UPDATE))
        } else {
            startService(liveIntent(KineticLiveService.ACTION_UPDATE))
        }
    }
}
