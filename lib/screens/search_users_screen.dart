import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/friend_service.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_card.dart';

class SearchUsersScreen extends StatefulWidget {
  const SearchUsersScreen({super.key});

  @override
  State<SearchUsersScreen> createState() => _SearchUsersScreenState();
}

class _SearchUsersScreenState extends State<SearchUsersScreen> {
  final TextEditingController _controller = TextEditingController();
  final FriendService _friendService = FriendService();

  String _query = '';
  List<Map<String, dynamic>> _results = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    final trimmed = query.trim();

    if (trimmed.isEmpty) {
      setState(() {
        _results = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    final queryLower = trimmed.toLowerCase();
    final currentUid = FirebaseAuth.instance.currentUser!.uid;

    final snap = await FirebaseFirestore.instance
        .collection('users')
        .where('usernameLower', isGreaterThanOrEqualTo: queryLower)
        .where('usernameLower', isLessThan: '$queryLower')
        .limit(10)
        .get();

    final results = snap.docs
        .where((doc) => doc.id != currentUid)
        .map((doc) => doc.data())
        .toList();

    if (mounted) {
      setState(() {
        _results = results;
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Search Users',
          style: TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.w800,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.text),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextFormField(
              controller: _controller,
              autofocus: true,
              onChanged: (value) {
                setState(() => _query = value);
                _search(value);
              },
              decoration: InputDecoration(
                hintText: 'Search by username...',
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.mutedText,
                ),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: AppColors.mutedText,
                        ),
                        onPressed: () {
                          _controller.clear();
                          setState(() {
                            _query = '';
                            _results = [];
                          });
                        },
                      )
                    : null,
              ),
            ),
          ),

          Expanded(
            child: _query.isEmpty
                ? const _EmptyState()
                : _isSearching
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    : _results.isEmpty
                        ? const _NoResultsState()
                        : ListView.separated(
                            physics: const ClampingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _results.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final user = _results[index];
                              return _UserResultCard(
                                uid: user['uid'] as String,
                                displayName: user['displayName'] as String,
                                username: user['username'] as String,
                                avatarUrl: user['avatarUrl'] as String? ?? '',
                                friendService: _friendService,
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search, size: 48, color: AppColors.mutedText),
          SizedBox(height: 12),
          Text(
            'Search by username to find friends',
            style: TextStyle(fontSize: 14, color: AppColors.mutedText),
          ),
        ],
      ),
    );
  }
}

class _NoResultsState extends StatelessWidget {
  const _NoResultsState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_search, size: 48, color: AppColors.mutedText),
          SizedBox(height: 12),
          Text(
            'No users found',
            style: TextStyle(fontSize: 14, color: AppColors.mutedText),
          ),
        ],
      ),
    );
  }
}

class _UserResultCard extends StatefulWidget {
  final String uid;
  final String displayName;
  final String username;
  final String avatarUrl;
  final FriendService friendService;

  const _UserResultCard({
    required this.uid,
    required this.displayName,
    required this.username,
    required this.avatarUrl,
    required this.friendService,
  });

  @override
  State<_UserResultCard> createState() => _UserResultCardState();
}

class _UserResultCardState extends State<_UserResultCard> {
  FriendStatus _status = FriendStatus.none;
  bool _isLoadingStatus = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final status = await widget.friendService.getFriendStatus(widget.uid);
    if (mounted) {
      setState(() {
        _status = status;
        _isLoadingStatus = false;
      });
    }
  }

  Future<void> _sendRequest() async {
    setState(() => _isSending = true);
    try {
      await widget.friendService.sendFriendRequest(widget.uid);
      if (mounted) setState(() => _status = FriendStatus.pendingSent);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.border,
            backgroundImage: widget.avatarUrl.isNotEmpty
                ? NetworkImage(widget.avatarUrl)
                : null,
            child: widget.avatarUrl.isEmpty
                ? const Icon(
                    Icons.person,
                    size: 22,
                    color: AppColors.mutedText,
                  )
                : null,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.displayName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                Text(
                  '@${widget.username}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.mutedText,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          _isLoadingStatus
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                )
              : _buildButton(),
        ],
      ),
    );
  }

  Widget _buildButton() {
    switch (_status) {
      case FriendStatus.none:
        return ElevatedButton(
          onPressed: _isSending ? null : _sendRequest,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            textStyle:
                const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            minimumSize: Size.zero,
          ),
          child: _isSending
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Add Friend'),
        );

      case FriendStatus.pendingSent:
        return OutlinedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.schedule, size: 14),
          label: const Text('Pending'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.mutedText,
            side: const BorderSide(color: AppColors.border),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            textStyle:
                const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            minimumSize: Size.zero,
          ),
        );

      case FriendStatus.pendingReceived:
        return OutlinedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.reply, size: 14),
          label: const Text('Respond'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.mutedText,
            side: const BorderSide(color: AppColors.border),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            textStyle:
                const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            minimumSize: Size.zero,
          ),
        );

      case FriendStatus.friends:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check, size: 14, color: AppColors.mutedText),
              SizedBox(width: 4),
              Text(
                'Friends',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mutedText,
                ),
              ),
            ],
          ),
        );
    }
  }
}
