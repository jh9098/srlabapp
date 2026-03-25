import 'package:flutter/widgets.dart';

import '../../core/config/app_config.dart';
import '../../core/navigation/app_navigator.dart';
import '../../core/network/api_client.dart';
import '../../core/push/push_notification_service.dart';
import '../../core/theme/theme_mode_controller.dart';
import '../auth/data/auth_repository.dart';
import '../home/data/firebase_home_repository.dart';
import '../home/data/home_repository.dart';
import '../notifications/data/firebase_notification_repository.dart';
import '../notifications/data/notification_repository.dart';
import '../notifications/presentation/notification_badge_controller.dart';
import '../shared/controllers/watchlist_controller.dart';
import '../stock/data/firebase_stock_repository.dart';
import '../stock/data/stock_repository.dart';
import '../theme/data/theme_repository.dart';
import '../user/data/user_profile_repository.dart';
import '../watchlist/data/watchlist_repository.dart';

class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required super.child,
    required this.config,
    required this.appNavigator,
    required this.themeModeController,
    required this.apiClient,
    required this.homeRepository,
    required this.firebaseHomeRepository,
    required this.stockRepository,
    required this.firebaseStockRepository,
    required this.themeRepository,
    required this.watchlistRepository,
    required this.notificationRepository,
    required this.firebaseNotificationRepository,
    required this.notificationBadgeController,
    required this.authRepository,
    required this.userProfileRepository,
    required this.pushNotificationService,
    required this.watchlistController,
  });

  final AppConfig config;
  final AppNavigator appNavigator;
  final ThemeModeController themeModeController;
  final ApiClient apiClient;
  final HomeRepository homeRepository;
  final FirebaseHomeRepository? firebaseHomeRepository;
  final StockRepository stockRepository;
  final FirebaseStockRepository? firebaseStockRepository;
  final ThemeRepository themeRepository;
  final WatchlistRepository watchlistRepository;
  final NotificationRepository notificationRepository;
  final FirebaseNotificationRepository? firebaseNotificationRepository;
  final NotificationBadgeController notificationBadgeController;
  final AuthRepository? authRepository;
  final UserProfileRepository? userProfileRepository;
  final PushNotificationService pushNotificationService;
  final WatchlistController watchlistController;

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope가 위젯 트리에 존재해야 합니다.');
    return scope!;
  }

  @override
  bool updateShouldNotify(covariant AppScope oldWidget) => false;
}
