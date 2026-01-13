// lib/Services/TrackingService.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:latlong2/latlong.dart';

class TrackingService {
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

  static const String _baseUrl = 'https://running-app-ywpg.onrender.com/Run';
  // static const String _baseUrl = 'http://192.168.100.231:5144/run';
  Future<bool> saveRunSession({
    required double distanceKm,
    required double calories,
    required Duration duration,
    required List<LatLng> routePoints,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      final headers = await _getHeaders();
      final dto = {
        "distanceKm": distanceKm,
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
      final http.Response response = await http.post(
        Uri.parse(_baseUrl),
        headers: headers,
        body: jsonEncode(dto),
      );

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