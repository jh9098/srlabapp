import '../../shared/models/common_models.dart';

class PriceDistanceModel {
  const PriceDistanceModel({required this.price, this.distancePct});

  final double price;
  final double? distancePct;

  factory PriceDistanceModel.fromJson(Map<String, dynamic> json) {
    return PriceDistanceModel(
      price: (json['price'] as num).toDouble(),
      distancePct: (json['distance_pct'] as num?)?.toDouble(),
    );
  }
}

class WatchlistItemModel {
  const WatchlistItemModel({
    required this.watchlistId,
    required this.stockCode,
    required this.stockName,
    required this.currentPrice,
    required this.changePct,
    required this.status,
    required this.summary,
    required this.alertEnabled,
    this.nearestSupport,
    this.nearestResistance,
  });

  final int watchlistId;
  final String stockCode;
  final String stockName;
  final double currentPrice;
  final double changePct;
  final StatusBadgeModel status;
  final PriceDistanceModel? nearestSupport;
  final PriceDistanceModel? nearestResistance;
  final String summary;
  final bool alertEnabled;

  factory WatchlistItemModel.fromJson(Map<String, dynamic> json) {
    return WatchlistItemModel(
      watchlistId: json['watchlist_id'] as int,
      stockCode: json['stock_code'] as String,
      stockName: json['stock_name'] as String,
      currentPrice: (json['current_price'] as num).toDouble(),
      changePct: (json['change_pct'] as num).toDouble(),
      status: StatusBadgeModel.fromJson(json['status'] as Map<String, dynamic>),
      nearestSupport: json['nearest_support'] == null
          ? null
          : PriceDistanceModel.fromJson(json['nearest_support'] as Map<String, dynamic>),
      nearestResistance: json['nearest_resistance'] == null
          ? null
          : PriceDistanceModel.fromJson(json['nearest_resistance'] as Map<String, dynamic>),
      summary: json['summary'] as String,
      alertEnabled: json['alert_enabled'] as bool,
    );
  }

  WatchlistItemModel copyWith({bool? alertEnabled}) {
    return WatchlistItemModel(
      watchlistId: watchlistId,
      stockCode: stockCode,
      stockName: stockName,
      currentPrice: currentPrice,
      changePct: changePct,
      status: status,
      nearestSupport: nearestSupport,
      nearestResistance: nearestResistance,
      summary: summary,
      alertEnabled: alertEnabled ?? this.alertEnabled,
    );
  }
}

class WatchlistSummaryModel {
  const WatchlistSummaryModel({
    required this.totalCount,
    required this.supportNearCount,
    required this.resistanceNearCount,
    required this.warningCount,
  });

  final int totalCount;
  final int supportNearCount;
  final int resistanceNearCount;
  final int warningCount;

  factory WatchlistSummaryModel.fromJson(Map<String, dynamic> json) {
    return WatchlistSummaryModel(
      totalCount: json['total_count'] as int,
      supportNearCount: json['support_near_count'] as int,
      resistanceNearCount: json['resistance_near_count'] as int,
      warningCount: json['warning_count'] as int,
    );
  }
}

class WatchlistResponseModel {
  const WatchlistResponseModel({required this.items, required this.summary});

  final List<WatchlistItemModel> items;
  final WatchlistSummaryModel summary;

  factory WatchlistResponseModel.fromJson(Map<String, dynamic> json) {
    return WatchlistResponseModel(
      items: (json['items'] as List<dynamic>)
          .map((item) => WatchlistItemModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      summary: WatchlistSummaryModel.fromJson(json['summary'] as Map<String, dynamic>),
    );
  }
}
