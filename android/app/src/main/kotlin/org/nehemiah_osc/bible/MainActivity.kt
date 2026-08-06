package org.nehemiah_osc.bible

import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private var webReaderChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val channel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "eotcbible/web_reader",
        )
        webReaderChannel = channel

        // Tapping Stop on the service's notification has to reach Dart, which
        // owns the socket — the service can only take its own notification
        // down.
        WebReaderService.onStopRequested = {
            webReaderChannel?.invokeMethod("stopRequested", null)
        }

        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "startForeground" -> {
                    val intent = Intent(this, WebReaderService::class.java).apply {
                        action = WebReaderService.ACTION_START
                        putExtra(WebReaderService.EXTRA_TITLE, call.argument<String>("title"))
                        putExtra(WebReaderService.EXTRA_URL, call.argument<String>("url"))
                        putExtra(
                            WebReaderService.EXTRA_STOP_LABEL,
                            call.argument<String>("stopLabel"),
                        )
                    }
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        startForegroundService(intent)
                    } else {
                        startService(intent)
                    }
                    result.success(true)
                }

                "stopForeground" -> {
                    stopService(Intent(this, WebReaderService::class.java))
                    result.success(true)
                }

                else -> result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        // The Dart server dies with the engine, so the notification must not
        // outlive it — otherwise the user is told something is being served
        // when nothing is.
        WebReaderService.onStopRequested = null
        stopService(Intent(this, WebReaderService::class.java))
        webReaderChannel?.setMethodCallHandler(null)
        webReaderChannel = null
        super.onDestroy()
    }
}
