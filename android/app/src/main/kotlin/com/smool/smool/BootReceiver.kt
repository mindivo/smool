package com.smool.smool

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

class BootReceiver : BroadcastReceiver() {
    private val tag = "Smool.Boot"
    private val prefsName = "FlutterSharedPreferences"
    private val keyAutostart = "flutter.autostart_enabled"

    override fun onReceive(context: Context, intent: Intent?) {
        val action = intent?.action ?: return
        if (action != Intent.ACTION_BOOT_COMPLETED &&
            action != Intent.ACTION_LOCKED_BOOT_COMPLETED &&
            action != "android.intent.action.QUICKBOOT_POWERON"
        ) return

        val prefs = context.getSharedPreferences(prefsName, Context.MODE_PRIVATE)
        val shouldStart = prefs.getBoolean(keyAutostart, true)
        if (!shouldStart) return

        val serviceIntent = Intent(context, LocationTrackingService::class.java).apply {
            this.action = LocationTrackingService.ACTION_START
        }
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(serviceIntent)
            } else {
                context.startService(serviceIntent)
            }
            Log.i(tag, "Service auto-started after boot.")
        } catch (t: Throwable) {
            Log.e(tag, "Failed to auto-start service", t)
        }
    }
}
