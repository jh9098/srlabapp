import 'package:flutter/material.dart';

import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_state.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/stock_card.dart';
import '../../app/app_scope.dart';
import '../../shared/controllers/watchlist_controller.dart';
import '../../stock/presentation/stock_detail_screen.dart';
import '../../stock/presentation/stock_search_screen.dart';

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  late WatchlistController _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller = AppScope.of(context).watchlistController;
    if (!_controller.isLoading && _controller.items.isEmpty && _controller.errorMessage == null) {
      _controller.load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        if (_controller.isLoading && _controller.items.isEmpty) {
          return const LoadingState(message: '관심종목을 불러오는 중입니다...');
        }
        if (_controller.errorMessage != null && _controller.items.isEmpty) {
          return ErrorState(message: _controller.errorMessage!, onRetry: () => _controller.load());
        }
        if (_controller.items.isEmpty) {
          return EmptyState(
            title: '관심종목이 아직 없습니다',
            description: '보고 싶은 종목을 추가하면 지지/저항 상태를 빠르게 확인할 수 있습니다.',
            actionLabel: '종목 검색하기',
            onAction: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StockSearchScreen())),
          );
        }
        final summary = _controller.summary;
        return RefreshIndicator(
          onRefresh: _controller.load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (summary != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 12,
                      children: [
                        _SummaryChip(label: '전체', value: summary.totalCount),
                        _SummaryChip(label: '지지 확인', value: summary.supportNearCount),
                        _SummaryChip(label: '저항 근접', value: summary.resistanceNearCount),
                        _SummaryChip(label: '주의', value: summary.warningCount),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              ..._controller.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: StockCard(
                    name: item.stockName,
                    code: item.stockCode,
                    price: item.currentPrice,
                    changePct: item.changePct,
                    status: StatusBadge(status: item.status),
                    summary: item.summary,
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (item.nearestSupport != null)
                          Text('가까운 지지선 ${item.nearestSupport!.price.toInt()}원 · 거리 ${item.nearestSupport!.distancePct?.toStringAsFixed(2) ?? '-'}%'),
                        if (item.nearestResistance != null)
                          Text('가까운 저항선 ${item.nearestResistance!.price.toInt()}원 · 거리 ${item.nearestResistance!.distancePct?.toStringAsFixed(2) ?? '-'}%'),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'delete') {
                          await _controller.remove(item.watchlistId);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'delete', child: Text('관심종목 삭제')),
                      ],
                    ),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => StockDetailScreen(stockCode: item.stockCode)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text('$label $value'));
  }
}
