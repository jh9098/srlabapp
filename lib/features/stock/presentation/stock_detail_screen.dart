import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_state.dart';
import '../../../core/widgets/status_badge.dart';
import '../../app/app_scope.dart';
import '../data/stock_models.dart';
import 'widgets/latest_signal_card.dart';
import 'widgets/price_level_summary_card.dart';
import 'widgets/stock_price_chart.dart';

class StockDetailScreen extends StatefulWidget {
  const StockDetailScreen({super.key, required this.stockCode});

  final String stockCode;

  @override
  State<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<StockDetailScreen> {
  late Future<_StockDetailViewData> _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future = _load();
  }

  Future<_StockDetailViewData> _load() async {
    final repository = AppScope.of(context).stockRepository;
    final detail = await repository.fetchStockDetail(widget.stockCode);
    if (detail.recentSignalEvents.isNotEmpty) {
      return _StockDetailViewData(detail: detail, recentSignals: detail.recentSignalEvents);
    }

    try {
      final recentSignals = await repository.fetchStockSignals(widget.stockCode);
      return _StockDetailViewData(detail: detail, recentSignals: recentSignals);
    } catch (_) {
      return _StockDetailViewData(detail: detail, recentSignals: const []);
    }
  }

  Future<void> _reload() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final watchlistController = AppScope.of(context).watchlistController;
    return Scaffold(
      appBar: AppBar(title: const Text('종목 상세')),
      body: AnimatedBuilder(
        animation: watchlistController,
        builder: (context, _) {
          return FutureBuilder<_StockDetailViewData>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingState();
              }
              if (snapshot.hasError) {
                return ErrorState(message: snapshot.error.toString(), onRetry: _reload);
              }
              final viewData = snapshot.data;
              if (viewData == null) {
                return ErrorState(message: '종목 상세 데이터를 불러오지 못했습니다.', onRetry: _reload);
              }

              final detail = viewData.detail;
              final watchItem = watchlistController.findByStockCode(widget.stockCode);
              final isInWatchlist = watchItem != null || detail.watchlist.isInWatchlist;
              final watchlistId = watchItem?.watchlistId ?? detail.watchlist.watchlistId;
              final alertEnabled = watchItem?.alertEnabled ?? detail.watchlist.alertEnabled;
              final latestDate = detail.price.updatedAt ??
                  (detail.validChartBars.isNotEmpty ? detail.validChartBars.first.tradeDate : null);

              return RefreshIndicator(
                onRefresh: _reload,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                Text(
                                  detail.stock.stockName.isEmpty ? widget.stockCode : detail.stock.stockName,
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                StatusBadge(status: detail.status),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text('${detail.stock.stockCode} · ${detail.stock.marketType}'),
                            const SizedBox(height: 16),
                            _SummaryMetrics(detail: detail, latestDate: latestDate),
                            const SizedBox(height: 20),
                            StockPriceChart(
                              bars: detail.validChartBars,
                              supportLevels: detail.supportLevels,
                              resistanceLevels: detail.resistanceLevels,
                              currentPrice: detail.price.currentPrice,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                const Icon(Icons.bookmark_border_rounded),
                                const SizedBox(width: 8),
                                Text(
                                  isInWatchlist ? '관심종목에 등록됨' : '아직 관심종목에 없음',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const Spacer(),
                                if (!isInWatchlist || watchlistId == null)
                                  FilledButton.icon(
                                    onPressed: () async => watchlistController.add(widget.stockCode),
                                    icon: const Icon(Icons.add_rounded),
                                    label: const Text('관심종목 추가'),
                                  )
                                else
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Switch(
                                        value: alertEnabled,
                                        onChanged: (value) => watchlistController.toggleAlert(
                                          watchlistId: watchlistId,
                                          alertEnabled: value,
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () async => watchlistController.remove(watchlistId),
                                        icon: const Icon(Icons.delete_outline_rounded),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    PriceLevelSummaryCard(
                      supportLevels: detail.supportLevels,
                      resistanceLevels: detail.resistanceLevels,
                    ),
                    if (detail.hasSignalCardData || viewData.recentSignals.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      LatestSignalCard(
                        latestSignalSummary: detail.latestSignalSummary,
                        recentSignalEvents: viewData.recentSignals,
                      ),
                    ],
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: '현재 시나리오',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _InfoLine(label: '기본', value: detail.scenario.base, fallback: '기본 시나리오 데이터 없음'),
                          const SizedBox(height: 8),
                          _InfoLine(label: '상방', value: detail.scenario.bull, fallback: '상방 시나리오 데이터 없음'),
                          const SizedBox(height: 8),
                          _InfoLine(label: '하방', value: detail.scenario.bear, fallback: '하방 시나리오 데이터 없음'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: '해설 3줄',
                      child: detail.reasonLines.isEmpty
                          ? const Text('표시할 해설이 없습니다.')
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: detail.reasonLines
                                  .map(
                                    (line) => Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Text('• $line'),
                                    ),
                                  )
                                  .toList(),
                            ),
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: '최근 일봉 요약',
                      child: detail.validChartBars.isEmpty
                          ? const Text('최근 일봉 데이터가 없습니다.')
                          : Column(
                              children: detail.validChartBars.take(5).map((bar) {
                                final tradeDate = bar.tradeDate == null ? '-' : Formatters.date(bar.tradeDate!);
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(tradeDate),
                                  subtitle: Text('고가 ${Formatters.price(bar.highPrice)} / 저가 ${Formatters.price(bar.lowPrice)}'),
                                  trailing: Text(Formatters.price(bar.closePrice)),
                                );
                              }).toList(),
                            ),
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: '관련 테마',
                      child: detail.relatedThemes.isEmpty
                          ? const Text('연결된 테마가 없습니다.')
                          : Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: detail.relatedThemes.map((theme) => Chip(label: Text(theme.name))).toList(),
                            ),
                    ),
                    if (detail.relatedContents.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _SectionCard(
                        title: '관련 콘텐츠',
                        child: Column(
                          children: detail.relatedContents
                              .map(
                                (content) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(content.title),
                                  subtitle: Text(content.summary?.isNotEmpty == true ? content.summary! : '요약 없음'),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _StockDetailViewData {
  const _StockDetailViewData({required this.detail, required this.recentSignals});

  final StockDetailModel detail;
  final List<StockSignalEventModel> recentSignals;
}

class _SummaryMetrics extends StatelessWidget {
  const _SummaryMetrics({required this.detail, required this.latestDate});

  final StockDetailModel detail;
  final DateTime? latestDate;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      _MetricItem(label: '현재가', value: Formatters.price(detail.price.currentPrice), emphasized: true),
      _MetricItem(label: '등락률', value: Formatters.percent(detail.price.changePct)),
      _MetricItem(label: '고가', value: Formatters.price(detail.price.dayHigh)),
      _MetricItem(label: '저가', value: Formatters.price(detail.price.dayLow)),
      _MetricItem(label: '거래량', value: detail.price.volume.toString()),
      _MetricItem(label: '기준일', value: latestDate == null ? '-' : Formatters.date(latestDate!)),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: metrics
          .map(
            (item) => Container(
              width: 150,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.label, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 6),
                  Text(
                    item.value,
                    style: (item.emphasized
                            ? Theme.of(context).textTheme.titleLarge
                            : Theme.of(context).textTheme.titleMedium)
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _MetricItem {
  const _MetricItem({required this.label, required this.value, this.emphasized = false});

  final String label;
  final String value;
  final bool emphasized;
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value, required this.fallback});

  final String label;
  final String value;
  final String fallback;

  @override
  Widget build(BuildContext context) {
    return Text('$label: ${value.isEmpty ? fallback : value}');
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
