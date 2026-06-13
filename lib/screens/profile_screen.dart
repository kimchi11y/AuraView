import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_card.dart';
import 'login_screen.dart';
import '../widgets/app_bottom_nav_bar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileService profileService = ProfileService();
  final ImagePicker picker = ImagePicker();

  bool isUploading = false;

  Future<void> pickAndUploadAvatar(String uid) async {
    final XFile? pickedImage = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (pickedImage == null) return;

    setState(() => isUploading = true);

    try {
      final File imageFile = File(pickedImage.path);

      await profileService.uploadAvatar(
        uid: uid,
        imageFile: imageFile,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Avatar updated successfully'),
          backgroundColor: AppColors.primary,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isUploading = false);
      }
    }
  }

  Future<void> handleLogout() async {
    await AuthService().logout();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void showEditProfileSheet({
  required String uid,
  required String displayName,
  required String username,
  required String bio,
  required String avatarUrl,
}) {
  final displayNameController = TextEditingController(text: displayName);
  final usernameController = TextEditingController(text: username);
  final bioController = TextEditingController(text: bio);
  final avatarUrlController = TextEditingController(text: avatarUrl);

  final formKey = GlobalKey<FormState>();
  bool isSaving = false;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(24),
      ),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    Text(
                      'Edit Profile',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Update your public profile information.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),

                    const SizedBox(height: 24),

                    TextFormField(
                      controller: displayNameController,
                      decoration: const InputDecoration(
                        labelText: 'Display Name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Display name is required';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        prefixIcon: Icon(Icons.alternate_email),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Username is required';
                        }
                        if (value.trim().contains(' ')) {
                          return 'Username cannot contain spaces';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: bioController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Bio',
                        hintText: 'Tell people about your movie taste',
                        prefixIcon: Icon(Icons.info_outline),
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: avatarUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Avatar URL',
                        hintText: 'Paste image link here',
                        prefixIcon: Icon(Icons.image_outlined),
                      ),
                    ),

                    const SizedBox(height: 24),

                    ElevatedButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;

                              setModalState(() {
                                isSaving = true;
                              });

                              try {
                                await profileService.updateUserProfile(
                                  uid: uid,
                                  displayName: displayNameController.text,
                                  username: usernameController.text,
                                  bio: bioController.text,
                                  avatarUrl: avatarUrlController.text,
                                );

                                if (!mounted) return;

                                Navigator.pop(context);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Profile updated successfully'),
                                    backgroundColor: AppColors.primary,
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(e.toString()),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                              } finally {
                                setModalState(() {
                                  isSaving = false;
                                });
                              }
                            },
                      child: isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('SAVE CHANGES'),
                    ),

                    const SizedBox(height: 12),

                    OutlinedButton(
                      onPressed: isSaving
                          ? null
                          : () {
                              Navigator.pop(context);
                            },
                      child: const Text('CANCEL'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const LoginScreen();
    }

    return Scaffold(
  backgroundColor: AppColors.background,

  bottomNavigationBar: AppBottomNavBar(
    currentIndex: 3,
    onTap: (index) {
      if (index == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Discover screen not ready yet')),
        );
      } else if (index == 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Matches screen not ready yet')),
        );
      } else if (index == 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Friends screen not ready yet')),
        );
      }
    },
  ),

  appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            onPressed: handleLogout,
            icon: const Icon(
              Icons.logout,
              color: AppColors.text,
            ),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text('User profile not found'),
            );
          }

          final data = snapshot.data!.data()!;
          final displayName = data['displayName'] ?? '';
          final username = data['username'] ?? '';
          final email = data['email'] ?? '';
          final avatarUrl = data['avatarUrl'] ?? '';
          final bio = data['bio'] ?? '';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Column(
                  children: [
                    AuthCard(
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              CircleAvatar(
                                radius: 58,
                                backgroundColor: AppColors.text,
                                backgroundImage: avatarUrl.isNotEmpty
                                    ? NetworkImage(avatarUrl)
                                    : null,
                                child: avatarUrl.isEmpty
                                    ? const Icon(
                                        Icons.person,
                                        size: 58,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                              InkWell(
                                onTap: isUploading
                                    ? null
                                    : () => pickAndUploadAvatar(user.uid),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 3,
                                    ),
                                  ),
                                  child: isUploading
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.camera_alt,
                                          size: 18,
                                          color: Colors.white,
                                        ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          Text(
                            displayName,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),

                          const SizedBox(height: 4),

                          Text(
                            '@$username',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),

                          const SizedBox(height: 16),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.text,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'MOVIE MATCH USER',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          ElevatedButton.icon(
                            onPressed: () {
                              showEditProfileSheet(
                                uid: user.uid,
                                displayName: displayName,
                                username: username,
                                bio: bio,
                                avatarUrl: avatarUrl,
                              );
                            },
                            icon: const Icon(Icons.edit),
                            label: const Text('EDIT PROFILE'),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    AuthCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Account Details',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 16),

                          ProfileInfoTile(
                            icon: Icons.email_outlined,
                            title: 'Email',
                            value: email,
                          ),

                          const Divider(height: 32),

                          ProfileInfoTile(
                            icon: Icons.person_outline,
                            title: 'Username',
                            value: username,
                          ),

                          const Divider(height: 32),

                          ProfileInfoTile(
                            icon: Icons.info_outline,
                            title: 'Bio',
                            value: bio.isEmpty ? 'No bio added yet' : bio,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    OutlinedButton.icon(
                      onPressed: handleLogout,
                      icon: const Icon(Icons.logout),
                      label: const Text('LOGOUT'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class ProfileInfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const ProfileInfoTile({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppColors.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: AppColors.mutedText,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}