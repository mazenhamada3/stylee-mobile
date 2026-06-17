import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db   = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signIn(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  Future<UserCredential> signUp(String name, String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email, password: password,
    );
    await cred.user?.updateDisplayName(name);
    await _db.collection('users').doc(cred.user!.uid).set({
      'name': name,
      'email': email,
      'address': '14 Gamal Abdel Nasser St., Cairo, Egypt 21500',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return cred;
  }

  Future<void> signOut() => _auth.signOut();
}
