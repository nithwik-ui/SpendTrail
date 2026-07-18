package com.spendtrail.app.spendtrail

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.spendtrail.app/quick_tile"
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getTileLaunchState") {
                val launchedFromTile = intent.getBooleanExtra("launched_from_tile", false)
                if (launchedFromTile) {
                    intent.removeExtra("launched_from_tile")
                }
                result.success(launchedFromTile)
            } else {
                result.notImplemented()
            }
        }
    }
    
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent) 
        if (intent.getBooleanExtra("launched_from_tile", false)) {
            flutterEngine?.dartExecutor?.binaryMessenger?.let {
                MethodChannel(it, CHANNEL).invokeMethod("tileClicked", null)
            }
            intent.removeExtra("launched_from_tile")
        }
    }
}
