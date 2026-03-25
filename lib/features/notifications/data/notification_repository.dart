import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/api_client.dart';
import 'notification_models.dart';

class NotificationRepository {
  const NotificationRepository(this._apiClient);

  static const _kAlertSettings = 'alert_settings_v1';
  static const _defaultSettings = AlertSettingsModel(
    pushEnabled: true,
    priceSignalEnabled: true,
    themeSignalEnabled: true,
    contentUpdateEnabled: false,
    adminNoticeEnabled: true,
  );

  final ApiClient _apiClient;

  Future<List<NotificationItemModel>> fetchNotifications() async {
    final response = await _apiClient.get('notifications', requiresUser: true);
    final items = response['data']['items'] as List<dynamic>;
    return items
        .map(
          (item) => NotificationItemModel.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<void> markAsRead(int notificationId) async {
    await _apiClient.patch('notifications/$notificationId/read', requiresUser: true);
  }

  Future<AlertSettingsModel> fetchAlertSettings() async {
    final response = await _apiClient.get('me/alert-settings', requiresUser: true);
    return AlertSettingsModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<AlertSettingsModel> updateAlertSettings(AlertSettingsModel settings) async {
    final response = await _apiClient.patch(
      'me/alert-settings',
      requiresUser: true,
      body: settings.toJson(),
    );
    return AlertSettingsModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<AlertSettingsModel> loadLocalSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kAlertSettings);
    if (raw == null || raw.isEmpty) {
      return _defaultSettings;
    }

    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return AlertSettingsModel.fromJson(json);
    } catch (_) {
      return _defaultSettings;
    }
  }

  Future<AlertSettingsModel> saveLocalSettings(AlertSettingsModel settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAlertSettings, jsonEncode(settings.toJson()));
    return settings;
  }
}
