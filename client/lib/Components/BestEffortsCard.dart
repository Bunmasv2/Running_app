import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/RunModels.dart';

class BestEffortsCard extends StatelessWidget {
  final List<RunHistoryDto> topSessions;

  const BestEffortsCard({super.key, required this.topSessions});

  @override
  Widget build(BuildContext context) {
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
                'Những nỗ lực tốt nhất',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (topSessions.isEmpty)
            const Text("No efforts recorded", style: TextStyle(color: Colors.grey))
          else
            ...topSessions.map((session) => _buildEffortItem(session)).toList(),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    int duration = seconds;
    int hours = duration ~/ 3600;
    int minutes = (duration % 3600) ~/ 60;
    int secs = duration % 60;

    if (hours > 0) {
      return "${hours}h ${minutes}m ${secs}s";
    } else if (minutes > 0) {
      return "${minutes}m ${secs}s";
    } else {
      return "${secs}s";
    }
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
                Text(
                  DateFormat('MMM dd, yyyy').format(session.endTime),
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
                Text(
                  _formatDuration(session.durationSeconds),
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            "${session.distanceKm.toStringAsFixed(2)} km",
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}