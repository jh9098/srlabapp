import 'package:flutter/material.dart';

/// 앱 전체 다크모드 상태를 관리하는 컨트롤러
/// app.dart의 MaterialApp.themeMode와 연동됩니다.
///
/// 사용 예:
///   ThemeModeController.instance.toggle();
///   ValueListenableBuilder(
///     valueListenable: ThemeModeController.instance,
///     builder: (_, mode, __) => MaterialApp(themeMode: mode),
///   );
class ThemeModeController extends ValueNotifier<ThemeMode> {
  ThemeModeController._() : super(ThemeMode.system);

  static final ThemeModeController instance = ThemeModeController._();

  bool get isDark => value == ThemeMode.dark;
  bool get isLight => value == ThemeMode.light;

  void setLight() => value = ThemeMode.light;
  void setDark() => value = ThemeMode.dark;
  void setSystem() => value = ThemeMode.system;

  void toggle() {
    value = (value == ThemeMode.dark) ? ThemeMode.light : ThemeMode.dark;
  }

  /// 현재 플랫폼 밝기 기준으로 실제 다크인지 여부
  bool resolvedIsDark(BuildContext context) {
    if (value == ThemeMode.dark) return true;
    if (value == ThemeMode.light) return false;
    return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
  }
}
