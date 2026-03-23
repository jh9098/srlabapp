import 'package:flutter/material.dart';

import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_state.dart';
import '../../app/app_scope.dart';
import '../../notifications/data/notification_models.dart';

class AlertSettingsScreen extends StatefulWidget {
  const AlertSettingsScreen({super.key});

  @override
  State<AlertSettingsScreen> createState() => _AlertSettingsScreenState();
}

class _AlertSettingsScreenState extends State<AlertSettingsScreen> {
  Future<AlertSettingsModel>? _future;
  AlertSettingsModel? _draft;
  bool _saving = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    if (!AppScope.of(context).config.useFirebaseOnly) {
      _future = _load();
    }
    _initialized = true;
  }

  Future<AlertSettingsModel> _load() async {
    final settings = await AppScope.of(context).notificationRepository.fetchAlertSettings();
    _draft = settings;
    return settings;
  }

  Future<void> _save() async {
    final draft = _draft;
    if (draft == null) return;
    setState(() => _saving = true);
    final saved = await AppScope.of(context).notificationRepository.updateAlertSettings(draft);
    if (!mounted) return;
    setState(() {
      _draft = saved;
      _saving = false;
      _future = Future.value(saved);
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('알림 설정을 저장했습니다.')));
  }

  @override
  Widget build(BuildContext context) {
    if (AppScope.of(context).config.useFirebaseOnly) {
      return Scaffold(
        appBar: AppBar(title: const Text('알림 설정')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Firebase 직독 1차 단계에서는 서버 기반 알림 설정을 사용하지 않습니다.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('알림 설정')),
      body: FutureBuilder<AlertSettingsModel>(
        future: _future,
        builder: (context, snapshot) {
          if ((_future == null || snapshot.connectionState != ConnectionState.done) && _draft == null) {
            return const LoadingState(message: '설정을 불러오는 중입니다.');
          }
          if (snapshot.hasError && _draft == null) {
            return ErrorState(
              message: '알림 설정을 불러오지 못했습니다.\n${snapshot.error}',
              onRetry: () => setState(() => _future = _load()),
            );
          }
          final draft = _draft ?? snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SwitchListTile(
                value: draft.pushEnabled,
                onChanged: (value) => setState(() => _draft = draft.copyWith(pushEnabled: value)),
                title: const Text('푸시 알림 전체 허용'),
                subtitle: const Text('실제 푸시 provider는 교체 가능한 구조로 연결됩니다.'),
              ),
              SwitchListTile(
                value: draft.priceSignalEnabled,
                onChanged: (value) => setState(() => _draft = draft.copyWith(priceSignalEnabled: value)),
                title: const Text('가격 신호 알림'),
                subtitle: const Text('지지선 접근, 반등 성공, 무효화 같은 핵심 변화 알림'),
              ),
              SwitchListTile(
                value: draft.themeSignalEnabled,
                onChanged: (value) => setState(() => _draft = draft.copyWith(themeSignalEnabled: value)),
                title: const Text('테마 알림'),
              ),
              SwitchListTile(
                value: draft.contentUpdateEnabled,
                onChanged: (value) => setState(() => _draft = draft.copyWith(contentUpdateEnabled: value)),
                title: const Text('콘텐츠 업데이트 알림'),
              ),
              SwitchListTile(
                value: draft.adminNoticeEnabled,
                onChanged: (value) => setState(() => _draft = draft.copyWith(adminNoticeEnabled: value)),
                title: const Text('운영 공지 알림'),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_rounded),
                label: const Text('설정 저장'),
              ),
            ],
          );
        },
      ),
    );
  }
}
