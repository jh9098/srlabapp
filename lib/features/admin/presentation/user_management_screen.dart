import 'package:flutter/material.dart';

import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_state.dart';
import '../../app/app_scope.dart';
import '../data/user_management_repository.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final UserManagementRepository _repository = UserManagementRepository();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _allowedPathsController =
      TextEditingController();

  late Future<List<ManagedUserAccount>> _future;

  ManagedUserAccount? _selectedUser;
  String? _roleFilter;
  String _selectedRole = 'guest';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
    _searchController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _allowedPathsController.dispose();
    super.dispose();
  }

  Future<List<ManagedUserAccount>> _load() {
    return _repository.fetchUsers(limit: 200);
  }

  Future<void> _reload({String? selectUid}) async {
    setState(() {
      _future = _load();
    });

    final users = await _future;
    if (!mounted) {
      return;
    }

    if (users.isEmpty) {
      setState(() {
        _selectedUser = null;
        _selectedRole = 'guest';
        _allowedPathsController.clear();
      });
      return;
    }

    ManagedUserAccount nextUser;
    if (selectUid != null) {
      nextUser = users.firstWhere(
        (user) => user.uid == selectUid,
        orElse: () => users.first,
      );
    } else if (_selectedUser != null) {
      nextUser = users.firstWhere(
        (user) => user.uid == _selectedUser!.uid,
        orElse: () => users.first,
      );
    } else {
      nextUser = users.first;
    }

    _applyUser(nextUser);
  }

  void _applyUser(ManagedUserAccount user) {
    setState(() {
      _selectedUser = user;
      _selectedRole = user.role;
      _allowedPathsController.text = user.allowedPaths.join('\n');
    });
  }

  List<String> _parseAllowedPaths(String raw) {
    return raw
        .split(RegExp(r'[\s,]+'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  List<ManagedUserAccount> _filterUsers(List<ManagedUserAccount> users) {
    final query = _searchController.text.trim().toLowerCase();

    return users.where((user) {
      if (_roleFilter != null && user.role != _roleFilter) {
        return false;
      }

      if (query.isEmpty) {
        return true;
      }

      final targets = [
        user.primaryName,
        user.email,
        user.uid,
        user.nickname,
        user.fullName,
      ].map((item) => item.toLowerCase());

      return targets.any((item) => item.contains(query));
    }).toList();
  }

  Future<void> _save() async {
    final user = _selectedUser;
    if (user == null || _isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _repository.updateUserPermissions(
        uid: user.uid,
        role: _selectedRole,
        allowedPaths: _parseAllowedPaths(_allowedPathsController.text),
      );

      if (!mounted) {
        return;
      }

      _showMessage('회원 권한을 저장했어.');
      await _reload(selectUid: user.uid);
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage('저장하지 못했어.\n$error');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildUserList(List<ManagedUserAccount> users) {
    if (users.isEmpty) {
      return const EmptyState(
        title: '회원이 없습니다',
        description: 'users 컬렉션 문서가 아직 없거나 현재 필터 조건과 맞는 사용자가 없습니다.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final user = users[index];
        final isSelected = _selectedUser?.uid == user.uid;

        return Card(
          color: isSelected ? Colors.blueGrey.shade50 : null,
          child: ListTile(
            onTap: () => _applyUser(user),
            leading: CircleAvatar(
              child: Text(user.role.substring(0, 1).toUpperCase()),
            ),
            title: Text(user.primaryName),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(user.email.isEmpty ? '이메일 없음' : user.email),
                const SizedBox(height: 4),
                Text(
                  user.uid,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(label: Text('role: ${user.role}')),
                    Chip(label: Text('allowedPaths ${user.allowedPaths.length}개')),
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

  Widget _buildEditor() {
    final user = _selectedUser;
    if (user == null) {
      return const EmptyState(
        title: '회원 선택 필요',
        description: '왼쪽 목록 또는 아래 목록에서 수정할 회원을 선택해줘.',
      );
    }

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
                  '회원 권한 편집',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Chip(label: Text('uid ${user.uid}')),
              ],
            ),
            const SizedBox(height: 16),
            _InfoRow(label: '이메일', value: user.email.isEmpty ? '없음' : user.email),
            _InfoRow(label: '표시 이름', value: user.displayName.isEmpty ? '없음' : user.displayName),
            _InfoRow(label: '닉네임', value: user.nickname.isEmpty ? '없음' : user.nickname),
            _InfoRow(label: '실명', value: user.fullName.isEmpty ? '없음' : user.fullName),
            _InfoRow(
              label: '마지막 로그인',
              value: _formatDateTime(user.lastLoginAt),
            ),
            _InfoRow(
              label: '업데이트 시각',
              value: _formatDateTime(user.updatedAt),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedRole,
              decoration: const InputDecoration(
                labelText: '권한(role)',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'guest', child: Text('guest')),
                DropdownMenuItem(value: 'member', child: Text('member')),
                DropdownMenuItem(value: 'admin', child: Text('admin')),
              ],
              onChanged: _isSaving
                  ? null
                  : (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        _selectedRole = value;
                      });
                    },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _allowedPathsController,
              minLines: 4,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: 'allowedPaths',
                hintText: '/admin\n/admin/users\n/admin/watchlist',
                helperText: '쉼표, 공백, 줄바꿈 모두 가능. 비워두면 빈 배열로 저장돼요.',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: _isSaving ? null : _save,
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
                  onPressed: _isSaving ? null : () => _reload(selectUid: user.uid),
                  icon: const Icon(Icons.refresh),
                  label: const Text('새로고침'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime? value) {
    if (value == null) {
      return '없음';
    }
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '${value.year}-$month-$day $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final firebaseEnabled = AppScope.of(context).config.isFirebaseConfigured;

    return Scaffold(
      appBar: AppBar(
        title: const Text('회원 관리'),
        actions: [
          IconButton(
            onPressed: _isSaving ? null : () => _reload(),
            icon: const Icon(Icons.refresh),
            tooltip: '새로고침',
          ),
        ],
      ),
      body: !firebaseEnabled
          ? const EmptyState(
              title: 'Firebase 설정 필요',
              description: '이 화면은 users 컬렉션 Firestore read/write를 전제로 합니다.',
            )
          : FutureBuilder<List<ManagedUserAccount>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !_isSaving) {
                  return const LoadingState();
                }

                if (snapshot.hasError) {
                  return ErrorState(
                    message: '회원 목록을 불러오지 못했습니다.\n${snapshot.error}',
                    onRetry: _reload,
                  );
                }

                final allUsers = snapshot.data ?? const <ManagedUserAccount>[];
                final filteredUsers = _filterUsers(allUsers);

                if (_selectedUser == null && allUsers.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) {
                      return;
                    }
                    _applyUser(filteredUsers.isNotEmpty ? filteredUsers.first : allUsers.first);
                  });
                }

                return RefreshIndicator(
                  onRefresh: _reload,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 980;
                      final listSection = Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                TextField(
                                  controller: _searchController,
                                  decoration: const InputDecoration(
                                    labelText: '회원 검색',
                                    hintText: '이메일, uid, 이름으로 검색',
                                    prefixIcon: Icon(Icons.search),
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<String?>(
                                  value: _roleFilter,
                                  decoration: const InputDecoration(
                                    labelText: 'role 필터',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: const [
                                    DropdownMenuItem<String?>(
                                      value: null,
                                      child: Text('전체'),
                                    ),
                                    DropdownMenuItem<String?>(
                                      value: 'guest',
                                      child: Text('guest'),
                                    ),
                                    DropdownMenuItem<String?>(
                                      value: 'member',
                                      child: Text('member'),
                                    ),
                                    DropdownMenuItem<String?>(
                                      value: 'admin',
                                      child: Text('admin'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _roleFilter = value;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          Expanded(child: _buildUserList(filteredUsers)),
                        ],
                      );

                      if (wide) {
                        return Row(
                          children: [
                            SizedBox(width: 420, child: listSection),
                            const VerticalDivider(width: 1),
                            Expanded(
                              child: ListView(
                                padding: const EdgeInsets.all(16),
                                children: [
                                  _buildEditor(),
                                ],
                              ),
                            ),
                          ],
                        );
                      }

                      return ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _buildEditor(),
                          const SizedBox(height: 16),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  TextField(
                                    controller: _searchController,
                                    decoration: const InputDecoration(
                                      labelText: '회원 검색',
                                      hintText: '이메일, uid, 이름으로 검색',
                                      prefixIcon: Icon(Icons.search),
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  DropdownButtonFormField<String?>(
                                    value: _roleFilter,
                                    decoration: const InputDecoration(
                                      labelText: 'role 필터',
                                      border: OutlineInputBorder(),
                                    ),
                                    items: const [
                                      DropdownMenuItem<String?>(
                                        value: null,
                                        child: Text('전체'),
                                      ),
                                      DropdownMenuItem<String?>(
                                        value: 'guest',
                                        child: Text('guest'),
                                      ),
                                      DropdownMenuItem<String?>(
                                        value: 'member',
                                        child: Text('member'),
                                      ),
                                      DropdownMenuItem<String?>(
                                        value: 'admin',
                                        child: Text('admin'),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        _roleFilter = value;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: filteredUsers.isEmpty ? 220 : 520,
                            child: _buildUserList(filteredUsers),
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
