import 'package:flutter/material.dart';
import '../models/RunModels.dart';

class WeeklyGoalsCard extends StatelessWidget {
  final List<RunHistoryDto> weeklySessions;
  final DateTime weekStart;

  const WeeklyGoalsCard({
    super.key,
    required this.weeklySessions,
    required this.weekStart,
  });

  int _countRunDays() {
    final weekEnd = weekStart.add(const Duration(days: 6));

    final runDays = weeklySessions.where((s) {
      if (s.endTime.year <= 1) return false;

      if (s.distanceKm <= 0) return false;

      final sessionDate = DateTime(s.endTime.year, s.endTime.month, s.endTime.day);
      final startDateOnly = DateTime(weekStart.year, weekStart.month, weekStart.day);
      final endDateOnly = DateTime(weekEnd.year, weekEnd.month, weekEnd.day);

      return !sessionDate.isBefore(startDateOnly) && !sessionDate.isAfter(endDateOnly);
    }).map((s) => DateTime(
      s.endTime.year,
      s.endTime.month,
      s.endTime.day,
    )).toSet();

    return runDays.length;
  }

  @override
  Widget build(BuildContext context) {
    final runDays = _countRunDays();
    final double goal = 7.0;
    final double percent = (runDays / goal).clamp(0.0, 1.0);

    return Container(
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
                'Mục tiêu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // Icon(Icons.chevron_right, color: Colors.grey[600], size: 20),
            ],
          ),
          const SizedBox(height: 16),

          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 55,
                height: 55,
                child: CircularProgressIndicator(
                  value: percent,
                  strokeWidth: 4,
                  backgroundColor: Colors.grey[800],
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                ),
              ),
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.directions_run,
                  color: percent >= 1.0 ? Colors.orange : Colors.grey[400],
                  size: 24,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Text(
            'Mục tiêu chạy bộ hàng tuần',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$runDays/7 cuộc chạy · ${(percent * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}