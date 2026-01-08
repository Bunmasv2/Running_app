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
      backgroundColor: Colors.black,
      elevation: 10,
      items: const [
        // Tab 1: Home [cite: 70]
        BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Trang chủ"
        ),
        // Tab 2: Lịch sử [cite: 95]
        BottomNavigationBarItem(
            icon: Icon(Icons.map_rounded),
            label: "Bản đồ"
        ),
        BottomNavigationBarItem(
            icon: Icon(Icons.fiber_smart_record_rounded),
            label: "Ghi đường"
        ),
        BottomNavigationBarItem(
            icon: Icon(Icons.group_work_rounded),
            label: "Nhóm"
        ),
        // Tab 3: Cá nhân [cite: 105]
        BottomNavigationBarItem(
            icon: Icon(Icons.person_sharp),
            label: "Cá nhân"
        ),
      ],
    );
  }
}