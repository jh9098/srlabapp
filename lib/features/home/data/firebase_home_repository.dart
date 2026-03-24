import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/firestore_parsers.dart';
import '../../../core/utils/json_parsers.dart';
import '../../shared/models/common_models.dart' show StatusBadgeModel;
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

    final featuredStocks = await Future.wait(
      publicWatchlist.docs.map(_buildFeaturedStock),
    );

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

  Future<HomeFeaturedStockModel> _buildFeaturedStock(
    QueryDocumentSnapshot<Map<String, dynamic>> watchlistDoc,
  ) async {
    final watchData = watchlistDoc.data();
    final ticker = normalizeTicker(watchData['ticker']);
    final priceSnapshot = ticker.isEmpty
        ? null
        : await _firestore.collection('stock_prices').doc(ticker).get();
    final priceData = priceSnapshot?.data() ?? const <String, dynamic>{};
    final priceSummary = parseFirestorePriceSummary(priceData);
    final supportLines = parseFirestoreDoubleList(watchData['supportLines']);
    final resistanceLines = parseFirestoreDoubleList(watchData['resistanceLines']);
    final supportPrice = _resolveSupportPrice(
      watchData: watchData,
      supportLines: supportLines,
    );

    return HomeFeaturedStockModel(
      watchlistDocId: watchlistDoc.id,
      stockCode: ticker,
      stockName: (watchData['name'] as String?) ?? (priceData['name'] as String?) ?? ticker,
      currentPrice: priceSummary.currentPrice,
      changePct: priceSummary.changePct,
      supportPrice: supportPrice,
      status: _resolveStatus(
        currentPrice: priceSummary.currentPrice,
        supportLines: supportLines,
        resistanceLines: resistanceLines,
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

  StatusBadgeModel _resolveStatus({
    required double currentPrice,
    required List<double> supportLines,
    required List<double> resistanceLines,
  }) {
    if (currentPrice <= 0) {
      return const StatusBadgeModel(code: 'WAITING', label: '가격 대기', severity: 'neutral');
    }

    final nearestSupportGap = _nearestGapPercent(currentPrice, supportLines);
    final nearestResistanceGap = _nearestGapPercent(currentPrice, resistanceLines);

    if (nearestSupportGap != null && nearestSupportGap <= 2) {
      return const StatusBadgeModel(
        code: 'TESTING_SUPPORT',
        label: '지지선 근접',
        severity: 'watch',
      );
    }
    if (nearestResistanceGap != null && nearestResistanceGap <= 2) {
      return const StatusBadgeModel(
        code: 'RESISTANCE_NEAR',
        label: '저항선 근접',
        severity: 'warning',
      );
    }
    return const StatusBadgeModel(code: 'REUSABLE', label: '관찰 중', severity: 'neutral');
  }

  double? _nearestGapPercent(double currentPrice, List<double> levels) {
    if (levels.isEmpty || currentPrice <= 0) {
      return null;
    }
    final gaps = levels.map((level) => ((currentPrice - level).abs() / level) * 100).toList();
    gaps.sort();
    return gaps.first;
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
