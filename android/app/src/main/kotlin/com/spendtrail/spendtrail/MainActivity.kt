package com.spendtrail.spendtrail

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val UPDATER_CHANNEL = "com.spendtrail.spendtrail/updater"
    private val SHORTCUT_CHANNEL = "com.spendtrail.spendtrail/shortcut"

    private var pendingQuickAdd = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ── Updater channel ─────────────────────────────────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, UPDATER_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "installApk") {
                val apkPath = call.argument<String>("path")
                if (apkPath != null) {
                    try {
                        installApk(apkPath)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("INSTALL_ERROR", e.localizedMessage, null)
                    }
                } else {
                    result.error("INVALID_PATH", "APK path was null", null)
                }
            } else {
                result.notImplemented()
            }
        }

        // ── Shortcut channel ────────────────────────────────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SHORTCUT_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "moveTaskToBack" -> {
                    moveTaskToBack(true)
                    result.success(true)
                }
                "checkPendingQuickAdd" -> {
                    result.success(pendingQuickAdd)
                    pendingQuickAdd = false
                }
                "openAccessibilitySettings" -> {
                    val intent = Intent(android.provider.Settings.ACTION_ACCESSIBILITY_SETTINGS)
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    startActivity(intent)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        // Check if launched with quick-add intent
        handleQuickAddIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleQuickAddIntent(intent)
    }

    private fun handleQuickAddIntent(intent: Intent?) {
        if (intent?.getBooleanExtra("OPEN_QUICK_ADD", false) == true) {
            pendingQuickAdd = true
            // Notify Flutter side via method channel if engine is ready
            flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                MethodChannel(messenger, SHORTCUT_CHANNEL).invokeMethod("openQuickAdd", null)
            }
            // Clear the flag so re-delivery doesn't re-trigger
            intent.removeExtra("OPEN_QUICK_ADD")
        }
    }

    private fun installApk(apkPath: String) {
        val file = File(apkPath)
        val context = applicationContext
        val apkUri: Uri = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            FileProvider.getUriForFile(context, "${context.packageName}.fileprovider", file)
        } else {
            Uri.fromFile(file)
        }

        val installIntent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(apkUri, "application/vnd.android.package-archive")
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        context.startActivity(installIntent)
    }
}
