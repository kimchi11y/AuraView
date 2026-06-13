import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProfileService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<DocumentSnapshot<Map<String, dynamic>>> getUserProfile(String uid) {
    return _db.collection('users').doc(uid).get();
  }

  Future<void> updateUserProfile({
  required String uid,
  required String displayName,
  required String username,
  required String bio,
  required String avatarUrl,
}) async {
  final usernameLower = username.trim().toLowerCase();

  final usernameCheck = await _db
      .collection('users')
      .where('usernameLower', isEqualTo: usernameLower)
      .limit(1)
      .get();

  if (usernameCheck.docs.isNotEmpty && usernameCheck.docs.first.id != uid) {
    throw Exception('Username already exists');
  }

  await _db.collection('users').doc(uid).update({
    'displayName': displayName.trim(),
    'username': username.trim(),
    'usernameLower': usernameLower,
    'bio': bio.trim(),
    'avatarUrl': avatarUrl.trim(),
    'updatedAt': FieldValue.serverTimestamp(),
  });
}

  Future<String> uploadAvatar({
    required String uid,
    required File imageFile,
  }) async {
    final ref = _storage.ref().child('avatars/$uid/profile.jpg');

    await ref.putFile(imageFile);

    final downloadUrl = await ref.getDownloadURL();

    await _db.collection('users').doc(uid).update({
      'avatarUrl': downloadUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return downloadUrl;
  }
}