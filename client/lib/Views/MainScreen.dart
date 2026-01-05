import 'package:client/Views/HistoryView.dart';
import 'package:flutter/material.dart';
import '../Components/BottomNavBarComponent.dart';
import 'HomeView.dart';
import 'HistoryView.dart';
import 'ProfileView.dart'; // Bạn cần tạo file này

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

  // Danh sách các màn hình tương ứng với 3 tabs [cite: 64]
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const HomeView(),                  // Tab 0
      const HistoryView(),  // Tab 1 (Thay bằng HistoryView sau này)
      const ProfileView(),  // Tab 2 (Thay bằng ProfileView sau này)
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack giữ trạng thái của các màn hình khi chuyển tab
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavBarComponent(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}