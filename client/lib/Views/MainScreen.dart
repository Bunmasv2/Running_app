import 'package:client/Views/PersonalView.dart';
import 'package:flutter/material.dart';
import '../Components/BottomNavBarComponent.dart';
import '../Components/TopNavBarComponent.dart';
import '../Models/UserProfile.dart';
import '../Services/UserService.dart';
import 'GroupView.dart';
import 'HomeView.dart';
import 'ProfileView.dart';
import 'RecordView.dart';
import 'TrackingView.dart';
import 'ChallengeView.dart';


// Widget Placeholder tạm thời cho History và Profile nếu bạn chưa tạo file
class PlaceholderView extends StatelessWidget {
  final String title;
  const PlaceholderView(this.title, {super.key});
  @override
  Widget build(BuildContext context) => Center(child: Text(title));
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final UserService _userService = UserService();
  UserProfile? _userProfile;
  String? _currentSubtitle; // Subtitle từ tab đang chọn

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    UserProfile? user = await _userService.getUserProfile();
    if (mounted) {
      setState(() {
        _userProfile = user;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      // Reset subtitle khi chuyển tab, các trang có tabs sẽ cập nhật lại
      if (index != 3 && index != 4) {
        _currentSubtitle = null;
      }
    });
  }

  void _onSubtitleChanged(String? subtitle) {
    if (_currentSubtitle != subtitle) {
      setState(() {
        _currentSubtitle = subtitle;
      });
    }
  }

  // --- TopNavBar Handlers ---
  void _handleAvatarTap() {
    // Navigate to ProfileView
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileView()),
    );
  }

  void _handleChatTap() {
    // Navigate to chat screen
    print("Tap Chat");
  }

  void _handleSearchTap() {
    // Navigate to search friends screen
    print("Tap Search");
  }

  void _handleNotiTap() {
    // Navigate to notifications screen
    print("Tap Notification");
  }

  @override
  Widget build(BuildContext context) {
    // Lấy title và content tương ứng với tab hiện tại
    String currentTitle = ['Trang chủ', 'Bản đồ', 'Ghi đường', 'Nhóm', 'Cá nhân'][_selectedIndex];
    Widget currentContent;

    switch (_selectedIndex) {
      case 0:
        currentContent = const HomeView();
        break;
      case 1:
        currentContent = const ChallengeView();
        break;
      case 2:
        currentContent = TrackingView();
        break;
      case 3:
        currentContent = Groupview(onSubtitleChanged: _onSubtitleChanged);
        break;
      case 4:
        currentContent = Personalview(onSubtitleChanged: _onSubtitleChanged);
        break;
      default:
        currentContent = const Center(child: Text("Error"));
    }

    // Chỉ hiển thị subtitle cho các trang có tabs (Nhóm, Cá nhân)
    String? subtitle = (_selectedIndex == 3 || _selectedIndex == 4) ? _currentSubtitle : null;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: TopNavBarComponent(
        title: currentTitle,
        subtitle: subtitle,
        userProfile: _userProfile,
        onAvatarTap: _handleAvatarTap,
        onChatTap: _handleChatTap,
        onSearchTap: _handleSearchTap,
        onNotificationTap: _handleNotiTap,
      ),
      body: currentContent,
      bottomNavigationBar: BottomNavBarComponent(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}