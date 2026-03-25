import 'package:flutter/widgets.dart';

import '../../core/config/app_config.dart';
import '../../core/navigation/app_navigator.dart';
import '../../core/network/api_client.dart';
import '../../core/push/push_notification_service.dart';
import '../../core/theme/theme_mode_controller.dart';
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
    required this.themeModeController,
  }) : apiClient = ApiClient(config: config) {
    homeRepository = HomeRepository(apiClient);
    firebaseHomeRepository = config.isFirebaseConfigured
        ? FirebaseHomeRepository()
        : null;
    stockRepository = StockRepository(apiClient);
    firebaseStockRepository = config.isFirebaseConfigured
        ? FirebaseStockRepository()
        : null;
    themeRepository = ThemeRepository(apiClient);
    watchlistRepository = WatchlistRepository(apiClient);
    notificationRepository = NotificationRepository(apiClient);
    authRepository = config.isFirebaseConfigured
        ? AuthRepository(
            googleClientId: config.googleClientId,
            googleServerClientId: config.googleServerClientId,
          )
        : null;
    userProfileRepository =
        config.isFirebaseConfigured ? UserProfileRepository() : null;
    pushNotificationService = PushNotificationService(
      config: config,
      apiClient: apiClient,
      appNavigator: appNavigator,
    );
    watchlistController = WatchlistController(watchlistRepository);
  }

  final AppConfig config;
  final AppNavigator appNavigator;
  final ThemeModeController themeModeController;
  final ApiClient apiClient;
  late final HomeRepository homeRepository;
  late final FirebaseHomeRepository? firebaseHomeRepository;
  late final StockRepository stockRepository;
  late final FirebaseStockRepository? firebaseStockRepository;
  late final ThemeRepository themeRepository;
  late final WatchlistRepository watchlistRepository;
  late final NotificationRepository notificationRepository;
  late final AuthRepository? authRepository;
  late final UserProfileRepository? userProfileRepository;
  late final PushNotificationService pushNotificationService;
  late final WatchlistController watchlistController;

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope가 위젯 트리에 존재해야 합니다.');
    return scope!;
  }

  @override
  bool updateShouldNotify(covariant AppScope oldWidget) => false;
}
