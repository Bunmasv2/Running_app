import 'package:latlong2/latlong.dart';

// 1. DTO Save (Giữ nguyên của bạn)
class RunCreateDto {
  final double distanceKm;
  final double calories;
  final int durationSeconds;
  final double avgSpeedKmh;
  final List<Map<String, double>> routePoints;

  RunCreateDto({
    required this.distanceKm,
    required this.calories,
    required this.durationSeconds,
    required this.avgSpeedKmh,
    required this.routePoints,
  });

  Map<String, dynamic> toJson() {
    return {
      "distanceKm": distanceKm,
      "calories": calories,
      "durationSeconds": durationSeconds,
      "avgSpeedKmh": avgSpeedKmh,
      "routePoints": routePoints,
    };
  }
}

// 2. DTO History List (Giữ nguyên của bạn)
class RunHistoryDto {
  final int id;
  final double distanceKm;
  final int durationSeconds;
  final double calories;
  final DateTime createdAt;
  final String? previewMapUrl;

  RunHistoryDto({
    required this.id,
    required this.distanceKm,
    required this.durationSeconds,
    required this.calories,
    required this.createdAt,
    this.previewMapUrl,
  });

  factory RunHistoryDto.fromJson(Map<String, dynamic> json) {
    return RunHistoryDto(
      id: json['id'] ?? 0,
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0.0,
      durationSeconds: json['durationSeconds'] ?? 0,
      calories: (json['calories'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      previewMapUrl: json['previewMapUrl'],
    );
  }
}

// 3. [MỚI] DTO Chi tiết (Dùng để vẽ lại Map theo Requirement 3.4)
class RunDetailDto {
  final int id;
  final double distanceKm;
  final double calories;
  final int durationSeconds;
  final DateTime createdAt;
  final List<LatLng> routePoints; // List tọa độ để vẽ map

  RunDetailDto({
    required this.id,
    required this.distanceKm,
    required this.calories,
    required this.durationSeconds,
    required this.createdAt,
    required this.routePoints,
  });

  factory RunDetailDto.fromJson(Map<String, dynamic> json) {
    List<LatLng> points = [];
    // Parse 'routePoints' từ backend trả về
    if (json['routePoints'] != null) {
      try {
        var list = json['routePoints'] as List;
        points = list.map((p) => LatLng(
          (p['latitude'] ?? p['lat'] as num).toDouble(),
          (p['longitude'] ?? p['lng'] as num).toDouble(),
        )).toList();
      } catch (e) {
        print("Lỗi parse route: $e");
      }
    }

    return RunDetailDto(
      id: json['id'] ?? 0,
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0.0,
      calories: (json['calories'] as num?)?.toDouble() ?? 0.0,
      durationSeconds: json['durationSeconds'] ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      routePoints: points,
    );
  }
}

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