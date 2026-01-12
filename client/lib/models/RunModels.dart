import 'package:latlong2/latlong.dart';
import 'dart:convert';

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

class RunHistoryDto {
  final int id;
  final double distanceKm;
  final int durationSeconds;
  final double calories;
  final DateTime createdAt;
  final DateTime endTime;
  final double? targetDistance;
  final String? previewMapUrl;

  RunHistoryDto({
    required this.id,
    required this.distanceKm,
    required this.durationSeconds,
    required this.calories,
    required this.createdAt,
    required this.endTime,
    this.targetDistance,
    this.previewMapUrl,
  });

  factory RunHistoryDto.fromJson(Map<String, dynamic> json) {
    return RunHistoryDto(
      id: json['id'] ?? 0,
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0.0,
      durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0, // Cast an toàn
      calories: (json['caloriesBurned'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      endTime: DateTime.tryParse(json['endTime'] ?? '') ?? DateTime.now(),
      targetDistance: (json['targetDistance'] as num?)?.toDouble() ?? 0.0,
      previewMapUrl: json['previewMapUrl'],
    );
  }
}

class RunDetailDto {
  final int id;
  final double distanceKm;
  final double calories;
  final int durationSeconds;
  final DateTime createdAt;
  final List<LatLng> routePoints;

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

    if (json['routeJson'] != null && json['routeJson'].toString().isNotEmpty) {
      try {
        final List<dynamic> list = jsonDecode(json['routeJson']);

        points = list.map((p) => LatLng(
          (p['latitude'] ?? p['lat'] as num).toDouble(),
          (p['longitude'] ?? p['lng'] as num).toDouble(),
        )).toList();
      } catch (e) {
        // debugPrint("❌ Lỗi parse routeJson: $e");
      }
    }

    return RunDetailDto(
      id: json['id'] ?? 0,
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0.0,
      calories: (json['caloriesBurned'] as num?)?.toDouble() ?? 0.0,
      durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0, // Cast an toàn
      createdAt: DateTime.tryParse(json['startTime'] ?? json['createdAt'] ?? '') ?? DateTime.now(),
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

  double get progress {
    if (targetDistanceKm <= 0) return 0;
    double p = currentDistanceKm / targetDistanceKm;
    return p > 1.0 ? 1.0 : p;
  }

  // Parse JSON từ Backend
  factory DailyGoal.fromJson(Map<String, dynamic> json) {
    return DailyGoal(
      targetDistanceKm: (json['targetDistanceKm'] as num?)?.toDouble() ?? 0.0,
      currentDistanceKm: (json['currentDistanceKm'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class RelativeEffort {
  final int id;
  final DateTime startTime;
  final DateTime endTime;
  final double distanceKm;
  final double durationSeconds;
  final double caloriesBurned;
  final double targetDistanceKm;
  final double progressPercent;

  RelativeEffort({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.distanceKm,
    required this.durationSeconds,
    required this.caloriesBurned,
    required this.targetDistanceKm,
    required this.progressPercent,
  });

  factory RelativeEffort.fromJson(Map<String, dynamic> json) {
    return RelativeEffort(
      id: json['id'],
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      distanceKm: (json['distanceKm'] as num).toDouble(),
      durationSeconds: (json['durationSeconds'] as num).toDouble(),
      caloriesBurned: (json['caloriesBurned'] as num).toDouble(),
      targetDistanceKm: (json['targetDistanceKm'] as num).toDouble(),
      progressPercent: (json['progressPercent'] as num).toDouble(),
    );
  }
}
