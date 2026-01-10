import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/RunModels.dart';

class TrainingLogCard extends StatelessWidget {
  final DateTime weekStart;
  final List<RunHistoryDto> weeklySessions;
  final VoidCallback onPrevWeek;
  final VoidCallback onNextWeek;

  const TrainingLogCard({
    required this.weekStart,
    required this.weeklySessions,
    required this.onPrevWeek,
    required this.onNextWeek,
  });

  @override
  Widget build(BuildContext context) {
    List<String> weekDays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    double totalKm = weeklySessions.fold(0, (sum, item) => sum + item.distanceKm);
    String range = "${DateFormat('MMM d').format(weekStart)} - ${DateFormat('MMM d').format(weekStart.add(const Duration(days: 6)))}, ${weekStart.year}";

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF2D2D2D), borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Training Log', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Text('${totalKm.toStringAsFixed(1)} km', style: const TextStyle(color: Colors.white)),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(icon: const Icon(Icons.chevron_left, color: Colors.grey), onPressed: onPrevWeek),
              Text(range, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              IconButton(icon: const Icon(Icons.chevron_right, color: Colors.grey), onPressed: onNextWeek),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: weekDays.map((day) => Expanded(child: Center(child: Text(day, style: TextStyle(color: Colors.grey[500], fontSize: 11))))).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(7, (index) {
              double dist = weeklySessions
                  .where((s) => s.createdAt.weekday == index + 1)
                  .fold(0.0, (sum, item) => sum + item.distanceKm);
              return Expanded(
                child: Center(
                  child: Text(
                    dist > 0 ? dist.toStringAsFixed(1) : '-',
                    style: TextStyle(color: dist > 0 ? Colors.white : Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w600),
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