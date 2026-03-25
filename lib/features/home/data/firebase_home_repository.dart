import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/firestore_parsers.dart';
import '../../../core/utils/json_parsers.dart';
import '../../../core/utils/stock_status_resolver.dart';
import 'home_models.dart';

class FirebaseHomeRepository {
  FirebaseHomeRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<HomeResponseModel> fetchHome({int featuredLimit = 6}) async {
    final publicWatchlist = await _firestore
        .collection('adminWatchlist')
        .where('isPublic', isEqualTo: true)
        .limit(featuredLimit)
        .get();

    final featuredStocks = await _buildFeaturedStocks(publicWatchlist.docs);

    final marketDocs = await Future.wait([
      _latestDoc('popularStocks'),
      _latestDoc('foreignNetBuy'),
      _latestDoc('institutionNetBuy'),
      _latestDoc('themeLeaders'),
    ]);

    final themes = _parseThemeLeaders(marketDocs[3]);
    final popularStocks = _extractNames(marketDocs[0].data());
    final foreignNetBuy = _extractNames(marketDocs[1].data());
    final institutionNetBuy = _extractNames(marketDocs[2].data());
    final headline = _buildHeadline(
      popular: marketDocs[0],
      foreign: marketDocs[1],
      institution: marketDocs[2],
    );

    return HomeResponseModel(
      marketHeadline: headline,
      featuredStocks: featuredStocks,
      watchlistSignalSummary: HomeWatchlistSignalSummaryModel(
        supportNearCount: featuredStocks.where((item) => item.status.code == 'TESTING_SUPPORT').length,
        resistanceNearCount: featuredStocks.where((item) => item.status.code == 'RESISTANCE_NEAR').length,
        warningCount: featuredStocks.where((item) => item.status.code == 'INVALID').length,
      ),
      popularStocks: HomeMarketSnapshotModel(
        title: '인기 종목',
        items: popularStocks,
      ),
      foreignNetBuy: HomeMarketSnapshotModel(
        title: '외국인 순매수',
        items: foreignNetBuy,
      ),
      institutionNetBuy: HomeMarketSnapshotModel(
        title: '기관 순매수',
        items: institutionNetBuy,
      ),
      themes: themes,
      recentContents: const [],
    );
  }

  Future<List<HomeFeaturedStockModel>> _buildFeaturedStocks(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> watchlistDocs,
  ) async {
    final tickers = watchlistDocs
        .map((doc) => normalizeTicker(doc.data()['ticker']))
        .where((ticker) => ticker.isNotEmpty)
        .toSet()
        .toList();
    final priceMap = await _loadPriceMap(tickers);

    return watchlistDocs
        .map((watchlistDoc) => _buildFeaturedStock(
              watchlistDoc,
              priceMap[normalizeTicker(watchlistDoc.data()['ticker'])],
            ))
        .toList();
  }

  Future<Map<String, Map<String, dynamic>>> _loadPriceMap(
    List<String> tickers,
  ) async {
    if (tickers.isEmpty) {
      return const {};
    }

    final result = <String, Map<String, dynamic>>{};
    const chunkSize = 10;

    for (var i = 0; i < tickers.length; i += chunkSize) {
      final end = (i + chunkSize > tickers.length) ? tickers.length : i + chunkSize;
      final chunk = tickers.sublist(i, end);
      final snapshot = await _firestore
          .collection('stock_prices')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final doc in snapshot.docs) {
        result[doc.id] = doc.data();
      }
    }

    return result;
  }

  HomeFeaturedStockModel _buildFeaturedStock(
    QueryDocumentSnapshot<Map<String, dynamic>> watchlistDoc,
    Map<String, dynamic>? priceData,
  ) {
    final watchData = watchlistDoc.data();
    final ticker = normalizeTicker(watchData['ticker']);
    final normalizedPriceData = priceData ?? const <String, dynamic>{};
    final priceSummary = parseFirestorePriceSummary(normalizedPriceData);
    final supportLines = parseFirestoreDoubleList(watchData['supportLines']);
    final resistanceLines = parseFirestoreDoubleList(watchData['resistanceLines']);
    final supportPrice = _resolveSupportPrice(
      watchData: watchData,
      supportLines: supportLines,
    );

    return HomeFeaturedStockModel(
      watchlistDocId: watchlistDoc.id,
      stockCode: ticker,
      stockName: (watchData['name'] as String?) ??
          (normalizedPriceData['name'] as String?) ??
          ticker,
      currentPrice: priceSummary.currentPrice,
      changePct: priceSummary.changePct,
      supportPrice: supportPrice,
      status: StockStatusResolver.resolve(
        currentPrice: priceSummary.currentPrice,
        supportLevels: supportLines,
        resistanceLevels: resistanceLines,
      ),
      summary: (watchData['memo'] as String?)?.trim().isNotEmpty == true
          ? (watchData['memo'] as String).trim()
          : '운영 메모가 아직 없습니다.',
    );
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> _latestDoc(String collection) {
    return _firestore.collection(collection).doc('latest').get();
  }

  String _buildHeadline({
    required DocumentSnapshot<Map<String, dynamic>> popular,
    required DocumentSnapshot<Map<String, dynamic>> foreign,
    required DocumentSnapshot<Map<String, dynamic>> institution,
  }) {
    final popularNames = _extractNames(popular.data());
    final foreignNames = _extractNames(foreign.data());
    final institutionNames = _extractNames(institution.data());

    final chunks = <String>[];
    if (popularNames.isNotEmpty) {
      chunks.add('인기 종목 ${popularNames.take(3).join(', ')}');
    }
    if (foreignNames.isNotEmpty) {
      chunks.add('외국인 관심 ${foreignNames.take(2).join(', ')}');
    }
    if (institutionNames.isNotEmpty) {
      chunks.add('기관 관심 ${institutionNames.take(2).join(', ')}');
    }
    if (chunks.isEmpty) {
      return '공개 관심종목과 시장 요약을 Firebase에서 직접 불러왔습니다.';
    }
    return chunks.join(' · ');
  }

  List<String> _extractNames(Map<String, dynamic>? data) {
    final source = data == null
        ? const []
        : (data['items'] as List<dynamic>? ??
            data['stocks'] as List<dynamic>? ??
            data['leaders'] as List<dynamic>? ??
            const []);
    return source
        .whereType<Map>()
        .map((item) => item['name']?.toString() ?? item['stockName']?.toString() ?? '')
        .where((name) => name.trim().isNotEmpty)
        .toList();
  }

  List<ThemeItemModel> _parseThemeLeaders(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    final items = data == null
        ? const []
        : (data['items'] as List<dynamic>? ?? data['leaders'] as List<dynamic>? ?? const []);

    return items.take(6).toList().asMap().entries.map((entry) {
      final map = parseFirestoreMap(entry.value);
      final leaderName = map['leaderName']?.toString() ?? map['leader']?.toString() ?? '';
      final themeName = map['themeName']?.toString() ?? map['name']?.toString() ?? '테마';
      return ThemeItemModel(
        themeId: entry.key + 1,
        name: themeName,
        score: null,
        summary: map['summary']?.toString() ?? map['memo']?.toString(),
        leaderStock: leaderName.isEmpty
            ? null
            : ThemeStockSummaryModel(stockCode: '', stockName: leaderName),
        followerStocks: const [],
        stockCount: parseJsonInt(map['stockCount']),
      );
    }).toList();
  }


  double? _resolveSupportPrice({
    required Map<String, dynamic> watchData,
    required List<double> supportLines,
  }) {
    final supportPrice = parseNullableJsonDouble(watchData['support_price']);
    if (supportPrice != null && supportPrice > 0) {
      return supportPrice;
    }
    if (supportLines.isEmpty) {
      return null;
    }
    return supportLines.first;
  }
}
