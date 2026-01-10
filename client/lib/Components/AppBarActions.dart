import 'package:flutter/material.dart';
import '../Models/UserProfile.dart';

List<Widget> buildAppBarActions({
  required UserProfile? userProfile,
  VoidCallback? onAvatarTap,
  VoidCallback? onNotificationTap,
}) {
  return [
    // Avatar
    GestureDetector(
      onTap: onAvatarTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: CircleAvatar(
          radius: 16,
          backgroundColor: Colors.grey[200],
          backgroundImage: userProfile?.avatarUrl != null && userProfile!.avatarUrl!.isNotEmpty
              ? NetworkImage(userProfile!.avatarUrl!)
              : null,
          child: userProfile?.avatarUrl == null || userProfile!.avatarUrl!.isEmpty
              ? const Icon(Icons.person, size: 20, color: Colors.grey)
              : null,
        ),
      ),
    ),
    // Icons
    IconButton(
      icon: const Icon(Icons.notifications_none, color: Colors.white),
      onPressed: onNotificationTap,
    ),
    const SizedBox(width: 8),
  ];
}