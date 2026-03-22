import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/firestore_parsers.dart';
import '../../../core/utils/json_parsers.dart';
import '../../shared/models/common_models.dart';
import 'stock_models.dart';

class FirebaseStockRepository {
  FirebaseStockRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<StockDetailModel> fetchStockDetail(
    String stockCode, {
    String? watchlistDocId,
  }) async {
    final normalizedTicker = normalizeTicker(stockCode);
    final watchlistDoc = await _resolveWatchlistDoc(
      normalizedTicker,
      watchlistDocId: watchlistDocId,
    );
    final watchData = watchlistDoc?.data() ?? const <String, dynamic>{};

    final priceDoc = normalizedTicker.isEmpty
        ? null
        : await _firestore.collection('stock_prices').doc(normalizedTicker).get();
    final priceData = priceDoc?.data() ?? const <String, dynamic>{};
    final priceSummary = parseFirestorePriceSummary(priceData);
    final bars = _parseDailyBars(priceData);
    final levels = _buildLevels(watchData, priceSummary.currentPrice);
    final supportLevels = levels.where((item) => item.isSupport).toList();
    final resistanceLevels = levels.where((item) => item.isResistance).toList();
    final status = _resolveStatus(
      currentPrice: priceSummary.currentPrice,
      supportLevels: supportLevels,
      resistanceLevels: resistanceLevels,
    );

    final memo = (watchData['memo'] as String?)?.trim() ?? '';
    return StockDetailModel(
      stock: StockSummaryModel(
        stockCode: normalizedTicker,
        stockName: (watchData['name'] as String?) ?? (priceData['name'] as String?) ?? normalizedTicker,
        marketType: 'KOR',
      ),
      price: PriceSnapshotModel(
        currentPrice: priceSummary.currentPrice,
        changeValue: priceSummary.changeValue,
        changePct: priceSummary.changePct,
        dayHigh: bars.isEmpty ? 0 : bars.map((item) => item.highPrice).reduce((a, b) => a > b ? a : b),
        dayLow: bars.isEmpty ? 0 : bars.map((item) => item.lowPrice).reduce((a, b) => a < b ? a : b),
        volume: bars.isEmpty ? 0 : bars.last.volume,
        updatedAt: priceSummary.updatedAt,
      ),
      status: status,
      levels: levels,
      supportState: SupportStateModel(
        status: status.code,
        reactionType: null,
        firstTouchedAt: null,
        reboundPct: null,
      ),
      scenario: ScenarioModel(
        base: memo.isEmpty ? '운영 메모가 아직 없습니다.' : memo,
        bull: supportLevels.isEmpty ? '지지선 정보가 아직 없습니다.' : '가까운 지지선 반응을 먼저 확인하세요.',
        bear: resistanceLevels.isEmpty ? '저항선 정보가 아직 없습니다.' : '저항선 도달 시 눌림/돌파 여부를 같이 보세요.',
      ),
      reasonLines: _buildReasonLines(
        memo: memo,
        supportLevels: supportLevels,
        resistanceLevels: resistanceLevels,
        updatedAt: priceSummary.updatedAt,
      ),
      chart: bars,
      relatedThemes: const [],
      relatedContents: const [],
      watchlist: const StockWatchlistStateModel(
        isInWatchlist: false,
        alertEnabled: false,
        watchlistId: null,
      ),
      latestSignalSummary: LatestSignalSummaryModel(
        title: status.label,
        summary: memo.isEmpty ? '운영 메모 없이 가격/레벨만 표시합니다.' : memo,
        signalType: status.code,
        eventTime: priceSummary.updatedAt,
      ),
      recentSignalEvents: const [],
    );
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?> _resolveWatchlistDoc(
    String ticker, {
    String? watchlistDocId,
  }) async {
    if ((watchlistDocId ?? '').isNotEmpty) {
      final doc = await _firestore.collection('adminWatchlist').doc(watchlistDocId).get();
      if (doc.exists) {
        return doc;
      }
    }

    if (ticker.isEmpty) {
      return null;
    }

    final query = await _firestore
        .collection('adminWatchlist')
        .where('ticker', isEqualTo: ticker)
        .limit(1)
        .get();
    if (query.docs.isEmpty) {
      return null;
    }
    return query.docs.first;
  }

  List<DailyBarModel> _parseDailyBars(Map<String, dynamic> priceData) {
    final prices = parseFirestoreMapList(priceData['prices']);
    return prices.map((item) {
      return DailyBarModel(
        tradeDate: parseFirestoreDateTime(item['date']),
        openPrice: parseJsonDouble(item['open']),
        highPrice: parseJsonDouble(item['high']),
        lowPrice: parseJsonDouble(item['low']),
        closePrice: parseJsonDouble(item['close']),
        volume: parseJsonInt(item['volume']),
      );
    }).toList().reversed.take(90).toList().reversed.toList();
  }

  List<StockLevelModel> _buildLevels(Map<String, dynamic> watchData, double currentPrice) {
    final supportLines = parseFirestoreDoubleList(watchData['supportLines']);
    final resistanceLines = parseFirestoreDoubleList(watchData['resistanceLines']);
    final levels = <StockLevelModel>[];

    for (var index = 0; index < supportLines.length; index += 1) {
      final price = supportLines[index];
      levels.add(
        StockLevelModel(
          levelId: index + 1,
          levelType: 'SUPPORT',
          levelOrder: index + 1,
          levelPrice: price,
          distancePct: _distancePct(currentPrice, price),
        ),
      );
    }
    for (var index = 0; index < resistanceLines.length; index += 1) {
      final price = resistanceLines[index];
      levels.add(
        StockLevelModel(
          levelId: supportLines.length + index + 1,
          levelType: 'RESISTANCE',
          levelOrder: index + 1,
          levelPrice: price,
          distancePct: _distancePct(currentPrice, price),
        ),
      );
    }
    return levels;
  }

  StatusBadgeModel _resolveStatus({
    required double currentPrice,
    required List<StockLevelModel> supportLevels,
    required List<StockLevelModel> resistanceLevels,
  }) {
    final nearestSupport = supportLevels
        .map((item) => item.distancePct)
        .whereType<double>()
        .fold<double?>(null, (prev, next) => prev == null || next < prev ? next : prev);
    final nearestResistance = resistanceLevels
        .map((item) => item.distancePct)
        .whereType<double>()
        .fold<double?>(null, (prev, next) => prev == null || next < prev ? next : prev);

    if (currentPrice <= 0) {
      return const StatusBadgeModel(code: 'WAITING', label: '가격 대기', severity: 'neutral');
    }
    if (nearestSupport != null && nearestSupport <= 2) {
      return const StatusBadgeModel(code: 'TESTING_SUPPORT', label: '지지선 확인 중', severity: 'watch');
    }
    if (nearestResistance != null && nearestResistance <= 2) {
      return const StatusBadgeModel(code: 'RESISTANCE_NEAR', label: '저항선 근접', severity: 'warning');
    }
    return const StatusBadgeModel(code: 'REUSABLE', label: '관찰 중', severity: 'neutral');
  }

  List<String> _buildReasonLines({
    required String memo,
    required List<StockLevelModel> supportLevels,
    required List<StockLevelModel> resistanceLevels,
    required DateTime? updatedAt,
  }) {
    return [
      if (memo.isNotEmpty) memo,
      if (supportLevels.isNotEmpty)
        '가장 가까운 지지선은 ${supportLevels.first.levelPrice.toStringAsFixed(0)}원입니다.',
      if (resistanceLevels.isNotEmpty)
        '가장 가까운 저항선은 ${resistanceLevels.first.levelPrice.toStringAsFixed(0)}원입니다.',
      if (updatedAt != null) '가격 기준 시각은 ${updatedAt.toIso8601String()} 입니다.',
      if (memo.isEmpty && supportLevels.isEmpty && resistanceLevels.isEmpty) '운영 데이터가 아직 충분하지 않습니다.',
    ];
  }

  double? _distancePct(double currentPrice, double levelPrice) {
    if (currentPrice <= 0 || levelPrice <= 0) {
      return null;
    }
    return ((currentPrice - levelPrice).abs() / levelPrice) * 100;
  }
}
