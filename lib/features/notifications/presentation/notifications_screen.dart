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
  Future<List<NotificationItemModel>>? _future;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _future = _load();
    _initialized = true;
  }

  Future<List<NotificationItemModel>> _load() {
    return AppScope.of(context).notificationRepository.fetchNotifications();
  }

  Future<void> _refresh() async {
    final future = _load();
    setState(() => _future = future);
    await future;
  }

  Future<void> _markAsRead(NotificationItemModel item) async {
    await AppScope.of(context).notificationRepository.markAsRead(item.notificationId);
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('알림함')),
      body: FutureBuilder<List<NotificationItemModel>>(
        future: _future,
        builder: (context, snapshot) {
          if (_future == null || snapshot.connectionState != ConnectionState.done) {
            return const LoadingState(message: '알림을 불러오는 중입니다.');
          }
          if (snapshot.hasError) {
            return ErrorState(
              message: '알림을 불러오지 못했습니다.\n${snapshot.error}',
              onRetry: _refresh,
            );
          }
          final items = snapshot.data ?? const <NotificationItemModel>[];
          if (items.isEmpty) {
            return const EmptyState(
              title: '도착한 알림이 없습니다',
              message: '중요한 상태 변화가 생기면 이곳에 저장됩니다.',
              icon: Icons.notifications_none_rounded,
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                return Card(
                  color: item.isRead ? null : Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4),
                  child: ListTile(
                    title: Text(item.title),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        Text(item.message),
                        const SizedBox(height: 8),
                        Text(
                          '${item.notificationType} · ${item.createdAt.toLocal()}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    trailing: item.isRead
                        ? const Icon(Icons.done_all_rounded)
                        : TextButton(
                            onPressed: () => _markAsRead(item),
                            child: const Text('읽음'),
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
