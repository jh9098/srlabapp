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
      stockCode: json['stock_code'] as String,
      stockName: json['stock_name'] as String,
      marketType: json['market_type'] as String,
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
  final DateTime updatedAt;

  factory PriceSnapshotModel.fromJson(Map<String, dynamic> json) {
    return PriceSnapshotModel(
      currentPrice: (json['current_price'] as num).toDouble(),
      changeValue: (json['change_value'] as num).toDouble(),
      changePct: (json['change_pct'] as num).toDouble(),
      dayHigh: (json['day_high'] as num).toDouble(),
      dayLow: (json['day_low'] as num).toDouble(),
      volume: json['volume'] as int,
      updatedAt: DateTime.parse(json['updated_at'] as String),
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

  factory StockLevelModel.fromJson(Map<String, dynamic> json) {
    return StockLevelModel(
      levelId: json['level_id'] as int,
      levelType: json['level_type'] as String,
      levelOrder: json['level_order'] as int,
      levelPrice: (json['level_price'] as num).toDouble(),
      distancePct: (json['distance_pct'] as num?)?.toDouble(),
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
      status: json['status'] as String,
      reactionType: json['reaction_type'] as String?,
      firstTouchedAt: json['first_touched_at'] == null
          ? null
          : DateTime.parse(json['first_touched_at'] as String),
      reboundPct: (json['rebound_pct'] as num?)?.toDouble(),
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
      base: json['base'] as String,
      bull: json['bull'] as String,
      bear: json['bear'] as String,
    );
  }
}

class ThemeReferenceModel {
  const ThemeReferenceModel({required this.themeId, required this.name});

  final int themeId;
  final String name;

  factory ThemeReferenceModel.fromJson(Map<String, dynamic> json) {
    return ThemeReferenceModel(
      themeId: json['theme_id'] as int,
      name: json['name'] as String,
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
      contentId: json['content_id'] as int,
      category: json['category'] as String,
      title: json['title'] as String,
      summary: json['summary'] as String?,
      externalUrl: json['external_url'] as String?,
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

  final DateTime tradeDate;
  final double openPrice;
  final double highPrice;
  final double lowPrice;
  final double closePrice;
  final int volume;

  factory DailyBarModel.fromJson(Map<String, dynamic> json) {
    return DailyBarModel(
      tradeDate: DateTime.parse(json['trade_date'] as String),
      openPrice: (json['open_price'] as num).toDouble(),
      highPrice: (json['high_price'] as num).toDouble(),
      lowPrice: (json['low_price'] as num).toDouble(),
      closePrice: (json['close_price'] as num).toDouble(),
      volume: json['volume'] as int,
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
      isInWatchlist: json['is_in_watchlist'] as bool,
      alertEnabled: json['alert_enabled'] as bool,
      watchlistId: json['watchlist_id'] as int?,
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

  factory StockDetailModel.fromJson(Map<String, dynamic> json) {
    return StockDetailModel(
      stock: StockSummaryModel.fromJson(json['stock'] as Map<String, dynamic>),
      price: PriceSnapshotModel.fromJson(json['price'] as Map<String, dynamic>),
      status: StatusBadgeModel.fromJson(json['status'] as Map<String, dynamic>),
      levels: (json['levels'] as List<dynamic>)
          .map((item) => StockLevelModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      supportState: SupportStateModel.fromJson(json['support_state'] as Map<String, dynamic>),
      scenario: ScenarioModel.fromJson(json['scenario'] as Map<String, dynamic>),
      reasonLines: (json['reason_lines'] as List<dynamic>).cast<String>(),
      chart: ((json['chart'] as Map<String, dynamic>)['daily_bars'] as List<dynamic>)
          .map((item) => DailyBarModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      relatedThemes: (json['related_themes'] as List<dynamic>)
          .map((item) => ThemeReferenceModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      relatedContents: (json['related_contents'] as List<dynamic>)
          .map((item) => ContentReferenceModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      watchlist: StockWatchlistStateModel.fromJson(json['watchlist'] as Map<String, dynamic>),
    );
  }
}
