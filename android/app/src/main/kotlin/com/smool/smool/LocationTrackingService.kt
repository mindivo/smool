package com.smool.smool

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.location.Location
import android.os.Build
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import com.google.android.gms.location.FusedLocationProviderClient
import com.google.android.gms.location.LocationCallback
import com.google.android.gms.location.LocationRequest
import com.google.android.gms.location.LocationResult
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.Priority

class LocationTrackingService : Service() {

    companion object {
        const val ACTION_START = "com.smool.smool.action.START"
        const val ACTION_STOP = "com.smool.smool.action.STOP"
        const val ACTION_REFRESH = "com.smool.smool.action.REFRESH"

        private const val TAG = "Smool.Service"
        private const val CHANNEL_ID = "smool_tracking"
        private const val CHANNEL_NAME = "Tracking"
        private const val NOTIFICATION_ID = 1714

        private const val UPDATE_INTERVAL_MS = 1000L

        @Volatile
        var isRunning: Boolean = false
            private set
    }

    private lateinit var fusedLocationClient: FusedLocationProviderClient
    private lateinit var wakeLock: PowerManager.WakeLock

    private var pinnedLocations: List<PinnedLocation> = emptyList()
    private val insidePinIds = HashSet<String>()
    private var lastFix: Location? = null
    private var receivingUpdates = false
    private var lastCommandedMuted: Boolean? = null

    private val locationCallback = object : LocationCallback() {
        override fun onLocationResult(locationResult: LocationResult) {
            for (location in locationResult.locations) {
                lastFix = location
                evaluateGeofences(location)
            }
            updateNotification(buildStatusText())
        }
    }

    override fun onCreate() {
        super.onCreate()
        fusedLocationClient = LocationServices.getFusedLocationProviderClient(this)
        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = pm.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "Smool::TrackingWakeLock")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                stopTracking()
                stopSelf()
                return START_NOT_STICKY
            }
            ACTION_REFRESH -> {
                pinnedLocations = PinnedLocationsStore.load(this)
                Log.i(TAG, "Pinned locations refreshed: ${pinnedLocations.size}")
                lastFix?.let { evaluateGeofences(it) }
                updateNotification(buildStatusText())
            }
            else -> startTracking()
        }
        return START_STICKY
    }

    private fun startTracking() {
        if (isRunning) return
        ensureChannel()
        startForeground(NOTIFICATION_ID, buildNotification(buildStatusText()))
        if (!wakeLock.isHeld) wakeLock.acquire()

        pinnedLocations = PinnedLocationsStore.load(this)

        if (!hasLocationPermission()) {
            Log.w(TAG, "Missing fine location permission; service will idle.")
        } else {
            requestUpdates()
            seedFromLastKnown()
        }

        isRunning = true
        Log.i(TAG, "Tracking started.")
    }

    private fun stopTracking() {
        try {
            fusedLocationClient.removeLocationUpdates(locationCallback)
        } catch (_: Throwable) {}
        receivingUpdates = false
        if (wakeLock.isHeld) wakeLock.release()
        isRunning = false
        
        // Always unmute DND as a fallback when stopping tracking
        MuteController.unmute(this)
        lastCommandedMuted = false

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        Log.i(TAG, "Tracking stopped.")
    }

    private fun requestUpdates() {
        if (!hasLocationPermission()) return
        if (receivingUpdates) return
        try {
            val locationRequest = LocationRequest.Builder(Priority.PRIORITY_HIGH_ACCURACY, UPDATE_INTERVAL_MS)
                .setMinUpdateDistanceMeters(0f)
                .build()

            fusedLocationClient.requestLocationUpdates(
                locationRequest,
                locationCallback,
                Looper.getMainLooper()
            )
            receivingUpdates = true
            Log.i(TAG, "Subscribed to high accuracy fused location updates")
        } catch (t: Throwable) {
            Log.e(TAG, "Failed to subscribe to location updates", t)
        }
    }

    private fun seedFromLastKnown() {
        if (!hasLocationPermission()) return
        try {
            fusedLocationClient.lastLocation.addOnSuccessListener { location: Location? ->
                if (location != null && isFresh(location)) {
                    lastFix = location
                    evaluateGeofences(location)
                    updateNotification(buildStatusText())
                }
            }
        } catch (_: Throwable) {}
    }

    private fun isFresh(loc: Location): Boolean {
        val ageMs = System.currentTimeMillis() - loc.time
        return ageMs in 0..120_000
    }

    private fun hasLocationPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun evaluateGeofences(fix: Location) {
        val active = pinnedLocations.filter { it.enabled }
        val nowInside = HashSet<String>()
        val pinBuf = Location("pin")
        for (pin in active) {
            pinBuf.latitude = pin.latitude
            pinBuf.longitude = pin.longitude
            val distance = fix.distanceTo(pinBuf)
            if (distance <= pin.radiusMeters.toFloat()) nowInside.add(pin.id)
        }

        insidePinIds.clear()
        insidePinIds.addAll(nowInside)

        val shouldBeMuted = nowInside.isNotEmpty()
        val previous = lastCommandedMuted
        if (previous == null || previous != shouldBeMuted) {
            if (shouldBeMuted) {
                val ok = MuteController.mute(this)
                Log.i(TAG, "Geofence -> MUTE (success=$ok). Inside: $nowInside")
                if (previous != null) playSound(R.raw.mute_alert)
            } else {
                val ok = MuteController.unmute(this)
                Log.i(TAG, "Geofence -> UNMUTE (success=$ok)")
                if (previous != null) playSound(R.raw.unmute_alert)
            }
            lastCommandedMuted = shouldBeMuted
        }
    }

    private fun playSound(resId: Int) {
        try {
            val mediaPlayer = android.media.MediaPlayer.create(this, resId)
            mediaPlayer?.setOnCompletionListener { it.release() }
            mediaPlayer?.start()
        } catch (e: Exception) {
            Log.e(TAG, "Error playing sound", e)
        }
    }

    private fun buildStatusText(): String {
        val total = pinnedLocations.count { it.enabled }
        val insideCount = insidePinIds.size
        return when {
            !hasLocationPermission() -> "Location permission needed"
            total == 0 -> "Watching · no pins yet"
            insideCount > 0 -> "Inside a quiet zone · muted"
            else -> "Watching · $total ${if (total == 1) "pin" else "pins"}"
        }
    }

    private fun ensureChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            if (nm.getNotificationChannel(CHANNEL_ID) == null) {
                val channel = NotificationChannel(
                    CHANNEL_ID,
                    CHANNEL_NAME,
                    NotificationManager.IMPORTANCE_LOW
                ).apply {
                    description = "Background location tracking for quiet zones."
                    setShowBadge(false)
                }
                nm.createNotificationChannel(channel)
            }
        }
    }

    private fun buildNotification(text: String): Notification {
        val openIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val pendingFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        else
            PendingIntent.FLAG_UPDATE_CURRENT
        val openPi = PendingIntent.getActivity(this, 0, openIntent, pendingFlags)

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_menu_mylocation)
            .setContentTitle("Smool")
            .setContentText(text)
            .setOngoing(true)
            .setContentIntent(openPi)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    private fun updateNotification(text: String) {
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        nm.notify(NOTIFICATION_ID, buildNotification(text))
    }

    override fun onDestroy() {
        stopTracking()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
