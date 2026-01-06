// lib/Services/TrackingService.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class TrackingService {

  // static const String _baseUrl = 'https://running-app-ywpg.onrender.com/run/history';
  static const String _baseUrl = 'http://10.0.2.2:5144/Run/history';
  Future<bool> saveRunSession({
    required double distanceKm,
    required double calories,
    required Duration duration,
    required List<LatLng> routePoints,
  }) async {
    try {
      // 1. Chuẩn bị dữ liệu body (theo format server bạn yêu cầu)
      // Chuyển List<LatLng> thành List<Map> để gửi JSON
      List<Map<String, double>> coordinates = routePoints.map((point) {
        return {
          'latitude': point.latitude,
          'longitude': point.longitude,
        };
      }).toList();

      final Map<String, dynamic> body = {
        'distance': distanceKm,
        'calories': calories,
        'duration_seconds': duration.inSeconds, // Gửi giây cho chuẩn
        'route': coordinates,
        'created_at': DateTime.now().toIso8601String(),
      };

      // 2. Gọi API POST
      final http.Response response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          // 'Authorization': 'Bearer ...' // Thêm token nếu server yêu cầu đăng nhập
        },
        body: jsonEncode(body),
      );

      // 3. Kiểm tra kết quả (200 hoặc 201 là thành công)
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print('Server Error: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Connection Error: $e');
      return false;
    }
  }
}