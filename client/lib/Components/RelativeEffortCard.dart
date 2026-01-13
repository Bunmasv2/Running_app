import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/RunModels.dart';
import '../Views/RelativeEffortHistoryView.dart';

class RelativeEffortCard extends StatelessWidget {
  final List<RelativeEffort> efforts;

  const RelativeEffortCard({
    super.key,
    required this.efforts,
  });

  @override
  Widget build(BuildContext context) {
    if (efforts.isEmpty) {
      return _buildEmptyCard();
    }

    final today = DateTime.now();

   final todayEffort = efforts.firstWhere(
          (e) =>
      e.startTime.year == today.year &&
          e.startTime.month == today.month &&
          e.startTime.day == today.day,
      orElse: () => efforts.first,
    );

    final progress = todayEffort.progressPercent.round();

    final dateText = DateFormat('MMM d, yyyy').format(today);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RelativeEffortHistoryView(
              efforts: efforts,
            ),
          ),
        );
      },
      child: Container(
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
                  'Nỗ lực tương đối',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey[600], size: 20),
              ],
            ),

            const Spacer(),

            Text(
              '$progress',
              style: const TextStyle(
                color: Colors.orange,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            // Date
            Text(
              dateText,
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'Chưa có dữ liệu Relative Effort',
        style: TextStyle(color: Colors.grey),
      ),
    );
  }
}
