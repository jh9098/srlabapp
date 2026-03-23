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

    if (!snapshot.exists) {
      await ref.set(_buildInitialUserDocument(
        user,
        now: now,
        email: email,
        displayName: displayName,
        nickname: nickname,
        fullName: fullName,
        gender: gender,
        birthDate: birthDate,
        phoneNumber: phoneNumber,
      ));
      return;
    }

    final existing = snapshot.data() ?? const <String, dynamic>{};
    final updateData = _buildExistingUserUpdate(
      user,
      existing: existing,
      now: now,
      email: email,
      displayName: displayName,
      nickname: nickname,
      fullName: fullName,
      gender: gender,
      birthDate: birthDate,
      phoneNumber: phoneNumber,
    );

    if (updateData.isEmpty) {
      return;
    }

    await ref.set(updateData, SetOptions(merge: true));
  }

  Map<String, dynamic> _buildInitialUserDocument(
    User user, {
    required FieldValue now,
    String? email,
    String? displayName,
    String? nickname,
    String? fullName,
    String? gender,
    String? birthDate,
    String? phoneNumber,
  }) {
    final data = <String, dynamic>{
      'uid': user.uid,
      'role': 'guest',
      'allowedPaths': <String>[],
      'createdAt': now,
      'updatedAt': now,
      'lastLoginAt': now,
      'email': _resolvedText(email, user.email),
      'displayName': _resolvedText(displayName, user.displayName),
      'photoURL': user.photoURL,
      'nickname': _normalizedOptionalText(nickname),
      'fullName': _normalizedOptionalText(fullName),
      'gender': _normalizedOptionalText(gender),
      'birthDate': _normalizedOptionalText(birthDate),
      'phoneNumber': _resolvedText(phoneNumber, user.phoneNumber),
    };

    return data;
  }

  Map<String, dynamic> _buildExistingUserUpdate(
    User user, {
    required Map<String, dynamic> existing,
    required FieldValue now,
    String? email,
    String? displayName,
    String? nickname,
    String? fullName,
    String? gender,
    String? birthDate,
    String? phoneNumber,
  }) {
    final data = <String, dynamic>{
      'uid': user.uid,
      'updatedAt': now,
      'lastLoginAt': now,
    };

    _putIfMissingOrBlank(
      data,
      existing: existing,
      key: 'email',
      nextValue: _resolvedText(email, user.email),
    );
    _putIfMissingOrBlank(
      data,
      existing: existing,
      key: 'displayName',
      nextValue: _resolvedText(displayName, user.displayName),
    );
    _putIfMissingOrBlank(
      data,
      existing: existing,
      key: 'photoURL',
      nextValue: user.photoURL,
    );

    _putIfProvidedAndMissingOrBlank(
      data,
      existing: existing,
      key: 'nickname',
      nextValue: nickname,
    );
    _putIfProvidedAndMissingOrBlank(
      data,
      existing: existing,
      key: 'fullName',
      nextValue: fullName,
    );
    _putIfProvidedAndMissingOrBlank(
      data,
      existing: existing,
      key: 'gender',
      nextValue: gender,
    );
    _putIfProvidedAndMissingOrBlank(
      data,
      existing: existing,
      key: 'birthDate',
      nextValue: birthDate,
    );
    _putIfProvidedAndMissingOrBlank(
      data,
      existing: existing,
      key: 'phoneNumber',
      nextValue: phoneNumber ?? user.phoneNumber,
    );

    return data;
  }

  void _putIfMissingOrBlank(
    Map<String, dynamic> data, {
    required Map<String, dynamic> existing,
    required String key,
    required String? nextValue,
  }) {
    final normalized = _normalizedOptionalText(nextValue);
    final current = _normalizedOptionalText(existing[key]);
    if (current == null && normalized != null) {
      data[key] = normalized;
    }
  }

  void _putIfProvidedAndMissingOrBlank(
    Map<String, dynamic> data, {
    required Map<String, dynamic> existing,
    required String key,
    required String? nextValue,
  }) {
    if (nextValue == null) {
      return;
    }
    _putIfMissingOrBlank(
      data,
      existing: existing,
      key: key,
      nextValue: nextValue,
    );
  }

  String _resolvedText(String? primary, String? fallback) {
    final primaryText = _normalizedOptionalText(primary);
    if (primaryText != null) {
      return primaryText;
    }
    return _normalizedOptionalText(fallback) ?? '';
  }

  String? _normalizedOptionalText(Object? value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty) {
      return null;
    }
    return text;
  }
}
