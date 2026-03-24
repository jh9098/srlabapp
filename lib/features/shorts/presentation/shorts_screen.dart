import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_state.dart';
import '../../app/app_scope.dart';
import '../../home/data/home_models.dart';

class ShortsScreen extends StatefulWidget {
  const ShortsScreen({super.key});

  @override
  State<ShortsScreen> createState() => _ShortsScreenState();
}

class _ShortsScreenState extends State<ShortsScreen> {
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
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<RecentContentModel>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingState();
        }
        if (snapshot.hasError) {
          return ErrorState(
            message: '쇼츠/콘텐츠를 불러오지 못했습니다.\n${snapshot.error}',
            onRetry: _reload,
          );
        }
        final items = snapshot.data ?? const <RecentContentModel>[];
        if (items.isEmpty) {
          return EmptyState(
            title: '쇼츠 연결 준비 중',
            description: '관리자에서 쇼츠 또는 요약 콘텐츠를 등록하면 여기에 표시됩니다.',
            icon: Icons.play_circle_outline_rounded,
            actionLabel: '다시 조회',
            onAction: _reload,
          );
        }
        return RefreshIndicator(
          onRefresh: _reload,
          child: ListView.separated(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: !item.hasExternalLink ? null : () => launchUrl(Uri.parse(item.externalUrl!)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.play_circle_fill_rounded),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children:[Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(999)), child: Text('콘텐츠', style: Theme.of(context).textTheme.labelSmall)), const SizedBox(width: 6)]),
                              const SizedBox(height: 6),
                              Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              Text(item.summary ?? '요약이 없습니다.', maxLines: 2, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        if (item.hasExternalLink) const Icon(Icons.open_in_new_rounded, size: 18),
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