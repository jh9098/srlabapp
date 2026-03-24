import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../admin/presentation/admin_hub_screen.dart';
import '../../app/app_scope.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../user/domain/feature_access.dart';
import '../../user/domain/user_profile.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_mode_controller.dart';
import 'alert_settings_screen.dart';

class MyScreen extends StatelessWidget {
  const MyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final config = scope.config;
    final authRepository = scope.authRepository;
    final profileRepository = scope.userProfileRepository;

    if (!config.isFirebaseConfigured || authRepository == null || profileRepository == null) {
      return _buildSimpleLayout(context);
    }

    return StreamBuilder<User?>(
      stream: authRepository.authStateChanges(),
      builder: (context, authSnapshot) {
        final user = authSnapshot.data;

        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (user == null) {
          return _buildLoggedOutLayout(context);
        }

        return StreamBuilder<UserProfile?>(
          stream: profileRepository.watchProfile(user.uid),
          builder: (context, profileSnapshot) {
            final profile = profileSnapshot.data;
            return _buildLoggedInLayout(
              context,
              user: user,
              profile: profile,
              onSignOut: authRepository.signOut,
            );
          },
        );
      },
    );
  }

  Widget _buildLoggedOutLayout(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, AppSpacing.bottomListPadding),
      children: [
        const SizedBox(height: 24),
        const _ProfilePlaceholder(),
        const SizedBox(height: 24),
        _buildMenuCard(context, profile: null),
        const SizedBox(height: 16),
        _buildSettingsCard(context),
        const SizedBox(height: 16),
        _buildContactCard(context),
        const SizedBox(height: 16),
        _buildAppInfoCard(context, isAdmin: false),
      ],
    );
  }

  Widget _buildSimpleLayout(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, AppSpacing.bottomListPadding),
      children: [
        _buildMenuCard(context, profile: null),
        const SizedBox(height: 16),
        _buildSettingsCard(context),
        const SizedBox(height: 16),
        _buildContactCard(context),
        const SizedBox(height: 16),
        _buildAppInfoCard(context, isAdmin: false),
      ],
    );
  }

  Widget _buildLoggedInLayout(
    BuildContext context, {
    required User user,
    required UserProfile? profile,
    required Future<void> Function() onSignOut,
  }) {
    final isAdmin = FeatureAccess.canOpenAdmin(profile);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, AppSpacing.bottomListPadding),
      children: [
        _ProfileCard(authUser: user, profile: profile, onSignOut: onSignOut),
        const SizedBox(height: 16),
        _buildMenuCard(context, profile: profile),
        if (isAdmin) ...[
          const SizedBox(height: 16),
          _AdminCard(profile: profile!),
        ],
        const SizedBox(height: 16),
        _buildSettingsCard(context),
        const SizedBox(height: 16),
        _buildContactCard(context),
        const SizedBox(height: 16),
        _buildAppInfoCard(context, isAdmin: isAdmin),
      ],
    );
  }

  Widget _buildMenuCard(BuildContext context, {required UserProfile? profile}) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.notifications_active_outlined),
            title: const Text('알림 설정'),
            subtitle: const Text('지지선 신호 · 테마 · 공지 알림'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AlertSettingsScreen()),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.notifications_none_rounded),
            title: const Text('알림함'),
            subtitle: const Text('신호 이벤트와 운영 공지 이력'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context) {
    return Card(
      child: Column(
        children: [
          // 다크모드 토글
          ValueListenableBuilder<ThemeMode>(
            valueListenable: ThemeModeController.instance,
            builder: (context, mode, _) {
              final isDark = ThemeModeController.instance.resolvedIsDark(context);
              return SwitchListTile(
                secondary: Icon(
                  isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                ),
                title: const Text('다크 모드'),
                subtitle: Text(
                  mode == ThemeMode.system ? '시스템 설정 따름' : (isDark ? '켜짐' : '꺼짐'),
                ),
                value: isDark,
                onChanged: (_) => ThemeModeController.instance.toggle(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.chat_outlined),
            title: const Text('카카오 오픈채팅'),
            subtitle: const Text('링크 준비 중 · 추후 실제 주소로 연결됩니다'),
            trailing: const Icon(Icons.open_in_new_rounded, size: 18),
            onTap: () => _launchUrl(
              context,
              // TODO: 실제 카카오 오픈채팅 URL로 교체
              'https://open.kakao.com/o/srlab',
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.send_outlined),
            title: const Text('텔레그램 채널'),
            subtitle: const Text('링크 준비 중 · 추후 실제 주소로 연결됩니다'),
            trailing: const Icon(Icons.open_in_new_rounded, size: 18),
            onTap: () => _launchUrl(
              context,
              // TODO: 실제 텔레그램 채널 URL로 교체
              'https://t.me/srlab',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppInfoCard(BuildContext context, {required bool isAdmin}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '앱 버전',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade500,
                      ),
                ),
                Text(
                  '1.0.0',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade500,
                      ),
                ),
              ],
            ),
            // 관리자에게만 연결 정보 표시
            if (isAdmin) ...[
              const SizedBox(height: 8),
              Builder(builder: (context) {
                final config = AppScope.of(context).config;
                return Text(
                  '${config.appEnv} · ${config.isFirebaseConfigured ? 'Firebase 연결됨' : 'Firebase 미설정'}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade400,
                        fontSize: 11,
                      ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('링크를 열 수 없습니다.')),
        );
      }
    }
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 내부 위젯
// ──────────────────────────────────────────────────────────────────────────────

class _ProfilePlaceholder extends StatelessWidget {
  const _ProfilePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFF5F3FF),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          child: Icon(
            Icons.person_outline_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: const Text('로그인이 필요합니다'),
        subtitle: const Text('로그인하면 관심종목/알림/개인화 기능을 바로 사용할 수 있어요.'),
      ),
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
    return raw.isEmpty ? '?' : raw.substring(0, 1).toUpperCase();
  }

  String get _displayName {
    if (profile?.displayName.isNotEmpty == true) return profile!.displayName;
    if (authUser.displayName?.isNotEmpty == true) return authUser.displayName!;
    return authUser.email?.split('@').first ?? '사용자';
  }

  String get _roleLabel {
    switch (profile?.role) {
      case 'admin':
        return '관리자';
      case 'member':
        return '멤버';
      default:
        return '게스트';
    }
  }

  Color _roleColor(BuildContext context) {
    switch (profile?.role) {
      case 'admin':
        return const Color(0xFF7C3AED);
      case 'member':
        return const Color(0xFF0369A1);
      default:
        return Colors.grey.shade500;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // 아바타
            CircleAvatar(
              radius: 28,
              backgroundColor: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.12),
              child: Text(
                _avatarLabel,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 14),
            // 이름 + 이메일
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          _displayName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _roleColor(context).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          _roleLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _roleColor(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    authUser.email ?? '-',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // 로그아웃
            FilledButton.tonal(
              onPressed: onSignOut,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                visualDensity: VisualDensity.compact,
              ),
              child: const Text('로그아웃', style: TextStyle(fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminCard extends StatelessWidget {
  const _AdminCard({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFDDD6FE), width: 1),
      ),
      color: const Color(0xFFF5F3FF),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFEDE9FE),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.admin_panel_settings_outlined,
            color: Color(0xFF7C3AED),
            size: 22,
          ),
        ),
        title: const Text(
          '관리자 메뉴',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: const Text('종목 편집 · 회원 관리 · 신호 운영'),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AdminHubScreen(profile: profile),
          ),
        ),
      ),
    );
  }
}
