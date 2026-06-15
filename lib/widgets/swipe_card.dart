import 'package:flutter/material.dart';

import '../models/movie.dart';
import '../theme/app_theme.dart';

class SwipeCard extends StatefulWidget {
  final Movie movie;
  final VoidCallback onSwipeRight;
  final VoidCallback onSwipeLeft;
  final bool isTopCard;

  const SwipeCard({
    super.key,
    required this.movie,
    required this.onSwipeRight,
    required this.onSwipeLeft,
    this.isTopCard = true,
  });

  @override
  State<SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<SwipeCard>
    with SingleTickerProviderStateMixin {
  Offset _position = Offset.zero;
  double _rotation = 0;
  bool _isDragging = false;
  bool _isAnimating = false;
  bool _isFlyingRight = false;
  bool _isSpringing = false;
  Offset _animStartPos = Offset.zero;
  double _animStartRot = 0;

  late AnimationController _animController;

  static const double _swipeThreshold = 120;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _animController.addListener(_onAnimUpdate);
    _animController.addStatusListener(_onAnimStatus);
  }

  @override
  void dispose() {
    _animController.removeListener(_onAnimUpdate);
    _animController.removeStatusListener(_onAnimStatus);
    _animController.dispose();
    super.dispose();
  }

  void _onAnimUpdate() {
    if (!_isAnimating) return;

    final rawValue = _animController.value;

    if (_isSpringing) {
      final t = Curves.elasticOut.transform(rawValue);
      setState(() {
        _position = Offset.lerp(_animStartPos, Offset.zero, t)!;
        _rotation = _animStartRot * (1 - t);
      });
    } else {
      final t = Curves.easeOut.transform(rawValue);
      final screenWidth = MediaQuery.of(context).size.width;
      final targetX = _isFlyingRight
          ? screenWidth * 1.5
          : -screenWidth * 1.5;
      final targetRot = _isFlyingRight ? 0.5 : -0.5;

      setState(() {
        _position = Offset.lerp(
          _animStartPos,
          Offset(targetX, _animStartPos.dy + 80),
          t,
        )!;
        _rotation = _animStartRot + (targetRot - _animStartRot) * t;
      });
    }
  }

  void _onAnimStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !_isAnimating) return;

    if (_isSpringing) {
      setState(() {
        _isAnimating = false;
        _isSpringing = false;
        _position = Offset.zero;
        _rotation = 0;
      });
    } else {
      setState(() => _isAnimating = false);
      if (_isFlyingRight) {
        widget.onSwipeRight();
      } else {
        widget.onSwipeLeft();
      }
    }
  }

  void _onPanStart(DragStartDetails details) {
    if (_isAnimating || !widget.isTopCard) return;
    setState(() => _isDragging = true);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isAnimating || !widget.isTopCard) return;
    setState(() {
      _position += details.delta;
      _rotation = _position.dx / 400;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_isAnimating || !widget.isTopCard) return;
    setState(() => _isDragging = false);

    if (_position.dx > _swipeThreshold) {
      _flyOff(toRight: true);
    } else if (_position.dx < -_swipeThreshold) {
      _flyOff(toRight: false);
    } else {
      _springBack();
    }
  }

  void _flyOff({required bool toRight}) {
    _animStartPos = _position;
    _animStartRot = _rotation;
    _isAnimating = true;
    _isFlyingRight = toRight;
    _isSpringing = false;
    _animController.reset();
    _animController.forward();
  }

  void _springBack() {
    _animStartPos = _position;
    _animStartRot = _rotation;
    _isAnimating = true;
    _isSpringing = true;
    _animController.reset();
    _animController.forward();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isTopCard) {
      return _buildCardContent();
    }

    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Transform.translate(
        offset: _position,
        child: Transform.rotate(
          angle: _rotation,
          child: _buildCardContent(),
        ),
      ),
    );
  }

  Widget _buildCardContent() {
    final swipeProgress =
        _position.dx.abs() / _swipeThreshold;

    return Container(
      width: MediaQuery.of(context).size.width - 32,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPoster(),
                _buildInfo(),
              ],
            ),

            // Like overlay (right)
            if (_isDragging || _isAnimating)
              Positioned(
                top: 32,
                left: _position.dx > 20 ? null : 24,
                right: _position.dx > 20 ? 24 : null,
                child: Opacity(
                  opacity: _position.dx > 20
                      ? (swipeProgress * 1.2).clamp(0.0, 1.0)
                      : 0.0,
                  child: Transform.rotate(
                    angle: -0.15,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: const Text(
                        'LIKE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // Nope overlay (left)
            if (_isDragging || _isAnimating)
              Positioned(
                top: 32,
                left: _position.dx < -20 ? 24 : null,
                right: _position.dx < -20 ? null : 24,
                child: Opacity(
                  opacity: _position.dx < -20
                      ? (swipeProgress * 1.2).clamp(0.0, 1.0)
                      : 0.0,
                  child: Transform.rotate(
                    angle: 0.15,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: const Text(
                        'NOPE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPoster() {
    final movie = widget.movie;

    if (movie.posterUrl.isNotEmpty) {
      return SizedBox(
        height: 320,
        width: double.infinity,
        child: Image.network(
          movie.posterUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stack) => _posterPlaceholder(),
        ),
      );
    }

    return _posterPlaceholder();
  }

  Widget _posterPlaceholder() {
    return Container(
      height: 320,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.border,
      ),
      child: const Center(
        child: Icon(Icons.movie, size: 64, color: AppColors.mutedText),
      ),
    );
  }

  Widget _buildInfo() {
    final movie = widget.movie;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            movie.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            [if (movie.year.isNotEmpty) movie.year,
             if (movie.genres.isNotEmpty) movie.genres]
                .join('  \u2022  '),
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.mutedText,
            ),
          ),
          if (movie.rating > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.star_rounded,
                  size: 18,
                  color: Color(0xFFF59E0B),
                ),
                const SizedBox(width: 4),
                Text(
                  movie.rating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
