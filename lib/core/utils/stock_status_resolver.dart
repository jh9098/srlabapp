import '../../features/shared/models/common_models.dart';

class StockStatusResolver {
  static const double kSupportNearThresholdPct = 2.0;
  static const double kResistanceNearThresholdPct = 2.0;

  static StatusBadgeModel resolve({
    required double currentPrice,
    required List<double> supportLevels,
    required List<double> resistanceLevels,
  }) {
    if (currentPrice <= 0) {
      return const StatusBadgeModel(
        code: 'WAITING',
        label: '가격 대기',
        severity: 'neutral',
      );
    }

    final nearestSupport = _nearestGapPct(currentPrice, supportLevels);
    final nearestResistance = _nearestGapPct(currentPrice, resistanceLevels);

    if (nearestSupport != null && nearestSupport <= kSupportNearThresholdPct) {
      return const StatusBadgeModel(
        code: 'TESTING_SUPPORT',
        label: '지지선 근접',
        severity: 'watch',
      );
    }

    if (nearestResistance != null &&
        nearestResistance <= kResistanceNearThresholdPct) {
      return const StatusBadgeModel(
        code: 'RESISTANCE_NEAR',
        label: '저항선 근접',
        severity: 'warning',
      );
    }

    return const StatusBadgeModel(
      code: 'REUSABLE',
      label: '관찰 중',
      severity: 'neutral',
    );
  }

  static double? _nearestGapPct(double price, List<double> levels) {
    if (levels.isEmpty || price <= 0) {
      return null;
    }

    return levels
        .map((level) => (price - level).abs() / level * 100)
        .reduce((a, b) => a < b ? a : b);
  }
}
