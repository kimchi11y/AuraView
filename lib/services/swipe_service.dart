import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SwipeService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> swipeRight(String movieId) async {
    final currentUid = _auth.currentUser!.uid;

    // 1. Record that you liked this movie in a personal 'likes' collection
    await _db.collection('likes').doc('${currentUid}_$movieId').set({
      'userId': currentUid,
      'movieId': movieId,
      'likedAt': FieldValue.serverTimestamp(),
    });

    // 2. Fetch all of your current friends to check against
    final friendships = await _db
        .collection('friendships')
        .where(
          Filter.or(
            Filter('userAId', isEqualTo: currentUid),
            Filter('userBId', isEqualTo: currentUid),
          ),
        )
        .get();

    if (friendships.docs.isEmpty)
      return; // Skip matching if you have no friends yet

    List<String> friendIds = [];
    for (var doc in friendships.docs) {
      final data = doc.data();
      friendIds.add(
        data['userAId'] == currentUid ? data['userBId'] : data['userAId'],
      );
    }

    // 3. Cross-reference: Did any of your friends already like this movie?
    for (String friendId in friendIds) {
      final friendLike = await _db
          .collection('likes')
          .doc('${friendId}_$movieId')
          .get();

      if (friendLike.exists) {
        // IT IS A MATCH!
        // Write this directly to the 'matches' collection Aalep built
        final matchId = '${currentUid}_${friendId}_$movieId';

        await _db.collection('matches').doc(matchId).set({
          'userAId': currentUid,
          'userBId': friendId,
          'movieId': movieId,
          'matchedAt': FieldValue.serverTimestamp(),
        });
      }
    }
  }
}
