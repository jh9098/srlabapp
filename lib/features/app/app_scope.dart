import 'package:flutter/widgets.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/push/push_notification_service.dart';
import '../home/data/home_repository.dart';
import '../notifications/data/notification_repository.dart';
import '../shared/controllers/watchlist_controller.dart';
import '../stock/data/stock_repository.dart';
import '../theme/data/theme_repository.dart';
import '../watchlist/data/watchlist_repository.dart';

class AppScope extends InheritedWidget {
  AppScope({
    super.key,
    required super.child,
    required this.config,
  })  : apiClient = ApiClient(config: config),
        homeRepository = HomeRepository(ApiClient(config: config)),
        stockRepository = StockRepository(ApiClient(config: config)),
        themeRepository = ThemeRepository(ApiClient(config: config)),
        watchlistRepository = WatchlistRepository(ApiClient(config: config)),
        notificationRepository = NotificationRepository(ApiClient(config: config)),
        pushNotificationService = PushNotificationService(
          config: config,
          apiClient: ApiClient(config: config),
        ),
        watchlistController = WatchlistController(WatchlistRepository(ApiClient(config: config)));

  final AppConfig config;
  final ApiClient apiClient;
  final HomeRepository homeRepository;
  final StockRepository stockRepository;
  final ThemeRepository themeRepository;
  final WatchlistRepository watchlistRepository;
  final NotificationRepository notificationRepository;
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
