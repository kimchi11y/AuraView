class Movie {
  final String id;
  final String title;
  final String year;
  final String genres;
  final String posterUrl;
  final double rating;

  const Movie({
    required this.id,
    required this.title,
    required this.year,
    required this.genres,
    required this.posterUrl,
    required this.rating,
  });

  factory Movie.fromFirestore(String id, Map<String, dynamic> data) {
    return Movie(
      id: id,
      title: data['title'] as String? ?? '',
      year: data['year']?.toString() ?? '',
      genres: data['genres'] as String? ?? '',
      posterUrl: data['posterUrl'] as String? ?? '',
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
