import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/RunModels.dart';
import '../models/UserRanking.dart';

class RunService {
  // static const String _baseUrl = 'https://running-app-ywpg.onrender.com/run';
  static const String _baseUrl = 'http://10.0.2.2:5144/Run';
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
  }) async {
    try {
      final headers = await _getHeaders();
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
        headers: headers,
        body: jsonEncode(dto.toJson()),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // 2. GET HISTORY
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
      print("Lỗi Get History: $e"); // Log lỗi để debug
      return [];
    }
  }

  // 3. GET DETAIL
  Future<RunDetailDto?> getRunDetail(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$_baseUrl/$id'), headers: headers);

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

        return listData
            .map((e) => UserRanking.fromJson(e))
            .toList();
      } else {
        print('Get ranking failed: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Get ranking error: $e');
      return [];
    }
  }
}