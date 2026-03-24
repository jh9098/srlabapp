import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../features/home/data/home_models.dart';

class FeaturedStockTile extends StatelessWidget {
  const FeaturedStockTile({
    super.key,
    required this.item,
    this.onTap,
  });

  final HomeFeaturedStockModel item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusPalette = _statusPalette(item.status.severity);

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _SeverityDot(severity: item.status.severity),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: _StockNameBlock(item: item),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: Text(
                      Formatters.price(item.currentPrice),
                      textAlign: TextAlign.right,
                      style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 62,
                    child: Text(
                      Formatters.percent(item.changePct),
                      textAlign: TextAlign.right,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: item.changePct >= 0 ? const Color(0xFFDC2626) : const Color(0xFF2563EB),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusPalette.background,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.status.label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: statusPalette.foreground,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 14,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
              if (item.supportPrice != null) ...[
                const SizedBox(height: 4),
                _SupportDistanceRow(item: item),
              ],
              if (_showSummary(item.summary)) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 16),
                  child: Text(
                    item.summary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  bool _showSummary(String summary) {
    if (summary.trim().isEmpty) {
      return false;
    }
    return summary.trim() != '운영자 코멘트가 아직 없습니다.';
  }

  _BadgePalette _statusPalette(String severity) {
    switch (severity) {
      case 'positive':
        return const _BadgePalette(Color(0xFFDCFCE7), Color(0xFF166534));
      case 'warning':
        return const _BadgePalette(Color(0xFFFFEDD5), Color(0xFF9A3412));
      case 'watch':
        return const _BadgePalette(Color(0xFFDBEAFE), Color(0xFF1D4ED8));
      default:
        return const _BadgePalette(Color(0xFFE2E8F0), Color(0xFF334155));
    }
  }
}

class _StockNameBlock extends StatelessWidget {
  const _StockNameBlock({required this.item});

  final HomeFeaturedStockModel item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconData = _statusIcon(item.status.code);
    final iconColor = _statusIconColor(item.status.code);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                item.stockName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            if (iconData != null) ...[
              const SizedBox(width: 4),
              Icon(iconData, size: 14, color: iconColor),
            ],
          ],
        ),
        Text(
          item.stockCode,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  IconData? _statusIcon(String code) {
    switch (code) {
      case 'SUPPORT_BOUNCE':
        return Icons.trending_up_rounded;
      case 'SUPPORT_BREAK_BOUNCE':
        return Icons.restart_alt_rounded;
      case 'SUPPORT_NEAR':
        return Icons.arrow_downward_rounded;
      case 'SUPPORT_BREAK':
        return Icons.warning_amber_rounded;
      default:
        return null;
    }
  }

  Color _statusIconColor(String code) {
    switch (code) {
      case 'SUPPORT_BOUNCE':
        return const Color(0xFF16A34A);
      case 'SUPPORT_BREAK_BOUNCE':
        return const Color(0xFFF97316);
      case 'SUPPORT_NEAR':
        return const Color(0xFFDC2626);
      case 'SUPPORT_BREAK':
        return Colors.red.shade700;
      default:
        return Colors.transparent;
    }
  }
}

class _SupportDistanceRow extends StatelessWidget {
  const _SupportDistanceRow({required this.item});

  final HomeFeaturedStockModel item;

  @override
  Widget build(BuildContext context) {
    final supportPrice = item.supportPrice;
    if (supportPrice == null) {
      return const SizedBox.shrink();
    }

    final ratio = (item.currentPrice - supportPrice) / supportPrice;
    final supportStatus = _resolveStatus(ratio);
    final statusText = '${supportStatus.label} ${_distanceLabel(ratio)}';
    final highlightBreak = ratio < 0;

    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Container(
        decoration: highlightBreak
            ? BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(6),
              )
            : null,
        padding: highlightBreak
            ? const EdgeInsets.symmetric(horizontal: 8, vertical: 3)
            : EdgeInsets.zero,
        child: Row(
          children: [
            Text(
              '지지',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              Formatters.price(supportPrice),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 5,
                  value: ratio.clamp(0.0, 1.0),
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(supportStatus.color),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              statusText,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: supportStatus.color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  _SupportStatus _resolveStatus(double ratio) {
    if (ratio < 0) {
      return _SupportStatus(label: '이탈', color: Colors.red.shade500);
    }
    if (ratio <= 0.03) {
      return _SupportStatus(label: '근접', color: Colors.red.shade400);
    }
    if (ratio <= 0.07) {
      return _SupportStatus(label: '주의', color: Colors.orange.shade500);
    }
    return _SupportStatus(label: '여유', color: Colors.green.shade500);
  }

  String _distanceLabel(double ratio) {
    final pct = ratio.abs() * 100;
    if (ratio < 0) {
      return '-${pct.toStringAsFixed(1)}%';
    }
    return '+${pct.toStringAsFixed(1)}%';
  }
}

class _SeverityDot extends StatelessWidget {
  const _SeverityDot({required this.severity});

  final String severity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: _severityColor(severity),
        shape: BoxShape.circle,
      ),
    );
  }

  Color _severityColor(String severity) {
    switch (severity) {
      case 'positive':
        return const Color(0xFF22C55E);
      case 'warning':
        return const Color(0xFFF59E0B);
      case 'watch':
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFF94A3B8);
    }
  }
}

class _BadgePalette {
  const _BadgePalette(this.background, this.foreground);

  final Color background;
  final Color foreground;
}

class _SupportStatus {
  const _SupportStatus({required this.label, required this.color});

  final String label;
  final Color color;
}
