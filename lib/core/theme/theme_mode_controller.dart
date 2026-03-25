import 'package:flutter/material.dart';

/// 앱 전체 다크모드 상태를 관리하는 컨트롤러.
/// AppScope를 통해 주입해서 사용합니다.
class ThemeModeController extends ValueNotifier<ThemeMode> {
  ThemeModeController() : super(ThemeMode.system);

  bool get isDark => value == ThemeMode.dark;
  bool get isLight => value == ThemeMode.light;

  void setLight() => value = ThemeMode.light;
  void setDark() => value = ThemeMode.dark;
  void setSystem() => value = ThemeMode.system;

  void toggle() {
    value = (value == ThemeMode.dark) ? ThemeMode.light : ThemeMode.dark;
  }

  bool resolvedIsDark(BuildContext context) {
    if (value == ThemeMode.dark) return true;
    if (value == ThemeMode.light) return false;
    return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
  }
}
