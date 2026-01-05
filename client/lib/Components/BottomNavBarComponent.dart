import 'package:flutter/material.dart';

class BottomNavBarComponent extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBarComponent({
    super.key,
    required this.currentIndex,
    required this.onTap
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      selectedItemColor: Colors.orange, // Màu chủ đạo theo PRD
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      elevation: 10,
      items: const [
        // Tab 1: Home [cite: 70]
        BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: "Home"
        ),
        // Tab 2: Lịch sử [cite: 95]
        BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: "Lịch sử"
        ),
        // Tab 3: Cá nhân [cite: 105]
        BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Cá nhân"
        ),
      ],
    );
  }
}