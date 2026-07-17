package com.suvarna.jewellers.suvarna_jewellers

import android.content.Intent
import android.provider.Settings
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterFragmentActivity() {
    private val CHANNEL = "suvarna_jewellers/system_intent"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "openSecuritySettings") {
                try {
                    // Open the device's main Security / Biometrics management dashboard activity window directly
                    val intent = Intent(Settings.ACTION_SECURITY_SETTINGS)
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    startActivity(intent)
                    result.success(true)
                } catch (e: Exception) {
                    // Fallback to primary System Settings view if Security layout structure cannot be pulled explicitly
                    try {
                        val intentFallback = Intent(Settings.ACTION_SETTINGS)
                        intentFallback.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(intentFallback)
                        result.success(true)
                    } catch (err: Exception) {
                        result.error("UNAVAILABLE", "Could not open settings panels: ${err.message}", null)
                    }
                }
            } else {
                result.notImplemented()
            }
        }
    }
}