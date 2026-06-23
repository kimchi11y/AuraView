import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';
import '../../services/tmdb_api/tmdb_service.dart';
import '../../services/tmdb_api/movie_model.dart';
import '../../services/swipe_service.dart';
import '../../widgets/match_overlay.dart';
import '../shared_matches_screen.dart';
import 'filter_bottom_sheet.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';

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

  final List<Movie> _movies = [];
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

  Future<bool> _onSwipe(
    int previousIndex,
    int? currentIndex,
    CardSwiperDirection direction,
  ) async {
    final movie = _movies[previousIndex];

    if (direction == CardSwiperDirection.right) {
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
    } else {
      if (widget.friendId != null) {
        _swipeService.swipeLeft(
          userId: FirebaseAuth.instance.currentUser!.uid,
          movieId: movie.id,
        );
      }
    }

    if (currentIndex != null && _movies.length - currentIndex < 5) {
      _currentPage++;
      _fetchMovies();
    }

    return true;
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
                : CardSwiper(
                    cardsCount: _movies.length,
                    cardBuilder: (
                      context,
                      index,
                      percentThresholdX,
                      percentThresholdY,
                    ) {
                      final movie = _movies[index];
                      final swipeProgress =
                          percentThresholdX.clamp(-1.0, 1.0).toDouble();
                      final isSwipingRight = swipeProgress > 0;
                      final isSwipingLeft = swipeProgress < 0;
                      final absProgress = swipeProgress.abs();
                      final rotation = swipeProgress * 0.05;

                      return Transform.rotate(
                        angle: rotation,
                        child: Stack(
                          children: [
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                image: DecorationImage(
                                  image: NetworkImage(movie.posterUrl),
                                  fit: BoxFit.cover,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                                border: absProgress > 0.1
                                    ? Border.all(
                                        color: (isSwipingRight
                                                ? const Color(0xFF22C55E)
                                                : AppColors.error)
                                            .withValues(alpha: absProgress),
                                        width: 4 * absProgress,
                                      )
                                    : null,
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.8),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                                padding: const EdgeInsets.all(24),
                                alignment: Alignment.bottomLeft,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      movie.title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${movie.year}  \u2022  \u2605 ${movie.rating}',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (isSwipingRight && absProgress > 0.1)
                              Positioned(
                                top: 32,
                                right: 24,
                                child: Opacity(
                                  opacity: absProgress,
                                  child: Transform.scale(
                                    scale: 0.5 + (absProgress * 1.5),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF22C55E),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 3,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.favorite,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'LIKE',
                                            style: GoogleFonts.inter(
                                              color: Colors.white,
                                              fontSize: 28,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            if (isSwipingLeft && absProgress > 0.1)
                              Positioned(
                                top: 32,
                                left: 24,
                                child: Opacity(
                                  opacity: absProgress,
                                  child: Transform.scale(
                                    scale: 0.5 + (absProgress * 1.5),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.error,
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 3,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 28,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'NOPE',
                                            style: GoogleFonts.inter(
                                              color: Colors.white,
                                              fontSize: 28,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                    onSwipe: _onSwipe,
                    onEnd: () {
                      if (_movies.isNotEmpty) {
                        _currentPage++;
                        _fetchMovies();
                      }
                    },
                    allowedSwipeDirection:
                        AllowedSwipeDirection.symmetric(horizontal: true),
                    isLoop: false,
                    numberOfCardsDisplayed: 2,
                    padding: const EdgeInsets.all(24),
                  ),
      ),
    );
  }
}
