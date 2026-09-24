import 'package:flutter/foundation.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Centralized service to manage screen wake lock state.
/// Ensures the device screen does not sleep or auto-lock during video calls
/// and meetings while safely restoring normal behavior upon leaving.
class WakelockService {
  WakelockService._();

  static bool _isEnabled = false;

  /// Returns true if wake lock is currently active.
  static bool get isWakeLockActive => _isEnabled;

  /// Prevents the screen from turning off or the phone from auto-locking.
  static Future<void> enable() async {
    try {
      await WakelockPlus.enable();
      _isEnabled = true;
      debugPrint('🔆 [WakelockService] Screen wake lock ENABLED (auto-lock prevented)');
    } catch (e) {
      debugPrint('⚠️ [WakelockService] Could not enable screen wake lock: $e');
    }
  }

  /// Restores normal OS screen timeout and auto-lock behavior.
  static Future<void> disable() async {
    try {
      await WakelockPlus.disable();
      _isEnabled = false;
      debugPrint('🌙 [WakelockService] Screen wake lock DISABLED (normal timeout restored)');
    } catch (e) {
      debugPrint('⚠️ [WakelockService] Could not disable screen wake lock: $e');
    }
  }

  /// Checks if wake lock is currently supported and enabled on this device.
  static Future<bool> isEnabled() async {
    try {
      return await WakelockPlus.enabled;
    } catch (e) {
      return _isEnabled;
    }
  }
}
