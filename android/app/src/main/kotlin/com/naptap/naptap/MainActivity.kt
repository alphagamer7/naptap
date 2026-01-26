package com.naptap.naptap

import android.app.ActivityManager
import android.content.Context
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.naptap/screen_lock"
    private var isLocked = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startLockTask" -> {
                    startLockMode()
                    result.success(true)
                }
                "stopLockTask" -> {
                    stopLockMode()
                    result.success(true)
                }
                "isLocked" -> {
                    result.success(isLocked)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun startLockMode() {
        isLocked = true

        // Keep screen on
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

        // Show when locked and turn screen on
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
            )
        }

        // Start screen pinning (lock task mode)
        // This will show a system dialog asking user to confirm
        try {
            startLockTask()
        } catch (e: Exception) {
            // If lock task fails, the app still runs but user can exit
            e.printStackTrace()
        }
    }

    private fun stopLockMode() {
        isLocked = false

        // Remove keep screen on flag
        window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

        // Stop screen pinning
        try {
            stopLockTask()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    override fun onBackPressed() {
        // Block back button when locked
        if (isLocked) {
            // Do nothing - blocked
            return
        }
        super.onBackPressed()
    }
}
