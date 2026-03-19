import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/push/push_notification_service.dart';
import '../../core/theme/app_theme.dart';
import '../home/presentation/home_screen.dart';
import '../my/presentation/my_screen.dart';
import '../notifications/presentation/notifications_screen.dart';
import '../shorts/presentation/shorts_screen.dart';
import '../stock/presentation/stock_search_screen.dart';
import '../theme/presentation/theme_screen.dart';
import '../watchlist/presentation/watchlist_screen.dart';
import 'app_scope.dart';

class SrLabApp extends StatelessWidget {
  const SrLabApp({super.key, required this.config});

  final AppConfig config;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      config: config,
      child: MaterialApp(
        title: '지지저항Lab',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const AppShell(),
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
    scope.watchlistController.load();
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsScreen())),
            icon: const Icon(Icons.notifications_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_pushBootstrapResult != null)
            MaterialBanner(
              content: Text(_pushBootstrapResult!.message),
              backgroundColor: _pushBootstrapResult!.didRegisterToken ? Colors.green.shade50 : Colors.blueGrey.shade50,
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
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StockSearchScreen())),
              icon: const Icon(Icons.add_rounded),
              label: const Text('종목 추가'),
            )
          : null,
    );
  }
}
