import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/match.dart';
import '../models/swipe.dart';

class SwipeService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<MatchResult> swipeRight({
    required String userId,
    required String friendId,
    required String movieId,
  }) async {
    try {
      await _db.collection('swipes').add(
        Swipe(
          fromUserId: userId,
          movieId: movieId,
          liked: true,
        ).toMap(),
      );
    } catch (e) {
      debugPrint('SwipeService: Failed to write swipe: $e');
      return MatchResult(matched: false, movieId: movieId);
    }

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
        try {
          await _db.collection('matches').add(
            Match(
              userAId: userAId,
              userBId: userBId,
              movieId: movieId,
            ).toMap(),
          );
          debugPrint('SwipeService: Match created for movie $movieId');
        } catch (e) {
          debugPrint('SwipeService: Failed to create match: $e');
        }
      }

      return MatchResult(matched: true, movieId: movieId);
    }

    return MatchResult(matched: false, movieId: movieId);
  }

  Future<void> swipeLeft({
    required String userId,
    required String movieId,
  }) async {
    try {
      await _db.collection('swipes').add(
        Swipe(
          fromUserId: userId,
          movieId: movieId,
          liked: false,
        ).toMap(),
      );
    } catch (e) {
      debugPrint('SwipeService: Failed to write swipe: $e');
    }
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
