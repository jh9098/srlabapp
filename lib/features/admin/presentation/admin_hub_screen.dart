import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../home/data/home_models.dart';
import '../../notifications/data/notification_models.dart';
import '../../user/domain/feature_access.dart';
import '../../user/domain/user_profile.dart';
import 'admin_watchlist_editor_screen.dart';
import 'admin_watchlist_preview_screen.dart';
import 'user_management_screen.dart';

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
    if (_initialized) return;
    _initialized = true;
    _signalPreviewFuture = _loadSignalPreview();
    _notificationPreviewFuture = _loadNotifications();
  }

  Future<HomeResponseModel?> _loadSignalPreview() async {
    final repo = AppScope.of(context).firebaseHomeRepository;
    if (repo == null) return null;
    return repo.fetchHome(featuredLimit: 6);
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
    await Future.wait([_signalPreviewFuture, _notificationPreviewFuture]);
  }

  @override
  Widget build(BuildContext context) {
    final hasFirebase = AppScope.of(context).config.isFirebaseConfigured;

    return Scaffold(
      appBar: AppBar(
        title: const Text('관리자 메뉴'),
        actions: [
          IconButton(
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: '새로고침',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 프로필 배지
            _AdminProfileBanner(
              profile: widget.profile,
              hasFirebase: hasFirebase,
            ),
            const SizedBox(height: 16),

            // 운영 기능 목록
            _AdminMenuCard(hasFirebase: hasFirebase),
            const SizedBox(height: 16),

            // 신호 미리보기
            _SignalPreviewCard(future: _signalPreviewFuture),
            const SizedBox(height: 16),

            // 알림 이력 미리보기
            _NotificationPreviewCard(future: _notificationPreviewFuture),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────

class _AdminProfileBanner extends StatelessWidget {
  const _AdminProfileBanner({
    required this.profile,
    required this.hasFirebase,
  });

  final UserProfile profile;
  final bool hasFirebase;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor:
                const Color(0xFF7C3AED).withValues(alpha: 0.25),
            child: const Icon(
              Icons.admin_panel_settings_outlined,
              color: Color(0xFFDDD6FE),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.displayName.isNotEmpty
                      ? profile.displayName
                      : '관리자',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  profile.email.isNotEmpty ? profile.email : profile.role,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Firebase 연결 상태
          _StatusPill(
            label: hasFirebase ? 'Firestore' : 'Firebase 없음',
            active: hasFirebase,
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────

enum _MenuItemStatus { active, preview, disabled }

class _AdminMenuCard extends StatelessWidget {
  const _AdminMenuCard({required this.hasFirebase});

  final bool hasFirebase;

  @override
  Widget build(BuildContext context) {
    final items = [
      _AdminMenuItem(
        icon: Icons.manage_accounts_outlined,
        title: '회원 관리',
        subtitle: '권한 · allowedPaths 편집',
        status:
            hasFirebase ? _MenuItemStatus.active : _MenuItemStatus.disabled,
        onTap: hasFirebase
            ? () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const UserManagementScreen()),
                )
            : null,
      ),
      _AdminMenuItem(
        icon: Icons.edit_note_rounded,
        title: '운영 종목 편집',
        subtitle: '지지선 · 저항선 · 메모 관리',
        status:
            hasFirebase ? _MenuItemStatus.active : _MenuItemStatus.disabled,
        onTap: hasFirebase
            ? () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) =>
                          const AdminWatchlistEditorScreen()),
                )
            : null,
      ),
      _AdminMenuItem(
        icon: Icons.visibility_outlined,
        title: '운영 종목 보기',
        subtitle: '읽기 전용 빠른 확인',
        status:
            hasFirebase ? _MenuItemStatus.active : _MenuItemStatus.disabled,
        onTap: hasFirebase
            ? () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) =>
                          const AdminWatchlistPreviewScreen()),
                )
            : null,
      ),
      const _AdminMenuItem(
        icon: Icons.notifications_active_outlined,
        title: '신호/푸시 운영',
        subtitle: '실시간 신호 발송 · 이력',
        status: _MenuItemStatus.preview,
        onTap: null,
      ),
    ];

    return Card(
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            items[i],
          ],
        ],
      ),
    );
  }
}

class _AdminMenuItem extends StatelessWidget {
  const _AdminMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final _MenuItemStatus status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = status == _MenuItemStatus.disabled;

    return ListTile(
      enabled: !disabled,
      leading: Icon(icon,
          color: disabled ? Colors.grey.shade400 : null),
      title: Text(
        title,
        style: TextStyle(
          color: disabled ? Colors.grey.shade400 : null,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: disabled ? Colors.grey.shade300 : null,
          fontSize: 12,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _statusWidget(context),
          if (status == _MenuItemStatus.active)
            const Icon(Icons.chevron_right_rounded),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _statusWidget(BuildContext context) {
    switch (status) {
      case _MenuItemStatus.active:
        return const SizedBox.shrink();
      case _MenuItemStatus.preview:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: const Color(0xFFFED7AA)),
          ),
          child: const Text(
            '준비 중',
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFFB45309),
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      case _MenuItemStatus.disabled:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            'Firebase 필요',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade400,
            ),
          ),
        );
    }
  }
}

// ──────────────────────────────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: active
            ? const Color(0xFF166534).withValues(alpha: 0.3)
            : Colors.grey.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: active
                  ? const Color(0xFF4ADE80)
                  : Colors.grey.shade500,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: active ? const Color(0xFF4ADE80) : Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────

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
            final featured =
                snapshot.data?.featuredStocks ??
                    const <HomeFeaturedStockModel>[];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '신호 후보 현황',
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                    ),
                    const Spacer(),
                    if (snapshot.connectionState ==
                        ConnectionState.waiting)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child:
                            CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (featured.isEmpty)
                  Text(
                    '현재 신호 후보가 없습니다.',
                    style: TextStyle(color: Colors.grey.shade500),
                  )
                else
                  ...featured.take(5).map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(item.stockName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500)),
                              ),
                              Text(
                                item.summary,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
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
                  '최근 알림 이력',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const LinearProgressIndicator()
                else if (items.isEmpty)
                  Text(
                    '알림 이력이 없습니다.',
                    style: TextStyle(color: Colors.grey.shade500),
                  )
                else
                  ...items.take(5).map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(item.title,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500)),
                              ),
                              Text(
                                item.deliveryStatus,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500),
                              ),
                            ],
                          ),
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
