import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/auth_card.dart';

class SharedMatchesScreen extends StatelessWidget {
  final String friendName;

  const SharedMatchesScreen({super.key, required this.friendName});

  static const List<Map<String, String>> _dummyMovies = [
    {'title': 'Blade Runner 2049', 'year': '2017', 'genre': 'Sci-Fi'},
    {'title': 'Dune', 'year': '2021', 'genre': 'Sci-Fi'},
    {'title': 'Interstellar', 'year': '2014', 'genre': 'Drama'},
    {'title': 'The Batman', 'year': '2022', 'genre': 'Action'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.text),
        title: Text(
          friendName,
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
            child: ListView.separated(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _dummyMovies.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final movie = _dummyMovies[index];
                return _MovieCard(
                  title: movie['title']!,
                  year: movie['year']!,
                  genre: movie['genre']!,
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
  final String genre;

  const _MovieCard({
    required this.title,
    required this.year,
    required this.genre,
  });

  @override
  Widget build(BuildContext context) {
    return AuthCard(
      child: Row(
        children: [
          // Poster placeholder
          Container(
            width: 75,
            height: 110,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.movie,
              size: 32,
              color: AppColors.mutedText,
            ),
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
                  '$year • $genre',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.mutedText,
                  ),
                ),

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
}
