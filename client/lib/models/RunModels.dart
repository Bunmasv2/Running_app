// lib/Models/RunModels.dart

import 'package:latlong2/latlong.dart';

// 1. DTO để gửi đi khi Save (POST)
class RunCreateDto {
  final double distanceKm;
  final double calories;
  final int durationSeconds;
  final double avgSpeedKmh;
  final List<Map<String, double>> routePoints; // List tọa độ

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

// 2. DTO để nhận về lịch sử (GET History)
class RunHistoryDto {
  final int id;
  final double distanceKm;
  final int durationSeconds;
  final double calories;
  final DateTime createdAt;
  final String? previewMapUrl; // Nếu server có trả về ảnh map nhỏ

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