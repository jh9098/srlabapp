import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/firestore_parsers.dart';

class AdminWatchlistPreviewItem {
  const AdminWatchlistPreviewItem({
    required this.docId,
    required this.name,
    required this.ticker,
    required this.memo,
    required this.isPublic,
    required this.alertEnabled,
    required this.portfolioReady,
    required this.supportCount,
    required this.resistanceCount,
    required this.updatedAt,
  });

  final String docId;
  final String name;
  final String ticker;
  final String memo;
  final bool isPublic;
  final bool alertEnabled;
  final bool portfolioReady;
  final int supportCount;
  final int resistanceCount;
  final DateTime? updatedAt;
}

class AdminWatchlistPreviewRepository {
  AdminWatchlistPreviewRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<List<AdminWatchlistPreviewItem>> fetchItems({int limit = 20}) async {
    final snapshot = await _firestore
        .collection('adminWatchlist')
        .limit(limit)
        .get();

    final items = snapshot.docs.map((doc) {
      final data = doc.data();
      return AdminWatchlistPreviewItem(
        docId: doc.id,
        name: data['name']?.toString() ?? '',
        ticker: normalizeTicker(data['ticker']),
        memo: data['memo']?.toString() ?? '',
        isPublic: data['isPublic'] as bool? ?? false,
        alertEnabled: data['alertEnabled'] as bool? ?? false,
        portfolioReady: data['portfolioReady'] as bool? ?? false,
        supportCount: parseFirestoreDoubleList(data['supportLines']).length,
        resistanceCount: parseFirestoreDoubleList(data['resistanceLines']).length,
        updatedAt: parseFirestoreDateTime(data['updatedAt']),
      );
    }).toList();

    items.sort((a, b) {
      final aTime = a.updatedAt?.millisecondsSinceEpoch ?? 0;
      final bTime = b.updatedAt?.millisecondsSinceEpoch ?? 0;
      return bTime.compareTo(aTime);
    });
    return items;
  }
}
