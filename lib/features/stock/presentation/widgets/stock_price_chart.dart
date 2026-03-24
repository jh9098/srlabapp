import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_breakpoints.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/stock_models.dart';

class StockPriceChart extends StatelessWidget {
  const StockPriceChart({
    super.key,
    required this.bars,
    required this.supportLevels,
    required this.resistanceLevels,
    required this.currentPrice,
  });

  final List<DailyBarModel> bars;
  final List<StockLevelModel> supportLevels;
  final List<StockLevelModel> resistanceLevels;
  final double currentPrice;

  @override
  Widget build(BuildContext context) {
    if (bars.isEmpty) {
      return const _ChartPlaceholder(
        icon: Icons.show_chart_rounded,
        title: '차트 데이터 없음',
        description: '최근 일봉 데이터가 없어 차트를 표시할 수 없습니다.',
      );
    }

    final allPrices = <double>[
      ...bars.expand((bar) => [bar.highPrice, bar.lowPrice, bar.closePrice]),
      ...supportLevels.map((item) => item.levelPrice),
      ...resistanceLevels.map((item) => item.levelPrice),
      if (currentPrice > 0) currentPrice,
    ].where((price) => price > 0).toList();

    if (allPrices.isEmpty) {
      return const _ChartPlaceholder(
        icon: Icons.signal_cellular_connected_no_internet_4_bar_rounded,
        title: '유효한 가격 데이터 없음',
        description: '가격 값이 비어 있거나 형식이 달라 차트를 그릴 수 없습니다.',
      );
    }

    final maxPrice = allPrices.reduce(math.max);
    final minPrice = allPrices.reduce(math.min);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: AppBreakpoints.isVeryNarrow(MediaQuery.sizeOf(context).width) ? 230 : 260,
          child: CustomPaint(
            painter: _StockPriceChartPainter(
              bars: bars,
              supportLevels: supportLevels.take(2).toList(),
              resistanceLevels: resistanceLevels.take(2).toList(),
              currentPrice: currentPrice,
              minPrice: minPrice,
              maxPrice: maxPrice,
              scheme: Theme.of(context).colorScheme,
            ),
            child: const SizedBox.expand(),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _LegendChip(label: '종가', color: Theme.of(context).colorScheme.primary),
            if (supportLevels.isNotEmpty) const _LegendChip(label: '지지선', color: Color(0xFF16A34A)),
            if (resistanceLevels.isNotEmpty) const _LegendChip(label: '저항선', color: Color(0xFFDC2626)),
            if (currentPrice > 0) const _LegendChip(label: '현재가', color: Color(0xFFF59E0B)),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('최저 ${Formatters.price(minPrice)}', style: Theme.of(context).textTheme.bodySmall),
              Text('최고 ${Formatters.price(maxPrice)}', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

class _StockPriceChartPainter extends CustomPainter {
  _StockPriceChartPainter({
    required this.bars,
    required this.supportLevels,
    required this.resistanceLevels,
    required this.currentPrice,
    required this.minPrice,
    required this.maxPrice,
    required this.scheme,
  });

  final List<DailyBarModel> bars;
  final List<StockLevelModel> supportLevels;
  final List<StockLevelModel> resistanceLevels;
  final double currentPrice;
  final double minPrice;
  final double maxPrice;
  final ColorScheme scheme;

  static const _padding = EdgeInsets.fromLTRB(12, 12, 12, 24);

  @override
  void paint(Canvas canvas, Size size) {
    final chartRect = Rect.fromLTWH(
      _padding.left,
      _padding.top,
      size.width - _padding.horizontal,
      size.height - _padding.vertical,
    );

    final gridPaint = Paint()
      ..color = scheme.outlineVariant
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final dy = chartRect.top + chartRect.height * (i / 3);
      canvas.drawLine(Offset(chartRect.left, dy), Offset(chartRect.right, dy), gridPaint);
    }

    _drawLevelLines(canvas, chartRect, supportLevels, const Color(0xFF16A34A));
    _drawLevelLines(canvas, chartRect, resistanceLevels, const Color(0xFFDC2626));
    if (currentPrice > 0) {
      _drawHorizontalLine(canvas, chartRect, currentPrice, const Color(0xFFF59E0B), dash: true, label: '현재', paintLabel: false);
    }

    final sortedBars = [...bars]
      ..sort((a, b) {
        final left = a.tradeDate?.millisecondsSinceEpoch ?? 0;
        final right = b.tradeDate?.millisecondsSinceEpoch ?? 0;
        return left.compareTo(right);
      });
    if (sortedBars.length == 1) {
      final priceY = _priceToY(sortedBars.first.closePrice, chartRect);
      final dotPaint = Paint()..color = scheme.primary;
      canvas.drawCircle(Offset(chartRect.center.dx, priceY), 4, dotPaint);
      return;
    }

    final path = Path();
    for (var i = 0; i < sortedBars.length; i++) {
      final bar = sortedBars[i];
      final dx = chartRect.left + chartRect.width * (i / (sortedBars.length - 1));
      final dy = _priceToY(bar.closePrice, chartRect);
      if (i == 0) {
        path.moveTo(dx, dy);
      } else {
        path.lineTo(dx, dy);
      }
    }

    final fillPath = Path.from(path)
      ..lineTo(chartRect.right, chartRect.bottom)
      ..lineTo(chartRect.left, chartRect.bottom)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [scheme.primary.withValues(alpha: 0.18), scheme.primary.withValues(alpha: 0.02)],
      ).createShader(chartRect);
    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = scheme.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);
  }

  void _drawLevelLines(Canvas canvas, Rect rect, List<StockLevelModel> levels, Color color) {
    for (final level in levels) {
      _drawHorizontalLine(
        canvas,
        rect,
        level.levelPrice,
        color,
        label: level.isSupport ? '지지 ${level.levelOrder}' : '저항 ${level.levelOrder}',
      );
    }
  }

  void _drawHorizontalLine(
    Canvas canvas,
    Rect rect,
    double price,
    Color color, {
    required String label,
    bool dash = false,
    bool paintLabel = true,
  }) {
    if (price <= 0) return;
    final y = _priceToY(price, rect);
    final paint = Paint()
      ..color = color.withValues(alpha: 0.82)
      ..strokeWidth = 1.5;

    if (dash) {
      const dashWidth = 6.0;
      const dashSpace = 4.0;
      var startX = rect.left;
      while (startX < rect.right) {
        canvas.drawLine(Offset(startX, y), Offset(math.min(startX + dashWidth, rect.right), y), paint);
        startX += dashWidth + dashSpace;
      }
    } else {
      canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), paint);
    }

    if (!paintLabel) return;
    final textPainter = TextPainter(
      text: TextSpan(
        text: '$label ${Formatters.compactPrice(price)}',
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: rect.width);
    textPainter.paint(canvas, Offset(rect.left + 4, math.max(rect.top, y - 18)));
  }

  double _priceToY(double price, Rect rect) {
    if ((maxPrice - minPrice).abs() < 0.0001) return rect.center.dy;
    final paddedRange = (maxPrice - minPrice) * 0.08;
    final top = maxPrice + paddedRange;
    final bottom = minPrice - paddedRange;
    final ratio = (top - price) / (top - bottom);
    return rect.top + ratio.clamp(0.0, 1.0) * rect.height;
  }

  @override
  bool shouldRepaint(covariant _StockPriceChartPainter oldDelegate) {
    return oldDelegate.bars != bars ||
        oldDelegate.supportLevels != supportLevels ||
        oldDelegate.resistanceLevels != resistanceLevels ||
        oldDelegate.currentPrice != currentPrice ||
        oldDelegate.minPrice != minPrice ||
        oldDelegate.maxPrice != maxPrice ||
        oldDelegate.scheme != scheme;
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _ChartPlaceholder extends StatelessWidget {
  const _ChartPlaceholder({required this.icon, required this.title, required this.description});

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(description, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
