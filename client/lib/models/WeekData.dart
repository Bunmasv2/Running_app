import 'RunModels.dart';

class WeekData {
  final DateTime startDate;
  final DateTime endDate;
  final double totalDistance;
  final int totalDuration;
  final double totalCalories;
  final List<RunHistoryDto> sessions;
  final int index;

  WeekData({
    required this.startDate,
    required this.endDate,
    required this.totalDistance,
    required this.totalDuration,
    required this.totalCalories,
    required this.sessions,
    required this.index
  });
}
