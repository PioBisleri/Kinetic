package com.kinetic.kinetic

import android.Manifest
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build

/**
 * Re-arms [KineticLiveService] after reboot / app update when the user left
 * it enabled. The activity-recognition permission must still be granted —
 * a permission revoked between reboots is treated as "off" without crashing
 * (starting a `health` foreground service without it would throw).
 */
class KineticLiveBootReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            "android.intent.action.QUICKBOOT_POWERON",
            -> {}
            else -> return
        }
        try {
            val prefs = context.getSharedPreferences(
                KineticLiveService.PREFS_NAME,
                Context.MODE_PRIVATE,
            )
            val enabled = prefs.all[KineticLiveService.KEY_ENABLED] == true ||
                prefs.getString(KineticLiveService.KEY_ENABLED, null) == "true"
            if (!enabled) return

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val granted = context.checkSelfPermission(
                    Manifest.permission.ACTIVITY_RECOGNITION,
                ) == PackageManager.PERMISSION_GRANTED
                if (!granted) return
            }
            context.startForegroundService(Intent(context, KineticLiveService::class.java))
        } catch (_: Exception) {
            // Boot-time service starts can be throttled or unavailable —
            // never crash the boot.
        }
    }
}
