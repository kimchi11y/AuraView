import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../services/tmdb_api/tmdb_service.dart';
import '../../services/tmdb_api/movie_model.dart';
import '../../services/swipe_service.dart';
import '../../widgets/match_overlay.dart';
import '../shared_matches_screen.dart';
import 'filter_bottom_sheet.dart';

class DiscoverScreen extends StatefulWidget {
  final String? friendId;
  final String? friendName;

  const DiscoverScreen({super.key, this.friendId, this.friendName});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final TmdbService _tmdbService = TmdbService();
  final SwipeService _swipeService = SwipeService();

  List<Movie> _movies = [];
  bool _isLoading = true;
  int _currentPage = 1;

  String _userAvatarUrl = '';
  String _friendAvatarUrl = '';

  @override
  void initState() {
    super.initState();
    _fetchMovies();
    _loadAvatars();
  }

  Future<void> _loadAvatars() async {
    if (widget.friendId == null) return;

    final db = FirebaseFirestore.instance;
    final currentUid = FirebaseAuth.instance.currentUser!.uid;

    final results = await Future.wait([
      db.collection('users').doc(currentUid).get(),
      db.collection('users').doc(widget.friendId!).get(),
    ]);

    if (mounted) {
      setState(() {
        _userAvatarUrl = results[0].data()?['avatarUrl'] as String? ?? '';
        _friendAvatarUrl = results[1].data()?['avatarUrl'] as String? ?? '';
      });
    }
  }

  Future<void> _fetchMovies({
    String? genre,
    String? year,
    double rating = 0.0,
  }) async {
    setState(() => _isLoading = true);
    try {
      final movies = await _tmdbService.fetchAndCacheMovies(
        page: _currentPage,
        genreId: genre,
        year: year,
        minRating: rating,
      );
      if (mounted) {
        setState(() {
          _movies.addAll(movies);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _handleSwipe(bool isLike) async {
    if (_movies.isEmpty) return;

    final movie = _movies.first;

    if (isLike) {
      if (widget.friendId != null) {
        final result = await _swipeService.swipeRight(
          userId: FirebaseAuth.instance.currentUser!.uid,
          friendId: widget.friendId!,
          movieId: movie.id,
        );

        if (result.matched && mounted) {
          MatchOverlay.show(
            context: context,
            friendName: widget.friendName!,
            friendAvatarUrl: _friendAvatarUrl,
            userAvatarUrl: _userAvatarUrl,
            movieTitle: movie.title,
            moviePosterUrl: movie.posterUrl,
            onKeepSwiping: () {},
            onViewMatches: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SharedMatchesScreen(
                    friendId: widget.friendId!,
                    friendName: widget.friendName!,
                  ),
                ),
              );
            },
          );
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Liked ${movie.title}!'),
            duration: const Duration(milliseconds: 500),
          ),
        );
      }
    } else {
      if (widget.friendId != null) {
        _swipeService.swipeLeft(
          userId: FirebaseAuth.instance.currentUser!.uid,
          movieId: movie.id,
        );
      }
    }

    setState(() {
      _movies.removeAt(0); // Remove the card from the deck
    });

    // Infinite Pagination Trigger: Fetch more when deck gets low
    if (_movies.length < 5) {
      _currentPage++;
      _fetchMovies();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: widget.friendId != null,
        title: const Text(
          'Discover',
          style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: AppColors.text),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => FilterBottomSheet(
                  onApply: (genre, year, rating) {
                    setState(() {
                      _movies.clear();
                      _currentPage = 1;
                    });
                    _fetchMovies(genre: genre, year: year, rating: rating);
                  },
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading && _movies.isEmpty
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : _movies.isEmpty
            ? const Center(
                child: Text(
                  'No more movies found.',
                  style: TextStyle(color: AppColors.mutedText),
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // The Movie Card
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          image: DecorationImage(
                            image: NetworkImage(_movies.first.posterUrl),
                            fit: BoxFit.cover,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.8),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                          padding: const EdgeInsets.all(24),
                          alignment: Alignment.bottomLeft,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _movies.first.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${_movies.first.year} • ★ ${_movies.first.rating}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // The Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        FloatingActionButton(
                          heroTag: 'pass',
                          backgroundColor: Colors.white,
                          onPressed: () => _handleSwipe(false),
                          child: const Icon(
                            Icons.close,
                            color: Colors.red,
                            size: 32,
                          ),
                        ),
                        FloatingActionButton(
                          heroTag: 'like',
                          backgroundColor: AppColors.primary,
                          onPressed: () => _handleSwipe(true),
                          child: const Icon(
                            Icons.favorite,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
