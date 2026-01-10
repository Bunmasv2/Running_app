import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/RunModels.dart';
import '../models/UserRanking.dart';

class RunService {
  static const String _baseUrl = 'https://running-app-ywpg.onrender.com/run';
  //  static const String _baseUrl = 'http://10.0.2.2:5144/Run';
  // static const String _baseUrl = 'http://192.168.173.173:5144/Run';
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

  Future<bool> saveRun({
    required double distance,
    required double calories,
    required Duration duration,
    required List<LatLng> routePoints,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      final headers = await _getHeaders();

      final dto = {
        "distanceKm": distance,
        "durationSeconds": duration.inSeconds,
        "startTime": startTime.toIso8601String(),
        "endTime": endTime.toIso8601String(),
        "routeJson": jsonEncode(
          routePoints
              .map((p) => {
                    "latitude": p.latitude,
                    "longitude": p.longitude,
                  })
              .toList(),
        )
      };

      print("Sending Body: ${jsonEncode(dto)}"); // [DEBUG] In ra xem gửi gì đi

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: headers,
        body: jsonEncode(dto),
      );

      // [QUAN TRỌNG] Kiểm tra và in lỗi từ server nếu có
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print("SAVE FAILED! Status: ${response.statusCode}");
        print(
            "Server Response: ${response.body}"); // [DEBUG] Đọc lỗi server trả về ở đây
        return false;
      }
    } catch (e) {
      print("Connection Error: $e");
      return false;
    }
  }

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
      print("Lỗi Get History: $e");
      return [];
    }
  }

  Future<RunDetailDto?> getRunDetail(int id) async {
    try {
      final headers = await _getHeaders();
      final response =
          await http.get(Uri.parse('$_baseUrl/$id'), headers: headers);

      if (response.statusCode == 200) {
        return RunDetailDto.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<UserRanking>> getWeeklyRanking() async {
    try {
      final headers = await _getHeaders();

      final response = await http.get(
        Uri.parse('$_baseUrl/top-weekly'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        print("Dữ liệu thật từ Server: ${response.body}");
        final decoded = jsonDecode(response.body);

        final List listData = decoded['data'];

        return listData.map((e) => UserRanking.fromJson(e)).toList();
      } else {
        print('Get ranking failed: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Get ranking error: $e');
      return [];
    }
  }

  Future<List<RunHistoryDto>> getMonthlyRunSessions(int month, int year) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/monthly-sessions/$month/$year'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        print("Dữ liệu Monthly Sessions: ${response.body}");
        final decoded = jsonDecode(response.body);

        final List listData = decoded['data'] ?? [];
        return listData.map((e) => RunHistoryDto.fromJson(e)).toList();
      } else {
        print('Get Monthly Sessions failed: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Get Monthly Sessions error: $e');
      return [];
    }
  }

  Future<List<RunHistoryDto>> getTop2RunSessions() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/top2-sessions'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        print("Dữ liệu Top 2 Sessions: ${response.body}");
        final decoded = jsonDecode(response.body);

        final List listData = decoded['data'] ?? [];
        return listData.map((e) => RunHistoryDto.fromJson(e)).toList();
      } else {
        print('Get Top 2 Sessions failed: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Get Top 2 Sessions error: $e');
      return [];
    }
  }

  Future<List<RunHistoryDto>> getWeeklyRunSessions(int month, int year) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/weekly-sessions/$month/$year'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        print("Dữ liệu Weekly Sessions: ${response.body}");
        final decoded = jsonDecode(response.body);

        final List listData = decoded['data'] ?? [];
        return listData.map((e) => RunHistoryDto.fromJson(e)).toList();
      } else {
        print('Get Weekly Sessions failed: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Get Weekly Sessions error: $e');
      return [];
    }
  }
}