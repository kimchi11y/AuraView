class Movie {
  final String id;
  final String title;
  final String posterUrl;
  final String year;
  final double rating;
  final String genres;

  Movie({
    required this.id,
    required this.title,
    required this.posterUrl,
    required this.year,
    required this.rating,
    required this.genres,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    // TMDB returns poster paths as partial strings, so we build the full URL
    final String partialPath = json['poster_path'] ?? '';
    final String fullPosterUrl = partialPath.isNotEmpty
        ? 'https://image.tmdb.org/t/p/w500$partialPath'
        : '';

    // Extract just the year from the release date (e.g., "2024-05-12" -> "2024")
    final String releaseDate = json['release_date'] ?? '';
    final String year = releaseDate.length >= 4
        ? releaseDate.substring(0, 4)
        : '';

    return Movie(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? 'Unknown Title',
      posterUrl: fullPosterUrl,
      year: year,
      // Safely parse the rating whether it arrives as an int or double
      rating: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      genres:
          'Action', // Can be updated later with a TMDB genre mapping function
    );
  }

  // Helper method to convert the Dart object into a Map for Firestore uploading
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'posterUrl': posterUrl,
      'year': year,
      'rating': rating,
      'genres': genres,
      'cachedAt': DateTime.now().toIso8601String(),
    };
  }
}
