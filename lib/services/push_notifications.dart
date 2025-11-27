import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

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
    }

    _messaging.onTokenRefresh.listen(
      (token) => debugPrint('[push] refreshed FCM token: $token'),
    );

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
}
