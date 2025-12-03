import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../firebase_options.dart';
import 'api_client.dart';
import 'token_storage.dart';
import '../constants/app_constants.dart';

const _broadcastTopic = 'all-users';
const AndroidNotificationChannel _defaultAndroidChannel =
    AndroidNotificationChannel(
  'barvin_push_default',
  'General Notifications',
  description: 'Default channel for Barvin notifications',
  importance: Importance.high,
);

final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
var _localNotificationsReady = false;

@pragma('vm:entry-point')
void _onDidReceiveBackgroundNotificationResponse(
    NotificationResponse response) {
  debugPrint('[push] background notification tap payload=${response.payload}');
}

Future<void> _ensureLocalNotificationsInitialized() async {
  if (_localNotificationsReady) return;

  const initSettings = InitializationSettings(
    android: AndroidInitializationSettings('@drawable/ic_notification'),
    iOS: DarwinInitializationSettings(),
  );

  await _localNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (resp) {
      debugPrint('[push] notification tapped payload=${resp.payload}');
    },
    onDidReceiveBackgroundNotificationResponse:
        _onDidReceiveBackgroundNotificationResponse,
  );

  if (Platform.isAndroid) {
    final androidImpl =
        _localNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(_defaultAndroidChannel);
  }

  _localNotificationsReady = true;
}

Future<void> _showLocalNotification(RemoteMessage message) async {
  await _ensureLocalNotificationsInitialized();

  final title = message.notification?.title ?? message.data['title'];
  final body = message.notification?.body ?? message.data['body'];
  if (title == null && body == null) return;

  final details = NotificationDetails(
    android: AndroidNotificationDetails(
      _defaultAndroidChannel.id,
      _defaultAndroidChannel.name,
      channelDescription: _defaultAndroidChannel.description,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      icon: '@drawable/ic_notification',
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );

  await _localNotificationsPlugin.show(
    message.hashCode,
    title,
    body,
    details,
    payload: jsonEncode(message.data),
  );
}

/// Top-level handler for background/terminated FCM delivery.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint(
    '[push] background message ${message.messageId} data=${message.data}',
  );
  await _showLocalNotification(message);
}

class PushNotifications {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    await _ensureLocalNotificationsInitialized();

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    final hasPermission = await _requestNotificationPermission();
    if (!hasPermission) {
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
      _showLocalNotification(message);
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

  static Future<bool> _requestNotificationPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      if (status.isDenied || status.isRestricted) {
        final result = await Permission.notification.request();
        debugPrint('[push] notification permission (Android) $result');
        return result.isGranted;
      }
      return status.isGranted;
    }

    final allowed =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional;
    debugPrint('[push] permission status: ${settings.authorizationStatus}');
    return allowed;
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
