import 'package:firebase_messaging/firebase_messaging.dart';

import '../navigation/app_navigator.dart';

class PushMessageRouter {
  const PushMessageRouter(this._navigator);

  final AppNavigator _navigator;

  Future<void> handleMessage(RemoteMessage message) {
    final route = _resolveRoute(message);
    return _navigator.openTargetPath(route);
  }

  void showForeground(RemoteMessage message) {
    final notification = message.notification;
    _navigator.showForegroundMessage(
      title: notification?.title ?? '새 알림',
      body: notification?.body ?? '중요한 상태 변화가 도착했습니다.',
      onTap: () {
        handleMessage(message);
      },
    );
  }

  String? _resolveRoute(RemoteMessage message) {
    final data = message.data;
    final route = data['route'];
    if (route is String && route.isNotEmpty) {
      return route;
    }
    final stockCode = data['stock_code'];
    if (stockCode is String && stockCode.isNotEmpty) {
      return '/stocks/$stockCode';
    }
    return '/notifications';
  }
}
