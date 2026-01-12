import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/RunModels.dart';
import '../models/WeekData.dart';

class MonthlyChartCard extends StatefulWidget {
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
  State<MonthlyChartCard> createState() => _MonthlyChartCardState();
}

class _MonthlyChartCardState extends State<MonthlyChartCard> {
  late int _selectedIndex;

  // Cache calculated weeks data to avoid recalculating on every build/touch
  List<WeekData> _weeksData = [];

  @override
  void initState() {
    super.initState();
    _calculateWeeksData();
    _setInitialIndex();
  }

  @override
  void didUpdateWidget(MonthlyChartCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentMonth != widget.currentMonth || oldWidget.sessions != widget.sessions) {
      _calculateWeeksData();
      _setInitialIndex();
    }
  }

  void _setInitialIndex() {
    // Logic: Find the week that contains "today". If found, select it.
    // If not found (browsing past history), default to 11 (latest week in that view).
    DateTime now = DateTime.now();
    int foundIndex = -1;

    for (var w in _weeksData) {
      DateTime start = DateTime(w.startDate.year, w.startDate.month, w.startDate.day);
      DateTime end = DateTime(w.endDate.year, w.endDate.month, w.endDate.day, 23, 59, 59);
      if (now.compareTo(start) >= 0 && now.compareTo(end) <= 0) {
        foundIndex = w.index;
        break;
      }
    }

    setState(() {
      _selectedIndex = foundIndex != -1 ? foundIndex : 11;
    });
  }

  void _calculateWeeksData() {
    _weeksData = [];
    DateTime lastDayOfMonth = DateTime(widget.currentMonth.year, widget.currentMonth.month + 1, 0);
    DateTime endReference = lastDayOfMonth;

    for (int i = 0; i < 12; i++) {
        int weeksAgo = 11 - i;
        DateTime weekEnd = endReference.subtract(Duration(days: 7 * weeksAgo));
        DateTime weekStart = weekEnd.subtract(const Duration(days: 6));

        DateTime rStart = DateTime(weekStart.year, weekStart.month, weekStart.day);
        DateTime rEnd = DateTime(weekEnd.year, weekEnd.month, weekEnd.day, 23, 59, 59);

        // Filter sessions for this week
        var weekSessions = widget.sessions.where((s) {
            return s.endTime.isAfter(rStart.subtract(const Duration(seconds: 1))) &&
                   s.endTime.isBefore(rEnd.add(const Duration(seconds: 1)));
        }).toList();

        double dist = weekSessions.fold(0.0, (sum, item) => sum + item.distanceKm);
        int duration = weekSessions.fold(0, (sum, item) => sum + item.durationSeconds);
        double calories = weekSessions.fold(0.0, (sum, item) => sum + item.calories);

        _weeksData.add(WeekData(
            startDate: weekStart,
            endDate: weekEnd,
            totalDistance: dist,
            totalDuration: duration,
            totalCalories: calories,
            sessions: weekSessions,
            index: i
        ));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Current selected data
    final selectedWeek = _weeksData.isNotEmpty && _selectedIndex < _weeksData.length
        ? _weeksData[_selectedIndex]
        : _weeksData.last; // Fallback

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
                children: [ // Navigation for months (kept as requested)
                  IconButton(
                      icon: const Icon(Icons.chevron_left, color: Colors.white),
                      onPressed: widget.onPrevMonth),
                  // Keeping the month display if user still wants to navigate "Chart Context"
                  // But the main header text below will show specific week.
                  IconButton(
                      icon: const Icon(Icons.chevron_right, color: Colors.white),
                      onPressed: widget.onNextMonth),
                ],
              )
            ],
          ),
          const SizedBox(height: 10),

          // Dynamic Header Text (Date Range)
          Text(
            "${DateFormat('MMM d').format(selectedWeek.startDate)} - ${DateFormat('MMM d, yyyy').format(selectedWeek.endDate)}",
            style: const TextStyle(
                color: Colors.white,
                fontSize: 20, // Large text
                fontWeight: FontWeight.bold
            ),
          ),

          const SizedBox(height: 20),
          _buildStatsRow(selectedWeek),
          const SizedBox(height: 30),

          const Text('Past 12 weeks',
              style: TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 20),
          // Chart
          SizedBox(height: 200, child: _buildLineChart()),
        ],
      ),
    );
  }

  Widget _buildLineChart() {
    List<FlSpot> spots = _weeksData.map((w) => FlSpot(w.index.toDouble(), w.totalDistance)).toList();

    double rawMaxY = spots.isEmpty ? 0 : spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);

    // Nice steps logic
    double maxY = 3;
    double interval = 1;

    if (rawMaxY > 3) {
      double rawInterval = rawMaxY / 3;
      interval = rawInterval.ceilToDouble(); // Integer interval
      maxY = interval * 3;
      // Ensure we cover rawMaxY
      if (maxY < rawMaxY) maxY += interval;
    }

    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          // Ensure we capture touches to update the selected index
          touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
            if (!event.isInterestedForInteractions || response == null || response.lineBarSpots == null) {
              return;
            }
            if (response.lineBarSpots!.isNotEmpty) {
               final spotIndex = response.lineBarSpots!.first.x.toInt();
               if (spotIndex != _selectedIndex && spotIndex >= 0 && spotIndex < 12) {
                 setState(() {
                   _selectedIndex = spotIndex;
                 });
               }
            }
          },
          handleBuiltInTouches: false, // Disable default tooltips and indicators
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withValues(alpha: 0.3),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              interval: interval,
              getTitlesWidget: (value, meta) {
                if (value < 0) return const SizedBox();
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  space: 8,
                  child: Text(
                    '${value.toInt()} km',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                int index = value.toInt();
                if (index == 1 || index == 5 || index == 9) {
                     // Use cached week data for label
                     if (index < _weeksData.length) {
                        return SideTitleWidget(
                            axisSide: meta.axisSide,
                            space: 8,
                            child: Text(
                                DateFormat('MMM').format(_weeksData[index].endDate).toUpperCase(),
                                style: const TextStyle(color: Colors.white, fontSize: 10),
                            ),
                        );
                     }
                }
                return const SizedBox();
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: 11,
        minY: 0,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false,
            color: Colors.deepOrange,
            barWidth: 2,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                // Highlight selected dot
                bool isSelected = (index == _selectedIndex);
                return FlDotCirclePainter(
                  radius: isSelected ? 6 : 3.5,
                  color: isSelected ? Colors.deepOrange : const Color(0xFF2D2D2D),
                  strokeColor: Colors.deepOrange,
                  strokeWidth: 2,
                );
              },
            ),
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(WeekData data) {
    return Row(
      children: [
        _buildStatItem('Distance', '${data.totalDistance.toStringAsFixed(2)} km'),
        const SizedBox(width: 30),
        _buildStatItem('Time', _formatDuration(data.totalDuration)),
        const SizedBox(width: 30),
        _buildStatItem('Calories', '${data.totalCalories.round()} kcal'),
      ],
    );
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) return '${seconds}s';
    int minutes = (seconds / 60).truncate();
    if (minutes < 60) return '${minutes}m';
    int hours = (minutes / 60).truncate();
    int remMin = minutes % 60;
    return '${hours}h ${remMin}m';
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

