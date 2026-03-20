import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../data/stock_models.dart';

class PriceLevelSummaryCard extends StatelessWidget {
  const PriceLevelSummaryCard({
    super.key,
    required this.supportLevels,
    required this.resistanceLevels,
  });

  final List<StockLevelModel> supportLevels;
  final List<StockLevelModel> resistanceLevels;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('지지선 / 저항선', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            if (supportLevels.isEmpty && resistanceLevels.isEmpty)
              const Text('표시할 가격 레벨이 없습니다.')
            else ...[
              if (supportLevels.isNotEmpty) ...[
                _LevelGroup(title: '지지선', color: const Color(0xFF16A34A), levels: supportLevels),
                if (resistanceLevels.isNotEmpty) const SizedBox(height: 12),
              ],
              if (resistanceLevels.isNotEmpty)
                _LevelGroup(title: '저항선', color: const Color(0xFFDC2626), levels: resistanceLevels),
            ],
          ],
        ),
      ),
    );
  }
}

class _LevelGroup extends StatelessWidget {
  const _LevelGroup({required this.title, required this.color, required this.levels});

  final String title;
  final Color color;
  final List<StockLevelModel> levels;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: color, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        ...levels.map(
          (level) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(child: Text('$title ${level.levelOrder}')),
                Text(Formatters.price(level.levelPrice)),
                const SizedBox(width: 8),
                Text(
                  level.distancePct == null ? '-' : '${Formatters.percent(level.distancePct!, signed: true)} 거리',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
