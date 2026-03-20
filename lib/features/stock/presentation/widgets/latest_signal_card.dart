import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../data/stock_models.dart';

class LatestSignalCard extends StatelessWidget {
  const LatestSignalCard({
    super.key,
    required this.latestSignalSummary,
    required this.recentSignalEvents,
  });

  final LatestSignalSummaryModel? latestSignalSummary;
  final List<StockSignalEventModel> recentSignalEvents;

  @override
  Widget build(BuildContext context) {
    final hasSummary = latestSignalSummary != null && !latestSignalSummary!.isEmpty;
    final visibleEvents = recentSignalEvents.take(3).toList();
    if (!hasSummary && visibleEvents.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('최근 신호', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            if (hasSummary) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      latestSignalSummary!.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    if (latestSignalSummary!.summary.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(latestSignalSummary!.summary),
                    ],
                    if (latestSignalSummary!.eventTime != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        '발생 시각 ${Formatters.dateTime(latestSignalSummary!.eventTime!)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ],
            if (visibleEvents.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...visibleEvents.map(
                (event) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _EventTile(event: event),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event});

  final StockSignalEventModel event;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(event.label, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          if (event.message.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(event.message),
          ],
          if (event.eventTime != null) ...[
            const SizedBox(height: 8),
            Text('발생 시각 ${Formatters.dateTime(event.eventTime!)}', style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}
