import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../firebase_options.dart';
import 'api_client.dart';
import 'token_storage.dart';
import '../constants/app_constants.dart';

const _broadcastTopic = 'all-users';

/// Top-level handler for background/terminated FCM delivery.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint(
    '[push] background message ${message.messageId} data=${message.data}',
  );
}

class PushNotifications {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('[push] permission status: ${settings.authorizationStatus}');
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return;
    }

    final token = await _messaging.getToken();
    if (token != null) {
      debugPrint('[push] FCM token: $token');
      await _registerToken(token);
    }

    _messaging.onTokenRefresh.listen(
      (token) async {
        debugPrint('[push] refreshed FCM token: $token');
        _subscribeToBroadcastTopic();
        await _registerToken(token);
      },
    );

    await _subscribeToBroadcastTopic();

    FirebaseMessaging.onMessage.listen((message) {
      debugPrint(
        '[push] foreground message ${message.messageId} data=${message.data}',
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint(
        '[push] notification tap ${message.messageId} data=${message.data}',
      );
    });

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint(
        '[push] launched from notification ${initialMessage.messageId} '
        'data=${initialMessage.data}',
      );
    }
  }

  static Future<void> _registerToken(String fcmToken) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = await TokenStorage.read();
      if (authToken == null || authToken.isEmpty) {
        debugPrint('[push] skip register (no auth token)');
        return;
      }

      final pkg = await PackageInfo.fromPlatform();
      final savedLocale = prefs.getString('locale');
      final localeCode = savedLocale ??
          WidgetsBinding.instance.platformDispatcher.locale.languageCode;

      final platform = Platform.isIOS
          ? 'ios'
          : Platform.isAndroid
              ? 'android'
              : Platform.operatingSystem;

      final body = {
        'token': fcmToken,
        'platform': platform,
        'device': Platform.operatingSystemVersion,
        'app_version': pkg.version,
        'app_build': pkg.buildNumber,
        'language': localeCode,
      };

      await ApiClient.instance.post(
        AppEndpoints.notificationsRegisterToken,
        body: jsonEncode(body),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
      );
      debugPrint('[push] token registered with backend');
    } catch (e) {
      debugPrint('[push] error registering token: $e');
    }
  }

  static Future<void> _subscribeToBroadcastTopic() async {
    try {
      await _messaging.subscribeToTopic(_broadcastTopic);
      debugPrint('[push] subscribed to topic $_broadcastTopic');
    } catch (e) {
      debugPrint('[push] failed to subscribe to topic $_broadcastTopic: $e');
    }
  }
}
