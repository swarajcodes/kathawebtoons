package com.katha.kathawebtoons.kathawebtoons

import android.os.Bundle
import android.view.WindowManager
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "secure_screen_channel"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Setup MethodChannel to communicate with Flutter
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "enableSecureScreen" -> {
                    // Enable screenshot blocking
                    window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    result.success(true)
                }
                "disableSecureScreen" -> {
                    // Disable screenshot blocking
                    window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}