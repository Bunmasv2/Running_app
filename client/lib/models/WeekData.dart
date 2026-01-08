/// Model cho dữ liệu tuần
class WeekData {
  final DateTime startDate;
  final DateTime endDate;
  final double distance; // km
  final int time; // phút

  WeekData({
    required this.startDate,
    required this.endDate,
    required this.distance,
    required this.time,
  });
}

