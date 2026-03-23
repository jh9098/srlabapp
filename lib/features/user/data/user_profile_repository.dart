import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/user_profile.dart';

class UserProfileRepository {
  UserProfileRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) {
    return _firestore.collection('users').doc(uid);
  }

  Stream<UserProfile?> watchProfile(String uid) {
    return _userDoc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }
      return _fromSnapshot(snapshot);
    });
  }

  Future<UserProfile> ensureUserProfile({
    required User user,
    String nickname = '',
    String fullName = '',
    String gender = '',
    String birthDate = '',
    String phoneNumber = '',
  }) async {
    final now = FieldValue.serverTimestamp();
    final doc = _userDoc(user.uid);
    final snapshot = await doc.get();

    if (!snapshot.exists) {
      await doc.set({
        'uid': user.uid,
        'email': _resolvedText(user.email),
        'displayName': _resolvedText(user.displayName ?? fullName),
        'photoURL': user.photoURL,
        'role': 'guest',
        'allowedPaths': <String>[],
        'updatedAt': now,
        'lastLoginAt': now,
        'createdAt': now,
        'nickname': _resolvedText(nickname),
        'fullName': _resolvedText(fullName),
        'gender': _resolvedText(gender),
        'birthDate': _resolvedText(birthDate),
        'phoneNumber': _resolvedText(phoneNumber.isNotEmpty ? phoneNumber : user.phoneNumber),
      }, SetOptions(merge: true));
    } else {
      final existing = snapshot.data() ?? const <String, dynamic>{};
      final updateData = <String, dynamic>{
        'uid': user.uid,
        'updatedAt': now,
        'lastLoginAt': now,
      };

      _putIfMissingOrBlank(
        updateData,
        existing: existing,
        key: 'email',
        value: user.email,
      );
      _putIfMissingOrBlank(
        updateData,
        existing: existing,
        key: 'displayName',
        value: user.displayName ?? fullName,
      );
      _putIfMissingOrBlank(
        updateData,
        existing: existing,
        key: 'photoURL',
        value: user.photoURL,
      );
      _putIfMissingOrBlank(
        updateData,
        existing: existing,
        key: 'nickname',
        value: nickname,
      );
      _putIfMissingOrBlank(
        updateData,
        existing: existing,
        key: 'fullName',
        value: fullName,
      );
      _putIfMissingOrBlank(
        updateData,
        existing: existing,
        key: 'gender',
        value: gender,
      );
      _putIfMissingOrBlank(
        updateData,
        existing: existing,
        key: 'birthDate',
        value: birthDate,
      );
      _putIfMissingOrBlank(
        updateData,
        existing: existing,
        key: 'phoneNumber',
        value: phoneNumber.isNotEmpty ? phoneNumber : user.phoneNumber,
      );

      await doc.set(updateData, SetOptions(merge: true));
    }

    final refreshed = await doc.get();
    return _fromSnapshot(refreshed);
  }

  Future<void> updateProfile({
    required String uid,
    String? displayName,
    String? nickname,
    String? fullName,
    String? phoneNumber,
  }) {
    return _userDoc(uid).set({
      if (displayName != null) 'displayName': displayName,
      if (nickname != null) 'nickname': nickname,
      if (fullName != null) 'fullName': fullName,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  UserProfile _fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    return UserProfile(
      uid: data['uid'] as String? ?? snapshot.id,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      photoUrl: data['photoURL'] as String?,
      role: data['role'] as String? ?? 'guest',
      allowedPaths: (data['allowedPaths'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      nickname: data['nickname'] as String? ?? '',
      fullName: data['fullName'] as String? ?? '',
      gender: data['gender'] as String? ?? '',
      birthDate: data['birthDate'] as String? ?? '',
      phoneNumber: data['phoneNumber'] as String? ?? '',
      createdAt: _toDateTime(data['createdAt']),
      updatedAt: _toDateTime(data['updatedAt']),
      lastLoginAt: _toDateTime(data['lastLoginAt']),
    );
  }

  void _putIfMissingOrBlank(
    Map<String, dynamic> data, {
    required Map<String, dynamic> existing,
    required String key,
    required Object? value,
  }) {
    final current = _resolvedText(existing[key]);
    final next = _resolvedText(value);
    if (current.isEmpty && next.isNotEmpty) {
      data[key] = next;
    }
  }

  String _resolvedText(Object? value) {
    return value?.toString().trim() ?? '';
  }

  DateTime? _toDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    return null;
  }
}
