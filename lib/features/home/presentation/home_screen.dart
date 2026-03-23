import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_state.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/stock_card.dart';
import '../../app/app_scope.dart';
import '../data/firebase_home_repository.dart';
import '../data/home_repository.dart';
import '../../theme/data/theme_repository.dart';
import '../../stock/presentation/stock_detail_screen.dart';
import '../../theme/presentation/theme_detail_screen.dart';
import '../../theme/presentation/theme_screen.dart';
import '../data/home_models.dart';
import 'widgets/market_snapshot_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<_HomeScreenPayload> _future;
  late HomeRepository _homeRepository;
  FirebaseHomeRepository? _firebaseHomeRepository;
  late ThemeRepository _themeRepository;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = AppScope.of(context);
    _homeRepository = scope.homeRepository;
    _firebaseHomeRepository = scope.firebaseHomeRepository;
    _themeRepository = scope.themeRepository;
    if (_initialized) return;
    _initialized = true;
    _future = _load();
  }

  Future<_HomeScreenPayload> _load() async {
    final scope = AppScope.of(context);
    try {
      if (scope.config.useFirebaseOnly) {
        if (_firebaseHomeRepository == null) {
          throw StateError('Firebase 홈 저장소를 사용할 수 없습니다. Firebase 설정(dart-define)을 먼저 확인하세요.');
        }
        final data = await _firebaseHomeRepository!.fetchHome();
        return _HomeScreenPayload(
          data: data,
          isFallback: false,
          fallbackReason: null,
        );
      }

      final data = _firebaseHomeRepository != null
          ? await _firebaseHomeRepository!.fetchHome()
          : await _homeRepository.fetchHome();
      return _HomeScreenPayload(
        data: data,
        isFallback: false,
        fallbackReason: null,
      );
    } on ApiException catch (e) {
      final shouldFallback = e.errorCode == 'SUPPORT_STATE_NOT_READY' ||
          e.errorCode == 'PRICE_NOT_READY';

      if (!shouldFallback) rethrow;

      final themes = scope.config.useFirebaseOnly || _firebaseHomeRepository != null
          ? (await (_firebaseHomeRepository?.fetchHome() ?? Future.error(StateError('Firebase 홈 저장소를 사용할 수 없습니다.')))).themes
          : await _themeRepository.fetchThemes();
      final contents = scope.config.useFirebaseOnly ? const <RecentContentModel>[] : await _themeRepository.fetchContents(limit: 4);

      return _HomeScreenPayload(
        isFallback: true,
        fallbackReason: e.message,
        data: HomeResponseModel(
          marketHeadline: '운영 종목 상태 계산 중입니다. 테마와 콘텐츠는 먼저 확인할 수 있습니다.',
          featuredStocks: const [],
          watchlistSignalSummary: const HomeWatchlistSignalSummaryModel(
            supportNearCount: 0,
            resistanceNearCount: 0,
            warningCount: 0,
          ),
          popularStocks: const HomeMarketSnapshotModel(
            title: '인기 종목',
            items: [],
          ),
          foreignNetBuy: const HomeMarketSnapshotModel(
            title: '외국인 순매수',
            items: [],
          ),
          institutionNetBuy: const HomeMarketSnapshotModel(
            title: '기관 순매수',
            items: [],
          ),
          themes: themes,
          recentContents: contents,
        ),
      );
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_HomeScreenPayload>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingState();
        }

        if (snapshot.hasError) {
          return ErrorState(
            message: '홈 데이터를 불러오지 못했습니다.\n${snapshot.error}',
            onRetry: _refresh,
          );
        }

        final payload = snapshot.data;
        if (payload == null) {
          return ErrorState(
            message: '홈 데이터를 받을 수 없습니다.',
            onRetry: _refresh,
          );
        }

        final data = payload.data;

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (payload.isFallback) ...[
                Card(
                  color: Colors.amber.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      '일부 종목의 지지선 상태가 아직 계산되지 않아 홈 종목 카드는 잠시 숨기고 있습니다.\n'
                      '테마와 콘텐츠는 정상적으로 확인할 수 있습니다.\n'
                      '사유: ${payload.fallbackReason ?? '상태 계산 대기'}',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Text(
                '오늘의 관찰 포인트',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    data.marketHeadline,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const _SectionHeader(
                title: '오늘의 관찰 종목',
                subtitle: '지금 빠르게 확인할 종목입니다.',
              ),
              const SizedBox(height: 12),
              if (payload.isFallback)
                EmptyState(
                  title: '운영 종목 상태 계산 중',
                  description:
                      '지지선 상태가 아직 준비되지 않은 종목이 있어 홈 종목 카드는 잠시 숨겨집니다.\n관심종목 탭이나 종목 검색에서 개별 종목은 계속 확인할 수 있습니다.',
                  actionLabel: '다시 조회',
                  onAction: _refresh,
                )
              else if (data.featuredStocks.isEmpty)
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
                        MaterialPageRoute(
                          builder: (_) => StockDetailScreen(
                            stockCode: item.stockCode,
                            watchlistDocId: item.watchlistDocId.isEmpty
                                ? null
                                : item.watchlistDocId,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              const _SectionHeader(
                title: '관심종목 신호 요약',
                subtitle: '내가 본 종목 중 오늘 체크할 개수입니다.',
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _SignalCard(
                      label: '지지 확인',
                      count: data.watchlistSignalSummary.supportNearCount,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SignalCard(
                      label: '저항 근접',
                      count: data.watchlistSignalSummary.resistanceNearCount,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SignalCard(
                      label: '주의',
                      count: data.watchlistSignalSummary.warningCount,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              MarketSnapshotSection(
                snapshots: [
                  data.popularStocks,
                  data.foreignNetBuy,
                  data.institutionNetBuy,
                ],
              ),
              const SizedBox(height: 24),
              _SectionHeader(
                title: '오늘의 테마',
                subtitle: '강한 흐름을 짧게 확인합니다.',
                action: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ThemeScreen()),
                  ),
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
                            builder: (_) => ThemeDetailScreen(
                              themeId: theme.themeId,
                              title: theme.name,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              const _SectionHeader(
                title: '최근 해설/콘텐츠',
                subtitle: '길게 읽기 전에 핵심만 확인합니다.',
              ),
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
                        trailing: content.hasExternalLink
                            ? const Icon(Icons.open_in_new_rounded)
                            : null,
                        onTap: !content.hasExternalLink
                            ? null
                            : () => launchUrl(Uri.parse(content.externalUrl!)),
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

class _HomeScreenPayload {
  const _HomeScreenPayload({
    required this.data,
    required this.isFallback,
    required this.fallbackReason,
  });

  final HomeResponseModel data;
  final bool isFallback;
  final String? fallbackReason;
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    this.action,
  });

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
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade700,
                    ),
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
  const _SignalCard({
    required this.label,
    required this.count,
  });

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
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
