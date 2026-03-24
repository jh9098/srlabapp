import 'package:flutter/material.dart';

import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_state.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/theme/app_spacing.dart';
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
  String _filter = '전체';
  String _sort = '최근 추가순';
  Future<List<HomeFeaturedStockModel>>? _operatorFallbackFuture;
  bool _fallbackInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = AppScope.of(context);
    _controller = scope.watchlistController;
    if (!scope.config.useFirebaseOnly &&
        !_controller.isLoading &&
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
    if (scope.config.useFirebaseOnly) {
      if (scope.firebaseHomeRepository == null) {
        throw StateError('Firebase 운영 관심종목을 불러오려면 Firebase 설정이 필요합니다.');
      }
      final home = await scope.firebaseHomeRepository!.fetchHome();
      return home.featuredStocks;
    }
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
    if (AppScope.of(context).config.useFirebaseOnly) {
      return true;
    }
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
            allowPersonalActions: !AppScope.of(context).config.useFirebaseOnly,
            onReload: () async {
              if (!AppScope.of(context).config.useFirebaseOnly) {
                await _controller.load();
              }
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
    final filtered = _controller.items.where((item) {
      if (_filter == '전체') return true;
      if (_filter == '지지') return item.summary.contains('지지');
      if (_filter == '저항') return item.summary.contains('저항');
      return item.summary.contains('주의') || item.summary.contains('이탈');
    }).toList();

    if (_sort == '변동률순') {
      filtered.sort((a, b) => b.changePct.compareTo(a.changePct));
    } else if (_sort == '지지 근접순') {
      filtered.sort((a, b) => (a.nearestSupport?.distancePct ?? 999).compareTo(b.nearestSupport?.distancePct ?? 999));
    }

    return RefreshIndicator(
      onRefresh: _controller.load,
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, AppSpacing.bottomListPadding),
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final f in const ['전체', '지지', '저항', '주의'])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(label: Text(f), selected: _filter == f, onSelected: (_) => setState(() => _filter = f)),
                  ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _sort,
                  items: const ['최근 추가순', '지지 근접순', '변동률순']
                      .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                      .toList(),
                  onChanged: (v) => setState(() => _sort = v ?? _sort),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (summary != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _SummaryChip(label: '전체', value: summary.totalCount),
                    _SummaryChip(label: '지지', value: summary.supportNearCount),
                    _SummaryChip(label: '저항', value: summary.resistanceNearCount),
                    _SummaryChip(label: '주의', value: summary.warningCount),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 10),
          Card(
            color: Colors.blueGrey.shade50,
            child: const Padding(
              padding: EdgeInsets.all(14),
              child: Text('내 관심종목 중심으로 신호를 빠르게 확인하고, 좌측 스와이프로 바로 삭제할 수 있습니다.'),
            ),
          ),
          const SizedBox(height: 12),
          if (filtered.isEmpty)
            EmptyState(
              title: '조건에 맞는 관심종목이 없습니다',
              description: '필터를 변경하거나 새 종목을 추가해 보세요.',
              actionLabel: '종목 검색하기',
              onAction: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StockSearchScreen())),
            )
          else
            ...filtered.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Dismissible(
                    key: ValueKey(item.watchlistId),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(color: Colors.red.shade400, borderRadius: BorderRadius.circular(16)),
                      child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                    ),
                    onDismissed: (_) async {
                      await _controller.remove(item.watchlistId);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${item.stockName} 삭제됨'),
                          action: SnackBarAction(label: '실행취소', onPressed: () => _controller.add(item.stockCode)),
                        ),
                      );
                    },
                    child: StockCard(
                      name: item.stockName,
                      code: item.stockCode,
                      price: item.currentPrice,
                      changePct: item.changePct,
                      status: StatusBadge(status: item.status),
                      summary: item.summary,
                      trailing: FilledButton.tonal(
                        onPressed: () async => _controller.remove(item.watchlistId),
                        child: const Text('삭제'),
                      ),
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => StockDetailScreen(stockCode: item.stockCode))),
                    ),
                  ),
                )),
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
    required this.allowPersonalActions,
    this.errorMessage,
  });

  final Future<List<HomeFeaturedStockModel>> future;
  final Future<void> Function() onReload;
  final VoidCallback onOpenSearch;
  final void Function(HomeFeaturedStockModel item) onOpenDetail;
  final Future<void> Function(HomeFeaturedStockModel item) onAddWatchlist;
  final WatchlistController controller;
  final bool allowPersonalActions;
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
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, AppSpacing.bottomListPadding),
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
                      subtitle: const Text('운영 관심종목 미리보기'),
                      trailing: !allowPersonalActions
                          ? const Chip(label: Text('운영 종목'))
                          : alreadyAdded
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
                label: Text(allowPersonalActions ? '직접 종목 검색해서 추가하기' : '직접 종목 검색하기'),
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
