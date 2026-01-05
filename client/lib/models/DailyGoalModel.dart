class DailyGoal {
  final double targetDistanceKm;
  final double currentDistanceKm;

  DailyGoal({
    required this.targetDistanceKm,
    required this.currentDistanceKm,
  });

  // Tính phần trăm (0.0 -> 1.0)
  double get progress {
    if (targetDistanceKm <= 0) return 0;
    double p = currentDistanceKm / targetDistanceKm;
    return p > 1.0 ? 1.0 : p; // Không vượt quá 100%
  }

  // Parse JSON từ Backend
  factory DailyGoal.fromJson(Map<String, dynamic> json) {
    return DailyGoal(
      targetDistanceKm: (json['targetDistanceKm'] as num?)?.toDouble() ?? 0.0,
      currentDistanceKm: (json['currentDistanceKm'] as num?)?.toDouble() ?? 0.0,
    );
  }
}