import 'package:flutter/material.dart';

import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_state.dart';
import '../../app/app_scope.dart';
import '../../home/data/home_models.dart';
import '../../stock/presentation/stock_detail_screen.dart';
import 'theme_detail_screen.dart';

class ThemeScreen extends StatefulWidget {
  const ThemeScreen({super.key});

  @override
  State<ThemeScreen> createState() => _ThemeScreenState();
}

class _ThemeScreenState extends State<ThemeScreen> {
  late Future<List<ThemeItemModel>> _future;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _future = _load();
  }

  Future<List<ThemeItemModel>> _load() async {
    final scope = AppScope.of(context);
    if (scope.config.useFirebaseOnly) {
      if (scope.firebaseHomeRepository == null) {
        throw StateError('Firebase 테마 데이터를 불러오려면 Firebase 설정이 필요합니다.');
      }
      final home = await scope.firebaseHomeRepository!.fetchHome();
      return home.themes;
    }
    if (scope.firebaseHomeRepository != null) {
      final home = await scope.firebaseHomeRepository!.fetchHome();
      return home.themes;
    }
    return scope.themeRepository.fetchThemes();
  }

  Future<void> _reload() async {
    setState(() {
      _future = _load();
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
          return ErrorState(
            message: '테마 목록을 불러오지 못했습니다.\n${snapshot.error}',
            onRetry: _reload,
          );
        }
        final themes = snapshot.data ?? const <ThemeItemModel>[];
        if (themes.isEmpty) {
          return EmptyState(
            title: '테마가 아직 없습니다',
            description: '운영자가 오늘의 테마를 등록하면 여기에 표시됩니다.',
            actionLabel: '다시 조회',
            onAction: _reload,
          );
        }
        return RefreshIndicator(
          onRefresh: _reload,
          child: ListView.separated(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            itemCount: themes.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final theme = themes[index];
              return Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ThemeDetailScreen(
                        themeId: theme.themeId,
                        title: theme.name,
                        fallbackTheme: theme,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                theme.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            if (theme.score != null)
                              Chip(
                                label:
                                    Text('점수 ${theme.score!.toStringAsFixed(1)}'),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(theme.summary ?? '테마 설명이 아직 없습니다.'),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Chip(label: Text('연결 종목 ${theme.stockCount}개')),
                            if (theme.leaderStock != null)
                              InkWell(
                                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => StockDetailScreen(stockCode: theme.leaderStock!.stockCode))),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text('대장 ${theme.leaderStock!.stockName}', style: Theme.of(context).textTheme.labelSmall),
                                ),
                              ),
                          ],
                        ),
                        if (theme.followerStocks.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ...theme.followerStocks.take(3).map((stock) => ActionChip(label: Text(stock.stockName), onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => StockDetailScreen(stockCode: stock.stockCode))))),
                              if (theme.followerStocks.length > 3) Chip(label: Text('+${theme.followerStocks.length - 3}')),
                            ],
                          ),
                        ],
                      ],
                    ),
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