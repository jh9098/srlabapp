import 'package:flutter/material.dart';

import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/stock/presentation/stock_detail_screen.dart';

class AppNavigator {
  AppNavigator({
    required this.navigatorKey,
    required this.scaffoldMessengerKey,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey;

  BuildContext? get _context => navigatorKey.currentContext;

  Future<void> openTargetPath(String? targetPath) async {
    if (targetPath == null || targetPath.isEmpty) {
      await openNotifications();
      return;
    }

    if (targetPath.startsWith('/stocks/')) {
      final stockCode = targetPath.replaceFirst('/stocks/', '');
      if (stockCode.isNotEmpty) {
        await openStockDetail(stockCode);
        return;
      }
    }

    if (targetPath.startsWith('/notifications')) {
      await openNotifications();
      return;
    }

    await openNotifications();
  }

  Future<void> openStockDetail(String stockCode) async {
    final context = _context;
    if (context == null) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => StockDetailScreen(stockCode: stockCode)),
    );
  }

  Future<void> openNotifications() async {
    final context = _context;
    if (context == null) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
  }

  void showForegroundMessage({
    required String title,
    required String body,
    required VoidCallback onTap,
  }) {
    final messenger = scaffoldMessengerKey.currentState;
    if (messenger == null) {
      return;
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$title\n$body'),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(label: '열기', onPressed: onTap),
        ),
      );
  }
}
