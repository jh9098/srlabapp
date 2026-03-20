import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../navigation/app_navigator.dart';
import '../network/api_client.dart';
import 'push_message_router.dart';

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
  PushNotificationService({
    required AppConfig config,
    required ApiClient apiClient,
    required AppNavigator appNavigator,
  })  : _config = config,
        _apiClient = apiClient,
        _messageRouter = PushMessageRouter(appNavigator);

  final AppConfig _config;
  final ApiClient _apiClient;
  final PushMessageRouter _messageRouter;
  bool _listenersBound = false;

  Future<PushNotificationBootstrapResult> bootstrap() async {
    if (!_config.isFirebaseConfigured) {
      return const PushNotificationBootstrapResult(
        isConfigured: false,
        didRegisterToken: false,
        message: 'Firebase 설정값이 없어 푸시 초기화를 건너뜁니다.',
      );
    }

    await ensureFirebaseInitialized(_config);

    final messaging = FirebaseMessaging.instance;
    final permission = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    if (permission.authorizationStatus == AuthorizationStatus.denied) {
      return const PushNotificationBootstrapResult(
        isConfigured: true,
        didRegisterToken: false,
        message: '알림 권한이 거부되어 토큰 등록을 건너뜁니다.',
      );
    }

    await messaging.setAutoInitEnabled(true);
    await _bindListeners();

    final token = await messaging.getToken(
      vapidKey: _config.firebaseWebVapidKey.isEmpty ? null : _config.firebaseWebVapidKey,
    );
    if (token == null || token.isEmpty) {
      return const PushNotificationBootstrapResult(
        isConfigured: true,
        didRegisterToken: false,
        message: 'FCM 토큰을 아직 받지 못했습니다.',
      );
    }

    await _registerToken(token);
    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _messageRouter.handleMessage(initialMessage);
      });
    }

    return PushNotificationBootstrapResult(
      isConfigured: true,
      didRegisterToken: true,
      message: 'FCM 토큰을 백엔드에 등록했습니다.',
      deviceTokenPreview: token.length > 16 ? '${token.substring(0, 16)}...' : token,
    );
  }

  Future<void> deactivateCurrentToken() async {
    if (!_config.isFirebaseConfigured) {
      return;
    }
    await ensureFirebaseInitialized(_config);
    final token = await FirebaseMessaging.instance.getToken(
      vapidKey: _config.firebaseWebVapidKey.isEmpty ? null : _config.firebaseWebVapidKey,
    );
    if (token == null || token.isEmpty) {
      return;
    }
    await _apiClient.post(
      'me/device-tokens/deactivate',
      requiresUser: true,
      body: {'device_token': token},
    );
  }

  Future<void> _bindListeners() async {
    if (_listenersBound) {
      return;
    }
    _listenersBound = true;

    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('Foreground push received: ${message.messageId} ${message.data}');
      _messageRouter.showForeground(message);
    });
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('Push opened app: ${message.data}');
      _messageRouter.handleMessage(message);
    });
    FirebaseMessaging.instance.onTokenRefresh.listen(_registerToken);
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
        'app_version': '1.0.0+1',
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

Future<void> ensureFirebaseInitialized(AppConfig config) async {
  if (Firebase.apps.isNotEmpty) {
    return;
  }
  await Firebase.initializeApp(options: _buildFirebaseOptions(config));
}

FirebaseOptions _buildFirebaseOptions(AppConfig config) {
  final appId = _resolveAppId(config);
  return FirebaseOptions(
    apiKey: config.firebaseApiKey,
    appId: appId,
    messagingSenderId: config.firebaseMessagingSenderId,
    projectId: config.firebaseProjectId,
    iosBundleId: config.firebaseIosBundleId.isEmpty ? null : config.firebaseIosBundleId,
  );
}

String _resolveAppId(AppConfig config) {
  if (kIsWeb && config.firebaseWebAppId.isNotEmpty) {
    return config.firebaseWebAppId;
  }
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return config.firebaseAndroidAppId.isNotEmpty ? config.firebaseAndroidAppId : config.firebaseAppId;
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      return config.firebaseAppId;
    default:
      return config.firebaseAppId.isNotEmpty ? config.firebaseAppId : config.firebaseWebAppId;
  }
}
