import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 앱 전체 다크모드 상태를 관리하는 컨트롤러.
/// AppScope를 통해 주입해서 사용합니다.
class ThemeModeController extends ValueNotifier<ThemeMode> {
  ThemeModeController() : super(ThemeMode.system) {
    _restore();
  }

  static const _themeModeKey = 'theme_mode';

  bool get isDark => value == ThemeMode.dark;
  bool get isLight => value == ThemeMode.light;

  void setLight() {
    value = ThemeMode.light;
    _persist();
  }

  void setDark() {
    value = ThemeMode.dark;
    _persist();
  }

  void setSystem() {
    value = ThemeMode.system;
    _persist();
  }

  void toggle() {
    value = (value == ThemeMode.dark) ? ThemeMode.light : ThemeMode.dark;
    _persist();
  }

  bool resolvedIsDark(BuildContext context) {
    if (value == ThemeMode.dark) return true;
    if (value == ThemeMode.light) return false;
    return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final rawMode = prefs.getString(_themeModeKey);
    switch (rawMode) {
      case 'light':
        value = ThemeMode.light;
        break;
      case 'dark':
        value = ThemeMode.dark;
        break;
      case 'system':
      default:
        value = ThemeMode.system;
        break;
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final rawMode = switch (value) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await prefs.setString(_themeModeKey, rawMode);
  }
}
