import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Stream<User?> authState() => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;
  Future<void> signOut() => _auth.signOut();

  Future<UserCredential> signInWithEmail(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _upsertUserDoc(cred.user); // 🔔 login’de de yaz/merge
    return cred;
  }

  Future<UserCredential> signUpWithEmail(String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = cred.user!.uid;
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'email': email,
      'displayName': email.split('@').first,
      'families': <String>[], // 👈 boş dizi
      'activeFamilyId': null, // 👈 açıkça null
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // (opsiyonel) doğrulama
    await cred.user?.sendEmailVerification();
    return cred;
  }

  Future<void> sendResetEmail(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  Future<void> _upsertUserDoc(User? u) async {
    if (u == null) return;
    final email = u.email ?? '';
    final display = (u.displayName?.trim().isNotEmpty == true)
        ? u.displayName!.trim()
        : (email.contains('@') ? email.split('@').first : email);

    await FirebaseFirestore.instance.collection('users').doc(u.uid).set({
      'email': email,
      'displayName': display,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
