import 'package:cloud_firestore/cloud_firestore.dart';

class Swipe {
  final String fromUserId;
  final String movieId;
  final bool liked;
  final DateTime? swipedAt;

  const Swipe({
    required this.fromUserId,
    required this.movieId,
    required this.liked,
    this.swipedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'fromUserId': fromUserId,
      'movieId': movieId,
      'liked': liked,
      'swipedAt': FieldValue.serverTimestamp(),
    };
  }
}
