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
  }) async {
    final now = FieldValue.serverTimestamp();
    final doc = _userDoc(user.uid);
    final snapshot = await doc.get();

    final baseData = <String, dynamic>{
      'uid': user.uid,
      'email': user.email ?? '',
      'displayName': user.displayName ?? fullName,
      'photoURL': user.photoURL,
      'role': 'guest',
      'allowedPaths': <String>[],
      'updatedAt': now,
      'lastLoginAt': now,
      'nickname': nickname,
      'fullName': fullName,
      'gender': '',
      'birthDate': '',
      'phoneNumber': user.phoneNumber ?? '',
    };

    if (!snapshot.exists) {
      await doc.set({
        ...baseData,
        'createdAt': now,
      }, SetOptions(merge: true));
    } else {
      await doc.set(baseData, SetOptions(merge: true));
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

  DateTime? _toDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    return null;
  }
}
