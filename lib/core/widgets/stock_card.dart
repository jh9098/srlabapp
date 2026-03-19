import 'package:flutter/material.dart';

import '../utils/formatters.dart';

class StockCard extends StatelessWidget {
  const StockCard({
    super.key,
    required this.name,
    required this.code,
    required this.price,
    required this.changePct,
    required this.status,
    required this.summary,
    this.trailing,
    this.onTap,
    this.subtitle,
  });

  final String name;
  final String code;
  final double price;
  final double changePct;
  final Widget status;
  final String summary;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Widget? subtitle;

  @override
  Widget build(BuildContext context) {
    final positive = changePct >= 0;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
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
                  Text(
                    Formatters.price(price),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
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
          ),
        ),
      ),
    );
  }
}
