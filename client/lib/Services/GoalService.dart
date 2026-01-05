import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
// import '../models/DailyGoalModel.dart'
import '../models/RunModels.dart';

class GoalService {
  // Đổi thành IP máy tính nếu chạy máy thật (VD: 192.168.1.x:5000)
  static const String _baseUrl = 'https://running-app-ywpg.onrender.com/Goal';

  // Bật true để test giao diện trước khi có Backend chạy ổn định
  final bool useMockData = true;

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

  // 1. Lấy mục tiêu hôm nay (GET /Goal/today)
  Future<DailyGoal?> getTodayGoal() async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 800));
      // Giả lập: 50% là chưa đặt (null), 50% là đã đặt
      // return null;
      return DailyGoal(targetDistanceKm: 5.0, currentDistanceKm: 2.3);
    }

    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$_baseUrl/today'), headers: headers);

      if (response.statusCode == 200) {
        if (response.body.isEmpty || response.body == "null") return null;
        return DailyGoal.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      print("Lỗi get goal: $e");
      return null;
    }
  }

  // 2. Đặt mục tiêu mới (POST /Goal)
  Future<DailyGoal?> setTodayGoal(double km) async {
    if (useMockData) {
      await Future.delayed(const Duration(seconds: 1));
      return DailyGoal(targetDistanceKm: km, currentDistanceKm: 0.0);
    }

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