import 'package:flutter/material.dart';

import '../../../core/theme/app_breakpoints.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_state.dart';
import '../../../core/widgets/status_badge.dart';
import '../../app/app_scope.dart';
import '../data/stock_models.dart';
import 'widgets/latest_signal_card.dart';
import 'widgets/price_level_summary_card.dart';
import 'widgets/stock_price_chart.dart';

class StockDetailScreen extends StatefulWidget {
  const StockDetailScreen({
    super.key,
    required this.stockCode,
    this.watchlistDocId,
  });

  final String stockCode;
  final String? watchlistDocId;

  @override
  State<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<StockDetailScreen> {
  late Future<_StockDetailViewData> _future;
  bool _initialized = false;

  // [FIX] AppBar 타이틀용 종목명 상태 변수 추가
  String? _stockName;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _future = _load();
  }

  Future<_StockDetailViewData> _load() async {
    final scope = AppScope.of(context);
    final detail = scope.firebaseStockRepository != null
        ? await scope.firebaseStockRepository!.fetchStockDetail(
            widget.stockCode,
            watchlistDocId: widget.watchlistDocId,
          )
        : await scope.stockRepository.fetchStockDetail(widget.stockCode);

    // [FIX] 로드 완료 후 종목명 AppBar에 반영
    if (mounted && detail.stock.stockName.isNotEmpty) {
      setState(() => _stockName = detail.stock.stockName);
    }

    if (detail.recentSignalEvents.isNotEmpty || scope.config.useFirebaseOnly) {
      return _StockDetailViewData(
          detail: detail, recentSignals: detail.recentSignalEvents);
    }

    try {
      final recentSignals =
          await scope.stockRepository.fetchStockSignals(widget.stockCode);
      return _StockDetailViewData(detail: detail, recentSignals: recentSignals);
    } catch (_) {
      return _StockDetailViewData(detail: detail, recentSignals: const []);
    }
  }

  Future<void> _reload() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final watchlistController = scope.watchlistController;
    final enablePersonalWatchlist = scope.config.enableBackendFeatures;

    return Scaffold(
      // [FIX] AppBar 타이틀: "종목 상세" → 종목명으로 교체
      appBar: AppBar(
        title: Text(
          _stockName?.isNotEmpty == true ? _stockName! : '종목 상세',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        // 데이터 로딩 중 얇은 프로그레스 표시
        bottom: _stockName == null
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2),
                child: LinearProgressIndicator(minHeight: 2),
              )
            : null,
      ),
      body: AnimatedBuilder(
        animation: watchlistController,
        builder: (context, _) {
          return FutureBuilder<_StockDetailViewData>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingState();
              }
              if (snapshot.hasError) {
                return ErrorState(
                    message: snapshot.error.toString(), onRetry: _reload);
              }
              final viewData = snapshot.data;
              if (viewData == null) {
                return ErrorState(
                    message: '종목 상세 데이터를 불러오지 못했습니다.', onRetry: _reload);
              }

              final detail = viewData.detail;
              final watchItem =
                  watchlistController.findByStockCode(widget.stockCode);
              final isInWatchlist =
                  watchItem != null || detail.watchlist.isInWatchlist;
              final int? watchlistId =
                  watchItem?.watchlistId ?? detail.watchlist.watchlistId;

              final alertEnabled =
                  watchItem?.alertEnabled ?? detail.watchlist.alertEnabled;
              final latestDate = detail.price.updatedAt ??
                  (detail.validChartBars.isNotEmpty
                      ? detail.validChartBars.first.tradeDate
                      : null);

              return RefreshIndicator(
                onRefresh: _reload,
                child: ListView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: AppSpacing.pageFull,
                  children: [
                    // ─────────────────────────────
                    // [FIX] 헤더 카드: 딥 네이비 다크 스타일
                    // ─────────────────────────────
                    _DarkHeaderCard(
                      detail: detail,
                      latestDate: latestDate,
                      stockCode: widget.stockCode,
                      isInWatchlist: isInWatchlist,
                      watchlistId: watchlistId,
                      alertEnabled: alertEnabled,
                      enablePersonalWatchlist: enablePersonalWatchlist,
                      watchlistController: watchlistController,
                    ),
                    const SizedBox(height: 16),
                    PriceLevelSummaryCard(
                      supportLevels: detail.supportLevels,
                      resistanceLevels: detail.resistanceLevels,
                    ),
                    if (detail.hasSignalCardData ||
                        viewData.recentSignals.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      LatestSignalCard(
                        latestSignalSummary: detail.latestSignalSummary,
                        recentSignalEvents: viewData.recentSignals,
                      ),
                    ],
                    const SizedBox(height: 16),
                    // ─────────────────────────────
                    // [FIX] 시나리오: 색상 뱃지 구분
                    // ─────────────────────────────
                    _SectionCard(
                      title: '현재 시나리오',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ScenarioLine(
                            label: '기본',
                            value: detail.scenario.base,
                            fallback: '기본 시나리오 데이터 없음',
                            type: _ScenarioType.base,
                          ),
                          const SizedBox(height: 10),
                          _ScenarioLine(
                            label: '상방',
                            value: detail.scenario.bull,
                            fallback: '상방 시나리오 데이터 없음',
                            type: _ScenarioType.bull,
                          ),
                          const SizedBox(height: 10),
                          _ScenarioLine(
                            label: '하방',
                            value: detail.scenario.bear,
                            fallback: '하방 시나리오 데이터 없음',
                            type: _ScenarioType.bear,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: '해설 3줄',
                      child: detail.reasonLines.isEmpty
                          ? const Text('표시할 해설이 없습니다.')
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: detail.reasonLines
                                  .map(
                                    (line) => Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 8),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text('• ',
                                              style: TextStyle(
                                                  color: Color(0xFF1D4ED8),
                                                  fontWeight:
                                                      FontWeight.w700)),
                                          Expanded(child: Text(line)),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: '최근 일봉 요약',
                      child: detail.validChartBars.isEmpty
                          ? const Text('최근 일봉 데이터가 없습니다.')
                          : Column(
                              children:
                                  detail.validChartBars.take(5).map((bar) {
                                final tradeDate = bar.tradeDate == null
                                    ? '-'
                                    : Formatters.date(bar.tradeDate!);
                                final isUp = bar.closePrice >= bar.openPrice;
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(tradeDate),
                                  subtitle: Text(
                                      '고가 ${Formatters.price(bar.highPrice)} / 저가 ${Formatters.price(bar.lowPrice)}'),
                                  trailing: Text(
                                    Formatters.price(bar.closePrice),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: isUp
                                          ? const Color(0xFFDC2626)
                                          : const Color(0xFF2563EB),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: '관련 테마',
                      child: detail.relatedThemes.isEmpty
                          ? const Text('연결된 테마가 없습니다.')
                          : Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: detail.relatedThemes.take(4).map((theme) => Chip(label: Text(theme.name))).toList(),
                            ),
                    ),
                    if (detail.relatedContents.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _SectionCard(
                        title: '관련 콘텐츠',
                        child: Column(
                          children: detail.relatedContents.take(3)
                              .map(
                                (content) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(content.title),
                                  subtitle: Text(
                                      content.summary?.isNotEmpty == true
                                          ? content.summary!
                                          : '요약 없음'),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ══════════════════════════════════════════
// Data class
// ══════════════════════════════════════════

class _StockDetailViewData {
  const _StockDetailViewData(
      {required this.detail, required this.recentSignals});

  final StockDetailModel detail;
  final List<StockSignalEventModel> recentSignals;
}

// ══════════════════════════════════════════
// [FIX] 다크 헤더 카드 — 기존 _SummaryMetrics 대체
// ══════════════════════════════════════════

class _DarkHeaderCard extends StatelessWidget {
  const _DarkHeaderCard({
    required this.detail,
    required this.latestDate,
    required this.stockCode,
    required this.isInWatchlist,
    required this.watchlistId,
    required this.alertEnabled,
    required this.enablePersonalWatchlist,
    required this.watchlistController,
  });

  final StockDetailModel detail;
  final DateTime? latestDate;
  final String stockCode;
  final bool isInWatchlist;
  final int? watchlistId;
  final bool alertEnabled;
  final bool enablePersonalWatchlist;
  final dynamic watchlistController;

  @override
  Widget build(BuildContext context) {
    final isUp = detail.price.changePct >= 0;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${detail.stock.stockCode} · ${detail.stock.marketType}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF60A5FA), fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        detail.stock.stockName.isEmpty ? stockCode : detail.stock.stockName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFFF8FAFC)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                StatusBadge(status: detail.status),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 10,
              children: [
                Text(
                  Formatters.price(detail.price.currentPrice),
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                Text(
                  Formatters.percent(detail.price.changePct),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isUp ? const Color(0xFFF87171) : const Color(0xFF60A5FA),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildMetricGrid(latestDate),
            const SizedBox(height: 16),
            StockPriceChart(
              bars: detail.validChartBars,
              supportLevels: detail.supportLevels,
              resistanceLevels: detail.resistanceLevels,
              currentPrice: detail.price.currentPrice,
            ),
            const SizedBox(height: 12),
            const Divider(color: Color(0xFF1E293B), height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  isInWatchlist ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                  color: isInWatchlist ? const Color(0xFFF59E0B) : const Color(0xFF64748B),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isInWatchlist ? '관심종목 등록됨' : '관심종목 미등록',
                    style: TextStyle(
                      color: isInWatchlist ? const Color(0xFFF59E0B) : const Color(0xFF94A3B8),
                      fontSize: 13,
                    ),
                  ),
                ),
                if (!enablePersonalWatchlist)
                  const Chip(label: Text('조회 전용'))
                else if (!isInWatchlist || watchlistId == null)
                  FilledButton.icon(
                    onPressed: () async => watchlistController.add(stockCode),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('관심종목 추가'),
                  )
                else
                  FilledButton.tonalIcon(
                    onPressed: () async => watchlistController.remove(watchlistId),
                    icon: const Icon(Icons.delete_outline_rounded, size: 16),
                    label: const Text('삭제'),
                  ),
              ],
            ),
            if (enablePersonalWatchlist && isInWatchlist && watchlistId != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Text('알림 받기', style: TextStyle(color: Color(0xFFCBD5E1))),
                  const Spacer(),
                  Switch(
                    value: alertEnabled,
                    activeThumbColor: const Color(0xFF60A5FA),
                    onChanged: (value) => watchlistController.toggleAlert(watchlistId: watchlistId, alertEnabled: value),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricGrid(DateTime? latestDate) {
    final metrics = [
      _MetricData(label: '고가', value: Formatters.price(detail.price.dayHigh)),
      _MetricData(label: '저가', value: Formatters.price(detail.price.dayLow)),
      _MetricData(label: '거래량', value: _formatVolume(detail.price.volume)),
      _MetricData(label: '기준일', value: latestDate == null ? '-' : Formatters.date(latestDate)),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final twoByTwo = AppBreakpoints.isNarrow(constraints.maxWidth);
        if (twoByTwo) {
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: metrics
                .map((m) => SizedBox(width: (constraints.maxWidth - 8) / 2, child: _MetricTile(metric: m)))
                .toList(),
          );
        }
        return Row(children: metrics.map((m) => Expanded(child: _MetricTile(metric: m))).toList());
      },
    );
  }

  String _formatVolume(int volume) {
    if (volume >= 1000000) return '${(volume / 1000000).toStringAsFixed(1)}M';
    if (volume >= 1000) return '${(volume / 1000).toStringAsFixed(0)}K';
    return volume.toString();
  }
}


class _MetricData {
  const _MetricData({required this.label, required this.value});

  final String label;
  final String value;
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.metric});

  final _MetricData metric;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(metric.label, style: const TextStyle(fontSize: 9, color: Color(0xFF60A5FA))),
          const SizedBox(height: 3),
          Text(metric.value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFF1F5F9))),
        ],
      ),
    );
  }
}

enum _ScenarioType { base, bull, bear }

class _ScenarioLine extends StatelessWidget {
  const _ScenarioLine({
    required this.label,
    required this.value,
    required this.fallback,
    required this.type,
  });

  final String label;
  final String value;
  final String fallback;
  final _ScenarioType type;

  @override
  Widget build(BuildContext context) {
    final palette = _palette();
    final text = value.isEmpty ? fallback : value;
    final isEmpty = value.isEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: palette.badgeBg,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: palette.badgeText,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isEmpty
                        ? Colors.grey.shade400
                        : palette.contentColor,
                    fontStyle:
                        isEmpty ? FontStyle.italic : FontStyle.normal,
                  ),
            ),
          ),
        ),
      ],
    );
  }

  _ScenarioPalette _palette() {
    switch (type) {
      case _ScenarioType.base:
        return const _ScenarioPalette(
          badgeBg: Color(0xFFEFF6FF),
          badgeText: Color(0xFF1D4ED8),
          contentColor: Color(0xFF1E3A5F),
        );
      case _ScenarioType.bull:
        return const _ScenarioPalette(
          badgeBg: Color(0xFFDCFCE7),
          badgeText: Color(0xFF166534),
          contentColor: Color(0xFF15803D),
        );
      case _ScenarioType.bear:
        return const _ScenarioPalette(
          badgeBg: Color(0xFFFEE2E2),
          badgeText: Color(0xFF991B1B),
          contentColor: Color(0xFFB91C1C),
        );
    }
  }
}

class _ScenarioPalette {
  const _ScenarioPalette({
    required this.badgeBg,
    required this.badgeText,
    required this.contentColor,
  });

  final Color badgeBg;
  final Color badgeText;
  final Color contentColor;
}

// ══════════════════════════════════════════
// 공통 섹션 카드 (변경 없음)
// ══════════════════════════════════════════

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
