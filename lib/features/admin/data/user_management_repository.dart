import 'package:cloud_firestore/cloud_firestore.dart';

class UserManagementRepository {
  UserManagementRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  Future<List<ManagedUserAccount>> fetchUsers({int limit = 100}) async {
    final snapshot = await _users.limit(limit).get();
    final users = snapshot.docs.map(_fromSnapshot).toList()
      ..sort(_compareUsersForList);

    await _repairMissingUserMetadata(snapshot.docs);
    return users;
  }

  Future<ManagedUserAccount?> fetchUser(String uid) async {
    final snapshot = await _users.doc(uid).get();
    if (!snapshot.exists) {
      return null;
    }
    return _fromSnapshot(snapshot);
  }

  Future<void> updateUserPermissions({
    required String uid,
    required String role,
    required List<String> allowedPaths,
  }) {
    return _users.doc(uid).set({
      'role': _normalizeRole(role),
      'allowedPaths': _normalizeAllowedPaths(allowedPaths),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<int> countAdminUsers({int limit = 2}) async {
    final snapshot = await _users
        .where('role', isEqualTo: 'admin')
        .limit(limit)
        .get();
    return snapshot.size;
  }

  Future<PermissionUpdateGuardResult> validatePermissionUpdate({
    required ManagedUserAccount user,
    required String nextRole,
    required String? actingUserUid,
  }) async {
    final normalizedNextRole = _normalizeRole(nextRole);
    final isRoleChanged = user.role != normalizedNextRole;
    final isSelfAdminDemotion =
        actingUserUid == user.uid && user.role == 'admin' && normalizedNextRole != 'admin';

    if (isSelfAdminDemotion) {
      return const PermissionUpdateGuardResult.blocked(
        '현재 로그인한 admin 계정은 자기 자신을 member/guest로 내릴 수 없어요.',
      );
    }

    final isAdminDemotion = user.role == 'admin' && normalizedNextRole != 'admin';
    if (isRoleChanged && isAdminDemotion) {
      final adminCount = await countAdminUsers();
      if (adminCount <= 1) {
        return const PermissionUpdateGuardResult.blocked(
          '현재 시스템에 admin 계정이 1명뿐이라 마지막 admin을 강등할 수 없어요.',
        );
      }
    }

    return const PermissionUpdateGuardResult.allowed();
  }

  ManagedUserAccount _fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    return ManagedUserAccount(
      uid: data['uid'] as String? ?? snapshot.id,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      nickname: data['nickname'] as String? ?? '',
      fullName: data['fullName'] as String? ?? '',
      photoUrl: data['photoURL'] as String?,
      role: _normalizeRole(data['role'] as String?),
      allowedPaths: (data['allowedPaths'] as List<dynamic>? ?? const [])
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList(),
      createdAt: _toDateTime(data['createdAt']),
      updatedAt: _toDateTime(data['updatedAt']),
      lastLoginAt: _toDateTime(data['lastLoginAt']),
    );
  }

  Future<void> _repairMissingUserMetadata(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    final batch = _firestore.batch();
    var hasPendingWrite = false;

    for (final doc in docs) {
      final data = doc.data();
      final hasUpdatedAt = data['updatedAt'] != null;
      final hasCreatedAt = data['createdAt'] != null;
      if (hasUpdatedAt && hasCreatedAt) {
        continue;
      }

      final createdAt = data['createdAt'];
      batch.set(doc.reference, {
        if (!hasCreatedAt) 'createdAt': FieldValue.serverTimestamp(),
        if (!hasUpdatedAt) 'updatedAt': createdAt ?? FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      hasPendingWrite = true;
    }

    if (hasPendingWrite) {
      await batch.commit();
    }
  }

  int _compareUsersForList(ManagedUserAccount a, ManagedUserAccount b) {
    final aSortKey = a.updatedAt ?? a.createdAt;
    final bSortKey = b.updatedAt ?? b.createdAt;
    if (aSortKey != null && bSortKey != null) {
      final compareDate = bSortKey.compareTo(aSortKey);
      if (compareDate != 0) {
        return compareDate;
      }
    } else if (aSortKey != null || bSortKey != null) {
      return aSortKey == null ? 1 : -1;
    }

    return a.uid.compareTo(b.uid);
  }

  List<String> _normalizeAllowedPaths(List<String> allowedPaths) {
    final unique = allowedPaths
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return unique;
  }

  String _normalizeRole(String? role) {
    switch ((role ?? '').trim()) {
      case 'admin':
      case 'member':
      case 'guest':
        return (role ?? '').trim();
      default:
        return 'guest';
    }
  }

  DateTime? _toDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    return null;
  }
}

class ManagedUserAccount {
  const ManagedUserAccount({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.nickname,
    required this.fullName,
    required this.photoUrl,
    required this.role,
    required this.allowedPaths,
    required this.createdAt,
    required this.updatedAt,
    required this.lastLoginAt,
  });

  final String uid;
  final String email;
  final String displayName;
  final String nickname;
  final String fullName;
  final String? photoUrl;
  final String role;
  final List<String> allowedPaths;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastLoginAt;

  String get primaryName {
    if (displayName.trim().isNotEmpty) {
      return displayName.trim();
    }
    if (nickname.trim().isNotEmpty) {
      return nickname.trim();
    }
    if (fullName.trim().isNotEmpty) {
      return fullName.trim();
    }
    if (email.trim().isNotEmpty) {
      return email.trim();
    }
    return uid;
  }
}

class PermissionUpdateGuardResult {
  const PermissionUpdateGuardResult._({
    required this.allowed,
    this.message,
  });

  const PermissionUpdateGuardResult.allowed() : this._(allowed: true);

  const PermissionUpdateGuardResult.blocked(String message)
      : this._(allowed: false, message: message);

  final bool allowed;
  final String? message;
}
