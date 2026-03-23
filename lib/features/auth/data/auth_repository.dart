import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthRepository {
  AuthRepository({
    FirebaseAuth? auth,
    String? googleClientId,
    String? googleServerClientId,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _googleClientId = (googleClientId ?? '').trim(),
        _googleServerClientId = (googleServerClientId ?? '').trim();

  final FirebaseAuth _auth;
  final String _googleClientId;
  final String _googleServerClientId;

  static Future<void>? _googleInitFuture;
  PendingUserProfileSeed? _pendingUserProfileSeed;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
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

      _pendingUserProfileSeed = PendingUserProfileSeed(
        uid: user.uid,
        nickname: (nickname ?? '').trim(),
        fullName: (fullName ?? '').trim(),
        gender: (gender ?? '').trim(),
        birthDate: (birthDate ?? '').trim(),
        phoneNumber: (phoneNumber ?? '').trim(),
      );
    }

    return credential;
  }

  Future<UserCredential> signInWithGoogle() async {
    if (kIsWeb) {
      final provider = GoogleAuthProvider();
      return _auth.signInWithPopup(provider);
    }

    await _ensureGoogleInitialized();

    final GoogleSignInAccount googleUser =
        await GoogleSignIn.instance.authenticate();

    final GoogleSignInAuthentication googleAuth = googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    return _auth.signInWithCredential(credential);
  }

  PendingUserProfileSeed? takePendingUserProfileSeed(String uid) {
    final seed = _pendingUserProfileSeed;
    if (seed == null || seed.uid != uid) {
      return null;
    }

    _pendingUserProfileSeed = null;
    return seed;
  }

  Future<void> signOut() async {
    _pendingUserProfileSeed = null;
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
}

class PendingUserProfileSeed {
  const PendingUserProfileSeed({
    required this.uid,
    required this.nickname,
    required this.fullName,
    required this.gender,
    required this.birthDate,
    required this.phoneNumber,
  });

  final String uid;
  final String nickname;
  final String fullName;
  final String gender;
  final String birthDate;
  final String phoneNumber;
}
