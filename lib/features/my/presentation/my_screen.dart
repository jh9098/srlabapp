import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../notifications/presentation/notifications_screen.dart';
import 'alert_settings_screen.dart';

class MyScreen extends StatelessWidget {
  const MyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final config = AppScope.of(context).config;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('마이 페이지', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                const Text('MVP 최소 버전에서는 앱 정보와 알림 운영 기준만 제공합니다.'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.notifications_active_outlined),
                title: const Text('알림 설정'),
                subtitle: const Text('가격 신호/테마/운영 공지 알림 범위를 설정합니다.'),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AlertSettingsScreen())),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.notifications_none_rounded),
                title: const Text('알림함'),
                subtitle: const Text('신호 이벤트와 운영 공지 이력을 확인합니다.'),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsScreen())),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.contact_support_outlined),
                title: const Text('문의 / 공지'),
                subtitle: const Text('운영 공지는 추후 연결 예정입니다.'),
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
                Text('API: ${config.apiBaseUrl}'),
                Text('사용자 식별자: ${config.userIdentifier}'),
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
