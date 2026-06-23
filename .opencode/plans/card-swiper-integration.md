# Plan: Replace Like/Dislike Buttons with flutter_card_swiper

## Overview
Replace the static movie card + FAB like/dislike buttons in `discover_screen.dart` with the `flutter_card_swiper` package's `CardSwiper` widget for Tinder-style swipe interactions.

---

## Step 1: Add dependency to pubspec.yaml

**File:** `pubspec.yaml`  
**Line:** After `http: ^1.6.0` (line 43)  
**Add:**
```yaml
  flutter_card_swiper: ^7.2.0
```

Then run:
```bash
flutter pub get
```

---

## Step 2: Rewrite discover_screen.dart

**File:** `lib/screens/movie_swipe/discover_screen.dart`

### 2a: Add import (after line 11)
Add after the `filter_bottom_sheet.dart` import:
```dart
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
```

### 2b: Delete the `_handleSwipe` method (lines 92–154)
Replace with `_onSwipe`:
```dart
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

    if (currentIndex != null && _movies.length - currentIndex < 5) {
      _currentPage++;
      _fetchMovies();
    }

    return true;
  }
```

### 2c: Replace the body's card + buttons section (lines 202–292)

**Replace** the `Padding` block (lines 202–292) — the entire `Padding` child containing `Column` with `Expanded` card + `Row` buttons — **with**:

```dart
            : Expanded(
                child: _movies.isEmpty
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
                          return Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              image: DecorationImage(
                                image: NetworkImage(movie.posterUrl),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 24,
                        ),
                      ),
              ),
```

### 2d: The final build method (lines 190–293 after the change)
The `body: SafeArea(...)` becomes:
```
SafeArea(
  child: _isLoading && _movies.isEmpty
      ? CircularProgressIndicator
      : Expanded(child: _movies.isEmpty
          ? Text('No more movies found.')
          : CardSwiper(...)),
)
```

Wait — that's wrong because `Expanded` can't be a direct child of `SafeArea`. The full structure should be:

```dart
body: SafeArea(
  child: _isLoading && _movies.isEmpty
      ? const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        )
      : _movies.isEmpty && !_isLoading
          ? const Center(
              child: Text(
                'No more movies found.',
                style: TextStyle(color: AppColors.mutedText),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: CardSwiper(
                cardsCount: _movies.length,
                cardBuilder: ... (same as above),
                onSwipe: _onSwipe,
                onEnd: ...,
                allowedSwipeDirection:
                    AllowedSwipeDirection.symmetric(horizontal: true),
                isLoop: false,
                numberOfCardsDisplayed: 2,
                padding: EdgeInsets.zero,
              ),
            ),
),
```

---

## Step 3: Verify
```bash
flutter pub get
flutter analyze lib/screens/movie_swipe/discover_screen.dart
```
