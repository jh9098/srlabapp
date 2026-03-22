import 'package:flutter/material.dart';

import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_state.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/stock_card.dart';
import '../../app/app_scope.dart';
import '../../home/data/home_models.dart';
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
  Future<List<HomeFeaturedStockModel>>? _operatorFallbackFuture;
  bool _fallbackInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller = AppScope.of(context).watchlistController;
    if (!_controller.isLoading &&
        _controller.items.isEmpty &&
        _controller.errorMessage == null) {
      _controller.load();
    }
    if (!_fallbackInitialized) {
      _fallbackInitialized = true;
      _operatorFallbackFuture = _loadOperatorFallback();
    }
  }

  Future<List<HomeFeaturedStockModel>> _loadOperatorFallback() async {
    final scope = AppScope.of(context);
    final home = scope.firebaseHomeRepository != null
        ? await scope.firebaseHomeRepository!.fetchHome()
        : await scope.homeRepository.fetchHome();
    return home.featuredStocks;
  }

  Future<void> _reloadFallback() async {
    setState(() {
      _operatorFallbackFuture = _loadOperatorFallback();
    });
    await _operatorFallbackFuture;
  }

  bool _shouldShowOperatorFallback() {
    if (_controller.items.isNotEmpty) {
      return false;
    }
    if (_controller.isLoading) {
      return false;
    }
    if (_controller.errorMessage == null) {
      return true;
    }

    final message = _controller.errorMessage!.toUpperCase();
    return message.contains('SUPPORT_STATE_NOT_READY') ||
        message.contains('PRICE_NOT_READY') ||
        message.contains('WATCHLIST') ||
        message.contains('APIEXCEPTION');
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        if (_controller.isLoading && _controller.items.isEmpty) {
          return const LoadingState(message: '관심종목을 불러오는 중입니다...');
        }

        if (_controller.items.isNotEmpty) {
          return _buildUserWatchlist();
        }

        if (_shouldShowOperatorFallback()) {
          return _OperatorWatchlistFallback(
            errorMessage: _controller.errorMessage,
            future: _operatorFallbackFuture ?? _loadOperatorFallback(),
            onReload: () async {
              await _controller.load();
              await _reloadFallback();
            },
            onOpenSearch: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const StockSearchScreen()),
            ),
            onOpenDetail: (item) => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => StockDetailScreen(
                  stockCode: item.stockCode,
                  watchlistDocId: item.watchlistDocId.isEmpty
                      ? null
                      : item.watchlistDocId,
                ),
              ),
            ),
            onAddWatchlist: (item) async {
              await _controller.add(item.stockCode);
            },
            controller: _controller,
          );
        }

        return ErrorState(
          message: _controller.errorMessage ?? '관심종목을 불러오지 못했습니다.',
          onRetry: () => _controller.load(),
        );
      },
    );
  }

  Widget _buildUserWatchlist() {
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
          const SizedBox(height: 12),
          Card(
            color: Colors.blueGrey.shade50,
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '이 탭은 내 개인 관심종목입니다.\n'
                '운영 watchlist(Firebase에서 가져온 종목)는 종목 상세에서 지지/저항/상태를 확인할 수 있고, '
                '추가 버튼으로 내 관심종목에 담을 수 있습니다.',
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
                      Text(
                        '가까운 지지선 ${item.nearestSupport!.price.toInt()}원 · 거리 '
                        '${item.nearestSupport!.distancePct?.toStringAsFixed(2) ?? '-'}%',
                      ),
                    if (item.nearestResistance != null)
                      Text(
                        '가까운 저항선 ${item.nearestResistance!.price.toInt()}원 · 거리 '
                        '${item.nearestResistance!.distancePct?.toStringAsFixed(2) ?? '-'}%',
                      ),
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
                  MaterialPageRoute(
                    builder: (_) => StockDetailScreen(stockCode: item.stockCode),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OperatorWatchlistFallback extends StatelessWidget {
  const _OperatorWatchlistFallback({
    required this.future,
    required this.onReload,
    required this.onOpenSearch,
    required this.onOpenDetail,
    required this.onAddWatchlist,
    required this.controller,
    this.errorMessage,
  });

  final Future<List<HomeFeaturedStockModel>> future;
  final Future<void> Function() onReload;
  final VoidCallback onOpenSearch;
  final void Function(HomeFeaturedStockModel item) onOpenDetail;
  final Future<void> Function(HomeFeaturedStockModel item) onAddWatchlist;
  final WatchlistController controller;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<HomeFeaturedStockModel>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingState(message: '운영 관심종목을 불러오는 중입니다...');
        }

        if (snapshot.hasError) {
          return ErrorState(
            message: '운영 관심종목도 불러오지 못했습니다.\n${snapshot.error}',
            onRetry: onReload,
          );
        }

        final items = snapshot.data ?? const <HomeFeaturedStockModel>[];

        if (items.isEmpty) {
          return EmptyState(
            title: '관심종목이 아직 없습니다',
            description: '개인 관심종목이 비어 있고, 운영 관심종목도 아직 준비되지 않았습니다.',
            actionLabel: '종목 검색하기',
            onAction: onOpenSearch,
          );
        }

        return RefreshIndicator(
          onRefresh: onReload,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                color: Colors.amber.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    errorMessage == null
                        ? '개인 관심종목이 비어 있어서 운영 관심종목을 먼저 보여줍니다.\n'
                            '아래 종목은 상세 화면에서 지지선/저항선/상태를 확인할 수 있고, '
                            '원하면 내 관심종목으로 추가할 수 있습니다.'
                        : '개인 관심종목 API가 아직 완전히 안정적이지 않아 운영 관심종목을 대신 보여줍니다.\n'
                            '원인: $errorMessage',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _SummaryChip(label: '운영 종목', value: items.length),
                ],
              ),
              const SizedBox(height: 16),
              ...items.map(
                (item) {
                  final alreadyAdded = controller.containsStock(item.stockCode);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: StockCard(
                      name: item.stockName,
                      code: item.stockCode,
                      price: item.currentPrice,
                      changePct: item.changePct,
                      status: StatusBadge(status: item.status),
                      summary: item.summary,
                      subtitle: const Text(
                        '운영 관심종목 미리보기 · 상세 화면에서 지지선/저항선/상태 확인',
                      ),
                      trailing: alreadyAdded
                          ? const Chip(label: Text('추가됨'))
                          : FilledButton(
                              onPressed: () async {
                                await onAddWatchlist(item);
                              },
                              child: const Text('추가'),
                            ),
                      onTap: () => onOpenDetail(item),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: onOpenSearch,
                icon: const Icon(Icons.search_rounded),
                label: const Text('직접 종목 검색해서 추가하기'),
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
