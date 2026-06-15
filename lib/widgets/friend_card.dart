import 'package:flutter/material.dart';

import '../screens/shared_matches_screen.dart';
import '../theme/app_theme.dart';
import '../theme/social_colors.dart';
import '../widgets/auth_card.dart';

class FriendCard extends StatelessWidget {
  final String friendId;
  final String username;
  final String avatarUrl;
  final bool isOnline;
  final VoidCallback? onViewMatches;

  const FriendCard({
    super.key,
    required this.friendId,
    required this.username,
    this.avatarUrl = '',
    this.isOnline = false,
    this.onViewMatches,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: isOnline ? SocialColors.matchAccent : AppColors.border,
            width: 4,
          ),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: AuthCard(
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.border,
                  backgroundImage:
                      avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                  child: avatarUrl.isEmpty
                      ? const Icon(
                          Icons.person,
                          size: 26,
                          color: AppColors.mutedText,
                        )
                      : null,
                ),
                if (isOnline)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: SocialColors.online,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Text(
                username,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
            ),

            ElevatedButton.icon(
              onPressed: onViewMatches ??
                  () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SharedMatchesScreen(
                            friendId: friendId,
                            friendName: username,
                          ),
                        ),
                      ),
              icon: const Icon(Icons.movie_outlined, size: 16),
              label: const Text('View Matches'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                minimumSize: Size.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
