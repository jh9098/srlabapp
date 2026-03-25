import 'package:flutter/material.dart';

import '../home/presentation/home_screen.dart';
import '../my/presentation/my_screen.dart';
import '../shorts/presentation/shorts_screen.dart';
import '../theme/presentation/theme_screen.dart';
import '../watchlist/presentation/watchlist_screen.dart';

class AppShellTab {
  const AppShellTab({
    required this.title,
    required this.screen,
    required this.destination,
  });

  final String title;
  final Widget screen;
  final NavigationDestination destination;
}

const List<AppShellTab> kAppShellTabs = [
  AppShellTab(
    title: '지지저항Lab',
    screen: HomeScreen(),
    destination: NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: '홈',
    ),
  ),
  AppShellTab(
    title: '관심종목',
    screen: WatchlistScreen(),
    destination: NavigationDestination(
      icon: Icon(Icons.star_outline_rounded),
      selectedIcon: Icon(Icons.star_rounded),
      label: '관심종목',
    ),
  ),
  AppShellTab(
    title: '테마',
    screen: ThemeScreen(),
    destination: NavigationDestination(
      icon: Icon(Icons.local_fire_department_outlined),
      selectedIcon: Icon(Icons.local_fire_department),
      label: '테마',
    ),
  ),
  AppShellTab(
    title: '콘텐츠',
    screen: ShortsScreen(),
    destination: NavigationDestination(
      icon: Icon(Icons.article_outlined),
      selectedIcon: Icon(Icons.article),
      label: '콘텐츠',
    ),
  ),
  AppShellTab(
    title: '마이',
    screen: MyScreen(),
    destination: NavigationDestination(
      icon: Icon(Icons.person_outline_rounded),
      selectedIcon: Icon(Icons.person),
      label: '마이',
    ),
  ),
];
