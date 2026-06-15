import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/movie.dart';
import '../services/movie_service.dart';
import '../services/swipe_service.dart';
import '../services/friend_service.dart';
import '../theme/app_theme.dart';
import '../theme/social_colors.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../widgets/swipe_card.dart';
import '../widgets/match_overlay.dart';
import 'friends_screen.dart';
import 'profile_screen.dart';
import 'shared_matches_screen.dart';

class DiscoverScreen extends StatefulWidget {
  final String? friendId;
  final String? friendName;

  const DiscoverScreen({
    super.key,
    this.friendId,
    this.friendName,
  });

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final MovieService _movieService = MovieService();
  final SwipeService _swipeService = SwipeService();
  final FriendService _friendService = FriendService();
  final String _userId = FirebaseAuth.instance.currentUser!.uid;

  String? _activeFriendId;
  String? _activeFriendName;
  String? _userAvatarUrl;

  List<Movie> _movies = [];
  bool _isLoadingMovies = false;
  bool _isLoadingInitial = true;
  Set<String> _swipedMovieIds = {};
  bool _fakeMode = true;

  @override
  void initState() {
    super.initState();
    MovieService.useFakeData = _fakeMode;
    if (widget.friendId != null) {
      _activeFriendId = widget.friendId;
      _activeFriendName = widget.friendName ?? 'Friend';
      _loadUserAndMovies();
    } else {
      _isLoadingInitial = false;
    }
  }

  Future<void> _loadUserAndMovies() async {
    setState(() => _isLoadingInitial = true);

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .get();
    if (mounted) {
      setState(() {
        _userAvatarUrl = userDoc.data()?['avatarUrl'] as String? ?? '';
      });
    }

    await _loadMovies();
    if (mounted) {
      setState(() => _isLoadingInitial = false);
    }
  }

  Future<void> _loadMovies() async {
    if (_activeFriendId == null) return;

    setState(() => _isLoadingMovies = true);

    final swipedIds = await _movieService.getSwipedMovieIds(_userId);
    final movies = await _movieService.fetchMovies(
      excludeIds: swipedIds.toList(),
      limit: 10,
      userId: _userId,
      friendId: _activeFriendId!,
    );

    if (mounted) {
      setState(() {
        _swipedMovieIds = swipedIds;
        _movies = movies;
        _isLoadingMovies = false;
      });
    }
  }

  void _selectFriend(String friendId, String friendName) {
    setState(() {
      _activeFriendId = friendId;
      _activeFriendName = friendName;
    });
    _loadUserAndMovies();
  }

  Future<void> _onSwipeRight(Movie movie) async {
    final result = await _swipeService.swipeRight(
      userId: _userId,
      friendId: _activeFriendId!,
      movieId: movie.id,
    );

    _removeTopCard();

    if (result.matched && mounted) {
      _showMatchOverlay(
        friendName: _activeFriendName!,
        movieTitle: movie.title,
        moviePosterUrl: movie.posterUrl,
        friendAvatarUrl: await _fetchFriendAvatar(_activeFriendId!),
      );
    }
  }

  Future<void> _onSwipeLeft(Movie movie) async {
    await _swipeService.swipeLeft(
      userId: _userId,
      movieId: movie.id,
    );
    _removeTopCard();
  }

  void _removeTopCard() {
    if (_movies.isEmpty) return;

    setState(() {
      _movies.removeAt(0);
    });

    if (_movies.length < 3) {
      _preloadMore();
    }
  }

  Future<void> _preloadMore() async {
    if (_activeFriendId == null || _isLoadingMovies) return;

    setState(() => _isLoadingMovies = true);

    final newMovies = await _movieService.fetchMovies(
      excludeIds: [
        ..._swipedMovieIds,
        ..._movies.map((m) => m.id),
      ],
      limit: 10,
      userId: _userId,
      friendId: _activeFriendId!,
    );

    if (mounted) {
      setState(() {
        _movies.addAll(newMovies);
        _isLoadingMovies = false;
      });
    }
  }

  void _toggleFakeMode() {
    setState(() {
      _fakeMode = !_fakeMode;
      MovieService.useFakeData = _fakeMode;
    });
    _loadMovies();
  }

  Future<String> _fetchFriendAvatar(String friendId) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(friendId)
        .get();
    return doc.data()?['avatarUrl'] as String? ?? '';
  }

  void _showMatchOverlay({
    required String friendName,
    required String movieTitle,
    required String moviePosterUrl,
    required String friendAvatarUrl,
  }) {
    MatchOverlay.show(
      context: context,
      friendName: friendName,
      friendAvatarUrl: friendAvatarUrl,
      userAvatarUrl: _userAvatarUrl ?? '',
      movieTitle: movieTitle,
      moviePosterUrl: moviePosterUrl,
      onKeepSwiping: () {},
      onViewMatches: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SharedMatchesScreen(
              friendId: _activeFriendId!,
              friendName: _activeFriendName!,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          _activeFriendName != null
              ? 'Swiping with @$_activeFriendName'
              : 'Discover',
          style: const TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _fakeMode ? Icons.science : Icons.science_outlined,
              color: _fakeMode ? AppColors.primary : AppColors.mutedText,
            ),
            tooltip: _fakeMode ? 'Fake data ON' : 'Fake data OFF',
            onPressed: _toggleFakeMode,
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 0) return;
          if (index == 1) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Matches screen not ready yet')),
            );
            return;
          }
          if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const FriendsScreen()),
            );
            return;
          }
          if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            );
            return;
          }
        },
      ),
      body: _activeFriendId == null ? _buildFriendPicker() : _buildSwipeDeck(),
    );
  }

  Widget _buildFriendPicker() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _friendService.getFriends(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        final currentUid = _userId;

        final friendIds = docs.map((doc) {
          final data = doc.data();
          return data['userAId'] == currentUid
              ? data['userBId'] as String
              : data['userAId'] as String;
        }).toList();

        if (friendIds.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.group_outlined,
                    size: 48, color: AppColors.mutedText),
                const SizedBox(height: 12),
                const Text(
                  'No friends yet',
                  style: TextStyle(fontSize: 16, color: AppColors.text),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Add friends to start swiping on movies together',
                  style: TextStyle(fontSize: 13, color: AppColors.mutedText),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: friendIds.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _FriendPickerTile(
                friendId: friendIds[index],
                onTap: (name) =>
                    _selectFriend(friendIds[index], name),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSwipeDeck() {
    if (_isLoadingInitial) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_movies.isEmpty && !_isLoadingMovies) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.movie_outlined,
                size: 48, color: AppColors.mutedText),
            const SizedBox(height: 12),
            const Text(
              'No more movies',
              style: TextStyle(fontSize: 16, color: AppColors.text),
            ),
            const SizedBox(height: 4),
            const Text(
              'Check back later for new suggestions',
              style: TextStyle(fontSize: 13, color: AppColors.mutedText),
            ),
          ],
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        // Background cards (peeking behind)
        for (int i = _movies.length - 1; i > 0 && i >= 0; i--)
          if (i > 0 && i < _movies.length)
            Positioned(
              top: 24 + (i * 12.0),
              child: IgnorePointer(
                ignoring: i > 0,
                child: Transform.scale(
                  scale: 1.0 - (i * 0.04),
                    child: SwipeCard(
                      movie: _movies[i],
                      onSwipeRight: (_) {},
                      onSwipeLeft: (_) {},
                      isTopCard: false,
                    ),
                ),
              ),
            ),

        // Top card
        if (_movies.isNotEmpty)
          Positioned(
            top: 24,
            child: SwipeCard(
              movie: _movies[0],
              onSwipeRight: (m) => _onSwipeRight(m),
              onSwipeLeft: (m) => _onSwipeLeft(m),
              isTopCard: true,
            ),
          ),

        if (_isLoadingMovies)
          const Positioned(
            bottom: 40,
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 2,
            ),
          ),
      ],
    );
  }
}

class _FriendPickerTile extends StatefulWidget {
  final String friendId;
  final void Function(String name) onTap;

  const _FriendPickerTile({
    required this.friendId,
    required this.onTap,
  });

  @override
  State<_FriendPickerTile> createState() => _FriendPickerTileState();
}

class _FriendPickerTileState extends State<_FriendPickerTile> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.friendId)
        .get();
    if (mounted) {
      setState(() {
        _userData = doc.data();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (_userData == null) return const SizedBox.shrink();

    final username = _userData!['username'] as String? ?? '';
    final displayName = _userData!['displayName'] as String? ?? '';
    final avatarUrl = _userData!['avatarUrl'] as String? ?? '';

    return GestureDetector(
      onTap: () => widget.onTap(username),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              offset: const Offset(0, 2),
              blurRadius: 4,
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.text,
              backgroundImage:
                  avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
              child: avatarUrl.isEmpty
                  ? const Icon(Icons.person, size: 24, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  Text(
                    '@$username',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.mutedText,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: SocialColors.matchAccent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'SWIPE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

