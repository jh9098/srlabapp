import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_state.dart';
import '../../app/app_scope.dart';
import '../../shared/controllers/watchlist_controller.dart';
import '../data/stock_models.dart';
import 'stock_detail_screen.dart';

class StockSearchScreen extends StatefulWidget {
  const StockSearchScreen({super.key});

  @override
  State<StockSearchScreen> createState() => _StockSearchScreenState();
}

class _StockSearchScreenState extends State<StockSearchScreen> {
  static const _recentKey = 'stock_search_recent';
  final _controller = TextEditingController();
  Timer? _debounce;
  List<StockSearchItemModel> _items = const [];
  final List<String> _recent = [];
  bool _initializingRecent = true;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _restoreRecentSearches();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _restoreRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_recentKey);
    if (raw == null || raw.isEmpty) {
      if (!mounted) return;
      setState(() => _initializingRecent = false);
      return;
    }

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      _recent
        ..clear()
        ..addAll(
          decoded
              .map((item) => item.toString().trim())
              .where((item) => item.isNotEmpty)
              .take(6),
        );
    } catch (_) {
      _recent.clear();
    }
    if (!mounted) return;
    setState(() => _initializingRecent = false);
  }

  Future<void> _saveRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_recentKey, jsonEncode(_recent));
  }

  Future<void> _search(String query) async {
    final keyword = query.trim();
    if (keyword.isEmpty) {
      setState(() {
        _items = const [];
        _error = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final scope = AppScope.of(context);
      final items = scope.config.useFirebaseOnly && scope.firebaseStockRepository != null
          ? await scope.firebaseStockRepository!.searchStocks(keyword)
          : await scope.stockRepository.searchStocks(keyword);
      setState(() {
        _items = items;
        _recent.remove(keyword);
        _recent.insert(0, keyword);
        if (_recent.length > 6) _recent.removeLast();
      });
      await _saveRecentSearches();
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final watchlistController = AppScope.of(context).watchlistController;
    return Scaffold(
      appBar: AppBar(title: const Text('종목 검색')),
      body: AnimatedBuilder(
        animation: watchlistController,
        builder: (context, _) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                child: TextField(
                  controller: _controller,
                  textInputAction: TextInputAction.search,
                  onSubmitted: _search,
                  decoration: InputDecoration(
                    hintText: '종목명 또는 종목코드를 입력하세요',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _controller.text.trim().isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _controller.clear();
                              _search('');
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                  ),
                  onChanged: (value) {
                    setState(() {});
                    _debounce?.cancel();
                    _debounce = Timer(const Duration(milliseconds: 300), () => _search(value));
                  },
                ),
              ),
              if (_controller.text.trim().isEmpty && _recent.isNotEmpty)
                SizedBox(
                  height: 42,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: _recent
                        .map((q) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ActionChip(label: Text(q), onPressed: () {
                                _controller.text = q;
                                _search(q);
                              }),
                            ))
                        .toList(),
                  ),
                ),
              Expanded(child: _buildBody(watchlistController)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(WatchlistController watchlistController) {
    if (_initializingRecent) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, AppSpacing.bottomListPadding),
        children: const [
          LoadingState(compact: true, message: '최근 검색어를 불러오는 중...'),
        ],
      );
    }
    if (_loading) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, AppSpacing.bottomListPadding),
        children: const [LoadingState(compact: true, message: '검색 결과를 불러오는 중...')],
      );
    }
    if (_error != null) {
      return ErrorState(message: _error!, onRetry: () => _search(_controller.text));
    }
    if (_controller.text.trim().isEmpty) {
      return EmptyState(
        title: '찾고 싶은 종목을 입력하세요',
        description: '예시: 삼성전자, 에코프로비엠, 005930',
        icon: Icons.search_rounded,
        isFullPage: true,
      );
    }
    if (_items.isEmpty) {
      return const EmptyState(
        title: '검색 결과가 없습니다',
        description: '검색어를 다시 확인하거나 다른 종목명으로 시도해보세요.',
        isFullPage: true,
      );
    }
    return ListView.separated(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, AppSpacing.bottomListPadding),
      itemCount: _items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = _items[index];
        final scope = AppScope.of(context);
        final enablePersonalWatchlist = scope.config.enableBackendFeatures;
        final existing = watchlistController.findByStockCode(item.stockCode);
        return Card(
          child: ListTile(
            title: Text(item.stockName, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text('${item.stockCode} · ${item.marketType}'),
            trailing: !enablePersonalWatchlist
                ? const Chip(label: Text('조회 전용'))
                : SizedBox(
                    height: 36,
                    child: existing != null
                        ? FilledButton.tonal(onPressed: () async => watchlistController.remove(existing.watchlistId), child: const Text('삭제'))
                        : FilledButton(onPressed: () async => watchlistController.add(item.stockCode), child: const Text('추가')),
                  ),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => StockDetailScreen(stockCode: item.stockCode))),
          ),
        );
      },
    );
  }
}
