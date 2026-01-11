import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ChallengeModels.dart';

class ChallengeService {
  // Ưu tiên baseUrl của UIA_FE
  // static const String _baseUrl = 'https://running-app-ywpg.onrender.com/Challenge';

  // static const String _baseUrl = 'http://192.168.173.173:5144/Challenge';
  static const String _baseUrl = 'http://10.0.2.2:5144/Challenge';

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
      final response = await http.get(Uri.parse(_baseUrl), headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final List<dynamic> data = body['data'] ?? [];
        return data.map((e) => Challenge.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print("Error getAllChallenges: $e");
      return [];
    }
  }

  // 2. Lấy danh sách thử thách CỦA TÔI
  Future<List<UserChallengeProgress>> getMyChallenges() async {
    try {
      final headers = await _getHeaders();
      final response =
          await http.get(Uri.parse('$_baseUrl/my-challenges'), headers: headers);

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

  // 3. Tham gia thử thách (bắt message từ backend)
  Future<Map<String, dynamic>> joinChallenge(int challengeId) async {
    try {
      final headers = await _getHeaders();

      final response = await http.post(
        Uri.parse('$_baseUrl/join/$challengeId'),
        headers: headers,
      );

      final json = jsonDecode(response.body);
      print(json);
      String serverMessage = json["message"] ?? "Có lỗi xảy ra";

      // Nếu code là 200/201 -> Thành công (True) + Message
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          "success": true,
          "message": serverMessage
        };
      } else {
        // Nếu code lỗi -> Thất bại (False) + Message lỗi từ server
        return {
          "success": false,
          "message": serverMessage
        };
      }
    } catch (e) {
      print("Join challenge error: $e");
      return {
        "success": false,
        "message": "Lỗi kết nối server"
      };
    }
  }
}
