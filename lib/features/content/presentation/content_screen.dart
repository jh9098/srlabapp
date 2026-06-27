import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../app/app_scope.dart';
import '../../education/presentation/trading_rules_screen.dart';
import '../../home/data/home_models.dart';

class ContentScreen extends StatefulWidget {
  const ContentScreen({super.key});

  @override
  State<ContentScreen> createState() => _ContentScreenState();
}

class _ContentScreenState extends State<ContentScreen> {
  late Future<List<RecentContentModel>> _future;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _future = _load();
  }

  Future<List<RecentContentModel>> _load() async {
    final scope = AppScope.of(context);
    if (scope.config.useFirebaseOnly) {
      if (scope.firebaseHomeRepository == null) {
        throw StateError('Firebase 콘텐츠 데이터를 불러오려면 Firebase 설정이 필요합니다.');
      }
      final home = await scope.firebaseHomeRepository!.fetchHome();
      return home.recentContents;
    }
    return scope.themeRepository.fetchContents(category: 'SHORTS', limit: 20);
  }

  Future<void> _reload() async {
    setState(() {
      _future = _load();
    });
    try {
      await _future;
    } catch (_) {
      // 화면의 오류 안내 카드에서 다시 시도할 수 있습니다.
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<RecentContentModel>>(
      future: _future,
      builder: (BuildContext context, AsyncSnapshot<List<RecentContentModel>> snapshot) {
        final List<RecentContentModel> items =
            snapshot.data ?? const <RecentContentModel>[];

        return RefreshIndicator(
          onRefresh: _reload,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: AppSpacing.pageFull,
            children: <Widget>[
              const _EducationEntryCard(),
              const SizedBox(height: 28),
              const _ContentSectionHeader(),
              const SizedBox(height: 12),
              if (snapshot.connectionState == ConnectionState.waiting)
                const _CompactLoadingCard()
              else if (snapshot.hasError)
                _CompactErrorCard(
                  message: '최신 콘텐츠를 불러오지 못했습니다.',
                  onRetry: _reload,
                )
              else if (items.isEmpty)
                const _CompactEmptyCard()
              else
                ...items.map(
                  (RecentContentModel item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ContentItemCard(item: item),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _EducationEntryCard extends StatelessWidget {
  const _EducationEntryCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF0F172A),
            Color(0xFF1E3A8A),
            Color(0xFF0369A1),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.16),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const TradingRulesScreen(),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Stack(
              children: <Widget>[
                Positioned(
                  right: -34,
                  bottom: -54,
                  child: Icon(
                    Icons.auto_graph_rounded,
                    size: 150,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Icon(
                                Icons.school_outlined,
                                size: 15,
                                color: Color(0xFFBAE6FD),
                              ),
                              SizedBox(width: 6),
                              Text(
                                '회원 필수교육',
                                style: TextStyle(
                                  color: Color(0xFFBAE6FD),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      '지지저항연구소\n회원 매매규칙',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        height: 1.25,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '지지선부터 분할매수, 수익실현, 멘징까지\n반드시 알아야 할 계좌관리 원칙을 확인하세요.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontSize: 14,
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        _HeroTag(label: '핵심원칙 8개'),
                        _HeroTag(label: '상세교육'),
                        _HeroTag(label: '매매 전 확인'),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroTag extends StatelessWidget {
  const _HeroTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ContentSectionHeader extends StatelessWidget {
  const _ContentSectionHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '최신 콘텐츠',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                '시장과 종목을 이해하는 데 도움이 되는 콘텐츠입니다.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ContentItemCard extends StatelessWidget {
  const _ContentItemCard({required this.item});

  final RecentContentModel item;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: !item.hasExternalLink
            ? null
            : () => launchUrl(Uri.parse(item.externalUrl!)),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(
            children: <Widget>[
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF172554)
                      : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.play_circle_fill_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.brandAmber.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        '콘텐츠',
                        style: TextStyle(
                          color: AppTheme.brandAmber,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.summary ?? '요약이 없습니다.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                    ),
                  ],
                ),
              ),
              if (item.hasExternalLink) ...<Widget>[
                const SizedBox(width: 8),
                Icon(
                  Icons.open_in_new_rounded,
                  size: 17,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactLoadingCard extends StatelessWidget {
  const _CompactLoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('최신 콘텐츠를 불러오는 중입니다.'),
          ],
        ),
      ),
    );
  }
}

class _CompactErrorCard extends StatelessWidget {
  const _CompactErrorCard({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: <Widget>[
            Icon(
              Icons.cloud_off_outlined,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
            TextButton(
              onPressed: onRetry,
              child: const Text('다시 조회'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactEmptyCard extends StatelessWidget {
  const _CompactEmptyCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: <Widget>[
            Icon(
              Icons.video_library_outlined,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('최신 콘텐츠를 준비 중입니다.'),
            ),
          ],
        ),
      ),
    );
  }
}
