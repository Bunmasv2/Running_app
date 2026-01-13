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
    final size = MediaQuery.of(context).size;

    final Map<DateTime, List<RelativeEffort>> grouped = {};
    for (final e in efforts) {
      final dateKey = DateTime(e.endTime.year, e.endTime.month, e.endTime.day);
      grouped.putIfAbsent(dateKey, () => []).add(e);
    }

    final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text(
          'Nỗ lực tương đối',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: sortedDates.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
        padding: EdgeInsets.only(bottom: size.height * 0.05),
        itemCount: sortedDates.length,
        itemBuilder: (context, index) {
          final date = sortedDates[index];
          final dayEfforts = grouped[date]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(size.width * 0.05, 16, size.width * 0.05, 8),
                child: Text(
                  DateFormat('EEEE, dd/MM/yyyy').format(date),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ...dayEfforts.map((e) => _buildRunCard(e, size)).toList(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRunCard(RelativeEffort e, Size size) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: size.width * 0.04, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${DateFormat('HH:mm').format(e.startTime)} - ${DateFormat('HH:mm').format(e.endTime)}',
                style: TextStyle(color: Colors.grey[500], fontSize: 11),
              ),
              Icon(Icons.directions_run, size: 16, color: Colors.grey[600]),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${e.progressPercent.toStringAsFixed(0)}%',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: size.width * 0.065,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'nỗ lực',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ),
              const Spacer(),
              Text(
                '${e.distanceKm.toStringAsFixed(2)} / ${e.targetDistanceKm.toStringAsFixed(1)} km',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _infoChip(Icons.timer_outlined, _formatDuration(e.durationSeconds)),
              const SizedBox(width: 16),
              _infoChip(Icons.local_fire_department_outlined, '${e.caloriesBurned.toStringAsFixed(0)} kcal'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.orange.withOpacity(0.8)),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(color: Colors.grey[300], fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        "Chưa có dữ liệu hoạt động",
        style: TextStyle(color: Colors.grey),
      ),
    );
  }

  String _formatDuration(double seconds) {
    final d = Duration(seconds: seconds.toInt());
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return h > 0 ? '${h}h ${m}m' : '${m}p ${s}s';
  }
}