import 'package:flutter/material.dart';

import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_state.dart';
import '../../app/app_scope.dart';
import '../../stock/presentation/stock_detail_screen.dart';
import '../../home/data/home_models.dart';

class ThemeScreen extends StatefulWidget {
  const ThemeScreen({super.key});

  @override
  State<ThemeScreen> createState() => _ThemeScreenState();
}

class _ThemeScreenState extends State<ThemeScreen> {
  late Future<List<ThemeItemModel>> _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future = AppScope.of(context).themeRepository.fetchThemes();
  }

  Future<void> _reload() async {
    setState(() {
      _future = AppScope.of(context).themeRepository.fetchThemes();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ThemeItemModel>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingState();
        }
        if (snapshot.hasError) {
          return ErrorState(message: snapshot.error.toString(), onRetry: () { _reload(); });
        }
        final themes = snapshot.data!;
        if (themes.isEmpty) {
          return const EmptyState(title: '테마가 아직 없습니다', description: '운영자가 오늘의 테마를 등록하면 여기에 표시됩니다.');
        }
        return RefreshIndicator(
          onRefresh: _reload,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: themes.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final theme = themes[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(theme.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                          ),
                          if (theme.score != null) Chip(label: Text('점수 ${theme.score!.toStringAsFixed(1)}')),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(theme.summary ?? '테마 설명이 아직 없습니다.'),
                      const SizedBox(height: 12),
                      if (theme.leaderStock != null)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text('대장주 · ${theme.leaderStock!.stockName}'),
                          subtitle: Text(theme.leaderStock!.stockCode),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => StockDetailScreen(stockCode: theme.leaderStock!.stockCode),
                            ),
                          ),
                        ),
                      if (theme.followerStocks.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: theme.followerStocks
                              .map(
                                (stock) => ActionChip(
                                  label: Text(stock.stockName),
                                  onPressed: () => Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => StockDetailScreen(stockCode: stock.stockCode)),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
