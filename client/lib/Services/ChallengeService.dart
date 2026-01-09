import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/Chanllenge.dart';

class ChallengeService {
  // 1. SỬA IP: Dùng đúng IP LAN của máy tính (không dùng localhost trên điện thoại)
  static const String _baseUrl = 'https://running-app-ywpg.onrender.com/Challenge';
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

    Future<List<Challenge>> getChallenges() async {
        try {
            final headers = await _getHeaders();
            final response = await http.get(
            Uri.parse('$_baseUrl'),
                headers: headers,
            );

            if (response.statusCode == 200) {
                final jsonData = jsonDecode(response.body);

                final List list = jsonData['data'];

                return list.map((e) => UserRanking.fromJson(e)).toList();
            }

            return [];
        } catch (e) {
            print("Get all chanllenges error: $e");
            return [];
        }
    }
}