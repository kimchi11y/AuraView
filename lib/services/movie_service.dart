import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/fake_movies.dart';
import '../models/movie.dart';

class MovieService {
  static bool useFakeData = false;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<Movie>> fetchMovies({
    List<String>? excludeIds,
    int limit = 10,
    DocumentSnapshot? startAfter,
    required String friendId,
    required String userId,
  }) async {
    if (useFakeData) {
      return _fetchFakeMovies(excludeIds: excludeIds, limit: limit);
    }

    var query = _db.collection('movies_cache').limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.get();

    final movies = snapshot.docs.map((doc) {
      return Movie.fromFirestore(doc.id, doc.data());
    }).toList();

    if (excludeIds != null && excludeIds.isNotEmpty) {
      movies.removeWhere((m) => excludeIds.contains(m.id));
    }

    return movies;
  }

  Future<Set<String>> getSwipedMovieIds(String userId) async {
    final snapshot = await _db
        .collection('swipes')
        .where('fromUserId', isEqualTo: userId)
        .get();

    return snapshot.docs
        .map((doc) => doc['movieId'] as String)
        .toSet();
  }

  List<Movie> _fetchFakeMovies({
    List<String>? excludeIds,
    int limit = 10,
  }) {
    final excludeSet = excludeIds?.toSet() ?? {};
    final available = fakeMovies
        .where((m) => !excludeSet.contains(m.id))
        .toList();

    available.shuffle(Random());

    return available.take(limit).toList();
  }
}
