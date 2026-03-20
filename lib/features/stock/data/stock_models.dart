import '../../../core/utils/json_parsers.dart';
import '../../shared/models/common_models.dart';

class StockSearchItemModel {
  const StockSearchItemModel({
    required this.stockCode,
    required this.stockName,
    required this.marketType,
  });

  final String stockCode;
  final String stockName;
  final String marketType;

  factory StockSearchItemModel.fromJson(Map<String, dynamic> json) {
    return StockSearchItemModel(
      stockCode: json['stock_code'] as String? ?? '',
      stockName: json['stock_name'] as String? ?? '',
      marketType: json['market_type'] as String? ?? '',
    );
  }
}

class PriceSnapshotModel {
  const PriceSnapshotModel({
    required this.currentPrice,
    required this.changeValue,
    required this.changePct,
    required this.dayHigh,
    required this.dayLow,
    required this.volume,
    required this.updatedAt,
  });

  final double currentPrice;
  final double changeValue;
  final double changePct;
  final double dayHigh;
  final double dayLow;
  final int volume;
  final DateTime? updatedAt;

  factory PriceSnapshotModel.fromJson(Map<String, dynamic> json) {
    return PriceSnapshotModel(
      currentPrice: parseJsonDouble(json['current_price']),
      changeValue: parseJsonDouble(json['change_value']),
      changePct: parseJsonDouble(json['change_pct']),
      dayHigh: parseJsonDouble(json['day_high']),
      dayLow: parseJsonDouble(json['day_low']),
      volume: parseJsonInt(json['volume']),
      updatedAt: parseNullableJsonDateTime(json['updated_at']),
    );
  }
}

class StockLevelModel {
  const StockLevelModel({
    required this.levelId,
    required this.levelType,
    required this.levelOrder,
    required this.levelPrice,
    required this.distancePct,
  });

  final int levelId;
  final String levelType;
  final int levelOrder;
  final double levelPrice;
  final double? distancePct;

  bool get isSupport => levelType == 'SUPPORT';
  bool get isResistance => levelType == 'RESISTANCE';

  factory StockLevelModel.fromJson(Map<String, dynamic> json) {
    return StockLevelModel(
      levelId: parseJsonInt(json['level_id']),
      levelType: json['level_type'] as String? ?? '',
      levelOrder: parseJsonInt(json['level_order']),
      levelPrice: parseJsonDouble(json['level_price']),
      distancePct: parseNullableJsonDouble(json['distance_pct']),
    );
  }
}

class SupportStateModel {
  const SupportStateModel({
    required this.status,
    required this.reactionType,
    required this.firstTouchedAt,
    required this.reboundPct,
  });

  final String status;
  final String? reactionType;
  final DateTime? firstTouchedAt;
  final double? reboundPct;

  factory SupportStateModel.fromJson(Map<String, dynamic> json) {
    return SupportStateModel(
      status: json['status'] as String? ?? '',
      reactionType: json['reaction_type'] as String?,
      firstTouchedAt: parseNullableJsonDateTime(json['first_touched_at']),
      reboundPct: parseNullableJsonDouble(json['rebound_pct']),
    );
  }
}

class ScenarioModel {
  const ScenarioModel({required this.base, required this.bull, required this.bear});

  final String base;
  final String bull;
  final String bear;

  factory ScenarioModel.fromJson(Map<String, dynamic> json) {
    return ScenarioModel(
      base: json['base'] as String? ?? '',
      bull: json['bull'] as String? ?? '',
      bear: json['bear'] as String? ?? '',
    );
  }
}

class ThemeReferenceModel {
  const ThemeReferenceModel({required this.themeId, required this.name});

  final int themeId;
  final String name;

  factory ThemeReferenceModel.fromJson(Map<String, dynamic> json) {
    return ThemeReferenceModel(
      themeId: parseJsonInt(json['theme_id']),
      name: json['name'] as String? ?? '',
    );
  }
}

class ContentReferenceModel {
  const ContentReferenceModel({
    required this.contentId,
    required this.category,
    required this.title,
    required this.summary,
    required this.externalUrl,
  });

  final int contentId;
  final String category;
  final String title;
  final String? summary;
  final String? externalUrl;

  factory ContentReferenceModel.fromJson(Map<String, dynamic> json) {
    return ContentReferenceModel(
      contentId: parseJsonInt(json['content_id']),
      category: json['category'] as String? ?? '',
      title: json['title'] as String? ?? '',
      summary: parseNullableJsonString(json['summary']),
      externalUrl: parseNullableJsonString(json['external_url']),
    );
  }
}

class DailyBarModel {
  const DailyBarModel({
    required this.tradeDate,
    required this.openPrice,
    required this.highPrice,
    required this.lowPrice,
    required this.closePrice,
    required this.volume,
  });

  final DateTime? tradeDate;
  final double openPrice;
  final double highPrice;
  final double lowPrice;
  final double closePrice;
  final int volume;

  bool get hasValidPriceRange => highPrice > 0 && lowPrice > 0 && highPrice >= lowPrice;

  factory DailyBarModel.fromJson(Map<String, dynamic> json) {
    return DailyBarModel(
      tradeDate: parseNullableJsonDate(json['trade_date']),
      openPrice: parseJsonDouble(json['open_price']),
      highPrice: parseJsonDouble(json['high_price']),
      lowPrice: parseJsonDouble(json['low_price']),
      closePrice: parseJsonDouble(json['close_price']),
      volume: parseJsonInt(json['volume']),
    );
  }
}

class StockSignalEventModel {
  const StockSignalEventModel({
    required this.eventId,
    required this.signalType,
    required this.label,
    required this.message,
    required this.eventTime,
  });

  final int eventId;
  final String signalType;
  final String label;
  final String message;
  final DateTime? eventTime;

  factory StockSignalEventModel.fromJson(Map<String, dynamic> json) {
    return StockSignalEventModel(
      eventId: parseJsonInt(json['event_id']),
      signalType: json['signal_type'] as String? ?? '',
      label: json['label'] as String? ?? '최근 신호',
      message: json['message'] as String? ?? '',
      eventTime: parseNullableJsonDateTime(json['event_time']),
    );
  }
}

class LatestSignalSummaryModel {
  const LatestSignalSummaryModel({
    required this.title,
    required this.summary,
    required this.signalType,
    required this.eventTime,
  });

  final String title;
  final String summary;
  final String? signalType;
  final DateTime? eventTime;

  bool get isEmpty => title.isEmpty && summary.isEmpty && signalType == null && eventTime == null;

  factory LatestSignalSummaryModel.fromJson(Map<String, dynamic> json) {
    return LatestSignalSummaryModel(
      title: json['title'] as String? ?? json['label'] as String? ?? '최근 신호',
      summary: json['summary'] as String? ?? json['message'] as String? ?? '',
      signalType: json['signal_type'] as String?,
      eventTime: parseNullableJsonDateTime(json['event_time']),
    );
  }
}

class StockWatchlistStateModel {
  const StockWatchlistStateModel({
    required this.isInWatchlist,
    required this.alertEnabled,
    required this.watchlistId,
  });

  final bool isInWatchlist;
  final bool alertEnabled;
  final int? watchlistId;

  factory StockWatchlistStateModel.fromJson(Map<String, dynamic> json) {
    return StockWatchlistStateModel(
      isInWatchlist: json['is_in_watchlist'] as bool? ?? false,
      alertEnabled: json['alert_enabled'] as bool? ?? false,
      watchlistId: parseNullableJsonInt(json['watchlist_id']),
    );
  }
}

class StockDetailModel {
  const StockDetailModel({
    required this.stock,
    required this.price,
    required this.status,
    required this.levels,
    required this.supportState,
    required this.scenario,
    required this.reasonLines,
    required this.chart,
    required this.relatedThemes,
    required this.relatedContents,
    required this.watchlist,
    required this.latestSignalSummary,
    required this.recentSignalEvents,
  });

  final StockSummaryModel stock;
  final PriceSnapshotModel price;
  final StatusBadgeModel status;
  final List<StockLevelModel> levels;
  final SupportStateModel supportState;
  final ScenarioModel scenario;
  final List<String> reasonLines;
  final List<DailyBarModel> chart;
  final List<ThemeReferenceModel> relatedThemes;
  final List<ContentReferenceModel> relatedContents;
  final StockWatchlistStateModel watchlist;
  final LatestSignalSummaryModel? latestSignalSummary;
  final List<StockSignalEventModel> recentSignalEvents;

  List<StockLevelModel> get supportLevels => levels.where((item) => item.isSupport).toList();
  List<StockLevelModel> get resistanceLevels => levels.where((item) => item.isResistance).toList();
  List<DailyBarModel> get validChartBars => chart.where((item) => item.hasValidPriceRange).toList();

  bool get hasSignalCardData =>
      recentSignalEvents.isNotEmpty || (latestSignalSummary != null && !latestSignalSummary!.isEmpty);

  factory StockDetailModel.fromJson(Map<String, dynamic> json) {
    final chartJson = json['chart'] as Map<String, dynamic>?;
    final recentSignalEvents = ((json['recent_signal_events'] ?? json['signal_events']) as List<dynamic>? ?? const [])
        .map((item) => StockSignalEventModel.fromJson(item as Map<String, dynamic>))
        .toList();
    final latestSignalJson = json['latest_signal_summary'] as Map<String, dynamic>?;

    return StockDetailModel(
      stock: StockSummaryModel.fromJson((json['stock'] as Map<String, dynamic>?) ?? const {}),
      price: PriceSnapshotModel.fromJson((json['price'] as Map<String, dynamic>?) ?? const {}),
      status: StatusBadgeModel.fromJson((json['status'] as Map<String, dynamic>?) ?? const {}),
      levels: (json['levels'] as List<dynamic>? ?? const [])
          .map((item) => StockLevelModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      supportState: SupportStateModel.fromJson((json['support_state'] as Map<String, dynamic>?) ?? const {}),
      scenario: ScenarioModel.fromJson((json['scenario'] as Map<String, dynamic>?) ?? const {}),
      reasonLines: (json['reason_lines'] as List<dynamic>? ?? const [])
          .map((item) => item?.toString() ?? '')
          .where((item) => item.trim().isNotEmpty)
          .toList(),
      chart: ((chartJson?['daily_bars'] ?? json['daily_bars']) as List<dynamic>? ?? const [])
          .map((item) => DailyBarModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      relatedThemes: (json['related_themes'] as List<dynamic>? ?? const [])
          .map((item) => ThemeReferenceModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      relatedContents: (json['related_contents'] as List<dynamic>? ?? const [])
          .map((item) => ContentReferenceModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      watchlist: StockWatchlistStateModel.fromJson((json['watchlist'] as Map<String, dynamic>?) ?? const {}),
      latestSignalSummary:
          latestSignalJson == null ? null : LatestSignalSummaryModel.fromJson(latestSignalJson),
      recentSignalEvents: recentSignalEvents,
    );
  }
}
