import 'package:flutter/material.dart';

import '../utils/formatters.dart';
import 'support_distance_bar.dart';

class StockCard extends StatelessWidget {
  const StockCard({
    super.key,
    required this.name,
    required this.code,
    required this.price,
    required this.changePct,
    required this.status,
    required this.summary,
    this.supportPrice,
    this.severity = 'neutral',
    this.compact = false,
    this.trailing,
    this.onTap,
    this.subtitle,
  });

  final String name;
  final String code;
  final double price;
  final double changePct;
  final double? supportPrice;
  final String severity;
  final Widget status;
  final String summary;
  final bool compact;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Widget? subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: compact ? const EdgeInsets.symmetric(horizontal: 14, vertical: 12) : const EdgeInsets.all(16),
          child: compact
              ? _CompactStockCardBody(
                  name: name,
                  code: code,
                  price: price,
                  changePct: changePct,
                  supportPrice: supportPrice,
                  trailing: trailing,
                  severity: severity,
                )
              : _DefaultStockCardBody(
                  name: name,
                  code: code,
                  price: price,
                  changePct: changePct,
                  status: status,
                  summary: summary,
                  subtitle: subtitle,
                  trailing: trailing,
                ),
        ),
      ),
    );
  }
}

class _DefaultStockCardBody extends StatelessWidget {
  const _DefaultStockCardBody({
    required this.name,
    required this.code,
    required this.price,
    required this.changePct,
    required this.status,
    required this.summary,
    required this.subtitle,
    required this.trailing,
  });

  final String name;
  final String code;
  final double price;
  final double changePct;
  final Widget status;
  final String summary;
  final Widget? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final positive = changePct >= 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(code, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600)),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(Formatters.price(price), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            Text(
              Formatters.percent(changePct),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: positive ? const Color(0xFFDC2626) : const Color(0xFF2563EB),
                    fontWeight: FontWeight.w700,
                  ),
            ),
            status,
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 12),
          subtitle!,
        ],
        const SizedBox(height: 12),
        Text(summary, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade800)),
      ],
    );
  }
}

class _CompactStockCardBody extends StatelessWidget {
  const _CompactStockCardBody({
    required this.name,
    required this.code,
    required this.price,
    required this.changePct,
    required this.supportPrice,
    required this.trailing,
    required this.severity,
  });

  final String name;
  final String code;
  final double price;
  final double changePct;
  final double? supportPrice;
  final Widget? trailing;
  final String severity;

  @override
  Widget build(BuildContext context) {
    final positive = changePct >= 0;
    final changeColor = positive ? const Color(0xFFDC2626) : const Color(0xFF2563EB);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _SeverityDot(severity: severity),
            const SizedBox(width: 8),
            Expanded(
              child: RichText(
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  text: name,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  children: [
                    TextSpan(
                      text: '  $code',
                      style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 104),
                child: trailing!,
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                Formatters.price(price),
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              Formatters.percent(changePct),
              style: theme.textTheme.labelLarge?.copyWith(color: changeColor, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        if (supportPrice != null) ...[
          const SizedBox(height: 8),
          SupportDistanceBar(currentPrice: price, supportPrice: supportPrice!),
        ],
      ],
    );
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
      decoration: BoxDecoration(color: _severityColor(severity), shape: BoxShape.circle),
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
