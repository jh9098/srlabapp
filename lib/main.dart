import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'core/config/app_config.dart';
import 'core/push/push_notification_service.dart';
import 'features/app/app.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  final config = AppConfig.fromEnvironment();
  if (!config.isFirebaseConfigured) {
    return;
  }
  await ensureFirebaseInitialized(config);
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  runApp(SrLabApp(config: AppConfig.fromEnvironment()));
}
