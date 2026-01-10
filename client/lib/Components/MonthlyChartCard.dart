import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/RunModels.dart';

class MonthlyChartCard extends StatelessWidget {
  final DateTime currentMonth;
  final List<RunHistoryDto> sessions;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;

  const MonthlyChartCard({
    super.key,
    required this.currentMonth,
    required this.sessions,
    required this.onPrevMonth,
    required this.onNextMonth,
  });

  @override
  Widget build(BuildContext context) {
    double totalDist = sessions.where((s) {
      return s.endTime.month == currentMonth.month &&
          s.endTime.year == currentMonth.year;
    }).fold(0.0, (sum, item) => sum + item.distanceKm);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: const Color(0xFF2D2D2D),
          borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildRunTag(),
              Row(
                children: [
                  IconButton(
                      icon: const Icon(Icons.chevron_left, color: Colors.white),
                      onPressed: onPrevMonth),
                  Text(DateFormat('MM / yyyy').format(currentMonth),
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  IconButton(
                      icon: const Icon(Icons.chevron_right, color: Colors.white),
                      onPressed: onNextMonth),
                ],
              )
            ],
          ),
          const SizedBox(height: 20),
          _buildStatsRow(totalDist),
          const SizedBox(height: 30),
          const Text('Past Monthly Run',
              style: TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 20),
          SizedBox(height: 200, child: _buildLineChart()),
        ],
      ),
    );
  }

  Widget _buildLineChart() {
    int daysInMonth = DateTime(currentMonth.year, currentMonth.month + 1, 0).day;

    List<FlSpot> spots = List.generate(daysInMonth, (index) {
      int day = index + 1;
      double dist = sessions.where((s) {
        return s.endTime.day == day &&
            s.endTime.month == currentMonth.month &&
            s.endTime.year == currentMonth.year;
      }).fold(0.0, (sum, item) => sum + item.distanceKm);

      return FlSpot(day.toDouble(), dist);
    });

    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => Colors.orangeAccent,
            tooltipRoundedRadius: 8,
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((barSpot) {
                return LineTooltipItem(
                  'Ngày ${barSpot.x.toInt()}\n${barSpot.y.toStringAsFixed(1)} km',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                );
              }).toList();
            },
          ),
          handleBuiltInTouches: true,
        ),
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 10,
              getTitlesWidget: (value, meta) {
                if (value < 1 || value > daysInMonth) return const SizedBox();
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  space: 8,
                  child: Text(
                    value.toInt().toString(),
                    style: const TextStyle(color: Colors.grey, fontSize: 10),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 1,
        maxX: daysInMonth.toDouble(),
        minY: 0,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.orange,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
                show: true,
                color: Colors.orange.withOpacity(0.1)
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(double dist) {
    int monthlyActivities = sessions.where((s) =>
    s.endTime.month == currentMonth.month &&
        s.endTime.year == currentMonth.year
    ).length;

    return Row(
      children: [
        _buildStatItem('Distance', '${dist.toStringAsFixed(1)} km'),
        const SizedBox(width: 40),
        _buildStatItem('Activities', '$monthlyActivities'),
        const SizedBox(width: 40),
        _buildStatItem('Elev Gain', '0 m'),
      ],
    );
  }

  Widget _buildRunTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
          border: Border.all(color: Colors.orange, width: 1.5),
          borderRadius: BorderRadius.circular(20)),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.directions_run, color: Colors.orange, size: 18),
          SizedBox(width: 6),
          Text('Run',
              style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.w600,
                  fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    );
  }
}