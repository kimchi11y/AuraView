import 'package:flutter/material.dart';

import '../screens/shared_matches_screen.dart';
import '../theme/app_theme.dart';
import '../theme/social_colors.dart';
import '../widgets/auth_card.dart';

class FriendCard extends StatelessWidget {
  final String avatarUrl;
  final String username;
  final bool isOnline;
  final String lastSeen;
  final int matchPercent;
  final VoidCallback? onViewMatches;
  final VoidCallback? onHistory;

  const FriendCard({
    super.key,
    required this.username,
    this.avatarUrl = '',
    this.isOnline = false,
    this.lastSeen = '',
    this.matchPercent = 0,
    this.onViewMatches,
    this.onHistory,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    username,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (isOnline)
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: SocialColors.onlineBg,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'ONLINE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: SocialColors.online,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$matchPercent% Match',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.mutedText,
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      lastSeen,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.mutedText,
                      ),
                    ),
                ],
              ),
            ),

            if (isOnline)
              ElevatedButton.icon(
                onPressed: onViewMatches ??
                    () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                SharedMatchesScreen(friendName: username),
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
              )
            else
              OutlinedButton(
                onPressed: onHistory,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  minimumSize: Size.zero,
                ),
                child: const Text('History'),
              ),
          ],
        ),
      ),
    );
  }
}
