import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/auth_card.dart';

class SearchUsersScreen extends StatefulWidget {
  const SearchUsersScreen({super.key});

  @override
  State<SearchUsersScreen> createState() => _SearchUsersScreenState();
}

class _SearchUsersScreenState extends State<SearchUsersScreen> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  final List<Map<String, String>> _dummyUsers = [
    {'displayName': 'Alex Reel', 'username': 'Alex_Reel'},
    {'displayName': 'Cinema Ghost', 'username': 'CinemaGhost'},
    {'displayName': 'Pixel Director', 'username': 'PixelDirector'},
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
              onChanged: (value) => setState(() => _query = value),
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
                          setState(() => _query = '');
                        },
                      )
                    : null,
              ),
            ),
          ),

          Expanded(
            child: _query.isEmpty
                ? const _EmptyState()
                : ListView.separated(
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _dummyUsers.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final user = _dummyUsers[index];
                      return _UserResultCard(
                        displayName: user['displayName']!,
                        username: user['username']!,
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
            style: TextStyle(
              fontSize: 14,
              color: AppColors.mutedText,
            ),
          ),
        ],
      ),
    );
  }
}

class _UserResultCard extends StatefulWidget {
  final String displayName;
  final String username;

  const _UserResultCard({
    required this.displayName,
    required this.username,
  });

  @override
  State<_UserResultCard> createState() => _UserResultCardState();
}

class _UserResultCardState extends State<_UserResultCard> {
  _FriendStatus _status = _FriendStatus.none;

  @override
  Widget build(BuildContext context) {
    return AuthCard(
      child: Row(
        children: [
          const CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.border,
            child: Icon(Icons.person, size: 22, color: AppColors.mutedText),
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

          _buildButton(),
        ],
      ),
    );
  }

  Widget _buildButton() {
    switch (_status) {
      case _FriendStatus.none:
        return ElevatedButton(
          onPressed: () => setState(() => _status = _FriendStatus.pending),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            minimumSize: Size.zero,
          ),
          child: const Text('Add Friend'),
        );

      case _FriendStatus.pending:
        return OutlinedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.schedule, size: 14),
          label: const Text('Pending'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.mutedText,
            side: const BorderSide(color: AppColors.border),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            minimumSize: Size.zero,
          ),
        );

      case _FriendStatus.friends:
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

enum _FriendStatus { none, pending, friends }
