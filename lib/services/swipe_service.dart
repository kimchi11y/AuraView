import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/match.dart';
import '../models/swipe.dart';

class SwipeService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<MatchResult> swipeRight({
    required String userId,
    required String friendId,
    required String movieId,
  }) async {
    await _db.collection('swipes').add(
      Swipe(
        fromUserId: userId,
        movieId: movieId,
        liked: true,
      ).toMap(),
    );

    final friendSwipe = await _db
        .collection('swipes')
        .where('fromUserId', isEqualTo: friendId)
        .where('movieId', isEqualTo: movieId)
        .where('liked', isEqualTo: true)
        .limit(1)
        .get();

    if (friendSwipe.docs.isNotEmpty) {
      final userAId = userId.compareTo(friendId) < 0 ? userId : friendId;
      final userBId = userId.compareTo(friendId) < 0 ? friendId : userId;

      final existing = await _db
          .collection('matches')
          .where('userAId', isEqualTo: userAId)
          .where('userBId', isEqualTo: userBId)
          .where('movieId', isEqualTo: movieId)
          .limit(1)
          .get();

      if (existing.docs.isEmpty) {
        await _db.collection('matches').add(
          Match(
            userAId: userAId,
            userBId: userBId,
            movieId: movieId,
          ).toMap(),
        );
      }

      return MatchResult(matched: true, movieId: movieId);
    }

    return MatchResult(matched: false, movieId: movieId);
  }

  Future<void> swipeLeft({
    required String userId,
    required String movieId,
  }) async {
    await _db.collection('swipes').add(
      Swipe(
        fromUserId: userId,
        movieId: movieId,
        liked: false,
      ).toMap(),
    );
  }
}

class MatchResult {
  final bool matched;
  final String movieId;

  const MatchResult({
    required this.matched,
    required this.movieId,
  });
}
