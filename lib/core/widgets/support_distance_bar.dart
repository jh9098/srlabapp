import 'package:flutter/material.dart';

import '../utils/formatters.dart';

class SupportDistanceBar extends StatelessWidget {
  const SupportDistanceBar({
    super.key,
    required this.currentPrice,
    required this.supportPrice,
  });

  final double currentPrice;
  final double supportPrice;

  @override
  Widget build(BuildContext context) {
    if (supportPrice <= 0) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final ratio = (currentPrice - supportPrice) / supportPrice;
    final clamped = ratio.clamp(0.0, 1.0).toDouble();
    final status = _resolveStatus(ratio);

    return Row(
      children: [
        Text(
          '지지',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          Formatters.price(supportPrice),
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 7,
              value: clamped,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(status.color),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '${status.label} ${_distanceLabel(ratio)}',
          style: theme.textTheme.labelSmall?.copyWith(
            color: status.color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  String _distanceLabel(double ratio) {
    final pct = (ratio * 100).abs();
    if (ratio < 0) {
      return '-${pct.toStringAsFixed(1)}%';
    }
    return '+${pct.toStringAsFixed(1)}%';
  }

  _SupportDistanceStatus _resolveStatus(double ratio) {
    if (ratio < 0) {
      return _SupportDistanceStatus(label: '이탈', color: Colors.red.shade400);
    }
    if (ratio <= 0.03) {
      return _SupportDistanceStatus(label: '근접', color: Colors.red.shade400);
    }
    if (ratio <= 0.07) {
      return _SupportDistanceStatus(label: '주의', color: Colors.orange.shade400);
    }
    return _SupportDistanceStatus(label: '여유', color: Colors.green.shade400);
  }
}

class _SupportDistanceStatus {
  const _SupportDistanceStatus({required this.label, required this.color});

  final String label;
  final Color color;
}
