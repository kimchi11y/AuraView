import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/friend_service.dart';
import '../theme/app_theme.dart';
import '../widgets/friend_card.dart';
import '../widgets/friend_request_card.dart';
import 'search_users_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
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
          'Friends List',
          style: TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.w800,
          ),
        ),
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
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _friendService.getIncomingRequests(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Error loading requests: ${snapshot.error}',
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 13,
                      ),
                    ),
                  );
                }

                // Filter pending status client-side
                final docs = (snapshot.data?.docs ?? [])
                    .where((doc) => doc['status'] == 'pending')
                    .toList();

                if (docs.isEmpty) return const SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                          child: Text(
                            '${docs.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    ...docs.map(
                      (doc) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _RequestItem(
                          requestId: doc.id,
                          fromUserId: doc['fromUserId'] as String,
                          friendService: _friendService,
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),
                  ],
                );
              },
            ),

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

            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _friendService.getFriends(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                final currentUid = FirebaseAuth.instance.currentUser!.uid;

                if (docs.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.group_outlined,
                            size: 48,
                            color: AppColors.mutedText,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'No friends yet',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.mutedText,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Search for users to add friends',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.mutedText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: docs.map((doc) {
                    final data = doc.data();
                    final friendId = data['userAId'] == currentUid
                        ? data['userBId'] as String
                        : data['userAId'] as String;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _FriendItem(friendId: friendId),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _RequestItem extends StatefulWidget {
  final String requestId;
  final String fromUserId;
  final FriendService friendService;

  const _RequestItem({
    required this.requestId,
    required this.fromUserId,
    required this.friendService,
  });

  @override
  State<_RequestItem> createState() => _RequestItemState();
}

class _RequestItemState extends State<_RequestItem> {
  Map<String, dynamic>? _userData;
  bool _isLoadingUser = true;
  bool _isActing = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.fromUserId)
        .get();
    if (mounted) {
      setState(() {
        _userData = doc.data();
        _isLoadingUser = false;
      });
    }
  }

  Future<void> _accept() async {
    setState(() => _isActing = true);
    try {
      await widget.friendService.acceptFriendRequest(
        requestId: widget.requestId,
        fromUserId: widget.fromUserId,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept: $e'),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() => _isActing = false);
      }
    }
  }

  Future<void> _decline() async {
    setState(() => _isActing = true);
    try {
      await widget.friendService.declineFriendRequest(widget.requestId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to decline: $e'),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() => _isActing = false);
      }
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
    final displayName = _userData!['displayName'] as String? ?? '';
    final avatarUrl = _userData!['avatarUrl'] as String? ?? '';

    return _isActing
        ? const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2,
              ),
            ),
          )
        : FriendRequestCard(
            username: username,
            subtitle: displayName,
            avatarUrl: avatarUrl,
            onAccept: _accept,
            onDecline: _decline,
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
    );
  }
}
