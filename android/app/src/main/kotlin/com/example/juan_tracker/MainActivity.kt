package com.example.juan_tracker

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel

class MainActivity : FlutterActivity() {
    private val MUSIC_CHANNEL = "juan_training/music_launcher"
    private val MUSIC_EVENTS_CHANNEL = "juan_training/music_events"
    private val TIMER_SERVICE_CHANNEL = "com.juantraining/timer_service"
    private val TIMER_EVENTS_CHANNEL = "com.juantraining/timer_events"
    private val BEEP_CHANNEL = "com.juantraining/beep_sound"

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
                    // Accept parameters; no-op implementation returns false to allow Flutter fallback
                    result.success(false)
                }
                "updateTimerService" -> {
                    result.success(false)
                }
                "stopTimerService" -> {
                    result.success(false)
                }
                else -> result.notImplemented()
            }
        }

        // Expose timer events channel to allow Dart to receive platform-initiated method calls if needed
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, TIMER_EVENTS_CHANNEL)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BEEP_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "beep" -> {
                    // no-op for now
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }
}
