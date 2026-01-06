import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/RunModels.dart';

class GoalService {
  // 1. SỬA IP: Dùng đúng IP LAN của máy tính (không dùng localhost trên điện thoại)
  static const String _baseUrl = 'https://running-app-ywpg.onrender.com/DailyGoal';
  // static const String _baseUrl = 'http://10.0.2.2:5144/Goal';
  // 2. TẮT MOCK DATA: Đặt thành false để gọi API thật
  final bool useMockData = false;
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('accessToken');
  }

  Future<Map<String, String>> _getHeaders() async {
    String? token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token', // Token này sẽ được gửi lên để [Authorize] ở server đọc
    };
  }

  // GET GOAL
  Future<DailyGoal?> getTodayGoal() async {
    // Nếu vẫn muốn test mock thì giữ logic này, không thì API thật sẽ chạy
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 800));
      return DailyGoal(targetDistanceKm: 5.0, currentDistanceKm: 2.3);
    }

    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$_baseUrl/today'), headers: headers);

      print("GET Goal Status: ${response.statusCode}");
      print("GET Goal Body: ${response.body}");

      if (response.statusCode == 200) {
        // Backend trả về null (chuỗi "null" hoặc rỗng) nghĩa là chưa đặt mục tiêu
        if (response.body.isEmpty || response.body == "null") {
          return null;
        }
        return DailyGoal.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      print("Lỗi get goal: $e");
      return null;
    }
  }

  // SET GOAL
  Future<DailyGoal?> setTodayGoal(double km) async {
    if (useMockData) return DailyGoal(targetDistanceKm: km, currentDistanceKm: 0.0);

    try {
      final headers = await _getHeaders();
      final body = jsonEncode({
        "targetDistanceKm": km
      });

      final response = await http.post(
          Uri.parse(_baseUrl),
          headers: headers,
          body: body
      );

      print("SET Goal Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        return DailyGoal.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      print("Lỗi set goal: $e");
      return null;
    }
  }
}