import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
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
  final _controller = TextEditingController();
  Timer? _debounce;
  List<StockSearchItemModel> _items = const [];
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
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
      final items = await AppScope.of(context).stockRepository.searchStocks(query.trim());
      setState(() {
        _items = items;
      });
    } catch (error) {
      setState(() {
        _error = error.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
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
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: '종목명 또는 종목코드를 입력하세요',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                  onChanged: (value) {
                    _debounce?.cancel();
                    _debounce = Timer(const Duration(milliseconds: 350), () => _search(value));
                  },
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
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return ErrorState(message: _error!, onRetry: () { _search(_controller.text); });
    }
    if (_controller.text.trim().isEmpty) {
      return const EmptyState(
        title: '찾고 싶은 종목을 입력하세요',
        description: '이름이나 코드로 검색하면 바로 관심종목에 추가할 수 있습니다.',
        icon: Icons.search_rounded,
      );
    }
    if (_items.isEmpty) {
      return const EmptyState(
        title: '검색 결과가 없습니다',
        description: '검색어를 다시 확인하거나 다른 종목명으로 시도해보세요.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: _items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = _items[index];
        final existing = watchlistController.findByStockCode(item.stockCode);
        return Card(
          child: ListTile(
            title: Text(item.stockName),
            subtitle: Text('${item.stockCode} · ${item.marketType}'),
            trailing: existing != null
                ? FilledButton.tonal(
                    onPressed: () async => watchlistController.remove(existing.watchlistId),
                    child: const Text('삭제'),
                  )
                : FilledButton(
                    onPressed: () async => watchlistController.add(item.stockCode),
                    child: const Text('추가'),
                  ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => StockDetailScreen(stockCode: item.stockCode)),
            ),
          ),
        );
      },
    );
  }
}
