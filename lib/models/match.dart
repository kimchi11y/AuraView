import 'package:cloud_firestore/cloud_firestore.dart';

class Match {
  final String userAId;
  final String userBId;
  final String movieId;
  final DateTime? matchedAt;

  const Match({
    required this.userAId,
    required this.userBId,
    required this.movieId,
    this.matchedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userAId': userAId,
      'userBId': userBId,
      'movieId': movieId,
      'matchedAt': FieldValue.serverTimestamp(),
    };
  }
}
