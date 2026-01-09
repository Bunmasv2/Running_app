import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Models/ChallengeModels.dart';

class ChallengeService {
  static const String _baseUrl = 'http://192.168.173.173:5144/Challenge';

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

  // 1. Lấy danh sách tất cả thử thách (Tab Danh sách)
  Future<List<Challenge>> getAllChallenges() async {
    try {
      final headers = await _getHeaders();
      // Giả sử API là GET /Challenge
      final response = await http.get(Uri.parse(_baseUrl), headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        // Tùy cấu trúc API trả về, nếu data nằm trong 'data':
        final List<dynamic> data = body['data'] ?? [];
        return data.map((e) => Challenge.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print("Error getAllChallenges: $e");
      return [];
    }
  }

  // 2. Lấy danh sách thử thách CỦA TÔI (Tab Thử thách của bạn)
  Future<List<UserChallengeProgress>> getMyChallenges() async {
    try {
      final headers = await _getHeaders();
      // Giả sử API là GET /Challenge/my-challenges
      final response = await http.get(Uri.parse('$_baseUrl/my-challenges'), headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final List<dynamic> data = body['data'] ?? [];
        return data.map((e) => UserChallengeProgress.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print("Error getMyChallenges: $e");
      return [];
    }
  }

  // 3. Tham gia thử thách
  Future<bool> joinChallenge(int challengeId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/join/$challengeId'), // Endpoint giả định
        headers: headers,
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }
}