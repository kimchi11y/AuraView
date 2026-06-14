import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/auth_card.dart';

class FriendRequestCard extends StatelessWidget {
  final String avatarUrl;
  final String username;
  final String subtitle;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  const FriendRequestCard({
    super.key,
    required this.username,
    required this.subtitle,
    this.avatarUrl = '',
    this.onAccept,
    this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return AuthCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.border,
            backgroundImage:
                avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
            child: avatarUrl.isEmpty
                ? const Icon(Icons.person, size: 24, color: AppColors.mutedText)
                : null,
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
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.mutedText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          Row(
            children: [
              _ActionButton(
                icon: Icons.close,
                iconColor: AppColors.text,
                backgroundColor: AppColors.border,
                onTap: onDecline,
              ),
              const SizedBox(width: 8),
              _ActionButton(
                icon: Icons.check,
                iconColor: Colors.white,
                backgroundColor: AppColors.primary,
                onTap: onAccept,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 20, color: iconColor),
      ),
    );
  }
}
