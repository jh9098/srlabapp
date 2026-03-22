import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthRepository {
  AuthRepository({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
    String? googleClientId,
    String? googleServerClientId,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn.instance,
        _googleClientId = googleClientId,
        _googleServerClientId = googleServerClientId;

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final String? _googleClientId;
  final String? _googleServerClientId;

  Stream<User?> authStateChanges() => _firebaseAuth.authStateChanges();

  User? get currentUser => _firebaseAuth.currentUser;

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    if ((displayName ?? '').trim().isNotEmpty) {
      await credential.user?.updateDisplayName(displayName!.trim());
    }
    return credential;
  }

  Future<UserCredential> signInWithGoogle() async {
    await _googleSignIn.initialize(
      clientId: (_googleClientId ?? '').isEmpty ? null : _googleClientId,
      serverClientId: (_googleServerClientId ?? '').isEmpty ? null : _googleServerClientId,
    );
    if (!_googleSignIn.supportsAuthenticate()) {
      throw UnsupportedError('현재 플랫폼에서는 Google authenticate()를 직접 지원하지 않습니다.');
    }
    final googleUser = await _googleSignIn.authenticate();
    final googleAuthentication = googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuthentication.accessToken,
      idToken: googleAuthentication.idToken,
    );
    return _firebaseAuth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    await Future.wait([
      _firebaseAuth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }
}
