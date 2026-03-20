import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_state.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/stock_card.dart';
import '../../app/app_scope.dart';
import '../../stock/presentation/stock_detail_screen.dart';
import '../../theme/presentation/theme_detail_screen.dart';
import '../../theme/presentation/theme_screen.dart';
import '../data/home_models.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<HomeResponseModel> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<HomeResponseModel> _load() {
    return AppScope.of(context).homeRepository.fetchHome();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<HomeResponseModel>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingState();
        }
        if (snapshot.hasError) {
          return ErrorState(message: '홈 데이터를 불러오지 못했습니다.\n${snapshot.error}', onRetry: _refresh);
        }
        final data = snapshot.data;
        if (data == null) {
          return ErrorState(message: '홈 데이터를 받을 수 없습니다.', onRetry: _refresh);
        }
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                '오늘의 관찰 포인트',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(data.marketHeadline, style: Theme.of(context).textTheme.titleMedium),
                ),
              ),
              const SizedBox(height: 24),
              _SectionHeader(title: '오늘의 관찰 종목', subtitle: '지금 빠르게 확인할 종목입니다.'),
              const SizedBox(height: 12),
              if (data.featuredStocks.isEmpty)
                EmptyState(
                  title: '추천 종목이 없습니다',
                  description: '관리자에서 홈 추천 종목을 등록하면 여기에 표시됩니다.',
                  actionLabel: '다시 조회',
                  onAction: _refresh,
                )
              else
                ...data.featuredStocks.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: StockCard(
                      name: item.stockName,
                      code: item.stockCode,
                      price: item.currentPrice,
                      changePct: item.changePct,
                      status: StatusBadge(status: item.status),
                      summary: item.summary,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => StockDetailScreen(stockCode: item.stockCode)),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              _SectionHeader(title: '관심종목 신호 요약', subtitle: '내가 본 종목 중 오늘 체크할 개수입니다.'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _SignalCard(label: '지지 확인', count: data.watchlistSignalSummary.supportNearCount)),
                  const SizedBox(width: 12),
                  Expanded(child: _SignalCard(label: '저항 근접', count: data.watchlistSignalSummary.resistanceNearCount)),
                  const SizedBox(width: 12),
                  Expanded(child: _SignalCard(label: '주의', count: data.watchlistSignalSummary.warningCount)),
                ],
              ),
              const SizedBox(height: 24),
              _SectionHeader(
                title: '오늘의 테마',
                subtitle: '강한 흐름을 짧게 확인합니다.',
                action: TextButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ThemeScreen())),
                  child: const Text('전체 보기'),
                ),
              ),
              const SizedBox(height: 12),
              if (data.themes.isEmpty)
                EmptyState(
                  title: '노출 중인 테마가 없습니다',
                  description: '관리자에서 테마를 공개하면 홈에 표시됩니다.',
                  actionLabel: '다시 조회',
                  onAction: _refresh,
                )
              else
                ...data.themes.map(
                  (theme) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      child: ListTile(
                        title: Text(theme.name),
                        subtitle: Text(theme.summary ?? '테마 요약이 아직 없습니다.'),
                        trailing: Text(theme.leaderStock?.stockName ?? '-'),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ThemeDetailScreen(themeId: theme.themeId, title: theme.name),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              _SectionHeader(title: '최근 해설/콘텐츠', subtitle: '길게 읽기 전에 핵심만 확인합니다.'),
              const SizedBox(height: 12),
              if (data.recentContents.isEmpty)
                EmptyState(
                  title: '콘텐츠가 아직 없습니다',
                  description: '관리자에서 콘텐츠를 공개하면 여기에 표시됩니다.',
                  actionLabel: '다시 조회',
                  onAction: _refresh,
                )
              else
                ...data.recentContents.map(
                  (content) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      child: ListTile(
                        title: Text(content.title),
                        subtitle: Text(content.summary ?? '요약이 없습니다.'),
                        trailing: content.hasExternalLink ? const Icon(Icons.open_in_new_rounded) : null,
                        onTap: !content.hasExternalLink ? null : () => launchUrl(Uri.parse(content.externalUrl!)),
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle, this.action});

  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}

class _SignalCard extends StatelessWidget {
  const _SignalCard({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              '$count',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
