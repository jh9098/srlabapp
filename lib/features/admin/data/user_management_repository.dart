import 'package:cloud_firestore/cloud_firestore.dart';

class UserManagementRepository {
  UserManagementRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  Future<List<ManagedUserAccount>> fetchUsers({int limit = 100}) async {
    final snapshot = await _users
        .orderBy('updatedAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map(_fromSnapshot).toList();
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
