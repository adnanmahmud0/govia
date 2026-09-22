import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gsabino365/config/routes/app_pages.dart';
import 'package:gsabino365/core/services/api_client.dart';
import 'package:gsabino365/module/citizen/notification/controller/citizen_notification_controller.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  debugPrint('FCM Background message received: ${message.messageId}');
}

class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  bool isInitialized = false;
  String? fcmToken;

  /// Call in main() or during app initialization.
  /// If credentials file (google-services.json / GoogleService-Info.plist) is absent,
  /// this fails gracefully without halting the application.
  Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      final messaging = FirebaseMessaging.instance;

      // 1. Request permissions (iOS and Android 13+)
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint('FCM Permission status: ${settings.authorizationStatus}');

      // 2. Fetch FCM Token
      fcmToken = await messaging.getToken();
      debugPrint('FCM Token: $fcmToken');

      if (fcmToken != null) {
        _syncTokenWithBackend(fcmToken!);
      }

      // Listen for token refreshes
      messaging.onTokenRefresh.listen((newToken) {
        fcmToken = newToken;
        _syncTokenWithBackend(newToken);
      });

      // 3. Foreground message listener
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _handleForegroundMessage(message);
      });

      // 4. Background message tap listener (app in background)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleNotificationTap(message);
      });

      // 5. Cold start notification check
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      isInitialized = true;
      debugPrint('FCM Service successfully initialized.');
    } catch (e) {
      debugPrint(
        'FCM Service: Firebase initialization deferred. '
        'Add google-services.json (Android) / GoogleService-Info.plist (iOS) to enable push notifications. Error: $e',
      );
    }
  }

  /// Sync FCM token to backend user profile
  Future<void> _syncTokenWithBackend(String token) async {
    try {
      if (Get.isRegistered<ApiClient>()) {
        final apiClient = Get.find<ApiClient>();
        await apiClient.postData(
          '/user/fcm-token',
          {'fcmToken': token},
        );
      }
    } catch (_) {
      // Backend may not have /user/fcm-token implemented yet; ignore error
    }
  }

  /// Handles incoming notifications while the app is in the foreground
  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title'] ?? 'GoVia Alert';
    final body = notification?.body ?? message.data['body'] ?? '';

    // Refresh notification count/list if controller is active
    if (Get.isRegistered<CitizenNotificationController>()) {
      Get.find<CitizenNotificationController>().fetchNotifications();
    }

    // Display rich in-app toast/snackbar
    if (Get.context != null) {
      Get.rawSnackbar(
        titleText: Text(
          title,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        messageText: Text(
          body,
          style: GoogleFonts.inter(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 12,
          ),
        ),
        icon: const Icon(
          Icons.notifications_active_rounded,
          color: Color(0xFF38BDF8),
        ),
        backgroundColor: const Color(0xFF0F172A),
        borderRadius: 12,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: const Duration(seconds: 4),
        snackPosition: SnackPosition.TOP,
        onTap: (_) => _handleNotificationTap(message),
      );
    }
  }

  /// Routes the user to the relevant screen when a push notification is tapped
  void _handleNotificationTap(RemoteMessage message) {
    final type = message.data['type']?.toString().toLowerCase();
    final meetingId = message.data['meetingId']?.toString();
    final conversationId = message.data['conversationId']?.toString();

    if (type == 'meeting' || meetingId != null) {
      Get.toNamed(
        AppRoutes.citizenLiveCall,
        arguments: {'meetingId': meetingId, 'isHost': false},
      );
    } else if (type == 'chat' || conversationId != null) {
      Get.toNamed(AppRoutes.attorneyChatDetails);
    } else {
      Get.toNamed(AppRoutes.citizenNotification);
    }
  }
}
