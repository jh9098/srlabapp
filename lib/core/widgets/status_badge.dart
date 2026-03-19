import 'package:flutter/material.dart';

import '../../features/shared/models/common_models.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final StatusBadgeModel status;

  @override
  Widget build(BuildContext context) {
    final palette = _palette(status.severity);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: palette.foreground,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }

  _BadgePalette _palette(String severity) {
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

class _BadgePalette {
  const _BadgePalette(this.background, this.foreground);

  final Color background;
  final Color foreground;
}
