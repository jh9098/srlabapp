import 'package:flutter/material.dart';

import '../theme/app_breakpoints.dart';
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = AppBreakpoints.isNarrow(constraints.maxWidth);
        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _supportLabel(theme),
                  const SizedBox(width: 8),
                  Text(
                    Formatters.price(supportPrice),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  _statusText(theme, status, ratio),
                ],
              ),
              const SizedBox(height: 8),
              _progress(theme, clamped, status),
            ],
          );
        }

        return Row(
          children: [
            _supportLabel(theme),
            const SizedBox(width: 6),
            Text(
              Formatters.price(supportPrice),
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: _progress(theme, clamped, status)),
            const SizedBox(width: 10),
            _statusText(theme, status, ratio),
          ],
        );
      },
    );
  }

  Widget _progress(ThemeData theme, double value, _SupportDistanceStatus status) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        minHeight: 7,
        value: value,
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        valueColor: AlwaysStoppedAnimation<Color>(status.color),
      ),
    );
  }

  Widget _supportLabel(ThemeData theme) {
    return Text(
      '지지',
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _statusText(ThemeData theme, _SupportDistanceStatus status, double ratio) {
    return Text(
      '${status.label} ${_distanceLabel(ratio)}',
      style: theme.textTheme.labelSmall?.copyWith(
        color: status.color,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  String _distanceLabel(double ratio) {
    final pct = (ratio * 100).abs();
    return ratio < 0 ? '-${pct.toStringAsFixed(1)}%' : '+${pct.toStringAsFixed(1)}%';
  }

  _SupportDistanceStatus _resolveStatus(double ratio) {
    if (ratio < 0) return _SupportDistanceStatus(label: '이탈', color: Colors.red.shade400);
    if (ratio <= 0.03) return _SupportDistanceStatus(label: '근접', color: Colors.red.shade400);
    if (ratio <= 0.07) return _SupportDistanceStatus(label: '주의', color: Colors.orange.shade500);
    return _SupportDistanceStatus(label: '여유', color: Colors.green.shade500);
  }
}

class _SupportDistanceStatus {
  const _SupportDistanceStatus({required this.label, required this.color});

  final String label;
  final Color color;
}
