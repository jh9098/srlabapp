import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../data/home_models.dart';

class MarketSnapshotSection extends StatefulWidget {
  const MarketSnapshotSection({
    super.key,
    required this.snapshots,
  });

  final List<HomeMarketSnapshotModel> snapshots;

  @override
  State<MarketSnapshotSection> createState() => _MarketSnapshotSectionState();
}

class _MarketSnapshotSectionState extends State<MarketSnapshotSection> {
  final Set<String> _expandedTitles = <String>{};

  void _toggle(String key) {
    setState(() {
      if (_expandedTitles.contains(key)) {
        _expandedTitles.remove(key);
      } else {
        _expandedTitles.add(key);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final visibleSnapshots = widget.snapshots.where((item) => !item.isEmpty).toList();
    if (visibleSnapshots.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '시장 빠른 보기',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          '최신 인기/수급 데이터를 간단히 확인합니다.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade700,
              ),
        ),
        const SizedBox(height: AppSpacing.sectionSmall),
        ...visibleSnapshots.map((snapshot) {
          final key = snapshot.title;
          final isExpanded = _expandedTitles.contains(key);
          final visibleItems = isExpanded ? snapshot.items : snapshot.items.take(6).toList();
          final remain = snapshot.items.length - visibleItems.length;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.insights_rounded,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            snapshot.title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Text(
                          isExpanded ? '전체 ${visibleItems.length}' : 'TOP ${visibleItems.length}',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        ...visibleItems.map(
                          (item) => Chip(
                            visualDensity: VisualDensity.compact,
                            label: Text(
                              item,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        if (remain > 0)
                          ActionChip(
                            visualDensity: VisualDensity.compact,
                            label: Text('+$remain 더보기'),
                            onPressed: () => _toggle(key),
                          ),
                        if (isExpanded && snapshot.items.length > 6)
                          ActionChip(
                            visualDensity: VisualDensity.compact,
                            label: const Text('접기'),
                            onPressed: () => _toggle(key),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
