package com.example.juan_tracker

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioTrack
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import androidx.core.app.NotificationCompat
import kotlin.math.max

private const val TAG = "TimerForegroundService"
private const val CHANNEL_ID = "rest_timer_channel"
private const val NOTIFICATION_ID = 1001

const val ACTION_START = "com.juantraining.timer.START"
const val ACTION_UPDATE = "com.juantraining.timer.UPDATE"
const val ACTION_STOP = "com.juantraining.timer.STOP"
const val ACTION_PAUSE = "com.juantraining.timer.PAUSE"
const val ACTION_RESUME = "com.juantraining.timer.RESUME"
const val ACTION_SKIP = "com.juantraining.timer.SKIP"
const val ACTION_ADD30 = "com.juantraining.timer.ADD30"

const val EXTRA_TOTAL_SECONDS = "totalSeconds"
const val EXTRA_END_TIME_MS = "endTimeMillis"
const val EXTRA_IS_PAUSED = "isPaused"

class TimerForegroundService : Service() {
    private val handler = Handler(Looper.getMainLooper())
    private var runnable: Runnable? = null

    private var totalSeconds: Int = 90
    private var endTimeMs: Long = 0
    private var isPaused: Boolean = false

    override fun onCreate() {
        super.onCreate()
        createChannel()
        Log.d(TAG, "Service created")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        intent ?: return START_NOT_STICKY
        when (intent.action) {
            ACTION_START -> {
                totalSeconds = intent.getIntExtra(EXTRA_TOTAL_SECONDS, 90)
                endTimeMs = intent.getLongExtra(EXTRA_END_TIME_MS, 0)
                isPaused = intent.getBooleanExtra(EXTRA_IS_PAUSED, false)
                startForeground(NOTIFICATION_ID, buildNotification())
                // Notify Dart that native service started
                try { TimerEventBridge.channel?.invokeMethod("onServiceStarted", mapOf("totalSeconds" to totalSeconds)) } catch (_: Exception) {}
                startTicker()
                Log.d(TAG, "Timer started: $totalSeconds s endTime=$endTimeMs paused=$isPaused")
            }
            ACTION_UPDATE -> {
                totalSeconds = intent.getIntExtra(EXTRA_TOTAL_SECONDS, totalSeconds)
                endTimeMs = intent.getLongExtra(EXTRA_END_TIME_MS, endTimeMs)
                val newPaused = intent.getBooleanExtra(EXTRA_IS_PAUSED, isPaused)
                if (newPaused != isPaused) {
                    isPaused = newPaused
                    if (isPaused) stopTicker() else startTicker()
                }
                updateNotification()
                Log.d(TAG, "Timer updated: total=$totalSeconds end=$endTimeMs paused=$isPaused")
            }
            ACTION_PAUSE -> {
                if (!isPaused) {
                    isPaused = true
                    stopTicker()
                    updateNotification()
                    TimerEventBridge.channel?.invokeMethod("onPause", null)
                }
            }
            ACTION_RESUME -> {
                if (isPaused) {
                    isPaused = false
                    // recalculate endTime based on remaining seconds
                    val remaining = intent.getIntExtra(EXTRA_TOTAL_SECONDS, totalSeconds)
                    endTimeMs = System.currentTimeMillis() + remaining * 1000L
                    startTicker()
                    updateNotification()
                    TimerEventBridge.channel?.invokeMethod("onResume", null)
                }
            }
            ACTION_ADD30 -> {
                // add 30 seconds
                if (isPaused) {
                    totalSeconds += 30
                } else {
                    endTimeMs += 30 * 1000L
                }
                updateNotification()
                TimerEventBridge.channel?.invokeMethod("onAdd30", null)
            }
            ACTION_SKIP -> {
                TimerEventBridge.channel?.invokeMethod("onSkip", null)
                stopSelf()
            }
            ACTION_STOP -> {
                stopSelf()
                Log.d(TAG, "Timer stop requested")
            }
        }
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        stopTicker()
        stopAllTracks()
        try { TimerEventBridge.channel?.invokeMethod("onServiceStopped", null) } catch (_: Exception) {}
        Log.d(TAG, "Service destroyed")
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun startTicker() {
        runnable?.let { handler.removeCallbacks(it) }
        runnable = object : Runnable {
            override fun run() {
                val now = System.currentTimeMillis()
                if (!isPaused && endTimeMs > 0) {
                    val remaining = ((endTimeMs - now) / 1000).toInt()
                            if (remaining <= 0) {
                        // finished
                        playFinalBeep()
                        // Notify Dart side if channel available
                        try {
                            TimerEventBridge.channel?.invokeMethod("onFinished", null)
                        } catch (_: Exception) {}
                        stopSelf()
                        return
                    } else {
                        // play beeps at thresholds (10-6 -> low, 5-3 -> medium, 2-1 -> high)
                        when (remaining) {
                            in 6..10 -> playLowBeep()
                            in 3..5 -> playMediumBeep()
                            in 1..2 -> playHighBeep()
                        }
                    }
                }
                updateNotification()
                handler.postDelayed(this, 1000)
            }
        }
        handler.post(runnable!!)
    }

    private fun stopTicker() {
        runnable?.let { handler.removeCallbacks(it) }
        runnable = null
    }

    private fun updateNotification() {
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        nm.notify(NOTIFICATION_ID, buildNotification())
    }

    private fun buildNotification(): Notification {
        val remaining = if (isPaused || endTimeMs == 0L) totalSeconds else max(0, ((endTimeMs - System.currentTimeMillis()) / 1000).toInt())
        val minutes = remaining / 60
        val seconds = remaining % 60
        val timeStr = String.format("%02d:%02d", minutes, seconds)

        // PendingIntent to open the app
        val pi = packageManager.getLaunchIntentForPackage(packageName)?.let { launch ->
            PendingIntent.getActivity(this, 0, launch, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
        }

        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("🏋️ Descanso: $timeStr")
            .setContentText(if (isPaused) "Timer pausado" else "En curso")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setShowWhen(false)
            .setWhen(if (isPaused) 0 else endTimeMs)
            .setContentIntent(pi)
            .apply {
                // Add actions for pause/resume, +30s, skip
                val pauseIntent = Intent(this@TimerForegroundService, TimerForegroundService::class.java).apply { action = ACTION_PAUSE }
                val resumeIntent = Intent(this@TimerForegroundService, TimerForegroundService::class.java).apply { action = ACTION_RESUME }
                val add30Intent = Intent(this@TimerForegroundService, TimerForegroundService::class.java).apply { action = ACTION_ADD30 }
                val skipIntent = Intent(this@TimerForegroundService, TimerForegroundService::class.java).apply { action = ACTION_SKIP }

                val pausePi = PendingIntent.getService(this@TimerForegroundService, 1, pauseIntent, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
                val resumePi = PendingIntent.getService(this@TimerForegroundService, 2, resumeIntent, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
                val add30Pi = PendingIntent.getService(this@TimerForegroundService, 3, add30Intent, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
                val skipPi = PendingIntent.getService(this@TimerForegroundService, 4, skipIntent, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)

                if (isPaused) {
                    addAction(NotificationCompat.Action(0, "▶️ Reanudar", resumePi))
                } else {
                    addAction(NotificationCompat.Action(0, "⏸️ Pausar", pausePi))
                    addAction(NotificationCompat.Action(0, "+30s", add30Pi))
                }
                addAction(NotificationCompat.Action(0, "⏭️ Saltar", skipPi))
            }

        return builder.build()
    }

    // ===========================
    // BEEP UTILITIES (copiado/ligero)
    // ===========================
    private val _currentTracks = mutableListOf<AudioTrack>()

    private fun stopAllTracks() {
        synchronized(this) {
            for (t in _currentTracks.toList()) {
                try { if (t.playState == AudioTrack.PLAYSTATE_PLAYING) t.stop() } catch (_: Exception) {}
                try { t.release() } catch (_: Exception) {}
                _currentTracks.remove(t)
            }
        }
    }

    private fun playTone(freqHz: Double, durationMs: Int, volume: Float, useMusicStream: Boolean) {
        val sampleRate = 44100
        val toneSamples = (sampleRate * (durationMs / 1000.0)).toInt().coerceAtLeast(1)
        val silenceMs = 30
        val silenceSamples = (sampleRate * (silenceMs / 1000.0)).toInt().coerceAtLeast(1)
        val totalSamples = silenceSamples + toneSamples
        val samples = ShortArray(totalSamples)
        val fadeLength = (toneSamples / 16).coerceAtLeast(1)

        for (i in 0 until toneSamples) {
            val idx = silenceSamples + i
            val t = i.toDouble() / sampleRate
            val angle = 2.0 * Math.PI * freqHz * t
            var env = 1.0
            if (i < fadeLength) env = i.toDouble() / fadeLength
            else if (i > toneSamples - fadeLength) env = (toneSamples - i).toDouble() / fadeLength
            val s = (Math.sin(angle) * Short.MAX_VALUE * volume * env).toInt().toShort()
            samples[idx] = s
        }

        val minBuf = AudioTrack.getMinBufferSize(sampleRate, AudioFormat.CHANNEL_OUT_MONO, AudioFormat.ENCODING_PCM_16BIT)
        val bufferSizeInBytes = max(minBuf, totalSamples * 2)
        val streamType = if (useMusicStream) AudioManager.STREAM_MUSIC else AudioManager.STREAM_NOTIFICATION

        val track = AudioTrack(streamType, sampleRate, AudioFormat.CHANNEL_OUT_MONO, AudioFormat.ENCODING_PCM_16BIT, bufferSizeInBytes, AudioTrack.MODE_STATIC)
        try {
            track.write(samples, 0, samples.size)
            synchronized(this) { _currentTracks.add(track) }
            track.play()
            Thread.sleep((durationMs + silenceMs).toLong())
        } catch (e: Exception) {
            // ignore
        } finally {
            try { if (track.playState == AudioTrack.PLAYSTATE_PLAYING) track.stop() } catch (_: Exception) {}
            try { track.release() } catch (_: Exception) {}
            synchronized(this) { _currentTracks.remove(track) }
        }
    }

    private fun playLowBeep() { playTone(440.0, 100, 0.5f, false) }
    private fun playMediumBeep() { playTone(660.0, 150, 0.5f, false) }
    private fun playHighBeep() { playTone(880.0, 200, 0.6f, false) }
    private fun playFinalBeep() {
        playTone(1047.0, 200, 0.6f, false)
        Thread.sleep(150)
        playTone(1047.0, 200, 0.6f, false)
    }

    private fun createChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val ch = NotificationChannel(CHANNEL_ID, "Temporizador de Descanso", NotificationManager.IMPORTANCE_HIGH)
            ch.description = "Notificaciones del temporizador de descanso"
            ch.setSound(null, null)
            ch.vibrationPattern = longArrayOf(0)
            nm.createNotificationChannel(ch)
        }
    }
}
