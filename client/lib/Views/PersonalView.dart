import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../Components/HeaderComponent.dart';
import '../models/BestEffort.dart';
import '../models/TrainingDay.dart';
import '../models/WeekData.dart';
import '../Services/UserService.dart';

class Personalview extends StatefulWidget {
  final ValueChanged<String?>? onSubtitleChanged;

  const Personalview({super.key, this.onSubtitleChanged});

  @override
  State<Personalview> createState() => _PersonalviewState();
}

class _PersonalviewState extends State<Personalview> {
  int _selectedDotIndex = 6; // Mặc định chọn dot cuối cùng (tuần hiện tại)
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // TODO: gọi API khi cần
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  // ====== LOGOUT ======
  void _handleLogout() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Đăng xuất"),
        content: const Text("Bạn có muốn đăng xuất khỏi ứng dụng?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text("Đăng xuất"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
            (route) => false,
      );
    }
  }

  // Dữ liệu mẫu cho 12 tuần (Past 12 weeks)
  final List<WeekData> _weeklyData = [
    WeekData(startDate: DateTime(2024, 10, 14), endDate: DateTime(2024, 10, 20), distance: 0, time: 0),
    WeekData(startDate: DateTime(2024, 10, 21), endDate: DateTime(2024, 10, 27), distance: 5.2, time: 32),
    WeekData(startDate: DateTime(2024, 10, 28), endDate: DateTime(2024, 11, 3), distance: 8.5, time: 52),
    WeekData(startDate: DateTime(2024, 11, 4), endDate: DateTime(2024, 11, 10), distance: 12.3, time: 75),
    WeekData(startDate: DateTime(2024, 11, 11), endDate: DateTime(2024, 11, 17), distance: 6.8, time: 42),
    WeekData(startDate: DateTime(2024, 11, 18), endDate: DateTime(2024, 11, 24), distance: 15.2, time: 93),
    WeekData(startDate: DateTime(2024, 11, 25), endDate: DateTime(2024, 12, 1), distance: 0, time: 0),
    WeekData(startDate: DateTime(2024, 12, 2), endDate: DateTime(2024, 12, 8), distance: 0, time: 0),
    WeekData(startDate: DateTime(2024, 12, 9), endDate: DateTime(2024, 12, 15), distance: 0, time: 0),
    WeekData(startDate: DateTime(2024, 12, 16), endDate: DateTime(2024, 12, 22), distance: 0, time: 0),
    WeekData(startDate: DateTime(2024, 12, 23), endDate: DateTime(2024, 12, 29), distance: 0, time: 0),
    WeekData(startDate: DateTime(2024, 12, 30), endDate: DateTime(2025, 1, 5), distance: 0, time: 0),
  ];

  @override
  Widget build(BuildContext context) {
    return ScrollableHeaderTabsComponent(
      tabs: [
        HeaderTabItem(label: 'Tiến trình', content: _buildProgressContent(context)),
        HeaderTabItem(label: 'Hoạt động', content: _buildActivitiesContent()),
      ],
      backgroundColor: const Color(0xFF1A1A1A),
      activeColor: Colors.orange,
      onTabLabelChanged: (label) {
        widget.onSubtitleChanged?.call(label);
      },
    );
  }

  // --- Tab Tiến trình (Progress) ---
  Widget _buildProgressContent(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Widget 1: Card thống kê tiến trình + Line Chart
          _buildWidget1ProgressCard(),
          const SizedBox(height: 20),
          // Widget 2: Cards nỗ lực (Best Efforts, Goals, Relative Effort, Training Log)
          _buildWidget2Cards(),
  const SizedBox(height: 30),
  Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16),
  child: SizedBox(
  width: double.infinity,
  child: ElevatedButton.icon(
  icon: const Icon(Icons.logout),
  label: const Text(
  'Đăng xuất',
  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
  ),
  style: ElevatedButton.styleFrom(
  backgroundColor: Colors.redAccent,
  foregroundColor: Colors.white,
  padding: const EdgeInsets.symmetric(vertical: 14),
  shape: RoundedRectangleBorder(
  borderRadius: BorderRadius.circular(12),
  ),
  ),
  onPressed: _handleLogout,
  ),
  ),
  ),
  const SizedBox(height: 30),
        ],
      ),
    );
  }

  // ============================================
  // WIDGET 1:  thống kê tiến trình + Chart
  // ============================================
  Widget _buildWidget1ProgressCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Run button/tag
          _buildRunTag(),
          const SizedBox(height: 20),
          // Ngày được chọn
          _buildSelectedDateText(),
          const SizedBox(height: 20),
          // Thống kê Distance, Time, Elev Gain
          _buildStatsRow(),
          const SizedBox(height: 30),
          // Past 12 weeks label
          const Text(
            'Past 12 weeks',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 20),
          // Line Chart
          SizedBox(
            height: 200,
            child: _buildLineChart(),
          ),
        ],
      ),
    );
  }

  // --- Widget 1 Components ---
  Widget _buildRunTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.orange, width: 1.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.directions_run, color: Colors.orange, size: 18),
          const SizedBox(width: 6),
          const Text(
            'Run',
            style: TextStyle(
              color: Colors.orange,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedDateText() {
    final selectedWeek = _weeklyData[_selectedDotIndex];
    return Text(
      _formatDateRange(selectedWeek.startDate, selectedWeek.endDate),
      style: const TextStyle(
        color: Colors.white,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildStatsRow() {
    final selectedWeek = _weeklyData[_selectedDotIndex];
    return Row(
      children: [
        _buildStatItem('Distance', '${selectedWeek.distance.toStringAsFixed(0)} km'),
        const SizedBox(width: 40),
        _buildStatItem('Time', '${selectedWeek.time}m'),
        const SizedBox(width: 40),
        _buildStatItem('Elev Gain', '0 m'),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // --- Line Chart với fl_chart ---
  Widget _buildLineChart() {
    // Tìm giá trị max để scale trục Y
    double maxDistance = _weeklyData.map((w) => w.distance).reduce((a, b) => a > b ? a : b);
    if (maxDistance == 0) maxDistance = 10; // Default nếu tất cả = 0

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxDistance / 2,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withOpacity(0.2),
              strokeWidth: 1,
              dashArray: [5, 5],
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                // Hiển thị nhãn tháng ở vị trí phù hợp
                if (index == 2) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text('NOV', style: TextStyle(color: Colors.grey, fontSize: 11)),
                  );
                } else if (index == 6) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text('DEC', style: TextStyle(color: Colors.grey, fontSize: 11)),
                  );
                } else if (index == 10) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text('JAN', style: TextStyle(color: Colors.grey, fontSize: 11)),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: maxDistance / 2,
              reservedSize: 45,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toStringAsFixed(0)} km',
                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: 11,
        minY: 0,
        maxY: maxDistance + 2,
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => Colors.orange,
            tooltipRoundedRadius: 8,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final week = _weeklyData[spot.x.toInt()];
                return LineTooltipItem(
                  '${week.distance} km\n${_formatShortDate(week.startDate)}',
                  const TextStyle(color: Colors.white, fontSize: 12),
                );
              }).toList();
            },
          ),
          touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
            if (touchResponse != null && touchResponse.lineBarSpots != null) {
              if (touchResponse.lineBarSpots!.isNotEmpty) {
                setState(() {
                  _selectedDotIndex = touchResponse.lineBarSpots!.first.x.toInt();
                });
              }
            }
          },
          handleBuiltInTouches: true,
        ),
        extraLinesData: ExtraLinesData(
          verticalLines: [
            VerticalLine(
              x: _selectedDotIndex.toDouble(),
              color: Colors.white.withOpacity(0.5),
              strokeWidth: 1,
              dashArray: [5, 5],
            ),
          ],
        ),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(_weeklyData.length, (index) {
              return FlSpot(index.toDouble(), _weeklyData[index].distance);
            }),
            isCurved: false,
            color: Colors.orange,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                final isSelected = index == _selectedDotIndex;
                return FlDotCirclePainter(
                  radius: isSelected ? 8 : 5,
                  color: isSelected ? Colors.orange : Colors.orange.withOpacity(0.7),
                  strokeWidth: isSelected ? 3 : 0,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
    );
  }

  // --- Widget 2: Cards thống kê nỗ lực ---
  Widget _buildWidget2Cards() {
    return Column(
      children: [
        // Container 1: Best Efforts
        _buildBestEffortsCard(),
        const SizedBox(height: 16),

        // Container 2 & 3: Goals + Relative Effort (Row)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(child: _buildGoalsCard()),
              const SizedBox(width: 12),
              Expanded(child: _buildRelativeEffortCard()),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Container 4: Training Log
        _buildTrainingLogCard(),
        const SizedBox(height: 20),
      ],
    );
  }

  // --- Card 1: Best Efforts (Nỗ lực tốt nhất) ---
  Widget _buildBestEffortsCard() {
    // Dữ liệu mẫu - sắp xếp theo km cao nhất, thời gian thấp nhất
    final bestEfforts = [
      BestEffort(title: '5K PR', date: DateTime(2026, 1, 8), time: '26:54', isPersonalRecord: true),
      BestEffort(title: '2nd-fastest 5K', date: DateTime(2025, 1, 8), time: '30:12', isPersonalRecord: false),
    ];

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
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[600]),
            ],
          ),
          const SizedBox(height: 16),
          ...bestEfforts.map((effort) => _buildEffortItem(effort)).toList(),
        ],
      ),
    );
  }

  Widget _buildEffortItem(BestEffort effort) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Medal icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: effort.isPersonalRecord
                  ? Colors.orange.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.emoji_events,
              color: effort.isPersonalRecord ? Colors.orange : Colors.grey,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          // Title and date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  effort.title,
                  style: TextStyle(
                    color: effort.isPersonalRecord ? Colors.orange : Colors.grey,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _formatFullDate(effort.date),
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Time
          Text(
            effort.time,
            style: TextStyle(
              color: effort.isPersonalRecord ? Colors.white : Colors.grey,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // --- Card 2: Goals (Mục tiêu) ---
  Widget _buildGoalsCard() {
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
                'Goals',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[600], size: 20),
            ],
          ),
          const SizedBox(height: 12),
          // Progress ring
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey[700]!, width: 3),
            ),
            child: Center(
              child: Icon(Icons.directions_run, color: Colors.grey[500], size: 24),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Weekly Run Goal',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '1/4 runs',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // --- Card 3: Relative Effort (Nỗ lực tương đối) ---
  Widget _buildRelativeEffortCard() {
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
                'Relative Effort',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[600], size: 20),
            ],
          ),
          const SizedBox(height: 12),
          // Main score
          const Text(
            '89',
            style: TextStyle(
              color: Colors.orange,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'thg 1 5 - thg 1 11,\n2026',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '22',
            style: TextStyle(
              color: Colors.orange,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // --- Card 4: Training Log (Log luyện tập) ---
  Widget _buildTrainingLogCard() {
    // Dữ liệu 7 ngày trong tuần
    final trainingData = [
      TrainingDay(day: 'T2', timeOfDay: 'Sáng', distance: 3.2),
      TrainingDay(day: 'T3', timeOfDay: '-', distance: 0),
      TrainingDay(day: 'T4', timeOfDay: 'Tối', distance: 5.1),
      TrainingDay(day: 'T5', timeOfDay: '-', distance: 0),
      TrainingDay(day: 'T6', timeOfDay: 'Chiều', distance: 2.6),
      TrainingDay(day: 'T7', timeOfDay: 'Sáng', distance: 0),
      TrainingDay(day: 'CN', timeOfDay: '-', distance: 0),
    ];

    // Tính tổng km
    final totalKm = trainingData.fold(0.0, (sum, day) => sum + day.distance);

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
                'Training Log',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${totalKm.toStringAsFixed(1)} km',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'thg 1 5 - thg 1 11, 2026',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          // Header row: Days
          Row(
            children: trainingData.map((day) {
              return Expanded(
                child: Center(
                  child: Text(
                    day.day,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          // Row 1: Time of day (Sáng, Tối, Chiều, ...)
          Row(
            children: trainingData.map((day) {
              return Expanded(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    decoration: BoxDecoration(
                      color: day.distance > 0
                          ? Colors.orange.withOpacity(0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      day.timeOfDay,
                      style: TextStyle(
                        color: day.distance > 0 ? Colors.orange : Colors.grey[600],
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 6),
          // Row 2: Distance (km)
          Row(
            children: trainingData.map((day) {
              return Expanded(
                child: Center(
                  child: Text(
                    day.distance > 0 ? '${day.distance.toStringAsFixed(1)}' : '-',
                    style: TextStyle(
                      color: day.distance > 0 ? Colors.white : Colors.grey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _formatFullDate(DateTime date) {
    return 'thg ${date.month} ${date.day}, ${date.year}';
  }

  // --- Tab Hoạt động (Activities) ---
  Widget _buildActivitiesContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.directions_run, size: 64, color: Colors.grey.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            'Chưa có hoạt động nào',
            style: TextStyle(
              color: Colors.grey.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper functions ---
  String _formatDateRange(DateTime start, DateTime end) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[start.month - 1]} ${start.day} - ${months[end.month - 1]} ${end.day}, ${end.year}';
  }

  String _formatShortDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }
}






