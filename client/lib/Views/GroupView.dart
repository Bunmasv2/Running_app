import 'package:flutter/material.dart';
import '../Components/HeaderComponent.dart';

class Groupview extends StatefulWidget {
  final ValueChanged<String?>? onSubtitleChanged;

  const Groupview({super.key, this.onSubtitleChanged});

  @override
  State<Groupview> createState() => _GroupviewState();
}

class _GroupviewState extends State<Groupview> {
  @override
  Widget build(BuildContext context) {
    return ScrollableHeaderTabsComponent(
      tabs: [
        HeaderTabItem(label: 'Nhóm của tôi', content: _buildMyGroupsContent()),
        HeaderTabItem(label: 'Khám phá', content: _buildExploreContent()),
      ],
      backgroundColor: const Color(0xFF2D2D2D),
      activeColor: Colors.orange,
      onTabLabelChanged: (label) {
        widget.onSubtitleChanged?.call(label);
      },
    );
  }

  // --- Tab Nhóm của tôi ---
  Widget _buildMyGroupsContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group, size: 64, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text(
            'Bạn chưa tham gia nhóm nào',
            style: TextStyle(color: Colors.grey[500], fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Tạo nhóm mới'),
          ),
        ],
      ),
    );
  }

  // --- Tab Khám phá ---
  Widget _buildExploreContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.explore, size: 64, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text(
            'Khám phá các nhóm chạy bộ',
            style: TextStyle(color: Colors.grey[500], fontSize: 16),
          ),
        ],
      ),
    );
  }
}