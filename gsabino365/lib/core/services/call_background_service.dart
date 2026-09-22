import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

@pragma('vm:entry-point')
void startCallForegroundCallback() {
  FlutterForegroundTask.setTaskHandler(CallForegroundTaskHandler());
}

class CallForegroundTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    debugPrint('📞 [CallBackgroundService] Foreground task started');
  }

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isStopping) async {
    debugPrint('📞 [CallBackgroundService] Foreground task destroyed');
  }
}

/// Service to maintain an ongoing Android foreground service notification
/// during active video/audio meetings so that the OS does not kill microphone
/// capture or WebRTC sockets when the phone is locked or in the user's pocket.
class CallBackgroundService {
  CallBackgroundService._();

  static bool _initialized = false;

  static void initialize() {
    if (_initialized || !Platform.isAndroid) return;

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'govia_active_call_channel',
        channelName: 'GoVia Active Call',
        channelDescription: 'Maintains live audio during ongoing GoVia sessions',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        enableVibration: false,
        playSound: false,
        showWhen: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );

    _initialized = true;
  }

  /// Starts the ongoing foreground notification during an active call.
  static Future<void> start({
    String title = 'GoVia Live Consultation',
    String text = 'Call in progress • Audio active',
  }) async {
    if (!Platform.isAndroid) return;

    try {
      initialize();

      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.updateService(
          notificationTitle: title,
          notificationText: text,
        );
        return;
      }

      await FlutterForegroundTask.startService(
        serviceId: 1001,
        notificationTitle: title,
        notificationText: text,
        callback: startCallForegroundCallback,
      );
      debugPrint('🎙️ [CallBackgroundService] Started foreground call service');
    } catch (e) {
      debugPrint('⚠️ [CallBackgroundService] Could not start service: $e');
    }
  }

  /// Stops the ongoing foreground service when call ends.
  static Future<void> stop() async {
    if (!Platform.isAndroid) return;

    try {
      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.stopService();
        debugPrint('⏹️ [CallBackgroundService] Stopped foreground call service');
      }
    } catch (e) {
      debugPrint('⚠️ [CallBackgroundService] Could not stop service: $e');
    }
  }
}
