package br.com.hostaraguaia.bina_intercept

import android.os.Bundle
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.bina_intercept/call"

    companion object {
        var eventSink: MethodChannel.Result? = null // Not used for simple channel
        var channel: MethodChannel? = null

        fun sendCallEvent(number: String, source: String) {
            Handler(Looper.getMainLooper()).post {
                channel?.invokeMethod("onIncomingCall", mapOf(
                    "number" to number,
                    "source" to source
                ))
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        channel?.setMethodCallHandler { call, result ->
             if (call.method == "checkPermission") {
                 // Placeholder for permission check if needed
                 result.success(true)
             } else {
                 result.notImplemented()
             }
        }
    }
}
