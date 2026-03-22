import 'package:flutter/material.dart';

import '../../data/home_models.dart';

class MarketSnapshotSection extends StatelessWidget {
  const MarketSnapshotSection({
    super.key,
    required this.snapshots,
  });

  final List<HomeMarketSnapshotModel> snapshots;

  @override
  Widget build(BuildContext context) {
    final visibleSnapshots = snapshots.where((item) => !item.isEmpty).toList();
    if (visibleSnapshots.isEmpty) {
      return const SizedBox.shrink();
    }

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
        const SizedBox(height: 12),
        ...visibleSnapshots.map(
          (snapshot) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      snapshot.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: snapshot.items
                          .take(6)
                          .map((item) => Chip(label: Text(item)))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
