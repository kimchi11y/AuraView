import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../widgets/friend_card.dart';
import '../widgets/friend_request_card.dart';
import 'search_users_screen.dart';

class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Friends List',
          style: TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 2,
        onTap: (index) {
          if (index == 2) return;
          if (index == 3) {
            Navigator.pop(context);
            return;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Screen not ready yet')),
          );
        },
      ),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar
            TextFormField(
              readOnly: true,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SearchUsersScreen(),
                ),
              ),
              decoration: const InputDecoration(
                hintText: 'Search by username...',
                prefixIcon: Icon(Icons.search, color: AppColors.mutedText),
              ),
            ),

            const SizedBox(height: 24),

            // Pending Requests section
            Row(
              children: [
                const Text(
                  'Pending Requests',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    '2',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            FriendRequestCard(
              username: 'Julian_Vortex',
              subtitle: 'Loves Sci-Fi & Thrillers',
            ),

            const SizedBox(height: 10),

            FriendRequestCard(
              username: 'Neon_Sky',
              subtitle: 'Wants to watch Dune',
            ),

            const SizedBox(height: 24),

            // Friends section
            const Text(
              'Friends',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),

            const SizedBox(height: 12),

            FriendCard(
              username: 'Marcus_Cine',
              isOnline: true,
              matchPercent: 84,
            ),

            const SizedBox(height: 10),

            FriendCard(
              username: 'Sarah_Spins',
              isOnline: true,
              matchPercent: 92,
            ),

            const SizedBox(height: 10),

            FriendCard(
              username: 'Erik_Noir',
              isOnline: false,
              lastSeen: 'Last seen 2h ago',
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
