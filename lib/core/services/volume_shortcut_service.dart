import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service that handles Volume-Down long-press quick-add shortcut.
///
/// Communicates with native VolumeKeyService via MethodChannel.
/// The native service sends `openQuickAdd` when a 3-second long-press
/// on Volume Down is detected.
class VolumeShortcutService {
  static const _channel = MethodChannel('com.spendtrail.spendtrail/shortcut');
  static const _permissionExplainedKey = 'volume_shortcut_explained';

  /// Callback invoked when volume-down quick-add is triggered
  static Function? onQuickAddRequested;

  /// Initialize the channel listener — call once from main app widget
  static void init() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'openQuickAdd') {
        onQuickAddRequested?.call();
      }
    });
  }

  /// Check if there's a pending quick-add from before Flutter was ready
  static Future<bool> checkPendingQuickAdd() async {
    try {
      final bool pending = await _channel.invokeMethod<bool>('checkPendingQuickAdd') ?? false;
      return pending;
    } catch (e) {
      return false;
    }
  }

  /// Send the app to background (used after quick-add save)
  static Future<void> moveTaskToBack() async {
    try {
      await _channel.invokeMethod('moveTaskToBack');
    } catch (e) {
      // Silently fail — not critical
    }
  }

  /// Check if we've already shown the permission explanation
  static Future<bool> hasExplainedPermission() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_permissionExplainedKey) ?? false;
  }

  /// Mark that we've shown the permission explanation
  static Future<void> markPermissionExplained() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_permissionExplainedKey, true);
  }

  /// Open Android Accessibility Settings
  static Future<void> openAccessibilitySettings() async {
    const intent = AndroidIntent(
      action: 'android.settings.ACCESSIBILITY_SETTINGS',
    );
    // We use the platform channel directly since android_intent_plus isn't available
    try {
      await _channel.invokeMethod('openAccessibilitySettings');
    } catch (e) {
      // Fall back to nothing — user can open manually
    }
  }
}

/// Placeholder — we handle the intent opening natively
class AndroidIntent {
  final String action;
  const AndroidIntent({required this.action});
}
