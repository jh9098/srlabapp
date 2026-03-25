import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/navigation/app_navigator.dart';
import '../../core/network/api_client.dart';
import '../../core/push/push_notification_service.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_mode_controller.dart';
import '../auth/data/auth_repository.dart';
import '../auth/presentation/auth_gate.dart';
import '../home/data/firebase_home_repository.dart';
import '../home/data/home_repository.dart';
import '../notifications/data/firebase_notification_repository.dart';
import '../notifications/data/notification_repository.dart';
import '../notifications/presentation/notification_badge_controller.dart';
import '../shared/controllers/watchlist_controller.dart';
import '../stock/data/firebase_stock_repository.dart';
import '../stock/data/stock_repository.dart';
import '../stock/presentation/stock_search_screen.dart';
import '../theme/data/theme_repository.dart';
import '../user/data/user_profile_repository.dart';
import '../watchlist/data/watchlist_repository.dart';
import 'app_shell_tabs.dart';
import 'app_scope.dart';

class SrLabApp extends StatefulWidget {
  const SrLabApp({super.key, required this.config});

  final AppConfig config;

  @override
  State<SrLabApp> createState() => _SrLabAppState();
}

class _SrLabAppState extends State<SrLabApp> {
  late final GlobalKey<NavigatorState> _navigatorKey;
  late final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey;
  late final AppNavigator _appNavigator;
  late final ThemeModeController _themeModeController;

  late final ApiClient _apiClient;
  late final HomeRepository _homeRepository;
  late final FirebaseHomeRepository? _firebaseHomeRepository;
  late final StockRepository _stockRepository;
  late final FirebaseStockRepository? _firebaseStockRepository;
  late final ThemeRepository _themeRepository;
  late final WatchlistRepository _watchlistRepository;
  late final NotificationRepository _notificationRepository;
  late final FirebaseNotificationRepository? _firebaseNotificationRepository;
  late final AuthRepository? _authRepository;
  late final UserProfileRepository? _userProfileRepository;
  late final PushNotificationService _pushNotificationService;
  late final WatchlistController _watchlistController;
  late final NotificationBadgeController _notificationBadgeController;

  @override
  void initState() {
    super.initState();
    _navigatorKey = GlobalKey<NavigatorState>();
    _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
    _appNavigator = AppNavigator(
      navigatorKey: _navigatorKey,
      scaffoldMessengerKey: _scaffoldMessengerKey,
    );
    _themeModeController = ThemeModeController();

    _apiClient = ApiClient(config: widget.config);
    _homeRepository = HomeRepository(_apiClient);
    _firebaseHomeRepository =
        widget.config.isFirebaseConfigured ? FirebaseHomeRepository() : null;
    _stockRepository = StockRepository(_apiClient);
    _firebaseStockRepository =
        widget.config.isFirebaseConfigured ? FirebaseStockRepository() : null;
    _themeRepository = ThemeRepository(_apiClient);
    _watchlistRepository = WatchlistRepository(_apiClient);
    _notificationRepository = NotificationRepository(_apiClient);
    _firebaseNotificationRepository = widget.config.isFirebaseConfigured
        ? FirebaseNotificationRepository(config: widget.config)
        : null;
    _authRepository = widget.config.isFirebaseConfigured
        ? AuthRepository(
            googleClientId: widget.config.googleClientId,
            googleServerClientId: widget.config.googleServerClientId,
          )
        : null;
    _userProfileRepository =
        widget.config.isFirebaseConfigured ? UserProfileRepository() : null;
    _notificationBadgeController = NotificationBadgeController();
    _pushNotificationService = PushNotificationService(
      config: widget.config,
      apiClient: _apiClient,
      appNavigator: _appNavigator,
      onForegroundNotification: _notificationBadgeController.increment,
    );
    if (widget.config.isFirebaseConfigured) {
      _notificationBadgeController.bindFirestore(
        firestore: FirebaseFirestore.instance,
        userIdentifier: widget.config.userIdentifier,
      );
    }
    _watchlistController = WatchlistController(_watchlistRepository);
  }

  @override
  void dispose() {
    _watchlistController.dispose();
    _notificationBadgeController.dispose();
    _pushNotificationService.dispose();
    _apiClient.dispose();
    _themeModeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      config: widget.config,
      appNavigator: _appNavigator,
      themeModeController: _themeModeController,
      apiClient: _apiClient,
      homeRepository: _homeRepository,
      firebaseHomeRepository: _firebaseHomeRepository,
      stockRepository: _stockRepository,
      firebaseStockRepository: _firebaseStockRepository,
      themeRepository: _themeRepository,
      watchlistRepository: _watchlistRepository,
      notificationRepository: _notificationRepository,
      firebaseNotificationRepository: _firebaseNotificationRepository,
      notificationBadgeController: _notificationBadgeController,
      authRepository: _authRepository,
      userProfileRepository: _userProfileRepository,
      pushNotificationService: _pushNotificationService,
      watchlistController: _watchlistController,
      child: Builder(
        builder: (context) {
          final scope = AppScope.of(context);
          return ValueListenableBuilder<ThemeMode>(
            valueListenable: scope.themeModeController,
            builder: (context, themeMode, _) {
              return MaterialApp(
                title: '지지저항Lab',
                debugShowCheckedModeBanner: false,
                theme: AppTheme.light(),
                darkTheme: AppTheme.dark(),
                themeMode: themeMode,
                navigatorKey: _navigatorKey,
                scaffoldMessengerKey: _scaffoldMessengerKey,
                home: const AuthGate(
                  child: AppShell(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  bool _didBootstrap = false;
  String? _pushWarningMessage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_didBootstrap) {
      return;
    }
    _didBootstrap = true;

    final scope = AppScope.of(context);

    if (scope.config.enableBackendFeatures) {
      scope.watchlistController.load();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final result = await scope.pushNotificationService.bootstrap();
      if (!mounted) return;
      if (!result.didRegisterToken) {
        setState(() => _pushWarningMessage = result.message);
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) setState(() => _pushWarningMessage = null);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appNavigator = AppScope.of(context).appNavigator;
    final badgeController = AppScope.of(context).notificationBadgeController;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.pageHorizontal,
        title: Text(
          _titles[_index],
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ValueListenableBuilder<int>(
              valueListenable: badgeController,
              builder: (context, unreadCount, _) {
                return IconButton(
                  onPressed: () async {
                    await appNavigator.openNotifications();
                    if (!mounted) return;
                    badgeController.reset();
                  },
                  icon: Badge.count(
                    count: unreadCount,
                    isLabelVisible: unreadCount > 0,
                    child: const Icon(Icons.notifications_outlined, size: 22),
                  ),
                  tooltip: '알림함',
                );
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_pushWarningMessage != null)
            MaterialBanner(
              content: Text(
                _pushWarningMessage!,
                style: const TextStyle(fontSize: 13),
              ),
              backgroundColor:
                  isDark ? const Color(0xFF451A03) : const Color(0xFFFFF7ED),
              leading: Icon(
                Icons.warning_amber_rounded,
                color:
                    isDark ? const Color(0xFFFCD34D) : const Color(0xFFB45309),
              ),
              actions: [
                TextButton(
                  onPressed: () => setState(() => _pushWarningMessage = null),
                  child: const Text('닫기'),
                ),
              ],
            ),
          Expanded(
            child: IndexedStack(
              index: _index,
              children: _screens,
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: kAppShellTabs.map((tab) => tab.destination).toList(),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: _index == 1
          ? Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: FloatingActionButton.extended(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const StockSearchScreen(),
                  ),
                ),
                icon: const Icon(Icons.add_rounded),
                label: const Text('종목 추가'),
              ),
            )
          : null,
    );
  }

  List<String> get _titles => kAppShellTabs.map((tab) => tab.title).toList();
  List<Widget> get _screens => kAppShellTabs.map((tab) => tab.screen).toList();
}
