import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_state.dart';
import '../../../core/widgets/status_badge.dart';
import '../../app/app_scope.dart';
import '../data/stock_models.dart';

class StockDetailScreen extends StatefulWidget {
  const StockDetailScreen({super.key, required this.stockCode});

  final String stockCode;

  @override
  State<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<StockDetailScreen> {
  late Future<StockDetailModel> _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future = AppScope.of(context).stockRepository.fetchStockDetail(widget.stockCode);
  }

  Future<void> _reload() async {
    setState(() {
      _future = AppScope.of(context).stockRepository.fetchStockDetail(widget.stockCode);
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
          return FutureBuilder<StockDetailModel>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingState();
              }
              if (snapshot.hasError) {
                return ErrorState(message: snapshot.error.toString(), onRetry: () => _reload());
              }
              final detail = snapshot.data!;
              final watchItem = watchlistController.findByStockCode(widget.stockCode);
              final isInWatchlist = watchItem != null || detail.watchlist.isInWatchlist;
              final watchlistId = watchItem?.watchlistId ?? detail.watchlist.watchlistId;
              final alertEnabled = watchItem?.alertEnabled ?? detail.watchlist.alertEnabled;
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
                            Text(detail.stock.stockName, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text('${detail.stock.stockCode} · ${detail.stock.marketType}'),
                            const SizedBox(height: 16),
                            Text(
                              Formatters.price(detail.price.currentPrice),
                              style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                Text('등락 ${Formatters.percent(detail.price.changePct)}'),
                                Text('고가 ${Formatters.price(detail.price.dayHigh)}'),
                                Text('저가 ${Formatters.price(detail.price.dayLow)}'),
                                Text('거래량 ${detail.price.volume}'),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                StatusBadge(status: detail.status),
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
                    _SectionCard(
                      title: '지지선 / 저항선',
                      child: Column(
                        children: detail.levels
                            .map(
                              (level) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text('${level.levelType == 'SUPPORT' ? '지지선' : '저항선'} ${level.levelOrder}'),
                                subtitle: Text('거리 ${level.distancePct?.toStringAsFixed(2) ?? '-'}%'),
                                trailing: Text(Formatters.price(level.levelPrice)),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: '현재 시나리오',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('기본: ${detail.scenario.base}'),
                          const SizedBox(height: 8),
                          Text('상방: ${detail.scenario.bull}'),
                          const SizedBox(height: 8),
                          Text('하방: ${detail.scenario.bear}'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: '해설 3줄',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: detail.reasonLines
                            .map((line) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Text('• $line'),
                                ))
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: '최근 일봉(간단 요약)',
                      child: Column(
                        children: detail.chart.take(5).map((bar) {
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text('${bar.tradeDate.year}-${bar.tradeDate.month.toString().padLeft(2, '0')}-${bar.tradeDate.day.toString().padLeft(2, '0')}'),
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
