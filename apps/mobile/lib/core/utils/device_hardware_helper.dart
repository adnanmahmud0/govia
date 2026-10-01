import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:livekit_client/livekit_client.dart';

/// Helper to safely detect hardware capabilities, particularly avoiding native
/// WebRTC / AVFoundation crashes on iOS Simulators without camera sensors.
class DeviceHardwareHelper {
  DeviceHardwareHelper._();

  static bool? _cachedIsSimulator;
  static bool? _cachedHasCamera;
  static bool? _cachedUnsafeAndroidEmulatorAudio;

  /// flutter_webrtc currently aborts in AudioRecord on Android 17 preview
  /// x86_64 emulators. Physical devices are not affected by this guard.
  static Future<bool> hasUnsafeAndroidEmulatorAudio() async {
    if (kIsWeb || !Platform.isAndroid) return false;
    if (_cachedUnsafeAndroidEmulatorAudio != null) {
      return _cachedUnsafeAndroidEmulatorAudio!;
    }
    try {
      final info = await DeviceInfoPlugin().androidInfo;
      _cachedUnsafeAndroidEmulatorAudio =
          !info.isPhysicalDevice && info.version.sdkInt >= 37;
    } catch (e) {
      debugPrint('[DeviceHardwareHelper] Android emulator check error: $e');
      _cachedUnsafeAndroidEmulatorAudio = false;
    }
    return _cachedUnsafeAndroidEmulatorAudio!;
  }

  /// Returns true if currently running inside an iOS Simulator.
  static Future<bool> isIosSimulator() async {
    if (kIsWeb) return false;
    if (_cachedIsSimulator != null) return _cachedIsSimulator!;

    if (Platform.isIOS) {
      try {
        final iosInfo = await DeviceInfoPlugin().iosInfo;
        _cachedIsSimulator = !iosInfo.isPhysicalDevice;
        return _cachedIsSimulator!;
      } catch (e) {
        debugPrint('[DeviceHardwareHelper] iOS device check error: $e');
        return false;
      }
    }
    _cachedIsSimulator = false;
    return false;
  }

  /// Checks whether a real physical camera is available for video capture.
  /// On iOS Simulator or devices with no video input devices, returns false to
  /// prevent native WebRTC AVFoundation fatal crashes.
  static Future<bool> hasCameraDevice() async {
    if (_cachedHasCamera != null) return _cachedHasCamera!;

    final isSim = await isIosSimulator();
    if (isSim) {
      debugPrint('📱 [DeviceHardwareHelper] iOS Simulator detected: camera hardware absent.');
      _cachedHasCamera = false;
      return false;
    }

    try {
      final videoInputs = await Hardware.instance.videoInputs();
      final hasCam = videoInputs.isNotEmpty;
      _cachedHasCamera = hasCam;
      return hasCam;
    } catch (e) {
      debugPrint('[DeviceHardwareHelper] Video input enumeration error: $e');
      // If error occurs, assume physical device has camera unless on simulator
      _cachedHasCamera = !isSim;
      return _cachedHasCamera!;
    }
  }
}
