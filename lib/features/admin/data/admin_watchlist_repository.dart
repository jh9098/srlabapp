import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/firestore_parsers.dart';
import '../../../core/utils/json_parsers.dart';

class AdminWatchlistItem {
  const AdminWatchlistItem({
    required this.docId,
    required this.name,
    required this.ticker,
    required this.memo,
    required this.isPublic,
    required this.alertEnabled,
    required this.portfolioReady,
    required this.supportLines,
    required this.resistanceLines,
    required this.createdAt,
    required this.updatedAt,
  });

  final String docId;
  final String name;
  final String ticker;
  final String memo;
  final bool isPublic;
  final bool alertEnabled;
  final bool portfolioReady;
  final List<double> supportLines;
  final List<double> resistanceLines;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isNew => docId.trim().isEmpty;

  factory AdminWatchlistItem.empty() {
    return const AdminWatchlistItem(
      docId: '',
      name: '',
      ticker: '',
      memo: '',
      isPublic: true,
      alertEnabled: true,
      portfolioReady: false,
      supportLines: <double>[],
      resistanceLines: <double>[],
      createdAt: null,
      updatedAt: null,
    );
  }

  factory AdminWatchlistItem.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? const <String, dynamic>{};

    return AdminWatchlistItem(
      docId: snapshot.id,
      name: data['name']?.toString().trim() ?? '',
      ticker: normalizeTicker(data['ticker']),
      memo: data['memo']?.toString().trim() ?? '',
      isPublic: data['isPublic'] as bool? ?? false,
      alertEnabled: data['alertEnabled'] as bool? ?? false,
      portfolioReady: data['portfolioReady'] as bool? ?? false,
      supportLines: _sortedUniquePrices(
        parseFirestoreDoubleList(data['supportLines']),
      ),
      resistanceLines: _sortedUniquePrices(
        parseFirestoreDoubleList(data['resistanceLines']),
      ),
      createdAt: parseFirestoreDateTime(data['createdAt']),
      updatedAt: parseFirestoreDateTime(data['updatedAt']),
    );
  }

  AdminWatchlistItem copyWith({
    String? docId,
    String? name,
    String? ticker,
    String? memo,
    bool? isPublic,
    bool? alertEnabled,
    bool? portfolioReady,
    List<double>? supportLines,
    List<double>? resistanceLines,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AdminWatchlistItem(
      docId: docId ?? this.docId,
      name: name ?? this.name,
      ticker: ticker ?? this.ticker,
      memo: memo ?? this.memo,
      isPublic: isPublic ?? this.isPublic,
      alertEnabled: alertEnabled ?? this.alertEnabled,
      portfolioReady: portfolioReady ?? this.portfolioReady,
      supportLines: supportLines ?? this.supportLines,
      resistanceLines: resistanceLines ?? this.resistanceLines,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toFirestoreForCreate() {
    final normalizedTicker = normalizeTicker(ticker);
    final trimmedName = name.trim();

    if (normalizedTicker.isEmpty) {
      throw ArgumentError('ticker는 비어 있을 수 없습니다.');
    }
    if (trimmedName.isEmpty) {
      throw ArgumentError('name은 비어 있을 수 없습니다.');
    }

    return <String, dynamic>{
      'ticker': normalizedTicker,
      'name': trimmedName,
      'memo': memo.trim(),
      'isPublic': isPublic,
      'alertEnabled': alertEnabled,
      'portfolioReady': portfolioReady,
      'supportLines': _sortedUniquePrices(supportLines),
      'resistanceLines': _sortedUniquePrices(resistanceLines),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toFirestoreForUpdate() {
    final normalizedTicker = normalizeTicker(ticker);
    final trimmedName = name.trim();

    if (normalizedTicker.isEmpty) {
      throw ArgumentError('ticker는 비어 있을 수 없습니다.');
    }
    if (trimmedName.isEmpty) {
      throw ArgumentError('name은 비어 있을 수 없습니다.');
    }

    return <String, dynamic>{
      'ticker': normalizedTicker,
      'name': trimmedName,
      'memo': memo.trim(),
      'isPublic': isPublic,
      'alertEnabled': alertEnabled,
      'portfolioReady': portfolioReady,
      'supportLines': _sortedUniquePrices(supportLines),
      'resistanceLines': _sortedUniquePrices(resistanceLines),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static List<double> _sortedUniquePrices(List<double> prices) {
    final values = prices
        .map((e) => double.parse(e.toStringAsFixed(2)))
        .where((e) => e > 0)
        .toSet()
        .toList()
      ..sort();
    return values;
  }
}

class AdminWatchlistRepository {
  AdminWatchlistRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('adminWatchlist');

  Future<List<AdminWatchlistItem>> fetchItems({
    int limit = 50,
    bool newestFirst = true,
  }) async {
    Query<Map<String, dynamic>> query = _collection.limit(limit);

    try {
      query = newestFirst
          ? query.orderBy('updatedAt', descending: true)
          : query.orderBy('updatedAt', descending: false);
    } catch (_) {
      // orderBy 인덱스/필드 이슈가 있어도 fallback 되도록 둠
    }

    final snapshot = await query.get();
    final items = snapshot.docs
        .map(AdminWatchlistItem.fromFirestore)
        .toList();

    items.sort((a, b) {
      final aTime = a.updatedAt?.millisecondsSinceEpoch ?? 0;
      final bTime = b.updatedAt?.millisecondsSinceEpoch ?? 0;
      return newestFirst ? bTime.compareTo(aTime) : aTime.compareTo(bTime);
    });

    return items;
  }

  Stream<List<AdminWatchlistItem>> watchItems({
    int limit = 100,
    bool newestFirst = true,
  }) {
    Query<Map<String, dynamic>> query = _collection.limit(limit);

    try {
      query = newestFirst
          ? query.orderBy('updatedAt', descending: true)
          : query.orderBy('updatedAt', descending: false);
    } catch (_) {
      // query fallback
    }

    return query.snapshots().map((snapshot) {
      final items = snapshot.docs
          .map(AdminWatchlistItem.fromFirestore)
          .toList();

      items.sort((a, b) {
        final aTime = a.updatedAt?.millisecondsSinceEpoch ?? 0;
        final bTime = b.updatedAt?.millisecondsSinceEpoch ?? 0;
        return newestFirst ? bTime.compareTo(aTime) : aTime.compareTo(bTime);
      });

      return items;
    });
  }

  Future<AdminWatchlistItem?> fetchItemByDocId(String docId) async {
    final normalizedDocId = docId.trim();
    if (normalizedDocId.isEmpty) {
      return null;
    }

    final snapshot = await _collection.doc(normalizedDocId).get();
    if (!snapshot.exists) {
      return null;
    }
    return AdminWatchlistItem.fromFirestore(snapshot);
  }

  Stream<AdminWatchlistItem?> watchItemByDocId(String docId) {
    final normalizedDocId = docId.trim();
    if (normalizedDocId.isEmpty) {
      return Stream<AdminWatchlistItem?>.value(null);
    }

    return _collection.doc(normalizedDocId).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }
      return AdminWatchlistItem.fromFirestore(snapshot);
    });
  }

  Future<AdminWatchlistItem?> fetchItemByTicker(String ticker) async {
    final normalizedTicker = normalizeTicker(ticker);
    if (normalizedTicker.isEmpty) {
      return null;
    }

    final snapshot = await _collection
        .where('ticker', isEqualTo: normalizedTicker)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    return AdminWatchlistItem.fromFirestore(snapshot.docs.first);
  }

  Future<String> createItem(AdminWatchlistItem item) async {
    final normalized = _normalizeItem(item);

    final duplicate = await fetchItemByTicker(normalized.ticker);
    if (duplicate != null) {
      throw StateError(
        '이미 동일 ticker 문서가 있습니다. 기존 문서 docId: ${duplicate.docId}',
      );
    }

    final docRef = normalized.docId.trim().isEmpty
        ? _collection.doc()
        : _collection.doc(normalized.docId.trim());

    await docRef.set(normalized.toFirestoreForCreate(), SetOptions(merge: true));
    return docRef.id;
  }

  Future<void> updateItem(AdminWatchlistItem item) async {
    final normalized = _normalizeItem(item);
    final docId = normalized.docId.trim();

    if (docId.isEmpty) {
      throw ArgumentError('updateItem에는 docId가 필요합니다.');
    }

    final existing = await fetchItemByTicker(normalized.ticker);
    if (existing != null && existing.docId != docId) {
      throw StateError(
        '동일 ticker를 사용하는 다른 문서가 이미 있습니다. 기존 문서 docId: ${existing.docId}',
      );
    }

    await _collection.doc(docId).set(
          normalized.toFirestoreForUpdate(),
          SetOptions(merge: true),
        );
  }

  Future<String> saveItem(AdminWatchlistItem item) async {
    final normalized = _normalizeItem(item);

    if (normalized.docId.trim().isEmpty) {
      return createItem(normalized);
    }

    await updateItem(normalized);
    return normalized.docId;
  }

  Future<void> upsertByTicker(AdminWatchlistItem item) async {
    final normalized = _normalizeItem(item);
    final existing = await fetchItemByTicker(normalized.ticker);

    if (existing == null) {
      await createItem(normalized);
      return;
    }

    await _collection.doc(existing.docId).set(
          normalized.copyWith(docId: existing.docId).toFirestoreForUpdate(),
          SetOptions(merge: true),
        );
  }

  Future<void> deleteItem(String docId) async {
    final normalizedDocId = docId.trim();
    if (normalizedDocId.isEmpty) {
      throw ArgumentError('삭제할 docId가 비어 있습니다.');
    }

    await _collection.doc(normalizedDocId).delete();
  }

  Future<void> deleteByTicker(String ticker) async {
    final existing = await fetchItemByTicker(ticker);
    if (existing == null) {
      return;
    }
    await _collection.doc(existing.docId).delete();
  }

  Future<bool> existsTicker(String ticker, {String? excludingDocId}) async {
    final existing = await fetchItemByTicker(ticker);
    if (existing == null) {
      return false;
    }
    if (excludingDocId != null && existing.docId == excludingDocId.trim()) {
      return false;
    }
    return true;
  }

  Future<List<String>> importItems(List<AdminWatchlistItem> items) async {
    if (items.isEmpty) {
      return const <String>[];
    }

    final batch = _firestore.batch();
    final createdIds = <String>[];

    for (final raw in items) {
      final item = _normalizeItem(raw);
      final duplicate = await fetchItemByTicker(item.ticker);

      if (duplicate != null && item.docId.trim().isEmpty) {
        final docRef = _collection.doc(duplicate.docId);
        batch.set(docRef, item.toFirestoreForUpdate(), SetOptions(merge: true));
        createdIds.add(docRef.id);
        continue;
      }

      final docRef = item.docId.trim().isEmpty
          ? _collection.doc()
          : _collection.doc(item.docId.trim());

      final payload = item.docId.trim().isEmpty
          ? item.toFirestoreForCreate()
          : item.toFirestoreForUpdate();

      batch.set(docRef, payload, SetOptions(merge: true));
      createdIds.add(docRef.id);
    }

    await batch.commit();
    return createdIds;
  }

  AdminWatchlistItem _normalizeItem(AdminWatchlistItem item) {
    return item.copyWith(
      ticker: normalizeTicker(item.ticker),
      name: item.name.trim(),
      memo: item.memo.trim(),
      supportLines: _parseAndNormalizePriceList(item.supportLines),
      resistanceLines: _parseAndNormalizePriceList(item.resistanceLines),
    );
  }

  List<double> _parseAndNormalizePriceList(List<double> values) {
    return values
        .map((value) => parseJsonDouble(value))
        .where((value) => value > 0)
        .map((value) => double.parse(value.toStringAsFixed(2)))
        .toSet()
        .toList()
      ..sort();
  }
}