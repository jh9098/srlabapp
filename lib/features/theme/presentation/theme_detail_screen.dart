import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_state.dart';
import '../../app/app_scope.dart';
import '../../home/data/home_models.dart';
import '../../stock/presentation/stock_detail_screen.dart';

class ThemeDetailScreen extends StatefulWidget {
  const ThemeDetailScreen({
    super.key,
    required this.themeId,
    required this.title,
  });

  final int themeId;
  final String title;

  @override
  State<ThemeDetailScreen> createState() => _ThemeDetailScreenState();
}

class _ThemeDetailScreenState extends State<ThemeDetailScreen> {
  late Future<ThemeDetailModel> _future;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _future = _load();
  }

  Future<ThemeDetailModel> _load() {
    return AppScope.of(context)
        .themeRepository
        .fetchThemeDetail(widget.themeId);
  }

  Future<void> _reload() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: FutureBuilder<ThemeDetailModel>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingState();
          }
          if (snapshot.hasError) {
            return ErrorState(
              message: '테마 상세를 불러오지 못했습니다.\n${snapshot.error}',
              onRetry: _reload,
            );
          }
          final detail = snapshot.data;
          if (detail == null) {
            return ErrorState(
              message: '테마 상세 데이터가 없습니다.',
              onRetry: _reload,
            );
          }
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
                        Text(
                          detail.theme.name,
                          style:
                              Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Text(detail.theme.summary ?? '테마 설명이 아직 없습니다.'),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (detail.theme.score != null)
                              Chip(
                                label: Text(
                                  '점수 ${detail.theme.score!.toStringAsFixed(1)}',
                                ),
                              ),
                            Chip(label: Text('연결 종목 ${detail.theme.stockCount}개')),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '연결 종목',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),
                if (detail.stocks.isEmpty)
                  const EmptyState(
                    title: '연결 종목이 없습니다',
                    description: '관리자에서 테마에 종목을 연결하면 여기에 표시됩니다.',
                  )
                else
                  ...detail.stocks.map(
                    (stock) => Card(
                      child: ListTile(
                        title: Text(stock.stockName),
                        subtitle: Text(stock.stockCode),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                StockDetailScreen(stockCode: stock.stockCode),
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  '관련 콘텐츠',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),
                if (detail.recentContents.isEmpty)
                  const EmptyState(
                    title: '관련 콘텐츠가 없습니다',
                    description: '운영자가 테마 관련 콘텐츠를 등록하면 여기에 표시됩니다.',
                  )
                else
                  ...detail.recentContents.map(
                    (content) => Card(
                      child: ListTile(
                        title: Text(content.title),
                        subtitle: Text(content.summary ?? '요약이 없습니다.'),
                        trailing: content.hasExternalLink
                            ? const Icon(Icons.open_in_new_rounded)
                            : null,
                        onTap: !content.hasExternalLink
                            ? null
                            : () => launchUrl(Uri.parse(content.externalUrl!)),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}