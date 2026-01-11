import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/RunModels.dart';

class RelativeEffortHistoryView extends StatelessWidget {
  final List<RelativeEffort> efforts;

  const RelativeEffortHistoryView({
    super.key,
    required this.efforts,
  });

  @override
  Widget build(BuildContext context) {
    // Group theo ngày dựa vào EndTime
    final Map<DateTime, List<RelativeEffort>> grouped = {};

    for (final e in efforts) {
      final dateKey = DateTime(
        e.endTime.year,
        e.endTime.month,
        e.endTime.day,
      );

      grouped.putIfAbsent(dateKey, () => []).add(e);
    }

    final sortedDates = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Relative Effort theo ngày',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1A1A1A),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: const Color(0xFF1A1A1A),
      body: ListView.builder(
        itemCount: sortedDates.length,
        itemBuilder: (context, index) {
          final date = sortedDates[index];
          final dayEfforts = grouped[date]!;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Text(
                    DateFormat('EEEE, dd/MM/yyyy').format(date),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                ...dayEfforts.map((e) => _buildRunCard(e)).toList(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRunCard(RelativeEffort e) {
    return Card(
      color: const Color(0xFF2D2D2D),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${DateFormat('HH:mm').format(e.startTime)} - ${DateFormat('HH:mm').format(e.endTime)}',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),

            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${e.progressPercent.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${e.distanceKm.toStringAsFixed(2)} / ${e.targetDistanceKm.toStringAsFixed(1)} km',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                _infoChip(Icons.timer, formatDuration(e.durationSeconds)),
                const SizedBox(width: 12),
                _infoChip(Icons.local_fire_department, '${e.caloriesBurned.toStringAsFixed(0)} kcal'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[400]),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(color: Colors.grey[300], fontSize: 12),
        ),
      ],
    );
  }

  String formatDuration(double seconds) {
    final d = Duration(seconds: seconds.toInt());
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);

    if (h > 0) {
      return '${h}h ${m}m';
    }
    return '${m}m ${s}s';
  }
}
