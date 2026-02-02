package com.example.juan_tracker

import android.content.Context
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioTrack
import android.content.Intent
import android.os.Build
import android.util.Log
import kotlin.math.max

object TimerEventBridge { var channel: MethodChannel? = null }

class MainActivity : FlutterActivity() {
    private val MUSIC_CHANNEL = "juan_training/music_launcher"
    private val MUSIC_EVENTS_CHANNEL = "juan_training/music_events"
    private val TIMER_SERVICE_CHANNEL = "com.juantraining/timer_service"
    private val TIMER_EVENTS_CHANNEL = "com.juantraining/timer_events"
    private val BEEP_CHANNEL = "com.juantraining/beep_sound"
    private val HOME_WIDGET_CHANNEL = "com.juantracker/home_widget"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, MUSIC_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isMusicActive" -> result.success(false)
                "getMediaSession" -> result.success(null)
                "mediaPlayPause", "mediaNext", "mediaPrevious" -> result.success(null)
                else -> result.notImplemented()
            }
        }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, MUSIC_EVENTS_CHANNEL).setStreamHandler(object: EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                // No-op for now; platform can emit events here in the future
            }

            override fun onCancel(arguments: Any?) {}
        })

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, TIMER_SERVICE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startTimerService" -> {
                    val totalSeconds = call.argument<Int>("totalSeconds") ?: 90
                    val endTimeMillis = call.argument<Long>("endTimeMillis") ?: 0L
                    val isPaused = call.argument<Boolean>("isPaused") ?: false
                    try {
                        val intent = Intent(this, TimerForegroundService::class.java).apply {
                            action = ACTION_START
                            putExtra(EXTRA_TOTAL_SECONDS, totalSeconds)
                            putExtra(EXTRA_END_TIME_MS, endTimeMillis)
                            putExtra(EXTRA_IS_PAUSED, isPaused)
                        }
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(intent)
                        } else {
                            startService(intent)
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "updateTimerService" -> {
                    val totalSeconds = call.argument<Int>("totalSeconds")
                    val endTimeMillis = call.argument<Long>("endTimeMillis")
                    val isPaused = call.argument<Boolean>("isPaused")
                    try {
                        val intent = Intent(this, TimerForegroundService::class.java).apply {
                            action = ACTION_UPDATE
                            totalSeconds?.let { putExtra(EXTRA_TOTAL_SECONDS, it) }
                            endTimeMillis?.let { putExtra(EXTRA_END_TIME_MS, it) }
                            isPaused?.let { putExtra(EXTRA_IS_PAUSED, it) }
                        }
                        startService(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "stopTimerService" -> {
                    try {
                        val intent = Intent(this, TimerForegroundService::class.java).apply { action = ACTION_STOP }
                        startService(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // Expose timer events channel to allow Dart to receive platform-initiated method calls if needed
        val timerEvents = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, TIMER_EVENTS_CHANNEL)
        TimerEventBridge.channel = timerEvents

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BEEP_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "beep", "playBeep" -> {
                    val frequency = (call.argument<Int>("frequency") ?: 440).toDouble()
                    val duration = call.argument<Int>("durationMs") ?: 150
                    val vol = (call.argument<Double>("volume") ?: 0.5)
                    val useMusic = call.argument<Boolean>("useMusicStream") ?: false
                    Thread {
                        try {
                            Log.d("BEEP_NATIVE", "playBeep called: freq=$frequency dur=$duration vol=$vol useMusic=$useMusic")
                            playTone(frequency, duration, vol.toFloat(), useMusic)
                            Log.d("BEEP_NATIVE", "playBeep finished: freq=$frequency")
                        } catch (e: Exception) {
                            Log.e("BEEP_NATIVE", "playBeep error", e)
                        }
                    }.start()
                    result.success(true)
                }
                "playDoubleBeep" -> {
                    val frequency = (call.argument<Int>("frequency") ?: 1047).toDouble()
                    val duration = call.argument<Int>("durationMs") ?: 250
                    val gap = call.argument<Int>("gapMs") ?: 150
                    val vol = (call.argument<Double>("volume") ?: 0.5)
                    val useMusic = call.argument<Boolean>("useMusicStream") ?: false
                    Thread {
                        try {
                            Log.d("BEEP_NATIVE", "playDoubleBeep called: freq=$frequency dur=$duration gap=$gap vol=$vol useMusic=$useMusic")
                            playTone(frequency, duration, vol.toFloat(), useMusic)
                            Thread.sleep(gap.toLong())
                            playTone(frequency, duration, vol.toFloat(), useMusic)
                            Log.d("BEEP_NATIVE", "playDoubleBeep finished: freq=$frequency")
                        } catch (e: Exception) {
                            Log.e("BEEP_NATIVE", "playDoubleBeep error", e)
                        }
                    }.start()
                    result.success(true)
                }
                "playSequence" -> {
                    @Suppress("UNCHECKED_CAST")
                    val freqsRaw = call.argument<List<Any>>("frequencies") ?: emptyList()
                    val freqs = freqsRaw.map { when (it) { is Int -> it.toDouble(); is Double -> it; else -> (it.toString().toDoubleOrNull() ?: 440.0) } }
                    val durations = call.argument<List<Int>>("durations") ?: List(freqs.size) { 100 }
                    val gaps = call.argument<List<Int>>("gaps") ?: List(freqs.size) { 50 }
                    val vol = (call.argument<Double>("volume") ?: 0.5)
                    val useMusic = call.argument<Boolean>("useMusicStream") ?: false
                    Thread {
                        try {
                            for (i in freqs.indices) {
                                val f = freqs[i]
                                val d = durations.getOrNull(i) ?: 100
                                Log.d("BEEP_NATIVE", "playSequence tone: freq=$f dur=$d")
                                playTone(f, d, vol.toFloat(), useMusic)
                                if (i < freqs.size - 1) {
                                    val g = gaps.getOrNull(i) ?: 50
                                    Thread.sleep(g.toLong())
                                }
                            }
                        } catch (e: Exception) {
                            // ignore
                        }
                    }.start()
                    result.success(true)
                }
                "dispose" -> {
                    stopAllTracks()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        // Home Widget Channel - Comunicación con el widget de home screen
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, HOME_WIDGET_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "updateWidget" -> {
                    // Guardar datos del widget en SharedPreferences
                    val widgetData = call.argument<String>("widgetData")
                    if (widgetData != null) {
                        val prefs = getSharedPreferences(WorkoutWidgetProvider.PREFS_NAME, Context.MODE_PRIVATE)
                        prefs.edit().putString("widget_data", widgetData).apply()
                    }
                    // Forzar actualización del widget
                    WorkoutWidgetProvider.updateAllWidgets(this)
                    result.success(true)
                }
                "clearWidget" -> {
                    val prefs = getSharedPreferences(WorkoutWidgetProvider.PREFS_NAME, Context.MODE_PRIVATE)
                    prefs.edit().remove("widget_data").apply()
                    WorkoutWidgetProvider.updateAllWidgets(this)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    // Helper fields and functions for tone generation / resource management
    private val _currentTracks = mutableListOf<AudioTrack>()

    private fun stopAllTracks() {
        synchronized(this) {
            for (t in _currentTracks.toList()) {
                try {
                    if (t.playState == AudioTrack.PLAYSTATE_PLAYING) t.stop()
                } catch (_: Exception) {}
                try { t.release() } catch (_: Exception) {}
                _currentTracks.remove(t)
            }
        }
    }

    private fun playTone(freqHz: Double, durationMs: Int, volume: Float, useMusicStream: Boolean) {
        val sampleRate = 44100
        val toneSamples = (sampleRate * (durationMs / 1000.0)).toInt().coerceAtLeast(1)
        // Add a short silent lead-in to allow hardware buffers to stabilize and avoid the initial 'grave' click
        val silenceMs = 30
        val silenceSamples = (sampleRate * (silenceMs / 1000.0)).toInt().coerceAtLeast(1)
        val totalSamples = silenceSamples + toneSamples
        val samples = ShortArray(totalSamples)

        // Use a slightly shorter fade for tone portion to keep it crisp but avoid clicks
        val fadeLength = (toneSamples / 16).coerceAtLeast(1)

        for (i in 0 until toneSamples) {
            val idx = silenceSamples + i
            val t = i.toDouble() / sampleRate
            val angle = 2.0 * Math.PI * freqHz * t
            var env = 1.0
            if (i < fadeLength) {
                env = i.toDouble() / fadeLength
            } else if (i > toneSamples - fadeLength) {
                env = (toneSamples - i).toDouble() / fadeLength
            }
            val s = (Math.sin(angle) * Short.MAX_VALUE * volume * env).toInt().toShort()
            samples[idx] = s
        }

        // silenceSamples at the start remain zero

        val minBuf = AudioTrack.getMinBufferSize(sampleRate, AudioFormat.CHANNEL_OUT_MONO, AudioFormat.ENCODING_PCM_16BIT)
        val bufferSizeInBytes = max(minBuf, totalSamples * 2)
        val streamType = if (useMusicStream) AudioManager.STREAM_MUSIC else AudioManager.STREAM_NOTIFICATION

        val track = AudioTrack(streamType, sampleRate, AudioFormat.CHANNEL_OUT_MONO, AudioFormat.ENCODING_PCM_16BIT, bufferSizeInBytes, AudioTrack.MODE_STATIC)
        try {
            Log.d("BEEP_NATIVE", "Starting playback: freq=$freqHz duration=${durationMs + silenceMs}ms (incl. silence) stream=$streamType")
            track.write(samples, 0, samples.size)
            synchronized(this) { _currentTracks.add(track) }
            track.play()
            // Wait for entire buffer (tone + silence lead-in)
            Thread.sleep((durationMs + silenceMs).toLong())
            Log.d("BEEP_NATIVE", "Playback finished: freq=$freqHz")
        } catch (e: Exception) {
            Log.e("BEEP_NATIVE", "Playback error", e)
        } finally {
            try { if (track.playState == AudioTrack.PLAYSTATE_PLAYING) track.stop() } catch (_: Exception) {}
            try { track.release() } catch (_: Exception) {}
            synchronized(this) { _currentTracks.remove(track) }
        }
    }
}
