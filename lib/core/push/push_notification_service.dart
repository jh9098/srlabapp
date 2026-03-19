import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../network/api_client.dart';

class PushNotificationBootstrapResult {
  const PushNotificationBootstrapResult({
    required this.isConfigured,
    required this.didRegisterToken,
    required this.message,
    this.deviceTokenPreview,
  });

  final bool isConfigured;
  final bool didRegisterToken;
  final String message;
  final String? deviceTokenPreview;
}

class PushNotificationService {
  PushNotificationService({required AppConfig config, required ApiClient apiClient})
      : _config = config,
        _apiClient = apiClient;

  final AppConfig _config;
  final ApiClient _apiClient;

  Future<PushNotificationBootstrapResult> bootstrap() async {
    if (!_config.isFirebaseConfigured) {
      return const PushNotificationBootstrapResult(
        isConfigured: false,
        didRegisterToken: false,
        message: 'Firebase 설정값이 없어 푸시 초기화를 건너뜁니다.',
      );
    }

    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: _buildFirebaseOptions());
    }
    final messaging = FirebaseMessaging.instance;
    final permission = await messaging.requestPermission(alert: true, badge: true, sound: true, provisional: false);
    if (permission.authorizationStatus == AuthorizationStatus.denied) {
      return const PushNotificationBootstrapResult(
        isConfigured: true,
        didRegisterToken: false,
        message: '알림 권한이 거부되어 토큰 등록을 건너뜁니다.',
      );
    }

    final token = await messaging.getToken(vapidKey: _config.firebaseWebVapidKey.isEmpty ? null : _config.firebaseWebVapidKey);
    if (token == null || token.isEmpty) {
      return const PushNotificationBootstrapResult(
        isConfigured: true,
        didRegisterToken: false,
        message: 'FCM 토큰을 아직 받지 못했습니다.',
      );
    }

    await _registerToken(token);
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('Foreground push received: ${message.messageId}');
    });
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('Push opened app: ${message.data}');
    });
    FirebaseMessaging.instance.onTokenRefresh.listen(_registerToken);

    return PushNotificationBootstrapResult(
      isConfigured: true,
      didRegisterToken: true,
      message: 'FCM 토큰을 백엔드에 등록했습니다.',
      deviceTokenPreview: token.length > 16 ? '${token.substring(0, 16)}...' : token,
    );
  }

  FirebaseOptions _buildFirebaseOptions() {
    final appId = _resolveAppId();
    return FirebaseOptions(
      apiKey: _config.firebaseApiKey,
      appId: appId,
      messagingSenderId: _config.firebaseMessagingSenderId,
      projectId: _config.firebaseProjectId,
      iosBundleId: _config.firebaseIosBundleId.isEmpty ? null : _config.firebaseIosBundleId,
    );
  }

  String _resolveAppId() {
    if (kIsWeb && _config.firebaseWebAppId.isNotEmpty) {
      return _config.firebaseWebAppId;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _config.firebaseAndroidAppId.isNotEmpty ? _config.firebaseAndroidAppId : _config.firebaseAppId;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return _config.firebaseAppId;
      default:
        return _config.firebaseAppId.isNotEmpty ? _config.firebaseAppId : _config.firebaseWebAppId;
    }
  }

  Future<void> _registerToken(String token) {
    return _apiClient.post(
      'me/device-tokens',
      requiresUser: true,
      body: {
        'device_token': token,
        'platform': _platformLabel(),
        'provider': 'fcm',
        'device_label': 'flutter-${defaultTargetPlatform.name}',
      },
    );
  }

  String _platformLabel() {
    if (kIsWeb) {
      return 'web';
    }
    return defaultTargetPlatform.name;
  }
}
