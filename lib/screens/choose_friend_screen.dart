import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/friend_service.dart';
import '../theme/app_theme.dart';
import '../widgets/friend_card.dart';
import 'movie_swipe/discover_screen.dart';

class ChooseFriendScreen extends StatefulWidget {
  const ChooseFriendScreen({super.key});

  @override
  State<ChooseFriendScreen> createState() => _ChooseFriendScreenState();
}

class _ChooseFriendScreenState extends State<ChooseFriendScreen> {
  final FriendService _friendService = FriendService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Discover Together',
          style: TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _friendService.getFriends(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          final currentUid = FirebaseAuth.instance.currentUser!.uid;

          if (docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 48,
                    color: AppColors.mutedText,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'No friends yet',
                    style: TextStyle(fontSize: 14, color: AppColors.mutedText),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Add friends first to start discovering movies together',
                    style: TextStyle(fontSize: 13, color: AppColors.mutedText),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              final friendId = data['userAId'] == currentUid
                  ? data['userBId'] as String
                  : data['userAId'] as String;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _FriendItem(friendId: friendId),
              );
            },
          );
        },
      ),
    );
  }
}

class _FriendItem extends StatefulWidget {
  final String friendId;

  const _FriendItem({required this.friendId});

  @override
  State<_FriendItem> createState() => _FriendItemState();
}

class _FriendItemState extends State<_FriendItem> {
  Map<String, dynamic>? _userData;
  bool _isLoadingUser = true;

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
        _isLoadingUser = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingUser) {
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
    final avatarUrl = _userData!['avatarUrl'] as String? ?? '';

    return FriendCard(
      friendId: widget.friendId,
      username: username,
      avatarUrl: avatarUrl,
      buttonLabel: 'Discover',
      buttonIcon: Icons.explore_outlined,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DiscoverScreen(
              friendId: widget.friendId,
              friendName: username,
            ),
          ),
        );
      },
    );
  }
}
