class StatusBadgeModel {
  const StatusBadgeModel({
    required this.code,
    required this.label,
    required this.severity,
  });

  final String code;
  final String label;
  final String severity;

  factory StatusBadgeModel.fromJson(Map<String, dynamic> json) {
    return StatusBadgeModel(
      code: json['code'] as String,
      label: json['label'] as String,
      severity: json['severity'] as String,
    );
  }
}

class StockSummaryModel {
  const StockSummaryModel({
    required this.stockCode,
    required this.stockName,
    required this.marketType,
  });

  final String stockCode;
  final String stockName;
  final String marketType;

  factory StockSummaryModel.fromJson(Map<String, dynamic> json) {
    return StockSummaryModel(
      stockCode: json['stock_code'] as String,
      stockName: json['stock_name'] as String,
      marketType: json['market_type'] as String,
    );
  }
}

class ThemeStockSummaryModel {
  const ThemeStockSummaryModel({
    required this.stockCode,
    required this.stockName,
  });

  final String stockCode;
  final String stockName;

  factory ThemeStockSummaryModel.fromJson(Map<String, dynamic> json) {
    return ThemeStockSummaryModel(
      stockCode: json['stock_code'] as String,
      stockName: json['stock_name'] as String,
    );
  }
}
