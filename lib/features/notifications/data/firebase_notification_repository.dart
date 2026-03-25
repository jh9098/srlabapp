import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/config/app_config.dart';
import '../../../core/utils/json_parsers.dart';
import 'notification_models.dart';

class FirebaseNotificationRepository {
  FirebaseNotificationRepository({
    required AppConfig config,
    FirebaseFirestore? firestore,
  })  : _config = config,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final AppConfig _config;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _itemsCollection {
    return _firestore
        .collection('notifications')
        .doc(_config.userIdentifier)
        .collection('items');
  }

  Future<List<NotificationItemModel>> fetchNotifications({int limit = 50}) async {
    final snapshot = await _itemsCollection
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => _toNotificationModel(doc.id, doc.data()))
        .toList();
  }

  Future<void> markAsRead(String documentId) {
    return _itemsCollection.doc(documentId).set(
      {
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  NotificationItemModel _toNotificationModel(
    String documentId,
    Map<String, dynamic> data,
  ) {
    final createdRaw = data['createdAt'] ?? data['created_at'];
    final createdAt = _parseCreatedAt(createdRaw);

    return NotificationItemModel(
      notificationId: parseJsonInt(data['notification_id']) == 0
          ? documentId.hashCode
          : parseJsonInt(data['notification_id']),
      notificationType: data['notificationType']?.toString() ??
          data['notification_type']?.toString() ??
          'admin_notice',
      title: data['title']?.toString() ?? '알림',
      message: data['message']?.toString() ?? '',
      targetPath: data['targetPath']?.toString() ??
          data['target_path']?.toString(),
      deliveryStatus: data['deliveryStatus']?.toString() ??
          data['delivery_status']?.toString() ??
          'delivered',
      responseMessageId:
          data['responseMessageId']?.toString() ?? data['response_message_id']?.toString(),
      failureReason:
          data['failureReason']?.toString() ?? data['failure_reason']?.toString(),
      retryCount: parseJsonInt(data['retryCount'] ?? data['retry_count']),
      isRead: data['isRead'] as bool? ?? data['is_read'] as bool? ?? false,
      createdAt: createdAt,
      firestoreDocumentId: documentId,
    );
  }

  DateTime _parseCreatedAt(dynamic raw) {
    if (raw is Timestamp) {
      return raw.toDate();
    }
    if (raw is DateTime) {
      return raw;
    }
    if (raw is String) {
      final parsed = DateTime.tryParse(raw);
      if (parsed != null) {
        return parsed;
      }
    }
    final parsed = parseNullableJsonDateTime(raw);
    return parsed ?? DateTime.fromMillisecondsSinceEpoch(0);
  }
}
