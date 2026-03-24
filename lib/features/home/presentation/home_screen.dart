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
  String _todayLabel() {
    final now = DateTime.now();
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final wd = weekdays[now.weekday - 1];
    return '${now.month}/${now.day} ($wd)';
  }

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
    try {
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

      final themes = await _themeRepository.fetchThemes();
      final contents = await _themeRepository.fetchContents(limit: 4);

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
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFBFDBFE), width: 0.5),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          color: Color(0xFF1D4ED8), size: 20),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          '신호 데이터를 분석하고 있습니다. 테마와 콘텐츠는 지금 바로 확인할 수 있습니다.',
                          style: TextStyle(
                            color: Color(0xFF1E3A5F),
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
              ],
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 라벨
                    Row(
                      children: [
                        Container(
                          width: 3,
                          height: 14,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'TODAY\'S POINT',
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFF60A5FA),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.08,
                          ),
                        ),
                        const Spacer(),
                        // 날짜 표시 (선택)
                        Text(
                          _todayLabel(), // 아래 헬퍼 함수 참조
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // 헤드라인 본문
                    Text(
                      data.marketHeadline,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFFE2E8F0),
                        height: 1.6,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
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
                  title: '신호 데이터를 분석하고 있습니다',
                  description: '지지선 신호를 실시간으로 계산하고 있습니다.\n잠시 후 자동으로 업데이트됩니다.',
                  actionLabel: '다시 조회',
                  onAction: _refresh,
                )
              else if (data.featuredStocks.isEmpty)
                EmptyState(
                  title: '오늘의 관찰 종목을 준비 중입니다',
                  description: '잠시 후 다시 확인해 주세요.\n관심종목 탭에서 개별 종목은 바로 확인할 수 있습니다.',
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
                      type: SignalCardType.support,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SignalCard(
                      label: '저항 근접',
                      count: data.watchlistSignalSummary.resistanceNearCount,
                      type: SignalCardType.resistance,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SignalCard(
                      label: '주의',
                      count: data.watchlistSignalSummary.warningCount,
                      type: SignalCardType.warning,
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
                  title: '오늘의 테마를 준비 중입니다',
                  description: '매일 시장 흐름을 분석해 주요 테마를 선정합니다.\n잠시 후 확인해 주세요.',
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
                  title: '최근 해설이 없습니다',
                  description: '새로운 시장 해설과 매매 전략이 업로드되면 여기에 표시됩니다.',
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

enum SignalCardType { support, resistance, warning }
 
class _SignalCard extends StatelessWidget {
  const _SignalCard({
    required this.label,
    required this.count,
    required this.type,
  });
 
  final String label;
  final int count;
  final SignalCardType type;
 
  @override
  Widget build(BuildContext context) {
    final palette = _palette();
    return Container(
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border, width: 0.5),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      child: Column(
        children: [
          Text(
            '$count',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: palette.countColor,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: palette.labelColor,
                  fontWeight: FontWeight.w500,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
 
  _SignalPalette _palette() {
    switch (type) {
      case SignalCardType.support:
        return const _SignalPalette(
          background: Color(0xFFDCFCE7),
          border: Color(0xFF86EFAC),
          countColor: Color(0xFF166534),
          labelColor: Color(0xFF15803D),
        );
      case SignalCardType.resistance:
        return const _SignalPalette(
          background: Color(0xFFFFEDD5),
          border: Color(0xFFFDBA74),
          countColor: Color(0xFF9A3412),
          labelColor: Color(0xFFC2410C),
        );
      case SignalCardType.warning:
        return const _SignalPalette(
          background: Color(0xFFFEE2E2),
          border: Color(0xFFFCA5A5),
          countColor: Color(0xFF991B1B),
          labelColor: Color(0xFFB91C1C),
        );
    }
  }
}
 
class _SignalPalette {
  const _SignalPalette({
    required this.background,
    required this.border,
    required this.countColor,
    required this.labelColor,
  });
 
  final Color background;
  final Color border;
  final Color countColor;
  final Color labelColor;
}
