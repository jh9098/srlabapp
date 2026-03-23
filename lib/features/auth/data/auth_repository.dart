import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthRepository {
  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    String? googleClientId,
    String? googleServerClientId,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _googleClientId = (googleClientId ?? '').trim(),
        _googleServerClientId = (googleServerClientId ?? '').trim();

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final String _googleClientId;
  final String _googleServerClientId;

  static Future<void>? _googleInitFuture;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    await _upsertUserDocument(
      credential.user,
      email: email.trim(),
    );

    return credential;
  }

  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
    String? nickname,
    String? fullName,
    String? gender,
    String? birthDate,
    String? phoneNumber,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;
    if (user != null) {
      final normalizedDisplayName = (displayName ?? '').trim();
      if (normalizedDisplayName.isNotEmpty &&
          normalizedDisplayName != (user.displayName ?? '')) {
        await user.updateDisplayName(normalizedDisplayName);
      }

      await _upsertUserDocument(
        user,
        email: email.trim(),
        displayName:
            normalizedDisplayName.isEmpty ? null : normalizedDisplayName,
        nickname: nickname,
        fullName: fullName,
        gender: gender,
        birthDate: birthDate,
        phoneNumber: phoneNumber,
      );
    }

    return credential;
  }

  Future<UserCredential> signInWithGoogle() async {
    if (kIsWeb) {
      final provider = GoogleAuthProvider();
      final result = await _auth.signInWithPopup(provider);

      await _upsertUserDocument(
        result.user,
        email: result.user?.email,
        displayName: result.user?.displayName,
      );

      return result;
    }

    await _ensureGoogleInitialized();

    final GoogleSignInAccount googleUser =
        await GoogleSignIn.instance.authenticate();

    final GoogleSignInAuthentication googleAuth = googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    final result = await _auth.signInWithCredential(credential);

    await _upsertUserDocument(
      result.user,
      email: result.user?.email ?? googleUser.email,
      displayName: result.user?.displayName ?? googleUser.displayName,
    );

    return result;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> _ensureGoogleInitialized() async {
    if (kIsWeb) {
      return;
    }

    if (_googleInitFuture != null) {
      await _googleInitFuture;
      return;
    }

    _googleInitFuture = _initializeGoogleOnce();

    try {
      await _googleInitFuture;
    } catch (_) {
      _googleInitFuture = null;
      rethrow;
    }
  }

  Future<void> _initializeGoogleOnce() async {
    await GoogleSignIn.instance.initialize(
      clientId: _googleClientId.isEmpty ? null : _googleClientId,
      serverClientId:
          _googleServerClientId.isEmpty ? null : _googleServerClientId,
    );
  }

  Future<void> _upsertUserDocument(
    User? user, {
    String? email,
    String? displayName,
    String? nickname,
    String? fullName,
    String? gender,
    String? birthDate,
    String? phoneNumber,
  }) async {
    if (user == null) {
      return;
    }

    final now = FieldValue.serverTimestamp();
    final ref = _firestore.collection('users').doc(user.uid);
    final snapshot = await ref.get();
    final exists = snapshot.exists;

    final resolvedEmail = (email ?? user.email ?? '').trim();
    final resolvedDisplayName = (displayName ?? user.displayName ?? '').trim();

    final data = <String, dynamic>{
      'uid': user.uid,
      'email': resolvedEmail,
      'displayName': resolvedDisplayName,
      'photoURL': user.photoURL ?? '',
      'updatedAt': now,
      'lastLoginAt': now,
    };

    if (!exists) {
      data.addAll({
        'role': 'guest',
        'allowedPaths': <String>[],
        'createdAt': now,
        'nickname': (nickname ?? '').trim(),
        'fullName': (fullName ?? '').trim(),
        'gender': (gender ?? '').trim(),
        'birthDate': (birthDate ?? '').trim(),
        'phoneNumber': (phoneNumber ?? '').trim(),
      });
    } else {
      if (nickname != null) data['nickname'] = nickname.trim();
      if (fullName != null) data['fullName'] = fullName.trim();
      if (gender != null) data['gender'] = gender.trim();
      if (birthDate != null) data['birthDate'] = birthDate.trim();
      if (phoneNumber != null) data['phoneNumber'] = phoneNumber.trim();
    }

    await ref.set(data, SetOptions(merge: true));
  }
}