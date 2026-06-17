import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _loading = false;
  String? _error;
  bool isAdmin = false;
  String? _displayName;

  String? get displayName => _displayName;
  String? get currentUid => _auth.currentUser?.uid;
  String? get currentEmail => _auth.currentUser?.email;
  bool get loading => _loading;
  String? get error => _error;
  bool get isLoggedIn => _auth.currentUser != null;

  AuthProvider() {
    _auth.authStateChanges().listen((user) async {
      if (user == null) {
        isAdmin = false;
        _displayName = null;
        notifyListeners();
      } else {
        await _loadUserData(user.uid);
      }
    });
  }

  Future<void> _loadUserData(String uid) async { 
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      final data = doc.data() as Map<String, dynamic>?;
      isAdmin = data?['isAdmin'] ?? false;
      _displayName = data?['name'] ?? '';
    } catch (_) {
      isAdmin = false;
    }
    notifyListeners();
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'wrong-password': return 'Incorrect password';
      case 'user-not-found': return 'No user found with this email';
      case 'email-already-in-use': return 'Email already in use';
      default: return 'An unexpected error occurred';
    }
  }

  Future<bool> signUp(String name, String email, String password) async {
    try {
      _setLoading(true);
      _error = null;
      UserCredential userCred = await _auth.createUserWithEmailAndPassword(
        email: email, password: password,
      );
      await _firestore.collection('users').doc(userCred.user!.uid).set({
        'name': name, 'email': email, 'isAdmin': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _displayName = name;
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _friendlyError(e.code);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signIn(String email, String password) async {
    try {
      _setLoading(true);
      _error = null;
      UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: email, password: password,
      );

      await _loadUserData(cred.user!.uid);
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _friendlyError(e.code);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> refreshProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _loadUserData(uid);
  }
}