import 'package:flutter/material.dart';

import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_state.dart';
import '../../app/app_scope.dart';
import '../data/notification_models.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _showUnreadOnly = false;
  Future<List<NotificationItemModel>>? _future;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _future = _load();
  }

  Future<List<NotificationItemModel>> _load() async {
    final scope = AppScope.of(context);
    // useFirebaseOnly 모드에서는 빈 목록 반환 (Firestore 직접 연동 시 여기서 구현)
    if (scope.config.useFirebaseOnly) {
      return const <NotificationItemModel>[];
    }
    return scope.notificationRepository.fetchNotifications();
  }

  Future<void> _refresh() async {
    final future = _load();
    setState(() => _future = future);
    await future;
  }

  Future<void> _markAsRead(NotificationItemModel item) async {
    if (AppScope.of(context).config.useFirebaseOnly) return;
    await AppScope.of(context).notificationRepository.markAsRead(
          item.notificationId,
        );
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('알림함'),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(42), child: Padding(padding: const EdgeInsets.fromLTRB(16,0,16,8), child: Row(children:[ChoiceChip(label: const Text('전체'), selected: !_showUnreadOnly, onSelected: (_) => setState(() => _showUnreadOnly = false)), const SizedBox(width:8), ChoiceChip(label: const Text('안읽음'), selected: _showUnreadOnly, onSelected: (_) => setState(() => _showUnreadOnly = true))]))),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: '새로고침',
          ),
        ],
      ),
      body: FutureBuilder<List<NotificationItemModel>>(
        future: _future,
        builder: (context, snapshot) {
          if (_future == null ||
              snapshot.connectionState != ConnectionState.done) {
            return const LoadingState(message: '알림을 불러오는 중입니다.');
          }

          if (snapshot.hasError) {
            return ErrorState(
              message: '알림을 불러오지 못했습니다.',
              onRetry: _refresh,
            );
          }

          final sourceItems = snapshot.data ?? const <NotificationItemModel>[];
          final items = _showUnreadOnly ? sourceItems.where((e) => !e.isRead).toList() : sourceItems;

          if (items.isEmpty) {
            return const EmptyState(
              title: '도착한 알림이 없습니다',
              description: '지지선 접근, 반등 성공 등 중요한 신호가 생기면\n이곳에 표시됩니다.',
              icon: Icons.notifications_none_rounded,
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = items[index];
                return _NotificationCard(
                  item: item,
                  onTap: () async {
                    if (!item.isRead) await _markAsRead(item);
                    if (!context.mounted) return;
                    await AppScope.of(context)
                        .appNavigator
                        .openTargetPath(item.targetPath);
                  },
                  onMarkRead: () => _markAsRead(item),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.item,
    required this.onTap,
    required this.onMarkRead,
  });

  final NotificationItemModel item;
  final VoidCallback onTap;
  final VoidCallback onMarkRead;

  IconData get _typeIcon {
    switch (item.notificationType) {
      case 'price_signal':
        return Icons.show_chart_rounded;
      case 'theme':
        return Icons.local_fire_department_outlined;
      case 'content':
        return Icons.article_outlined;
      case 'admin_notice':
        return Icons.campaign_outlined;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  Color _typeColor(BuildContext context) {
    switch (item.notificationType) {
      case 'price_signal':
        return const Color(0xFF16A34A);
      case 'theme':
        return const Color(0xFFEA580C);
      case 'content':
        return Theme.of(context).colorScheme.primary;
      case 'admin_notice':
        return const Color(0xFF7C3AED);
      default:
        return Colors.grey.shade500;
    }
  }

  String _formattedTime() {
    final now = DateTime.now();
    final diff = now.difference(item.createdAt.toLocal());
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    final d = item.createdAt.toLocal();
    return '${d.month}/${d.day}';
  }

  @override
  Widget build(BuildContext context) {
    final color = _typeColor(context);

    return Card(
      color: item.isRead
          ? null
          : Theme.of(context)
              .colorScheme
              .primaryContainer
              .withValues(alpha: 0.25),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 타입 아이콘
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_typeIcon, color: color, size: 20),
              ),
              const SizedBox(width: 12),

              // 내용
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontWeight: item.isRead
                                  ? FontWeight.w400
                                  : FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formattedTime(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.message,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // 읽음 처리
              if (!item.isRead)
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 2),
                  child: Tooltip(message: '읽음 처리', child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  )),
                )
              else
                const Padding(
                  padding: EdgeInsets.only(left: 8, top: 2),
                  child: Icon(
                    Icons.done_all_rounded,
                    size: 16,
                    color: Colors.grey,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
