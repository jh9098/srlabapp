class NotificationItemModel {
  const NotificationItemModel({
    required this.notificationId,
    required this.notificationType,
    required this.title,
    required this.message,
    required this.targetPath,
    required this.deliveryStatus,
    required this.responseMessageId,
    required this.failureReason,
    required this.retryCount,
    required this.isRead,
    required this.createdAt,
  });

  final int notificationId;
  final String notificationType;
  final String title;
  final String message;
  final String? targetPath;
  final String deliveryStatus;
  final String? responseMessageId;
  final String? failureReason;
  final int retryCount;
  final bool isRead;
  final DateTime createdAt;

  factory NotificationItemModel.fromJson(Map<String, dynamic> json) {
    return NotificationItemModel(
      notificationId: json['notification_id'] as int,
      notificationType: json['notification_type'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      targetPath: json['target_path'] as String?,
      deliveryStatus: json['delivery_status'] as String? ?? 'pending',
      responseMessageId: json['response_message_id'] as String?,
      failureReason: json['failure_reason'] as String?,
      retryCount: json['retry_count'] as int? ?? 0,
      isRead: json['is_read'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class AlertSettingsModel {
  const AlertSettingsModel({
    required this.priceSignalEnabled,
    required this.themeSignalEnabled,
    required this.contentUpdateEnabled,
    required this.adminNoticeEnabled,
    required this.pushEnabled,
  });

  final bool priceSignalEnabled;
  final bool themeSignalEnabled;
  final bool contentUpdateEnabled;
  final bool adminNoticeEnabled;
  final bool pushEnabled;

  factory AlertSettingsModel.fromJson(Map<String, dynamic> json) {
    return AlertSettingsModel(
      priceSignalEnabled: json['price_signal_enabled'] as bool,
      themeSignalEnabled: json['theme_signal_enabled'] as bool,
      contentUpdateEnabled: json['content_update_enabled'] as bool,
      adminNoticeEnabled: json['admin_notice_enabled'] as bool,
      pushEnabled: json['push_enabled'] as bool,
    );
  }

  Map<String, dynamic> toJson() => {
        'price_signal_enabled': priceSignalEnabled,
        'theme_signal_enabled': themeSignalEnabled,
        'content_update_enabled': contentUpdateEnabled,
        'admin_notice_enabled': adminNoticeEnabled,
        'push_enabled': pushEnabled,
      };

  AlertSettingsModel copyWith({
    bool? priceSignalEnabled,
    bool? themeSignalEnabled,
    bool? contentUpdateEnabled,
    bool? adminNoticeEnabled,
    bool? pushEnabled,
  }) {
    return AlertSettingsModel(
      priceSignalEnabled: priceSignalEnabled ?? this.priceSignalEnabled,
      themeSignalEnabled: themeSignalEnabled ?? this.themeSignalEnabled,
      contentUpdateEnabled: contentUpdateEnabled ?? this.contentUpdateEnabled,
      adminNoticeEnabled: adminNoticeEnabled ?? this.adminNoticeEnabled,
      pushEnabled: pushEnabled ?? this.pushEnabled,
    );
  }
}
