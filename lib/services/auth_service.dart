import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> signUp({
    required String email,
    required String password,
    required String username,
    required String displayName,
  }) async {
    final usernameLower = username.trim().toLowerCase();

    final usernameCheck = await _db
        .collection('users')
        .where('usernameLower', isEqualTo: usernameLower)
        .limit(1)
        .get();

    if (usernameCheck.docs.isNotEmpty) {
      throw Exception('Username already exists');
    }

    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final uid = credential.user!.uid;

    await _db.collection('users').doc(uid).set({
      'uid': uid,
      'username': username.trim(),
      'usernameLower': usernameLower,
      'email': email.trim(),
      'displayName': displayName.trim(),
      'avatarUrl': '',
      'bio': '',
      'fcmTokens': [],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}