import 'package:flutter/material.dart';

import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_state.dart';
import '../../app/app_scope.dart';
import '../data/admin_watchlist_repository.dart';

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

  AdminWatchlistItem? _selectedItem;

  final TextEditingController _tickerController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();
  final TextEditingController _supportLinesController = TextEditingController();
  final TextEditingController _resistanceLinesController =
      TextEditingController();

  bool _isPublic = true;
  bool _alertEnabled = true;
  bool _portfolioReady = false;

  bool _isSaving = false;
  bool _isDeleting = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    _initialized = true;
  }

  @override
  void dispose() {
    _tickerController.dispose();
    _nameController.dispose();
    _memoController.dispose();
    _supportLinesController.dispose();
    _resistanceLinesController.dispose();
    super.dispose();
  }

  Future<List<AdminWatchlistItem>> _load() {
    return _repository.fetchItems(limit: 100);
  }

  Future<void> _reload({String? selectDocId}) async {
    setState(() {
      _future = _load();
    });

    final items = await _future;

    if (!mounted) {
      return;
    }

    if (items.isEmpty) {
      if (selectDocId == null) {
        _startCreateMode();
      }
      return;
    }

    if (selectDocId != null) {
      final matched = items.where((e) => e.docId == selectDocId).toList();
      if (matched.isNotEmpty) {
        _applyItemToForm(matched.first);
        return;
      }
    }

    if (_selectedItem != null) {
      final matched = items.where((e) => e.docId == _selectedItem!.docId).toList();
      if (matched.isNotEmpty) {
        _applyItemToForm(matched.first);
        return;
      }
    }

    _applyItemToForm(items.first);
  }

  void _startCreateMode() {
    setState(() {
      _selectedItem = null;
      _tickerController.clear();
      _nameController.clear();
      _memoController.clear();
      _supportLinesController.clear();
      _resistanceLinesController.clear();
      _isPublic = true;
      _alertEnabled = true;
      _portfolioReady = false;
    });
  }

  void _applyItemToForm(AdminWatchlistItem item) {
    setState(() {
      _selectedItem = item;
      _tickerController.text = item.ticker;
      _nameController.text = item.name;
      _memoController.text = item.memo;
      _supportLinesController.text = _formatPriceList(item.supportLines);
      _resistanceLinesController.text = _formatPriceList(item.resistanceLines);
      _isPublic = item.isPublic;
      _alertEnabled = item.alertEnabled;
      _portfolioReady = item.portfolioReady;
    });
  }

  String _formatPriceList(List<double> values) {
    return values.map(_formatNumber).join(', ');
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toString();
  }

  List<double> _parsePriceList(String raw, String fieldName) {
    final text = raw.trim();
    if (text.isEmpty) {
      return const <double>[];
    }

    final tokens = text
        .split(RegExp(r'[,/\n\r\t ]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final result = <double>[];

    for (final token in tokens) {
      final normalized = token.replaceAll(',', '');
      final value = double.tryParse(normalized);
      if (value == null) {
        throw FormatException('$fieldName 값 "$token" 을 숫자로 해석할 수 없습니다.');
      }
      if (value <= 0) {
        throw FormatException('$fieldName 값은 0보다 커야 합니다.');
      }
      result.add(value);
    }

    final uniqueSorted = result.toSet().toList()..sort();
    return uniqueSorted;
  }

  Future<void> _save() async {
    if (_isSaving || _isDeleting) {
      return;
    }

    final ticker = _tickerController.text.trim();
    final name = _nameController.text.trim();
    final memo = _memoController.text.trim();

    if (ticker.isEmpty) {
      _showMessage('종목코드를 입력해줘.');
      return;
    }

    if (name.isEmpty) {
      _showMessage('종목명을 입력해줘.');
      return;
    }

    List<double> supportLines;
    List<double> resistanceLines;

    try {
      supportLines = _parsePriceList(_supportLinesController.text, '지지선');
      resistanceLines = _parsePriceList(_resistanceLinesController.text, '저항선');
    } on FormatException catch (e) {
      _showMessage(e.message);
      return;
    } catch (e) {
      _showMessage('레벨 값을 확인해줘.\n$e');
      return;
    }

    final item = AdminWatchlistItem(
      docId: _selectedItem?.docId ?? '',
      ticker: ticker,
      name: name,
      memo: memo,
      isPublic: _isPublic,
      alertEnabled: _alertEnabled,
      portfolioReady: _portfolioReady,
      supportLines: supportLines,
      resistanceLines: resistanceLines,
      createdAt: _selectedItem?.createdAt,
      updatedAt: _selectedItem?.updatedAt,
    );

    setState(() {
      _isSaving = true;
    });

    try {
      final savedDocId = await _repository.saveItem(item);

      if (!mounted) {
        return;
      }

      _showMessage(
        _selectedItem == null ? '운영 관심종목을 추가했어.' : '운영 관심종목을 수정했어.',
      );

      await _reload(selectDocId: savedDocId);
    } catch (e) {
      if (!mounted) {
        return;
      }
      _showMessage('저장하지 못했어.\n$e');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _delete() async {
    final item = _selectedItem;
    if (item == null || _isDeleting || _isSaving) {
      return;
    }

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('운영 관심종목 삭제'),
            content: Text(
              '${item.name.isEmpty ? item.ticker : item.name} (${item.ticker}) 문서를 삭제할까?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('취소'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('삭제'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) {
      return;
    }

    setState(() {
      _isDeleting = true;
    });

    try {
      await _repository.deleteItem(item.docId);

      if (!mounted) {
        return;
      }

      _showMessage('운영 관심종목을 삭제했어.');
      _startCreateMode();
      await _reload();
    } catch (e) {
      if (!mounted) {
        return;
      }
      _showMessage('삭제하지 못했어.\n$e');
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
  }

  Widget _buildForm() {
    final isEditMode = _selectedItem != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  isEditMode ? '운영 관심종목 수정' : '운영 관심종목 추가',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                if (isEditMode)
                  Chip(label: Text('docId ${_selectedItem!.docId}'))
                else
                  const Chip(label: Text('신규')),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _tickerController,
              decoration: const InputDecoration(
                labelText: '종목코드',
                hintText: '예: 005930',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '종목명',
                hintText: '예: 삼성전자',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _supportLinesController,
              minLines: 1,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: '지지선',
                hintText: '예: 61000, 59800, 58500',
                helperText: '쉼표, 공백, 줄바꿈 모두 가능',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _resistanceLinesController,
              minLines: 1,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: '저항선',
                hintText: '예: 66000, 68500',
                helperText: '쉼표, 공백, 줄바꿈 모두 가능',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _memoController,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: '운영 메모',
                hintText: '예: 단기 반등 확인용, 거래대금 조건 병행',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _isPublic,
              onChanged: (value) => setState(() => _isPublic = value),
              title: const Text('공개 여부'),
              subtitle: Text(_isPublic ? '홈/공개 영역에 노출 가능' : '관리자 내부용'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _alertEnabled,
              onChanged: (value) => setState(() => _alertEnabled = value),
              title: const Text('알림 사용'),
              subtitle: Text(_alertEnabled ? '알림 대상' : '알림 비활성'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _portfolioReady,
              onChanged: (value) => setState(() => _portfolioReady = value),
              title: const Text('포트폴리오 연결 준비'),
              subtitle: Text(
                _portfolioReady ? '포트폴리오 연결 대상' : '포트폴리오 미연결',
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: _isSaving || _isDeleting ? null : _save,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(_isSaving ? '저장 중...' : '저장'),
                ),
                OutlinedButton.icon(
                  onPressed: _isSaving || _isDeleting ? null : _startCreateMode,
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('새 문서 작성'),
                ),
                if (isEditMode)
                  OutlinedButton.icon(
                    onPressed: _isSaving || _isDeleting ? null : _delete,
                    icon: _isDeleting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.delete_outline),
                    label: Text(_isDeleting ? '삭제 중...' : '삭제'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<AdminWatchlistItem> items) {
    if (items.isEmpty) {
      return EmptyState(
        title: '운영 관심종목이 없습니다',
        description: '새 문서를 추가해서 관리자 쓰기 모드를 시작해줘.',
        actionLabel: '새 문서 작성',
        onAction: _startCreateMode,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected = _selectedItem?.docId == item.docId;

        return Card(
          color: isSelected ? Colors.blueGrey.shade50 : null,
          child: ListTile(
            onTap: () => _applyItemToForm(item),
            title: Text(item.name.isEmpty ? item.ticker : item.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(item.ticker),
                const SizedBox(height: 4),
                Text(
                  item.memo.isEmpty ? '운영 메모 없음' : item.memo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(label: Text(item.isPublic ? '공개' : '비공개')),
                    Chip(label: Text(item.alertEnabled ? '알림ON' : '알림OFF')),
                    Chip(
                      label: Text(
                        item.portfolioReady ? '포트폴리오 준비' : '포트폴리오 미연결',
                      ),
                    ),
                    Chip(label: Text('지지선 ${item.supportLines.length}개')),
                    Chip(label: Text('저항선 ${item.resistanceLines.length}개')),
                  ],
                ),
              ],
            ),
            trailing: isSelected
                ? const Icon(Icons.check_circle_outline)
                : const Icon(Icons.chevron_right_rounded),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final firebaseEnabled = AppScope.of(context).config.isFirebaseConfigured;

    return Scaffold(
      appBar: AppBar(
        title: const Text('운영 관심종목 편집'),
        actions: [
          IconButton(
            onPressed: _isSaving || _isDeleting ? null : () => _reload(),
            icon: const Icon(Icons.refresh),
            tooltip: '새로고침',
          ),
        ],
      ),
      body: !firebaseEnabled
          ? const EmptyState(
              title: 'Firebase 설정 필요',
              description: '이 화면은 adminWatchlist Firestore write를 전제로 합니다.',
            )
          : FutureBuilder<List<AdminWatchlistItem>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !_isSaving &&
                    !_isDeleting) {
                  return const LoadingState();
                }

                if (snapshot.hasError) {
                  return ErrorState(
                    message: '운영 관심종목 편집 데이터를 불러오지 못했습니다.\n${snapshot.error}',
                    onRetry: _reload,
                  );
                }

                final items = snapshot.data ?? const <AdminWatchlistItem>[];

                if (_selectedItem == null &&
                    items.isNotEmpty &&
                    _tickerController.text.isEmpty &&
                    _nameController.text.isEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) {
                      return;
                    }
                    _applyItemToForm(items.first);
                  });
                }

                return RefreshIndicator(
                  onRefresh: _reload,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 980;

                      if (wide) {
                        return Row(
                          children: [
                            SizedBox(
                              width: 420,
                              child: _buildList(items),
                            ),
                            const VerticalDivider(width: 1),
                            Expanded(
                              child: ListView(
                                padding: const EdgeInsets.all(16),
                                children: [
                                  _buildForm(),
                                ],
                              ),
                            ),
                          ],
                        );
                      }

                      return ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _buildForm(),
                          const SizedBox(height: 16),
                          Text(
                            '기존 운영 관심종목',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: items.isEmpty ? 220 : 520,
                            child: _buildList(items),
                          ),
                        ],
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}