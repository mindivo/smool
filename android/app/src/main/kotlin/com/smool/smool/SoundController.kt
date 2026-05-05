package com.smool.smool

import android.content.Context
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.util.Log

/**
 * Plays the mute / unmute confirmation chimes from android/res/raw/.
 *
 * Audio is routed via USAGE_MEDIA (STREAM_MUSIC), which is not silenced by
 * RINGER_MODE_SILENT or by an INTERRUPTION_FILTER_PRIORITY DND policy, so the
 * confirmation is always audible regardless of which mute strategy
 * MuteController is using.
 */
object SoundController {
    private const val TAG = "Smool.Sound"

    fun playMute(context: Context) = play(context, R.raw.mute_alert, "mute")
    fun playUnmute(context: Context) = play(context, R.raw.unmute_alert, "unmute")

    private fun play(context: Context, resId: Int, label: String) {
        try {
            val player = MediaPlayer()
            player.setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_MEDIA)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build()
            )
            val afd = context.resources.openRawResourceFd(resId)
            if (afd == null) {
                Log.e(TAG, "Resource $label not found")
                player.release()
                return
            }
            afd.use {
                player.setDataSource(it.fileDescriptor, it.startOffset, it.length)
            }
            player.setOnCompletionListener { it.release() }
            player.setOnErrorListener { mp, what, extra ->
                Log.e(TAG, "MediaPlayer $label error: what=$what extra=$extra")
                mp.release()
                true
            }
            player.prepare()
            player.start()
            Log.d(TAG, "Playing $label chime")
        } catch (t: Throwable) {
            Log.e(TAG, "Failed to play $label chime", t)
        }
    }
}
