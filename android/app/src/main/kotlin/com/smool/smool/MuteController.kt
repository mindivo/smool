package com.smool.smool

import android.app.NotificationManager
import android.content.Context
import android.util.Log

object MuteController {
    private const val TAG = "Smool.Mute"

    fun mute(context: Context): Boolean {
        val changed = setInterruptionFilter(context, NotificationManager.INTERRUPTION_FILTER_PRIORITY)
        if (changed) SoundController.playMute(context)
        return changed
    }

    fun unmute(context: Context): Boolean {
        val changed = setInterruptionFilter(context, NotificationManager.INTERRUPTION_FILTER_ALL)
        if (changed) SoundController.playUnmute(context)
        return changed
    }

    /**
     * @return true if the DND filter actually transitioned to [filter];
     *         false if it was already in that state, the policy access is not
     *         granted, or the call failed. The callers above use this to gate
     *         the chime so it only fires on real transitions.
     */
    private fun setInterruptionFilter(context: Context, filter: Int): Boolean {
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (!nm.isNotificationPolicyAccessGranted) {
            Log.w(TAG, "DND policy access NOT granted; cannot change DND mode.")
            return false
        }
        val before = nm.currentInterruptionFilter
        if (before == filter) {
            Log.d(TAG, "DND already in mode $filter; no-op.")
            return false
        }
        return try {
            nm.setInterruptionFilter(filter)
            val after = nm.currentInterruptionFilter
            val ok = after == filter
            Log.i(TAG, "DND: $before -> $filter (observed $after, ok=$ok)")
            ok
        } catch (t: Throwable) {
            Log.e(TAG, "Failed to set DND mode to $filter", t)
            false
        }
    }
}
