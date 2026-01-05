import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Cần import
import '../Models/RunModels.dart'; // File model bạn đã tạo

class RunService {
  // URL Server Render (Lưu ý: Backend bạn đặt Route là [controller] nên path là /run hoặc /Run)
  static const String _baseUrl = 'https://running-app-ywpg.onrender.com/run';

  // Helper lấy token (Giống bên UserService)
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('accessToken');
  }

  Future<Map<String, String>> _getHeaders() async {
    String? token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // 1. LƯU BÀI CHẠY (SAVE)
  Future<bool> saveRun({
    required double distance,
    required double calories,
    required Duration duration,
    required List<LatLng> routePoints,
  }) async {
    try {
      final headers = await _getHeaders();

      // Convert tọa độ
      List<Map<String, double>> coords = routePoints.map((p) => {
        "latitude": p.latitude,
        "longitude": p.longitude
      }).toList();

      double hours = duration.inSeconds / 3600;
      double avgSpeed = hours > 0 ? distance / hours : 0;

      final dto = RunCreateDto(
        distanceKm: distance,
        calories: calories,
        durationSeconds: duration.inSeconds,
        avgSpeedKmh: avgSpeed,
        routePoints: coords,
      );

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: headers, // Token được gửi ở đây
        body: jsonEncode(dto.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
      print('Lỗi Save Run: ${response.body}');
      return false;
    } catch (e) {
      print('Lỗi kết nối: $e');
      return false;
    }
  }

  // 2. LẤY LỊCH SỬ CHẠY (HISTORY)
  Future<List<RunHistoryDto>> getRunHistory({int pageIndex = 1}) async {
    try {
      final headers = await _getHeaders();

      final uri = Uri.parse('$_baseUrl/history').replace(queryParameters: {
        'pageIndex': pageIndex.toString(),
        'pageSize': '10',
      });

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => RunHistoryDto.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      print('Lỗi lấy lịch sử: $e');
      return [];
    }
  }
}