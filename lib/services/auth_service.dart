import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Stream<User?> authState() => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;
  Future<void> signOut() => _auth.signOut();

  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String username,
  }) async {
    final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // 1) Auth profiline yaz
    await cred.user!.updateDisplayName(username);
    await cred.user!.reload();

    // 2) users/{uid} belgesine yaz
    await FirebaseFirestore.instance
        .collection('users')
        .doc(cred.user!.uid)
        .set({
          'email': email,
          'displayName': username,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  Future<void> signInWithEmail(String email, String password) async {
    final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Auth.displayName boşsa users/{uid}.displayName’den doldur
    final u = cred.user!;
    if ((u.displayName ?? '').trim().isEmpty) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(u.uid)
          .get();
      final dn = (doc.data()?['displayName'] as String?)?.trim();
      if (dn != null && dn.isNotEmpty) {
        await u.updateDisplayName(dn);
        await u.reload();
      }
    }
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
