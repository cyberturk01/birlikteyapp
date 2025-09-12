import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> authState() => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<void> signOut() => _auth.signOut();

  Future<UserCredential> signInWithEmail(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> signUpWithEmail(String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    // İstersen e-posta doğrulaması:
    await cred.user?.sendEmailVerification();
    return cred;
  }

  Future<void> sendResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }
}
