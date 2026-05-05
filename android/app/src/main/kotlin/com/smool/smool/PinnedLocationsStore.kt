package com.smool.smool

import android.content.Context
import android.util.Log
import org.json.JSONArray

data class PinnedLocation(
    val id: String,
    val name: String,
    val latitude: Double,
    val longitude: Double,
    val radiusMeters: Double,
    val enabled: Boolean
)

object PinnedLocationsStore {
    private const val TAG = "Smool.Pins"
    private const val PREFS_NAME = "FlutterSharedPreferences"
    // shared_preferences plugin prefixes keys with "flutter."
    private const val KEY = "flutter.pinned_locations"

    fun load(context: Context): List<PinnedLocation> {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val raw = prefs.getString(KEY, null) ?: return emptyList()
        return try {
            val arr = JSONArray(raw)
            (0 until arr.length()).map { i ->
                val o = arr.getJSONObject(i)
                PinnedLocation(
                    id = o.getString("id"),
                    name = o.getString("name"),
                    latitude = o.getDouble("latitude"),
                    longitude = o.getDouble("longitude"),
                    radiusMeters = o.getDouble("radiusMeters"),
                    enabled = o.optBoolean("enabled", true)
                )
            }
        } catch (t: Throwable) {
            Log.e(TAG, "Failed to parse pinned locations", t)
            emptyList()
        }
    }
}
