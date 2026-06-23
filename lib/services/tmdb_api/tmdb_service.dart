import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'movie_model.dart';

class TmdbService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // TODO: Replace this string with your actual TMDB API Key from your developer account
  static const String _apiKey = 'eaca3a41db4ec2be0460469d94b7f134';
  static const String _baseUrl = 'https://api.themoviedb.org/3';

  Future<List<Movie>> fetchAndCacheMovies({
    int page = 1,
    String? genreId,
    String? year,
    double? minRating,
  }) async {
    // Base URL
    String query =
        '$_baseUrl/discover/movie?api_key=$_apiKey&page=$page&sort_by=popularity.desc';

    // Append filters if they exist
    if (genreId != null && genreId.isNotEmpty) {
      query += '&with_genres=$genreId';
    }
    if (year != null && year.isNotEmpty) {
      query += '&primary_release_year=$year';
    }
    if (minRating != null && minRating > 0) {
      query += '&vote_average.gte=$minRating';
    }

    final url = Uri.parse(query);

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> results = data['results'];

        List<Movie> movies = results
            .map((json) => Movie.fromJson(json))
            .toList();

        final batch = _db.batch();
        for (var movie in movies) {
          final docRef = _db.collection('movies_cache').doc(movie.id);
          batch.set(docRef, movie.toMap(), SetOptions(merge: true));
        }
        await batch.commit();

        return movies;
      } else {
        throw Exception(
          'Failed to load movies. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
