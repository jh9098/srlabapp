import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/navigation/app_navigator.dart';
import '../../core/push/push_notification_service.dart';
import '../../core/theme/app_theme.dart';
import '../auth/presentation/auth_gate.dart';
import '../home/presentation/home_screen.dart';
import '../my/presentation/my_screen.dart';
import '../notifications/presentation/notifications_screen.dart';
import '../shorts/presentation/shorts_screen.dart';
import '../stock/presentation/stock_search_screen.dart';
import '../theme/presentation/theme_screen.dart';
import '../watchlist/presentation/watchlist_screen.dart';
import 'app_scope.dart';

class SrLabApp extends StatelessWidget {
  SrLabApp({super.key, required this.config});

  final AppConfig config;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  Widget build(BuildContext context) {
    final appNavigator = AppNavigator(
      navigatorKey: _navigatorKey,
      scaffoldMessengerKey: _scaffoldMessengerKey,
    );
    return AppScope(
      config: config,
      appNavigator: appNavigator,
      child: MaterialApp(
        title: '지지저항Lab',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        navigatorKey: _navigatorKey,
        scaffoldMessengerKey: _scaffoldMessengerKey,
        home: _FirebaseBootstrapGate(
          config: config,
          child: AuthGate(child: const AppShell()),
        ),
      ),
    );
  }
}

class _FirebaseBootstrapGate extends StatelessWidget {
  const _FirebaseBootstrapGate({
    required this.config,
    required this.child,
  });

  final AppConfig config;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (config.useFirebaseOnly && !config.isFirebaseConfigured) {
      return const _FirebaseSetupRequiredScreen();
    }

    if (!config.isFirebaseConfigured) {
      return child;
    }

    return FutureBuilder<void>(
      future: ensureFirebaseInitialized(config),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Firebase 초기화에 실패했습니다.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }
        return child;
      },
    );
  }
}


class _FirebaseSetupRequiredScreen extends StatelessWidget {
  const _FirebaseSetupRequiredScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_rounded, size: 56),
              SizedBox(height: 16),
              Text(
                'Firebase 설정이 없어 앱을 시작할 수 없습니다.',
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                '백엔드 없는 모드(USE_FIREBASE_ONLY=true)에서는\nFIREBASE_PROJECT_ID, FIREBASE_API_KEY, FIREBASE_WEB_APP_ID 같은 dart-define 값이 필요합니다.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
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
  PushNotificationBootstrapResult? _pushBootstrapResult;

  final _screens = const [
    HomeScreen(),
    WatchlistScreen(),
    ThemeScreen(),
    ShortsScreen(),
    MyScreen(),
  ];

  final _titles = const ['홈', '관심종목', '테마', '쇼츠', '마이'];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = AppScope.of(context);
    if (scope.config.enableBackendFeatures) {
      scope.watchlistController.load();
    }
    if (_didBootstrap) {
      return;
    }
    _didBootstrap = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final result = await scope.pushNotificationService.bootstrap();
      if (!mounted) {
        return;
      }
      setState(() => _pushBootstrapResult = result);
    });
  }

  @override
  Widget build(BuildContext context) {
    final appNavigator = AppScope.of(context).appNavigator;
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: [
          IconButton(
            onPressed: appNavigator.openNotifications,
            icon: const Icon(Icons.notifications_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_pushBootstrapResult != null)
            MaterialBanner(
              content: Text(_pushBootstrapResult!.message),
              backgroundColor: _pushBootstrapResult!.didRegisterToken
                  ? Colors.green.shade50
                  : Colors.blueGrey.shade50,
              actions: const [SizedBox.shrink()],
            ),
          Expanded(child: IndexedStack(index: _index, children: _screens)),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: '홈'),
          NavigationDestination(icon: Icon(Icons.star_outline_rounded), selectedIcon: Icon(Icons.star_rounded), label: '관심종목'),
          NavigationDestination(icon: Icon(Icons.local_fire_department_outlined), selectedIcon: Icon(Icons.local_fire_department), label: '테마'),
          NavigationDestination(icon: Icon(Icons.play_circle_outline_rounded), selectedIcon: Icon(Icons.play_circle_fill_rounded), label: '쇼츠'),
          NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person), label: '마이'),
        ],
      ),
      floatingActionButton: _index == 1
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const StockSearchScreen()),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('종목 추가'),
            )
          : null,
    );
  }
}
