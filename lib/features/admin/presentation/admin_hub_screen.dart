import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../home/data/home_models.dart';
import '../../notifications/data/notification_models.dart';
import '../../user/domain/feature_access.dart';
import '../../user/domain/user_profile.dart';
import 'admin_watchlist_editor_screen.dart';
import 'admin_watchlist_preview_screen.dart';
import 'widgets/admin_action_placeholders.dart';

class AdminHubScreen extends StatefulWidget {
  const AdminHubScreen({
    super.key,
    required this.profile,
  });

  final UserProfile profile;

  @override
  State<AdminHubScreen> createState() => _AdminHubScreenState();
}

class _AdminHubScreenState extends State<AdminHubScreen> {
  late Future<HomeResponseModel?> _signalPreviewFuture;
  late Future<List<NotificationItemModel>> _notificationPreviewFuture;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    _initialized = true;
    _signalPreviewFuture = _loadSignalPreview();
    _notificationPreviewFuture = _loadNotifications();
  }

  Future<HomeResponseModel?> _loadSignalPreview() async {
    final firebaseHomeRepository = AppScope.of(context).firebaseHomeRepository;
    if (firebaseHomeRepository == null) {
      return null;
    }
    return firebaseHomeRepository.fetchHome(featuredLimit: 6);
  }

  Future<List<NotificationItemModel>> _loadNotifications() async {
    try {
      return await AppScope.of(context)
          .notificationRepository
          .fetchNotifications();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _reload() async {
    setState(() {
      _signalPreviewFuture = _loadSignalPreview();
      _notificationPreviewFuture = _loadNotifications();
    });
    await Future.wait([
      _signalPreviewFuture,
      _notificationPreviewFuture,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final hasFirebase = AppScope.of(context).config.isFirebaseConfigured;

    return Scaffold(
      appBar: AppBar(title: const Text('관리자 메뉴')),
      body: RefreshIndicator(
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
                      '관리자 운영 모드',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '이번 단계에서는 운영 관심종목 조회와 편집을 우선 열고, 신호/알림 운영 도구는 미리보기 중심으로 유지합니다.',
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(label: Text('role: ${widget.profile.role}')),
                        Chip(
                          label: Text(
                            'allowedPaths ${widget.profile.allowedPaths.length}개',
                          ),
                        ),
                        Chip(
                          label: Text(
                            FeatureAccess.canOpenAdmin(widget.profile)
                                ? '관리자 접근 허용'
                                : '관리자 접근 불가',
                          ),
                        ),
                        Chip(
                          label: Text(
                            hasFirebase ? 'Firestore 연결됨' : 'Firebase 미설정',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.edit_note_rounded),
                    title: const Text('운영 관심종목 편집'),
                    subtitle: const Text(
                      'adminWatchlist 문서를 추가, 수정, 삭제합니다.',
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: hasFirebase
                        ? () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    const AdminWatchlistEditorScreen(),
                              ),
                            )
                        : null,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.visibility_outlined),
                    title: const Text('운영 관심종목 보기'),
                    subtitle: const Text(
                      'adminWatchlist 문서를 읽기 전용으로 빠르게 확인합니다.',
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: hasFirebase
                        ? () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    const AdminWatchlistPreviewScreen(),
                              ),
                            )
                        : null,
                  ),
                  const Divider(height: 1),
                  const ListTile(
                    leading: Icon(Icons.linear_scale_rounded),
                    title: Text('지지/저항 레벨 보기'),
                    subtitle: Text(
                      '운영 관심종목 상세 카드 안에서 지지선/저항선 개수와 메모를 먼저 확인합니다.',
                    ),
                    trailing: Chip(label: Text('연결됨')),
                  ),
                  const Divider(height: 1),
                  const ListTile(
                    leading: Icon(Icons.notifications_active_outlined),
                    title: Text('신호/푸시 운영 보기'),
                    subtitle: Text(
                      '아래 미리보기 카드에서 최근 후보와 현재 계정 알림 이력을 확인합니다.',
                    ),
                    trailing: Chip(label: Text('미리보기')),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SignalPreviewCard(future: _signalPreviewFuture),
            const SizedBox(height: 16),
            _NotificationPreviewCard(future: _notificationPreviewFuture),
            const SizedBox(height: 16),
            const AdminActionPlaceholders(),
            const SizedBox(height: 16),
            Card(
              color: Colors.blueGrey.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  widget.profile.allowedPaths.isEmpty
                      ? 'allowedPaths가 비어 있어도 role=admin이면 관리자 진입을 허용합니다. 이제 adminWatchlist는 관리자 계정에서 직접 수정할 수 있습니다.'
                      : '현재 계정 allowedPaths: ${widget.profile.allowedPaths.join(', ')}',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignalPreviewCard extends StatelessWidget {
  const _SignalPreviewCard({required this.future});

  final Future<HomeResponseModel?> future;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<HomeResponseModel?>(
          future: future,
          builder: (context, snapshot) {
            final data = snapshot.data;
            final featured = data?.featuredStocks ?? const <HomeFeaturedStockModel>[];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '최근 신호 후보 미리보기',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '실제 signal_events 컬렉션이 아니라, 현재 공개 운영 종목과 가격 근접 상태를 읽기 전용으로 미리 보여줍니다.',
                ),
                const SizedBox(height: 12),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const LinearProgressIndicator()
                else if (featured.isEmpty)
                  const Text('표시할 신호 후보가 없습니다.')
                else
                  ...featured.take(5).map(
                    (item) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(item.stockName),
                      subtitle: Text(item.summary),
                      trailing: Chip(label: Text(item.status.label)),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _NotificationPreviewCard extends StatelessWidget {
  const _NotificationPreviewCard({required this.future});

  final Future<List<NotificationItemModel>> future;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<List<NotificationItemModel>>(
          future: future,
          builder: (context, snapshot) {
            final items = snapshot.data ?? const <NotificationItemModel>[];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '최근 알림 이력 미리보기',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '현재 계정 기준 알림 저장 이력을 읽기 전용으로 표시합니다. 전역 관리자 푸시 로그는 다음 단계에서 분리하는 것이 좋습니다.',
                ),
                const SizedBox(height: 12),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const LinearProgressIndicator()
                else if (items.isEmpty)
                  const Text('표시할 알림 이력이 없습니다.')
                else
                  ...items.take(5).map(
                    (item) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(item.title),
                      subtitle: Text(item.message),
                      trailing: Chip(label: Text(item.deliveryStatus)),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}