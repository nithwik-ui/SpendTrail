package com.spendtrail.spendtrail

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Intent
import android.view.KeyEvent
import android.view.accessibility.AccessibilityEvent

class VolumeKeyService : AccessibilityService() {

    private var volumeDownPressTime: Long = 0L
    private val LONG_PRESS_THRESHOLD = 3000L // 3 seconds

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        // We don't need to process accessibility events — only key events
    }

    override fun onInterrupt() {
        // Required override — nothing needed
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        val info = AccessibilityServiceInfo().apply {
            eventTypes = 0 // We don't care about accessibility events
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            flags = AccessibilityServiceInfo.FLAG_REQUEST_FILTER_KEY_EVENTS
            notificationTimeout = 100
        }
        serviceInfo = info
    }

    override fun onKeyEvent(event: KeyEvent): Boolean {
        if (event.keyCode == KeyEvent.KEYCODE_VOLUME_DOWN) {
            when (event.action) {
                KeyEvent.ACTION_DOWN -> {
                    if (event.repeatCount == 0) {
                        volumeDownPressTime = System.currentTimeMillis()
                    } else {
                        // Check if held for 3 seconds
                        val elapsed = System.currentTimeMillis() - volumeDownPressTime
                        if (elapsed >= LONG_PRESS_THRESHOLD && volumeDownPressTime > 0) {
                            volumeDownPressTime = 0L // Reset to prevent repeated triggers
                            launchQuickAdd()
                            return true // Consume the event
                        }
                    }
                }
                KeyEvent.ACTION_UP -> {
                    volumeDownPressTime = 0L
                }
            }
        }
        return false // Let other key events pass through normally
    }

    private fun launchQuickAdd() {
        val intent = Intent(this, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            putExtra("OPEN_QUICK_ADD", true)
        }
        startActivity(intent)
    }
}
