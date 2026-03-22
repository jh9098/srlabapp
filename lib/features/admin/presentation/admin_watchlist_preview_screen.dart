import 'package:flutter/material.dart';

import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_state.dart';
import '../../app/app_scope.dart';
import '../data/admin_watchlist_preview_repository.dart';

class AdminWatchlistPreviewScreen extends StatefulWidget {
  const AdminWatchlistPreviewScreen({super.key});

  @override
  State<AdminWatchlistPreviewScreen> createState() => _AdminWatchlistPreviewScreenState();
}

class _AdminWatchlistPreviewScreenState extends State<AdminWatchlistPreviewScreen> {
  late Future<List<AdminWatchlistPreviewItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<AdminWatchlistPreviewItem>> _load() {
    return AdminWatchlistPreviewRepository().fetchItems();
  }

  Future<void> _reload() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final firebaseEnabled = AppScope.of(context).config.isFirebaseConfigured;
    return Scaffold(
      appBar: AppBar(title: const Text('운영 관심종목 보기')),
      body: !firebaseEnabled
          ? const EmptyState(
              title: 'Firebase 설정 필요',
              description: '이 화면은 adminWatchlist Firestore direct read를 전제로 합니다.',
            )
          : FutureBuilder<List<AdminWatchlistPreviewItem>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingState();
                }
                if (snapshot.hasError) {
                  return ErrorState(
                    message: '운영 관심종목을 불러오지 못했습니다.\n${snapshot.error}',
                    onRetry: _reload,
                  );
                }
                final items = snapshot.data ?? const <AdminWatchlistPreviewItem>[];
                if (items.isEmpty) {
                  return EmptyState(
                    title: '운영 관심종목이 없습니다',
                    description: 'adminWatchlist 문서가 들어오면 여기에 표시됩니다.',
                    actionLabel: '다시 조회',
                    onAction: _reload,
                  );
                }
                return RefreshIndicator(
                  onRefresh: _reload,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  Text(
                                    item.name.isEmpty ? item.ticker : item.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  Chip(label: Text(item.ticker)),
                                  Chip(label: Text(item.isPublic ? '공개' : '비공개')),
                                  Chip(label: Text(item.alertEnabled ? '알림ON' : '알림OFF')),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(item.memo.isEmpty ? '운영 메모 없음' : item.memo),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  Chip(label: Text('지지선 ${item.supportCount}개')),
                                  Chip(label: Text('저항선 ${item.resistanceCount}개')),
                                  Chip(label: Text(item.portfolioReady ? '포트폴리오 연결 준비' : '포트폴리오 미연결')),
                                  Chip(label: Text('docId ${item.docId}')),
                                ],
                              ),
                              if (item.updatedAt != null) ...[
                                const SizedBox(height: 8),
                                Text('업데이트: ${item.updatedAt!.toIso8601String()}'),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
