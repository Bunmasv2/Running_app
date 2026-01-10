import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // 1. Thêm import này
import '../../../models/RunModels.dart';

class BestEffortsCard extends StatelessWidget {
  final List<RunHistoryDto> topSessions;

  const BestEffortsCard({super.key, required this.topSessions});

  @override
  Widget build(BuildContext context) {
    // 2. Đưa nội dung UI vào hàm build chính
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Best Efforts',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/history'),
                child: Icon(Icons.chevron_right, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 3. Sửa _top2Sessions thành topSessions (theo tham số của class)
          if (topSessions.isEmpty)
            const Text("No efforts recorded", style: TextStyle(color: Colors.grey))
          else
            ...topSessions.map((session) => _buildEffortItem(session)).toList(),
        ],
      ),
    );
  }

  Widget _buildEffortItem(RunHistoryDto session) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.emoji_events, color: Colors.orange, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hiển thị tiêu đề (ví dụ "Morning Run") hoặc ID ngắn gọn
                // Text(
                  // session. ?? "Run Session",
                  // style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                // ),
                // 4. Kiểm tra lại trường startTime hay createdAt trong Model của bạn
                Text(
                  DateFormat('MMM dd, yyyy').format(session.createdAt),
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            "${session.distanceKm.toStringAsFixed(1)} km",
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}