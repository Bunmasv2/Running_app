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
    try {
      await Future.wait([
        _loadMonthlyData(),
        _loadTop2Data(),
        _loadWeeklyData(),
        _loadRealativeEffort(),
      ]);
    } catch (e) {
      debugPrint("Lỗi tải dữ liệu Dashboard: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMonthlyData() async {
    List<Future<List<RunHistoryDto>>> futures = [];
    for (int i = 0; i < 3; i++) {
      DateTime date = DateTime(_currentMonthView.year, _currentMonthView.month - i, 1);
      futures.add(_runService.getMonthlyRunSessions(date.month, date.year));
    }
    final results = await Future.wait(futures);
    if (mounted) {
      setState(() => _monthlySessions = results.expand((x) => x).toList());
    }
  }

  Future<void> _loadTop2Data() async {
    final data = await _runService.getTop2RunSessions();
    if (mounted) setState(() => _top2Sessions = data);
  }

  Future<void> _loadWeeklyData() async {
    DateTime start = _currentWeekStart;
    DateTime end = start.add(const Duration(days: 6));
    List<RunHistoryDto> sessions = [];

    sessions.addAll(await _runService.getWeeklyRunSessions(start.month, start.year));
    if (start.month != end.month || start.year != end.year) {
      sessions.addAll(await _runService.getWeeklyRunSessions(end.month, end.year));
    }
    if (mounted) setState(() => _weeklySessions = sessions);
  }

  Future<void> _loadRealativeEffort() async {
    final data = await _runService.getRelativeEffort();
    if (mounted) setState(() => _realativeEffort = data);
  }

  void _changeMonth(int offset) {
    setState(() => _currentMonthView = DateTime(_currentMonthView.year, _currentMonthView.month + offset));
    _loadMonthlyData();
  }

  void _changeWeek(int offset) {
    setState(() => _currentWeekStart = _currentWeekStart.add(Duration(days: offset * 7)));
    _loadWeeklyData();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return ScrollableHeaderTabsComponent(
      tabs: [
        HeaderTabItem(label: 'Tiến trình', content: _buildProgressContent(context, size)),
        HeaderTabItem(label: 'Hoạt động', content: const HistoryView()),
        HeaderTabItem(label: 'Xếp hạng', content: const RankingView()),
      ],
      backgroundColor: const Color(0xFF1A1A1A),
      activeColor: Colors.orange,
      onTabLabelChanged: (label) => widget.onSubtitleChanged?.call(label),
    );
  }

  Widget _buildProgressContent(BuildContext context, Size size) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.orange));
    }

    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: size.height * 0.05),
      child: Column(
        children: [
          MonthlyChartCard(
            currentMonth: _currentMonthView,
            sessions: _monthlySessions,
            onPrevMonth: () => _changeMonth(-1),
            onNextMonth: () => _changeMonth(1),
          ),

          SizedBox(height: size.height * 0.02),

          BestEffortsCard(topSessions: _top2Sessions),

          SizedBox(height: size.height * 0.02),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: size.width * 0.04),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: WeeklyGoalsCard(
                      weeklySessions: _weeklySessions,
                      weekStart: _currentWeekStart,
                    ),
                  ),
                  SizedBox(width: size.width * 0.03),
                  Expanded(
                    child: RelativeEffortCard(efforts: _realativeEffort),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: size.height * 0.02),

          TrainingLogCard(
            weekStart: _currentWeekStart,
            weeklySessions: _weeklySessions,
            onPrevWeek: () => _changeWeek(-1),
            onNextWeek: () => _changeWeek(1),
          ),
        ],
      ),
    );
  }
}