import 'package:flutter/material.dart';

import '../../app/app_scope.dart';

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
        const Card(
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.notifications_active_outlined),
                title: Text('알림 설정'),
                subtitle: Text('현재는 관심종목별 알림 토글을 사용합니다.'),
              ),
              Divider(height: 1),
              ListTile(
                leading: Icon(Icons.contact_support_outlined),
                title: Text('문의 / 공지'),
                subtitle: Text('운영 공지는 추후 연결 예정입니다.'),
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
