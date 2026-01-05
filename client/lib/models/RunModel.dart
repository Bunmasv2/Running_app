// lib/Models/RunModel.dart

class DailyGoal {
  final double targetDistanceKm;
  final double currentDistanceKm;

  DailyGoal({
    required this.targetDistanceKm,
    required this.currentDistanceKm,
  });

  // Tính phần trăm hoàn thành
  double get progress => targetDistanceKm == 0 ? 0 : (currentDistanceKm / targetDistanceKm);
}

class RunSession {
  final String id;
  final double distanceKm;
  final Duration duration;
  final double calories;

  RunSession({
    required this.id,
    required this.distanceKm,
    required this.duration,
    required this.calories,
  });
}