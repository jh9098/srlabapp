import 'package:flutter/material.dart';

class AdminActionPlaceholders extends StatelessWidget {
  const AdminActionPlaceholders({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '잠긴 관리자 액션',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              '실제 Firestore rules / 운영 정책 확인 전까지 수정·발송 버튼은 자리만 두고 잠금 상태로 유지합니다.',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                _LockedButton(label: '관심종목 수정 잠금'),
                _LockedButton(label: '레벨 수정 잠금'),
                _LockedButton(label: '푸시 발송 잠금'),
                _LockedButton(label: '상태 강제변경 잠금'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LockedButton extends StatelessWidget {
  const _LockedButton({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: null,
      icon: const Icon(Icons.lock_outline_rounded),
      label: Text(label),
    );
  }
}
