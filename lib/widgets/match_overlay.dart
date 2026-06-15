import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/social_colors.dart';

class MatchOverlay extends StatefulWidget {
  final String friendName;
  final String friendAvatarUrl;
  final String userAvatarUrl;
  final String movieTitle;
  final String moviePosterUrl;
  final VoidCallback onKeepSwiping;
  final VoidCallback onViewMatches;

  const MatchOverlay({
    super.key,
    required this.friendName,
    required this.friendAvatarUrl,
    required this.userAvatarUrl,
    required this.movieTitle,
    required this.moviePosterUrl,
    required this.onKeepSwiping,
    required this.onViewMatches,
  });

  static void show({
    required BuildContext context,
    required String friendName,
    required String friendAvatarUrl,
    required String userAvatarUrl,
    required String movieTitle,
    required String moviePosterUrl,
    required VoidCallback onKeepSwiping,
    required VoidCallback onViewMatches,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => MatchOverlay(
        friendName: friendName,
        friendAvatarUrl: friendAvatarUrl,
        userAvatarUrl: userAvatarUrl,
        movieTitle: movieTitle,
        moviePosterUrl: moviePosterUrl,
        onKeepSwiping: onKeepSwiping,
        onViewMatches: onViewMatches,
      ),
    );
  }

  @override
  State<MatchOverlay> createState() => _MatchOverlayState();
}

class _MatchOverlayState extends State<MatchOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.elasticOut),
    );

    _opacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: AnimatedBuilder(
        animation: _animController,
        builder: (context, child) {
          return Opacity(
            opacity: _opacityAnim.value,
            child: Transform.scale(
              scale: _scaleAnim.value,
              child: child,
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "It's a Match!",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: SocialColors.matchAccent,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                'You and @${widget.friendName} both liked',
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.mutedText,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // Avatars + movie poster
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildAvatar(widget.userAvatarUrl, isUser: true),
                  const SizedBox(width: 8),
                  _buildMovieThumb(),
                  const SizedBox(width: 8),
                  _buildAvatar(widget.friendAvatarUrl, isUser: false),
                ],
              ),

              const SizedBox(height: 16),

              Text(
                widget.movieTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 8),

              Text(
                'You can find this match in your shared matches with @${widget.friendName}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.mutedText,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 28),

              // Buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onKeepSwiping();
                  },
                  child: const Text('KEEP SWIPING'),
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onViewMatches();
                  },
                  child: const Text('VIEW MATCHES'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(String avatarUrl, {required bool isUser}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: AppColors.text,
          backgroundImage:
              avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
          child: avatarUrl.isEmpty
              ? const Icon(Icons.person, size: 36, color: Colors.white)
              : null,
        ),
        const SizedBox(height: 4),
        Text(
          isUser ? 'You' : '@${widget.friendName}',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.mutedText,
          ),
        ),
      ],
    );
  }

  Widget _buildMovieThumb() {
    return Container(
      width: 56,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: SocialColors.matchAccent, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: widget.moviePosterUrl.isNotEmpty
            ? Image.network(
                widget.moviePosterUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => _posterFallback(),
              )
            : _posterFallback(),
      ),
    );
  }

  Widget _posterFallback() {
    return Container(
      color: AppColors.border,
      child: const Icon(Icons.movie, size: 28, color: AppColors.mutedText),
    );
  }
}
