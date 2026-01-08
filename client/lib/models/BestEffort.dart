class BestEffort {
  final String title;
  final DateTime date;
  final String time;
  final bool isPersonalRecord;

  BestEffort({
    required this.title,
    required this.date,
    required this.time,
    this.isPersonalRecord = false,
  });
}
