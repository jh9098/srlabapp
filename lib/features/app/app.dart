import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/navigation/app_navigator.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_mode_controller.dart';
import '../auth/presentation/auth_gate.dart';
import '../home/presentation/home_screen.dart';
import '../my/presentation/my_screen.dart';
import '../shorts/presentation/shorts_screen.dart';
import '../stock/presentation/stock_search_screen.dart';
import '../theme/presentation/theme_screen.dart';
import '../watchlist/presentation/watchlist_screen.dart';
import '../shared/controllers/watchlist_controller.dart';
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
  }

  @override
  void dispose() {
    _themeModeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      config: widget.config,
      appNavigator: _appNavigator,
      themeModeController: _themeModeController,
      child: _AppScopeDisposer(
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
      ),
    );
  }
}

class _AppScopeDisposer extends StatefulWidget {
  const _AppScopeDisposer({required this.child});

  final Widget child;

  @override
  State<_AppScopeDisposer> createState() => _AppScopeDisposerState();
}

class _AppScopeDisposerState extends State<_AppScopeDisposer> {
  WatchlistController? _watchlistController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _watchlistController ??= AppScope.of(context).watchlistController;
  }

  @override
  void dispose() {
    _watchlistController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  final List<String> _titles = const ['지지저항Lab', '관심종목', '테마', '콘텐츠', '마이'];
  bool _didBootstrap = false;
  String? _pushWarningMessage;

  final List<Widget> _screens = const [
    HomeScreen(),
    WatchlistScreen(),
    ThemeScreen(),
    ShortsScreen(),
    MyScreen(),
  ];

  final List<NavigationDestination> _destinations = const [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: '홈',
    ),
    NavigationDestination(
      icon: Icon(Icons.star_outline_rounded),
      selectedIcon: Icon(Icons.star_rounded),
      label: '관심종목',
    ),
    NavigationDestination(
      icon: Icon(Icons.local_fire_department_outlined),
      selectedIcon: Icon(Icons.local_fire_department),
      label: '테마',
    ),
    NavigationDestination(
      icon: Icon(Icons.article_outlined),
      selectedIcon: Icon(Icons.article),
      label: '콘텐츠',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline_rounded),
      selectedIcon: Icon(Icons.person),
      label: '마이',
    ),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final scope = AppScope.of(context);

    if (scope.config.enableBackendFeatures) {
      scope.watchlistController.load();
    }

    if (_didBootstrap) return;
    _didBootstrap = true;

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
            child: IconButton(
              onPressed: appNavigator.openNotifications,
              icon: const Icon(Icons.notifications_outlined, size: 22),
              tooltip: '알림함',
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
              backgroundColor: const Color(0xFFFFF7ED),
              leading: const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFB45309),
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
        destinations: _destinations,
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
}
