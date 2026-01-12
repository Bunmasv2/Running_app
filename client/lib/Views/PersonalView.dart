import 'package:flutter/material.dart';
import '../Components/HeaderComponent.dart';
import '../models/RunModels.dart';
import '../Services/RunService.dart';
import '../Components/BestEffortsCard.dart';
import "../Components/MonthlyChartCard.dart";
import "../Components/TrainingLogCard.dart";
import '../Components/WeeklyGoalsCard.dart';
import '../Components/RelativeEffortCard.dart';
import 'HistoryView.dart';
import 'RankingView.dart';

class Personalview extends StatefulWidget {
  final ValueChanged<String?>? onSubtitleChanged;

  const Personalview({super.key, this.onSubtitleChanged});

  @override
  State<Personalview> createState() => _PersonalviewState();
}

class _PersonalviewState extends State<Personalview> {
  final RunService _runService = RunService();
  bool _isLoading = false;

  DateTime _currentMonthView = DateTime.now();
  List<RunHistoryDto> _monthlySessions = [];

  List<RunHistoryDto> _top2Sessions = [];

  List<RelativeEffort> _realativeEffort = [];

  DateTime _currentWeekStart = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
  List<RunHistoryDto> _weeklySessions = [];

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _loadMonthlyData(),
      _loadTop2Data(),
      _loadWeeklyData(),
      _loadRealativeEffort(),
    ]);
    if (mounted) setState(() => _isLoading = false);
  }

  // --- API Calls ---
  Future<void> _loadMonthlyData() async {
    // Load current month and 2 previous months to cover the 12-week chart
    List<Future<List<RunHistoryDto>>> futures = [];
    for (int i = 0; i < 3; i++) {
      DateTime date = DateTime(_currentMonthView.year, _currentMonthView.month - i, 1);
      futures.add(_runService.getMonthlyRunSessions(date.month, date.year));
    }

    final results = await Future.wait(futures);
    List<RunHistoryDto> allSessions = results.expand((x) => x).toList();

    setState(() => _monthlySessions = allSessions);
  }

  Future<void> _loadTop2Data() async {
    final data = await _runService.getTop2RunSessions();
    setState(() => _top2Sessions = data);
  }

  Future<void> _loadWeeklyData() async {
    DateTime start = _currentWeekStart;
    DateTime end = start.add(const Duration(days: 6));
    List<RunHistoryDto> sessions = [];

    // Lấy dữ liệu tháng của ngày bắt đầu tuần
    sessions.addAll(await _runService.getWeeklyRunSessions(start.month, start.year));

    // Nếu tuần vắt qua tháng khác, lấy thêm dữ liệu tháng đó
    if (start.month != end.month || start.year != end.year) {
      sessions.addAll(await _runService.getWeeklyRunSessions(end.month, end.year));
    }

    setState(() => _weeklySessions = sessions);
  }

  Future<void> _loadRealativeEffort() async {
    final data = await _runService.getRelativeEffort();
    setState(() => _realativeEffort = data);
}

  void _changeMonth(int offset) {
    setState(() {
      _currentMonthView = DateTime(_currentMonthView.year, _currentMonthView.month + offset);
    });
    _loadMonthlyData();
  }

  void _changeWeek(int offset) {
    setState(() {
      _currentWeekStart = _currentWeekStart.add(Duration(days: offset * 7));
    });
    _loadWeeklyData();
  }


  @override
  Widget build(BuildContext context) {
    return ScrollableHeaderTabsComponent(
      tabs: [
        HeaderTabItem(label: 'Tiến trình', content: _buildProgressContent(context)),
        HeaderTabItem(label: 'Hoạt động', content: _buildActivitiesContent()),
        HeaderTabItem(label: 'Xếp hạng', content: _buildRankContent()),
      ],
      backgroundColor: const Color(0xFF1A1A1A),
      activeColor: Colors.orange,
      onTabLabelChanged: (label) => widget.onSubtitleChanged?.call(label),
    );
  }

  Widget _buildProgressContent(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: Colors.orange));

    return SingleChildScrollView(
      child: Column(
        children: [
          MonthlyChartCard(
            currentMonth: _currentMonthView,
            sessions: _monthlySessions,
            onPrevMonth: () => _changeMonth(-1),
            onNextMonth: () => _changeMonth(1),
          ),

          const SizedBox(height: 20),

          BestEffortsCard(topSessions: _top2Sessions),

          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child:WeeklyGoalsCard(
                    weeklySessions: _weeklySessions,
                    weekStart: _currentWeekStart,
                  ),),
                  const SizedBox(width: 12),
                  Expanded(child: RelativeEffortCard(efforts: _realativeEffort)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          TrainingLogCard(
            weekStart: _currentWeekStart,
            weeklySessions: _weeklySessions,
            onPrevWeek: () => _changeWeek(-1),
            onNextWeek: () => _changeWeek(1),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }


  // Widget _buildRelativeEffortCard() {
  //   return Container(
  //     padding: const EdgeInsets.all(16),
  //     decoration: BoxDecoration(color: const Color(0xFF2D2D2D), borderRadius: BorderRadius.circular(12)),
  //     child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
  //       Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
  //         const Text('Relative Effort', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
  //         Icon(Icons.chevron_right, color: Colors.grey[600], size: 20),
  //       ]),
  //       const SizedBox(height: 12),
  //       const Text('89', style: TextStyle(color: Colors.orange, fontSize: 32, fontWeight: FontWeight.bold)),
  //       const SizedBox(height: 4),
  //       Text('Jan 5 - Jan 11,\n2026', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
  //     ]),
  //   );
  // }

  Widget _buildActivitiesContent() {
    return const HistoryView();
  }

  Widget _buildRankContent() {
    return const RankingView();
  }
}