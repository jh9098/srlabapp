import 'package:flutter/widgets.dart';

import '../../core/config/app_config.dart';
import '../../core/navigation/app_navigator.dart';
import '../../core/network/api_client.dart';
import '../../core/push/push_notification_service.dart';
import '../auth/data/auth_repository.dart';
import '../home/data/firebase_home_repository.dart';
import '../home/data/home_repository.dart';
import '../notifications/data/notification_repository.dart';
import '../shared/controllers/watchlist_controller.dart';
import '../stock/data/firebase_stock_repository.dart';
import '../stock/data/stock_repository.dart';
import '../theme/data/theme_repository.dart';
import '../user/data/user_profile_repository.dart';
import '../watchlist/data/watchlist_repository.dart';

class AppScope extends InheritedWidget {
  AppScope({
    super.key,
    required super.child,
    required this.config,
    required this.appNavigator,
  })  : apiClient = ApiClient(config: config),
        homeRepository = HomeRepository(ApiClient(config: config)),
        firebaseHomeRepository = config.isFirebaseConfigured
            ? FirebaseHomeRepository()
            : null,
        stockRepository = StockRepository(ApiClient(config: config)),
        firebaseStockRepository = config.isFirebaseConfigured
            ? FirebaseStockRepository()
            : null,
        themeRepository = ThemeRepository(ApiClient(config: config)),
        watchlistRepository = WatchlistRepository(ApiClient(config: config)),
        notificationRepository = NotificationRepository(ApiClient(config: config)),
        authRepository = config.isFirebaseConfigured
            ? AuthRepository(
                googleClientId: config.googleClientId,
                googleServerClientId: config.googleServerClientId,
              )
            : null,
        userProfileRepository = config.isFirebaseConfigured ? UserProfileRepository() : null,
        pushNotificationService = PushNotificationService(
          config: config,
          apiClient: ApiClient(config: config),
          appNavigator: appNavigator,
        ),
        watchlistController = WatchlistController(WatchlistRepository(ApiClient(config: config)));

  final AppConfig config;
  final AppNavigator appNavigator;
  final ApiClient apiClient;
  final HomeRepository homeRepository;
  final FirebaseHomeRepository? firebaseHomeRepository;
  final StockRepository stockRepository;
  final FirebaseStockRepository? firebaseStockRepository;
  final ThemeRepository themeRepository;
  final WatchlistRepository watchlistRepository;
  final NotificationRepository notificationRepository;
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
