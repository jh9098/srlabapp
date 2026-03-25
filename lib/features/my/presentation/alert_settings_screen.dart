import 'package:flutter/material.dart';

import '../../../core/widgets/app_sticky_bottom_bar.dart';
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

  /// useFirebaseOnly 모드에서는 로컬 기본값을 사용하고 Firestore 저장은
  /// 연동 완료 후 활성화됩니다. 유저 입장에서는 설정 UI를 동일하게 사용합니다.
  AlertSettingsModel get _defaultSettings => const AlertSettingsModel(
        pushEnabled: true,
        priceSignalEnabled: true,
        themeSignalEnabled: true,
        contentUpdateEnabled: false,
        adminNoticeEnabled: true,
      );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final scope = AppScope.of(context);
    if (scope.config.useFirebaseOnly) {
      _future = _loadLocal();
    } else {
      _future = _load();
    }
  }


  Future<AlertSettingsModel> _loadLocal() async {
    final settings = await AppScope.of(context)
        .notificationRepository
        .loadLocalSettings();
    if (mounted) setState(() => _draft = settings);
    return settings;
  }

  Future<AlertSettingsModel> _load() async {
    final settings = await AppScope.of(context)
        .notificationRepository
        .fetchAlertSettings();
    if (mounted) setState(() => _draft = settings);
    return settings;
  }

  Future<void> _save() async {
    final draft = _draft;
    if (draft == null || _saving) return;

    setState(() => _saving = true);
    try {
      final scope = AppScope.of(context);

      if (scope.config.useFirebaseOnly) {
        final saved = await scope.notificationRepository.saveLocalSettings(draft);
        if (!mounted) return;
        setState(() {
          _draft = saved;
          _future = Future.value(saved);
        });
      } else {
        final saved =
            await scope.notificationRepository.updateAlertSettings(draft);
        if (!mounted) return;
        setState(() {
          _draft = saved;
          _future = Future.value(saved);
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('알림 설정을 저장했습니다.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('저장하지 못했습니다. 다시 시도해 주세요.\n$e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('알림 설정')),
      body: _buildBody(),
      bottomNavigationBar: AppStickyBottomBar(
        child: FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.check_rounded),
          label: const Text('설정 저장'),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return FutureBuilder<AlertSettingsModel>(
      future: _future,
      builder: (context, snapshot) {
        final draft = _draft;

        if (draft == null &&
            snapshot.connectionState != ConnectionState.done) {
          return const LoadingState(message: '알림 설정을 불러오는 중입니다.');
        }

        if (snapshot.hasError && draft == null) {
          return ErrorState(
            message: '알림 설정을 불러오지 못했습니다.',
            onRetry: () => setState(() {
              _future = AppScope.of(context).config.useFirebaseOnly
                  ? _loadLocal()
                  : _load();
            }),
          );
        }

        return _buildSettingsList(draft ?? snapshot.data ?? _defaultSettings);
      },
    );
  }

  Widget _buildSettingsList(AlertSettingsModel draft) {
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        // 전체 알림 마스터 스위치
        Card(
          color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.25),
          child: SwitchListTile(
            secondary: Icon(
              draft.pushEnabled
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_off_outlined,
              color: draft.pushEnabled
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey.shade400,
            ),
            title: const Text(
              '푸시 알림',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              draft.pushEnabled
                  ? '모든 알림 수신 중'
                  : '알림이 꺼져 있습니다',
            ),
            value: draft.pushEnabled,
            onChanged: (value) =>
                setState(() => _draft = draft.copyWith(pushEnabled: value)),
          ),
        ),

        const SizedBox(height: 16),

        // 알림 세부 설정
        AnimatedOpacity(
          opacity: draft.pushEnabled ? 1.0 : 0.45,
          duration: const Duration(milliseconds: 200),
          child: Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                  child: Text(
                    '알림 종류',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                SwitchListTile(
                  title: const Text('가격 신호 알림'),
                  subtitle: const Text(
                    '지지선 접근 · 반등 성공 · 무효화',
                  ),
                  value: draft.priceSignalEnabled && draft.pushEnabled,
                  onChanged: draft.pushEnabled
                      ? (value) => setState(
                            () => _draft =
                                draft.copyWith(priceSignalEnabled: value),
                          )
                      : null,
                ),
                const Divider(height: 1, indent: 16),
                SwitchListTile(
                  title: const Text('테마 알림'),
                  subtitle: const Text('주요 테마 변화 알림'),
                  value: draft.themeSignalEnabled && draft.pushEnabled,
                  onChanged: draft.pushEnabled
                      ? (value) => setState(
                            () => _draft =
                                draft.copyWith(themeSignalEnabled: value),
                          )
                      : null,
                ),
                const Divider(height: 1, indent: 16),
                SwitchListTile(
                  title: const Text('콘텐츠 업데이트'),
                  subtitle: const Text('새 해설 · 매매 전략 업로드'),
                  value: draft.contentUpdateEnabled && draft.pushEnabled,
                  onChanged: draft.pushEnabled
                      ? (value) => setState(
                            () => _draft =
                                draft.copyWith(contentUpdateEnabled: value),
                          )
                      : null,
                ),
                const Divider(height: 1, indent: 16),
                SwitchListTile(
                  title: const Text('운영 공지'),
                  subtitle: const Text('점검 · 중요 안내'),
                  value: draft.adminNoticeEnabled && draft.pushEnabled,
                  onChanged: draft.pushEnabled
                      ? (value) => setState(
                            () => _draft =
                                draft.copyWith(adminNoticeEnabled: value),
                          )
                      : null,
                ),
              ],
            ),
          ),
        ),

        if (AppScope.of(context).config.useFirebaseOnly) ...[
          const SizedBox(height: 12),
          Text('현재 Firebase 직독 모드에서는 로컬 기본값 기준으로 동작합니다.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600)),
        ],
      ],
    );
  }
}
