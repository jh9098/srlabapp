import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_breakpoints.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_state.dart';
import '../../app/app_scope.dart';
import '../../stock/presentation/stock_detail_screen.dart';
import '../../theme/data/theme_repository.dart';
import '../../theme/presentation/theme_detail_screen.dart';
import '../../theme/presentation/theme_screen.dart';
import '../data/firebase_home_repository.dart';
import '../data/home_models.dart';
import '../data/home_repository.dart';
import 'widgets/featured_stock_tile.dart';
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
  bool _expandFeatured = false;

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
      final data = _firebaseHomeRepository != null ? await _firebaseHomeRepository!.fetchHome() : await _homeRepository.fetchHome();
      return _HomeScreenPayload(data: data, isFallback: false, fallbackReason: null);
    } on ApiException catch (e) {
      final shouldFallback = e.errorCode == 'SUPPORT_STATE_NOT_READY' || e.errorCode == 'PRICE_NOT_READY';
      if (!shouldFallback) rethrow;
      final themes = await _themeRepository.fetchThemes();
      final contents = await _themeRepository.fetchContents(limit: 4);
      return _HomeScreenPayload(
        isFallback: true,
        fallbackReason: e.message,
        data: HomeResponseModel(
          marketHeadline: '운영 종목 상태 계산 중입니다. 테마와 콘텐츠는 먼저 확인할 수 있습니다.',
          featuredStocks: const [],
          watchlistSignalSummary: const HomeWatchlistSignalSummaryModel(supportNearCount: 0, resistanceNearCount: 0, warningCount: 0),
          popularStocks: const HomeMarketSnapshotModel(title: '인기 종목', items: []),
          foreignNetBuy: const HomeMarketSnapshotModel(title: '외국인 순매수', items: []),
          institutionNetBuy: const HomeMarketSnapshotModel(title: '기관 순매수', items: []),
          themes: themes,
          recentContents: contents,
        ),
      );
    }
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_HomeScreenPayload>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const LoadingState();
        if (snapshot.hasError) return ErrorState(message: '홈 데이터를 불러오지 못했습니다.\n${snapshot.error}', onRetry: _refresh);
        final payload = snapshot.data;
        if (payload == null) return ErrorState(message: '홈 데이터를 받을 수 없습니다.', onRetry: _refresh);
        final data = payload.data;
        final featured = _expandFeatured ? data.featuredStocks : data.featuredStocks.take(5).toList();

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, AppSpacing.bottomListPadding),
            children: [
              _TodayPointCard(todayLabel: _todayLabel(), headline: data.marketHeadline),
              const SizedBox(height: AppSpacing.sectionLarge),
              _SectionHeader(title: '오늘의 관찰 종목', trailingLabel: '${data.featuredStocks.length}종목'),
              const SizedBox(height: 10),
              if (payload.isFallback)
                EmptyState(title: '신호 데이터를 분석하고 있습니다', description: '잠시 후 자동으로 업데이트됩니다.', actionLabel: '다시 조회', onAction: _refresh)
              else if (data.featuredStocks.isEmpty)
                EmptyState(title: '오늘의 관찰 종목을 준비 중입니다', description: '잠시 후 다시 확인해 주세요.', actionLabel: '다시 조회', onAction: _refresh)
              else ...[
                ...featured.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: FeaturedStockTile(
                        item: item,
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => StockDetailScreen(stockCode: item.stockCode, watchlistDocId: item.watchlistDocId.isEmpty ? null : item.watchlistDocId))),
                      ),
                    )),
                if (data.featuredStocks.length > 5)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(onPressed: () => setState(() => _expandFeatured = !_expandFeatured), child: Text(_expandFeatured ? '접기' : '더보기')),
                  ),
              ],
              const SizedBox(height: AppSpacing.section),
              const _SectionHeader(title: '관심종목 신호 요약', subtitle: '내가 본 종목 중 오늘 체크할 개수입니다.'),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final cards = [
                    _SignalCard(label: '지지 확인', count: data.watchlistSignalSummary.supportNearCount, type: SignalCardType.support),
                    _SignalCard(label: '저항 근접', count: data.watchlistSignalSummary.resistanceNearCount, type: SignalCardType.resistance),
                    _SignalCard(label: '주의', count: data.watchlistSignalSummary.warningCount, type: SignalCardType.warning),
                  ];
                  if (AppBreakpoints.isVeryNarrow(constraints.maxWidth)) {
                    return Column(children: [for (final c in cards) Padding(padding: const EdgeInsets.only(bottom: 8), child: c)]);
                  }
                  return Row(children: [for (var i = 0; i < cards.length; i++) ...[Expanded(child: cards[i]), if (i < cards.length - 1) const SizedBox(width: 10)]]);
                },
              ),
              const SizedBox(height: AppSpacing.sectionLarge),
              MarketSnapshotSection(snapshots: [data.popularStocks, data.foreignNetBuy, data.institutionNetBuy]),
              const SizedBox(height: AppSpacing.sectionLarge),
              _SectionHeader(
                title: '오늘의 테마',
                subtitle: '강한 흐름을 짧게 확인합니다.',
                action: TextButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ThemeScreen())), child: const Text('전체 보기')),
              ),
              const SizedBox(height: 10),
              if (data.themes.isEmpty)
                EmptyState(title: '오늘의 테마를 준비 중입니다', description: '잠시 후 확인해 주세요.', actionLabel: '다시 조회', onAction: _refresh)
              else
                ...data.themes.map((theme) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Card(
                        child: ListTile(
                          title: Text(theme.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(theme.summary ?? '테마 요약이 아직 없습니다.', maxLines: 2, overflow: TextOverflow.ellipsis),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, borderRadius: BorderRadius.circular(999)),
                            child: Text(theme.leaderStock?.stockName ?? '대표 없음', style: Theme.of(context).textTheme.labelSmall),
                          ),
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ThemeDetailScreen(themeId: theme.themeId, title: theme.name))),
                        ),
                      ),
                    )),
              const SizedBox(height: AppSpacing.sectionLarge),
              const _SectionHeader(title: '최근 해설/콘텐츠', subtitle: '길게 읽기 전에 핵심만 확인합니다.'),
              const SizedBox(height: 10),
              if (data.recentContents.isEmpty)
                EmptyState(title: '최근 해설이 없습니다', description: '새로운 콘텐츠가 업로드되면 여기에 표시됩니다.', actionLabel: '다시 조회', onAction: _refresh)
              else
                ...data.recentContents.map((content) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Card(
                        child: ListTile(
                          title: Text(content.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(content.summary ?? '요약이 없습니다.', maxLines: 2, overflow: TextOverflow.ellipsis),
                          trailing: content.hasExternalLink ? const Icon(Icons.open_in_new_rounded) : null,
                          onTap: !content.hasExternalLink ? null : () => launchUrl(Uri.parse(content.externalUrl!)),
                        ),
                      ),
                    )),
            ],
          ),
        );
      },
    );
  }
}

class _TodayPointCard extends StatelessWidget {
  const _TodayPointCard({required this.todayLabel, required this.headline});

  final String todayLabel;
  final String headline;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('TODAY\'S POINT', style: TextStyle(fontSize: 10, color: Color(0xFF60A5FA), fontWeight: FontWeight.w700)),
              const Spacer(),
              Text(todayLabel, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
            ],
          ),
          const SizedBox(height: 10),
          Text(headline, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, color: Color(0xFFE2E8F0), height: 1.5, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _HomeScreenPayload {
  const _HomeScreenPayload({required this.data, required this.isFallback, required this.fallbackReason});

  final HomeResponseModel data;
  final bool isFallback;
  final String? fallbackReason;
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.action, this.subtitle, this.trailingLabel});

  final String title;
  final String? subtitle;
  final Widget? action;
  final String? trailingLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700)),
              ],
            ],
          ),
        ),
        if (trailingLabel != null) Text(trailingLabel!, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.grey.shade600, fontWeight: FontWeight.w700)),
        if (action case final action?) action,
      ],
    );
  }
}

enum SignalCardType { support, resistance, warning }

class _SignalCard extends StatelessWidget {
  const _SignalCard({required this.label, required this.count, required this.type});

  final String label;
  final int count;
  final SignalCardType type;

  @override
  Widget build(BuildContext context) {
    final palette = _palette();
    return Container(
      decoration: BoxDecoration(color: palette.background, borderRadius: BorderRadius.circular(16), border: Border.all(color: palette.border, width: 0.5)),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      child: Column(
        children: [
          Text('$count', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700, color: palette.countColor)),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: palette.labelColor, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  _SignalPalette _palette() {
    switch (type) {
      case SignalCardType.support:
        return const _SignalPalette(background: Color(0xFFDCFCE7), border: Color(0xFF86EFAC), countColor: Color(0xFF166534), labelColor: Color(0xFF15803D));
      case SignalCardType.resistance:
        return const _SignalPalette(background: Color(0xFFFFEDD5), border: Color(0xFFFDBA74), countColor: Color(0xFF9A3412), labelColor: Color(0xFFC2410C));
      case SignalCardType.warning:
        return const _SignalPalette(background: Color(0xFFFEE2E2), border: Color(0xFFFCA5A5), countColor: Color(0xFF991B1B), labelColor: Color(0xFFB91C1C));
    }
  }
}

class _SignalPalette {
  const _SignalPalette({required this.background, required this.border, required this.countColor, required this.labelColor});

  final Color background;
  final Color border;
  final Color countColor;
  final Color labelColor;
}
