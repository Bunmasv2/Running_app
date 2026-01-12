import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/RunModels.dart';

class TrainingLogCard extends StatelessWidget {
  final DateTime weekStart; // Thứ 2
  final List<RunHistoryDto> weeklySessions;
  final VoidCallback onPrevWeek;
  final VoidCallback onNextWeek;

  const TrainingLogCard({
    super.key,
    required this.weekStart,
    required this.weeklySessions,
    required this.onPrevWeek,
    required this.onNextWeek,
  });

  bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final weekEnd = weekStart.add(const Duration(days: 6));
    final weekDays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

    final range =
        "${DateFormat('MMM d').format(weekStart)} - ${DateFormat('MMM d').format(weekEnd)}, ${weekStart.year}";

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Log luyện tập',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
              SizedBox(),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: Colors.grey),
                onPressed: onPrevWeek,
              ),
              Text(range,
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: Colors.grey),
                onPressed: onNextWeek,
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: weekDays
                .map((d) => Expanded(
              child: Center(
                child: Text(
                  d,
                  style: TextStyle(
                      color: Colors.grey[500], fontSize: 11),
                ),
              ),
            ))
                .toList(),
          ),

          const SizedBox(height: 12),

          Row(
            children: List.generate(7, (index) {
              final day = weekStart.add(Duration(days: index));

              final dayKm = weeklySessions
                  .where((s) =>
              isSameDay(s.endTime, day) && s.distanceKm > 0)
                  .fold<double>(0, (sum, s) => sum + s.distanceKm);

              return Expanded(
                child: Center(
                  child: Text(
                    dayKm > 0 ? dayKm.toStringAsFixed(1) : '-',
                    style: TextStyle(
                      color: dayKm > 0 ? Colors.white : Colors.grey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
