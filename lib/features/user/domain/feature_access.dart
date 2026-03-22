import 'user_profile.dart';

class FeatureAccess {
  const FeatureAccess._();

  static const String themePath = '/theme';
  static const String shortsPath = '/shorts';
  static const String adminPath = '/admin';

  static bool canOpenTheme(UserProfile? profile) {
    return canAccessPath(profile, themePath);
  }

  static bool canOpenShorts(UserProfile? profile) {
    return canAccessPath(profile, shortsPath);
  }

  static bool canOpenAdmin(UserProfile? profile) {
    return canAccessPath(profile, adminPath);
  }

  static bool canAccessPath(UserProfile? profile, String path) {
    if (profile == null) {
      return false;
    }
    if (profile.isAdmin) {
      return true;
    }
    if (profile.allowedPaths.isEmpty) {
      return path != adminPath;
    }
    return profile.allowedPaths.any(
      (allowedPath) => allowedPath == path || allowedPath.startsWith('$path/'),
    );
  }
}
