import 'dart:convert'; // Để dùng jsonDecode
import 'package:google_maps_flutter/google_maps_flutter.dart'; // Để dùng LatLng

class RunDetailResponse {
  final int id;
  final double distanceKm;
  final double caloriesBurned;
  final List<LatLng> routePoints; // FE dùng List<LatLng>, không dùng String

  RunDetailResponse({
    required this.id,
    required this.distanceKm,
    required this.caloriesBurned,
    required this.routePoints,
  });

  factory RunDetailResponse.fromJson(Map<String, Object?> json) {
    // 1. Lấy chuỗi JSON từ Server
    String routeString = json['routeJson'] as String? ?? '[]';

    // 2. Parse chuỗi đó thành List object
    List<dynamic> parsedList = jsonDecode(routeString);

    // 3. Chuyển đổi an toàn từng phần tử thành LatLng
    // Giả sử JSON lưu dạng: [{"lat": 10.1, "lng": 105.2}, ...]
    List<LatLng> points = parsedList.map((item) {
      final Map<String, dynamic> pointMap = item as Map<String, dynamic>;
      return LatLng(
        (pointMap['lat'] as num).toDouble(),
        (pointMap['lng'] as num).toDouble(),
      );
    }).toList();

    return RunDetailResponse(
      id: json['id'] as int,
      distanceKm: (json['distanceKm'] as num).toDouble(),
      caloriesBurned: (json['caloriesBurned'] as num).toDouble(),
      routePoints: points, // Đã có dữ liệu để vẽ Polyline
    );
  }
}
