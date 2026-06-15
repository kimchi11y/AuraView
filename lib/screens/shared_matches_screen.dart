import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/auth_card.dart';

class SharedMatchesScreen extends StatefulWidget {
  final String friendId;
  final String friendName;

  const SharedMatchesScreen({
    super.key,
    required this.friendId,
    required this.friendName,
  });

  @override
  State<SharedMatchesScreen> createState() => _SharedMatchesScreenState();
}

class _SharedMatchesScreenState extends State<SharedMatchesScreen> {
  late final Future<List<Map<String, dynamic>>> _matchesFuture;

  @override
  void initState() {
    super.initState();
    _matchesFuture = _fetchSharedMatches();
  }

  Future<List<Map<String, dynamic>>> _fetchSharedMatches() async {
    final db = FirebaseFirestore.instance;
    final currentUid = FirebaseAuth.instance.currentUser!.uid;

    // Two single-field queries to avoid composite index requirement.
    // Merged and filtered client-side.
    final results = await Future.wait([
      db.collection('matches').where('userAId', isEqualTo: currentUid).get(),
      db.collection('matches').where('userAId', isEqualTo: widget.friendId).get(),
    ]);

    final matchDocs = [
      ...results[0].docs.where((d) => d['userBId'] == widget.friendId),
      ...results[1].docs.where((d) => d['userBId'] == currentUid),
    ];

    if (matchDocs.isEmpty) return [];

    // Fetch movie details from movies_cache for each match.
    final movies = await Future.wait(
      matchDocs.map((doc) async {
        final movieId = doc['movieId'] as String;
        final movieDoc =
            await db.collection('movies_cache').doc(movieId).get();
        return movieDoc.data() ?? <String, dynamic>{};
      }),
    );

    return movies.where((m) => m.isNotEmpty).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.text),
        title: Text(
          widget.friendName,
          style: const TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              'Movies you both liked',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),

          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _matchesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading matches: ${snapshot.error}',
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                final movies = snapshot.data ?? [];

                if (movies.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.movie_outlined,
                          size: 48,
                          color: AppColors.mutedText,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'No shared matches yet',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.mutedText,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Start swiping to find movies you both like',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.mutedText,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: movies.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final movie = movies[index];
                    return _MovieCard(
                      title: movie['title'] as String? ?? 'Unknown',
                      year: movie['year']?.toString() ?? '',
                      genres: movie['genres'] as String? ?? '',
                      posterUrl: movie['posterUrl'] as String? ?? '',
                      rating: (movie['rating'] as num?)?.toDouble() ?? 0.0,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MovieCard extends StatelessWidget {
  final String title;
  final String year;
  final String genres;
  final String posterUrl;
  final double rating;

  const _MovieCard({
    required this.title,
    required this.year,
    required this.genres,
    required this.posterUrl,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return AuthCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Movie poster
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: posterUrl.isNotEmpty
                ? Image.network(
                    posterUrl,
                    width: 75,
                    height: 110,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) =>
                        _posterPlaceholder(),
                  )
                : _posterPlaceholder(),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  [if (year.isNotEmpty) year, if (genres.isNotEmpty) genres]
                      .join(' • '),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.mutedText,
                  ),
                ),

                if (rating > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.mutedText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 10),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'MATCHED',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _posterPlaceholder() {
    return Container(
      width: 75,
      height: 110,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.movie, size: 32, color: AppColors.mutedText),
    );
  }
}
