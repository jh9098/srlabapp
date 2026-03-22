import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../admin/presentation/admin_hub_screen.dart';
import '../../app/app_scope.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../user/domain/feature_access.dart';
import '../../user/domain/user_profile.dart';
import 'alert_settings_screen.dart';

class MyScreen extends StatelessWidget {
  const MyScreen({super.key});



  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final config = scope.config;
    final authRepository = scope.authRepository;
    final profileRepository = scope.userProfileRepository;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '마이 페이지',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  config.isFirebaseConfigured
                      ? 'Firebase Auth 계정과 users/{uid} 권한 문서를 기준으로 내 정보를 보여줍니다.'
                      : '현재는 Firebase 설정이 없어 로컬/API 기반 정보만 표시합니다.',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (config.isFirebaseConfigured && authRepository != null && profileRepository != null)
          StreamBuilder<User?>(
            stream: authRepository.authStateChanges(),
            builder: (context, authSnapshot) {
              final user = authSnapshot.data;
              if (user == null) {
                return const Card(
                  child: ListTile(
                    leading: Icon(Icons.lock_outline_rounded),
                    title: Text('로그인이 필요합니다'),
                    subtitle: Text('Firebase 인증을 완료하면 role/allowedPaths를 여기에 표시합니다.'),
                  ),
                );
              }
              return StreamBuilder<UserProfile?>(
                stream: profileRepository.watchProfile(user.uid),
                builder: (context, profileSnapshot) {
                  final profile = profileSnapshot.data;
                  return Column(
                    children: [
                      _ProfileCard(
                        authUser: user,
                        profile: profile,
                        onSignOut: authRepository.signOut,
                      ),
                      const SizedBox(height: 16),
                      _FeatureAccessSummary(profile: profile),
                      if (FeatureAccess.canOpenAdmin(profile)) ...[
                        const SizedBox(height: 16),
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.admin_panel_settings_outlined),
                            title: const Text('관리자 메뉴'),
                            subtitle: const Text(
                              '현재 단계에서는 읽기 중심 관리자 화면만 먼저 엽니다.',
                            ),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: profile == null
                                ? null
                                : () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => AdminHubScreen(profile: profile),
                                      ),
                                    ),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              );
            },
          ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.notifications_active_outlined),
                title: const Text('알림 설정'),
                subtitle: const Text('가격 신호/테마/운영 공지 알림 범위를 설정합니다.'),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AlertSettingsScreen()),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.notifications_none_rounded),
                title: const Text('알림함'),
                subtitle: const Text('신호 이벤트와 운영 공지 이력을 확인합니다.'),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                ),
              ),
              const Divider(height: 1),
              const ListTile(
                leading: Icon(Icons.contact_support_outlined),
                title: Text('문의 / 공지'),
                subtitle: Text('공지와 문의 채널은 운영 준비가 끝나면 이 화면에서 안내됩니다.'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('앱 연결 정보'),
                const SizedBox(height: 8),
                Text('환경: ${config.appEnv}'),
                Text('API: ${config.apiBaseUrl}'),
                Text('Firebase 설정 여부: ${config.isFirebaseConfigured ? '설정됨' : '미설정'}'),
                if (!config.isFirebaseConfigured) Text('사용자 식별자: ${config.userIdentifier}'),
                const SizedBox(height: 12),
                const Text('버전: 1.0.0+1'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.authUser,
    required this.profile,
    required this.onSignOut,
  });

  final User authUser;
  final UserProfile? profile;
  final Future<void> Function() onSignOut;


  String get _avatarLabel {
    final raw = profile?.displayName.isNotEmpty == true
        ? profile!.displayName
        : (authUser.email ?? '?');
    return raw.isEmpty ? '?' : raw.substring(0, 1);
  }

  @override
  Widget build(BuildContext context) {
    final allowedPaths = profile?.allowedPaths ?? const <String>[];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  child: Text(_avatarLabel),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(profile?.displayName.isNotEmpty == true ? profile!.displayName : (authUser.displayName ?? '이름 없음')),
                      const SizedBox(height: 4),
                      Text(authUser.email ?? profile?.email ?? '-'),
                    ],
                  ),
                ),
                FilledButton.tonal(
                  onPressed: onSignOut,
                  child: const Text('로그아웃'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text('role: ${profile?.role ?? 'guest'}')),
                Chip(label: Text((profile?.isAdmin ?? false) ? '관리자' : '일반 사용자')),
                Chip(label: Text('allowedPaths ${allowedPaths.length}개')),
              ],
            ),
            const SizedBox(height: 12),
            _InfoRow(label: 'nickname', value: profile?.nickname ?? ''),
            _InfoRow(label: 'fullName', value: profile?.fullName ?? ''),
            _InfoRow(label: 'phoneNumber', value: profile?.phoneNumber ?? ''),
            _InfoRow(label: 'lastLoginAt', value: profile?.lastLoginAt?.toIso8601String() ?? '-'),
            const SizedBox(height: 8),
            Text(
              allowedPaths.isEmpty
                  ? 'allowedPaths가 비어 있으므로 guest/member 공통 화면만 노출하는 쪽이 안전합니다.'
                  : 'allowedPaths: ${allowedPaths.join(', ')}',
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(child: Text(value.isEmpty ? '-' : value)),
        ],
      ),
    );
  }
}

class _FeatureAccessSummary extends StatelessWidget {
  const _FeatureAccessSummary({required this.profile});

  final UserProfile? profile;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '기능 접근 상태',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              'allowedPaths 기준으로 현재 계정이 어떤 화면에 들어갈 수 있는지 미리 보여줍니다.',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _AccessChip(
                  label: '테마',
                  unlocked: FeatureAccess.canOpenTheme(profile),
                ),
                _AccessChip(
                  label: '쇼츠',
                  unlocked: FeatureAccess.canOpenShorts(profile),
                ),
                _AccessChip(
                  label: '관리자',
                  unlocked: FeatureAccess.canOpenAdmin(profile),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AccessChip extends StatelessWidget {
  const _AccessChip({
    required this.label,
    required this.unlocked,
  });

  final String label;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(
        unlocked ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
        size: 18,
      ),
      label: Text('$label ${unlocked ? '열림' : '잠금'}'),
    );
  }
}
