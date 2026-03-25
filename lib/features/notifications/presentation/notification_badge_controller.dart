import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class NotificationBadgeController extends ValueNotifier<int> {
  NotificationBadgeController() : super(0);

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;

  void increment() {
    value = value + 1;
  }

  void reset() {
    value = 0;
  }

  void bindFirestore({
    required FirebaseFirestore firestore,
    required String userIdentifier,
    int limit = 100,
  }) {
    _subscription?.cancel();
    _subscription = firestore
        .collection('notifications')
        .doc(userIdentifier)
        .collection('items')
        .where('isRead', isEqualTo: false)
        .limit(limit)
        .snapshots()
        .listen((snapshot) {
      value = snapshot.docs.length;
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
