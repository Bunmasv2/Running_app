import 'package:flutter/material.dart';
import '../Models/UserProfile.dart';
import 'AppBarActions.dart';

class TopNavBarComponent extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle; // Tab label khi header thu gọn
  final UserProfile? userProfile;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onChatTap;
  final VoidCallback? onSearchTap;
  final VoidCallback? onNotificationTap;

  const TopNavBarComponent({
    super.key,
    required this.title,
    this.subtitle,
    this.userProfile,
    this.onAvatarTap,
    this.onChatTap,
    this.onSearchTap,
    this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.black,
      elevation: 0,
      titleSpacing: 16,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          // Subtitle với animation
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: subtitle != null ? 1.0 : 0.0,
              child: subtitle != null
                  ? Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        subtitle!,
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
      centerTitle: false, // Để tiêu đề nằm bên trái
        actions: buildAppBarActions(
          userProfile: userProfile,
          onAvatarTap: onAvatarTap,
          onChatTap: onChatTap,
          onSearchTap: onSearchTap,
          onNotificationTap: onNotificationTap,
        ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 8);
}
