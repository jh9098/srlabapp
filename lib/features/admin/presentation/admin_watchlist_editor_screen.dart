import 'package:flutter/material.dart';

import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_state.dart';
import '../../app/app_scope.dart';
import '../data/admin_watchlist_repository.dart';

// ──────────────────────────────────────────────────────────────────────────────
// 리스트 화면 (진입점)
// ──────────────────────────────────────────────────────────────────────────────

class AdminWatchlistEditorScreen extends StatefulWidget {
  const AdminWatchlistEditorScreen({super.key});

  @override
  State<AdminWatchlistEditorScreen> createState() =>
      _AdminWatchlistEditorScreenState();
}

class _AdminWatchlistEditorScreenState
    extends State<AdminWatchlistEditorScreen> {
  final AdminWatchlistRepository _repository = AdminWatchlistRepository();
  late Future<List<AdminWatchlistItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<AdminWatchlistItem>> _load() =>
      _repository.fetchItems(limit: 100);

  Future<void> _reload() async {
    setState(() => _future = _load());
    await _future;
  }

  Future<void> _openEditor({AdminWatchlistItem? item}) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _AdminWatchlistItemEditScreen(
          repository: _repository,
          initialItem: item,
        ),
      ),
    );
    if (result == true) await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final firebaseEnabled =
        AppScope.of(context).config.isFirebaseConfigured;

    return Scaffold(
      appBar: AppBar(
        title: const Text('운영 종목 편집'),
        actions: [
          IconButton(
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: '새로고침',
          ),
        ],
      ),
      body: !firebaseEnabled
          ? const EmptyState(
              title: 'Firebase 연결이 필요합니다',
              description: '관리자 편집 기능은 Firestore 연결 후 사용할 수 있습니다.',
              icon: Icons.cloud_off_outlined,
            )
          : FutureBuilder<List<AdminWatchlistItem>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingState();
                }
                if (snapshot.hasError) {
                  return ErrorState(
                    message: '데이터를 불러오지 못했습니다.',
                    onRetry: _reload,
                  );
                }

                final items =
                    snapshot.data ?? const <AdminWatchlistItem>[];

                if (items.isEmpty) {
                  return EmptyState(
                    title: '운영 종목이 없습니다',
                    description: '+ 버튼을 눌러 첫 번째 종목을 추가해 보세요.',
                    icon: Icons.add_chart_rounded,
                    actionLabel: '종목 추가',
                    onAction: () => _openEditor(),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _reload,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _WatchlistListTile(
                        item: item,
                        onTap: () => _openEditor(item: item),
                      );
                    },
                  ),
                );
              },
            ),
      floatingActionButton: firebaseEnabled
          ? FloatingActionButton.extended(
              onPressed: () => _openEditor(),
              icon: const Icon(Icons.add_rounded),
              label: const Text('종목 추가'),
            )
          : null,
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 종목 리스트 아이템
// ──────────────────────────────────────────────────────────────────────────────

class _WatchlistListTile extends StatelessWidget {
  const _WatchlistListTile({required this.item, required this.onTap});

  final AdminWatchlistItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // 공개/비공개 인디케이터
              Container(
                width: 4,
                height: 48,
                decoration: BoxDecoration(
                  color: item.isPublic
                      ? const Color(0xFF16A34A)
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          item.name.isEmpty ? item.ticker : item.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          item.ticker,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _SmallChip(
                          label:
                              '지지 ${item.supportLines.length}',
                          color: const Color(0xFF16A34A),
                        ),
                        const SizedBox(width: 6),
                        _SmallChip(
                          label:
                              '저항 ${item.resistanceLines.length}',
                          color: const Color(0xFFDC2626),
                        ),
                        const SizedBox(width: 6),
                        if (item.alertEnabled)
                          _SmallChip(
                            label: '알림ON',
                            color: const Color(0xFF0369A1),
                          ),
                      ],
                    ),
                    if (item.memo.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.memo,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallChip extends StatelessWidget {
  const _SmallChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 편집 화면 (새 화면으로 push)
// ──────────────────────────────────────────────────────────────────────────────

class _AdminWatchlistItemEditScreen extends StatefulWidget {
  const _AdminWatchlistItemEditScreen({
    required this.repository,
    this.initialItem,
  });

  final AdminWatchlistRepository repository;
  final AdminWatchlistItem? initialItem;

  @override
  State<_AdminWatchlistItemEditScreen> createState() =>
      _AdminWatchlistItemEditScreenState();
}

class _AdminWatchlistItemEditScreenState
    extends State<_AdminWatchlistItemEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tickerController = TextEditingController();
  final _nameController = TextEditingController();
  final _memoController = TextEditingController();
  final _priceInputController = TextEditingController();

  List<double> _supportLines = [];
  List<double> _resistanceLines = [];
  bool _isPublic = true;
  bool _alertEnabled = true;
  bool _portfolioReady = false;
  bool _isSaving = false;
  bool _isDeleting = false;

  bool get _isEditMode => widget.initialItem != null;

  @override
  void initState() {
    super.initState();
    final item = widget.initialItem;
    if (item != null) {
      _tickerController.text = item.ticker;
      _nameController.text = item.name;
      _memoController.text = item.memo;
      _supportLines = List.from(item.supportLines);
      _resistanceLines = List.from(item.resistanceLines);
      _isPublic = item.isPublic;
      _alertEnabled = item.alertEnabled;
      _portfolioReady = item.portfolioReady;
    }
  }

  @override
  void dispose() {
    _tickerController.dispose();
    _nameController.dispose();
    _memoController.dispose();
    _priceInputController.dispose();
    super.dispose();
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  void _addPrice(List<double> list, String raw) {
    final normalized = raw.trim().replaceAll(',', '');
    final value = double.tryParse(normalized);
    if (value == null || value <= 0) {
      _showMessage('올바른 숫자를 입력해 주세요.');
      return;
    }
    if (list.contains(value)) {
      _showMessage('이미 추가된 가격입니다.');
      return;
    }
    setState(() {
      list.add(value);
      list.sort();
    });
    _priceInputController.clear();
  }

  Widget _buildPriceChipsField({
    required String label,
    required List<double> lines,
    required Color chipColor,
    required String hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),

        // 칩 목록
        if (lines.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '추가된 가격이 없습니다.',
              style:
                  TextStyle(fontSize: 13, color: Colors.grey.shade400),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: lines.map((price) {
              return Chip(
                label: Text(
                  _fmt(price),
                  style: TextStyle(
                    fontSize: 13,
                    color: chipColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                backgroundColor:
                    chipColor.withValues(alpha: 0.08),
                side: BorderSide(
                    color: chipColor.withValues(alpha: 0.3)),
                deleteIcon: Icon(Icons.close,
                    size: 16, color: chipColor),
                onDeleted: () =>
                    setState(() => lines.remove(price)),
              );
            }).toList(),
          ),

        // 입력 + 추가 버튼
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _priceInputController,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true),
                textInputAction: TextInputAction.done,
                onSubmitted: (v) => _addPrice(lines, v),
                decoration: InputDecoration(
                  hintText: hintText,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () =>
                  _addPrice(lines, _priceInputController.text),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                minimumSize: Size.zero,
              ),
              child: const Text('추가'),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (_isSaving || _isDeleting) return;
    if (!_formKey.currentState!.validate()) return;

    final item = AdminWatchlistItem(
      docId: widget.initialItem?.docId ?? '',
      ticker: _tickerController.text.trim(),
      name: _nameController.text.trim(),
      memo: _memoController.text.trim(),
      isPublic: _isPublic,
      alertEnabled: _alertEnabled,
      portfolioReady: _portfolioReady,
      supportLines: List.from(_supportLines),
      resistanceLines: List.from(_resistanceLines),
      createdAt: widget.initialItem?.createdAt,
      updatedAt: widget.initialItem?.updatedAt,
    );

    setState(() => _isSaving = true);
    try {
      await widget.repository.saveItem(item);
      if (!mounted) return;
      _showMessage(
          _isEditMode ? '종목을 수정했습니다.' : '종목을 추가했습니다.');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      _showMessage('저장하지 못했습니다. 다시 시도해 주세요.\n$e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _delete() async {
    final item = widget.initialItem;
    if (item == null || _isSaving || _isDeleting) return;

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('종목 삭제'),
            content: Text(
              '${item.name.isEmpty ? item.ticker : item.name}(${item.ticker})을 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('취소'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                ),
                child: const Text('삭제'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    setState(() => _isDeleting = true);
    try {
      await widget.repository.deleteItem(item.docId);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      _showMessage('삭제하지 못했습니다. 다시 시도해 주세요.\n$e');
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? '종목 수정' : '종목 추가'),
        actions: [
          if (_isEditMode)
            IconButton(
              onPressed: _isSaving || _isDeleting ? null : _delete,
              icon: _isDeleting
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline_rounded),
              tooltip: '삭제',
              color: const Color(0xFFDC2626),
            ),
          TextButton(
            onPressed: _isSaving || _isDeleting ? null : _save,
            child: _isSaving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    '저장',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── 기본 정보 ────────────────────────────────────
            _SectionLabel(label: '기본 정보'),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _tickerController,
                      decoration: const InputDecoration(
                        labelText: '종목코드',
                        hintText: '예: 005930',
                        prefixIcon:
                            Icon(Icons.tag_rounded),
                      ),
                      validator: (v) =>
                          (v?.trim().isEmpty ?? true)
                              ? '종목코드를 입력해 주세요.'
                              : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: '종목명',
                        hintText: '예: 삼성전자',
                        prefixIcon: Icon(Icons.business_outlined),
                      ),
                      validator: (v) =>
                          (v?.trim().isEmpty ?? true)
                              ? '종목명을 입력해 주세요.'
                              : null,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── 지지선 ────────────────────────────────────────
            _SectionLabel(label: '지지선'),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildPriceChipsField(
                  label: '지지 가격 목록',
                  lines: _supportLines,
                  chipColor: const Color(0xFF16A34A),
                  hintText: '예: 61000',
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── 저항선 ────────────────────────────────────────
            _SectionLabel(label: '저항선'),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildPriceChipsField(
                  label: '저항 가격 목록',
                  lines: _resistanceLines,
                  chipColor: const Color(0xFFDC2626),
                  hintText: '예: 66000',
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── 운영 메모 ─────────────────────────────────────
            _SectionLabel(label: '운영 메모'),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _memoController,
                  minLines: 3,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    hintText: '예: 단기 반등 확인용, 거래대금 조건 병행',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── 운영 설정 ─────────────────────────────────────
            _SectionLabel(label: '운영 설정'),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('공개'),
                    subtitle: Text(
                        _isPublic ? '홈/공개 영역에 노출' : '내부 관리용'),
                    value: _isPublic,
                    onChanged: (v) =>
                        setState(() => _isPublic = v),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('알림 사용'),
                    subtitle: Text(_alertEnabled ? '알림 대상' : '알림 비활성'),
                    value: _alertEnabled,
                    onChanged: (v) =>
                        setState(() => _alertEnabled = v),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('포트폴리오 연결'),
                    subtitle: Text(
                        _portfolioReady ? '포트폴리오 대상' : '미연결'),
                    value: _portfolioReady,
                    onChanged: (v) =>
                        setState(() => _portfolioReady = v),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // 저장 버튼
            FilledButton.icon(
              onPressed: _isSaving || _isDeleting ? null : _save,
              icon: _isSaving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check_rounded),
              label: Text(
                  _isSaving ? '저장 중...' : (_isEditMode ? '수정 완료' : '추가 완료')),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Colors.grey.shade500,
        letterSpacing: 0.5,
      ),
    );
  }
}
