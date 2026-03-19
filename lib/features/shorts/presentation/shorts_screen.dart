import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/widgets/empty_state.dart';
import '../../app/app_scope.dart';
import '../../home/data/home_models.dart';

class ShortsScreen extends StatefulWidget {
  const ShortsScreen({super.key});

  @override
  State<ShortsScreen> createState() => _ShortsScreenState();
}

class _ShortsScreenState extends State<ShortsScreen> {
  late Future<HomeResponseModel> _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future = AppScope.of(context).homeRepository.fetchHome();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<HomeResponseModel>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snapshot.data!.recentContents.where((item) => item.externalUrl != null).toList();
        if (items.isEmpty) {
          return const EmptyState(
            title: '쇼츠 연결 준비 중',
            description: 'MVP에서는 외부 콘텐츠 링크만 간단히 연결합니다.',
            icon: Icons.play_circle_outline_rounded,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = items[index];
            return Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.play_arrow_rounded)),
                title: Text(item.title),
                subtitle: Text(item.summary ?? '요약이 없습니다.'),
                onTap: () => launchUrl(Uri.parse(item.externalUrl!)),
              ),
            );
          },
        );
      },
    );
  }
}
