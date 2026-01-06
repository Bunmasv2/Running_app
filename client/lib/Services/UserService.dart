import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart'; // Cần import để dùng Navigator & Context
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Models/UserProfile.dart';
import '../Views/GoogleWebView.dart'; // Bắt buộc phải import file WebView này
import '../models/UserRanking.dart';

class UserService {
  // URL Server Render của bạn
  // static const String _baseUrl = 'https://running-app-ywpg.onrender.com/User';
  // static const String _baseUrl = 'http://10.0.2.2:5000/User';
  // --- 1. QUẢN LÝ AUTH (ĐĂNG NHẬP / ĐĂNG XUẤT) ---
  static const String _baseUrl = 'http://10.0.2.2:5144/User';

  // A. ĐĂNG NHẬP THƯỜNG (EMAIL/PASS)
  Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/signin'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "email": email,
          "password": password
        }),
      );

      // if (response.statusCode == 200) {
      //   final Map<String, dynamic> responseBody = jsonDecode(response.body);
      //
      //   // Phải vào trong node 'data' trước
      //   final userData = responseBody['data'];
      //
      //   if (userData != null && userData['token'] != null) {
      //     String token = userData['token'];
      //
      //     final prefs = await SharedPreferences.getInstance();
      //     await prefs.setString('accessToken', token);
      //
      //     print("Đăng nhập thành công, đã lưu Token!");
      //     return true;
      //   }
      if (response.statusCode == 200) {
        final fullResponse = jsonDecode(response.body);
        // Phải lấy từ Map 'data' mà bạn đã bọc ở Controller
        final userData = fullResponse['data'];

        if (userData != null && userData['token'] != null) {
          String token = userData['token'];
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('accessToken', token);
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Login Error: $e');
      return false;
    }
  }

  // B. ĐĂNG NHẬP GOOGLE (DÙNG WEBVIEW - KHÔNG CẦN FIREBASE)
  Future<bool> loginGoogle(BuildContext context) async {
    try {
      // 1. Mở màn hình WebView và chờ kết quả trả về (Token)
      final String? token = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const GoogleWebView()),
      );

      // 2. Nếu lấy được token (người dùng đăng nhập thành công và WebView bắt được link)
      if (token != null && token.isNotEmpty) {
        // Lưu token vào máy
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('accessToken', token);
        return true;
      }

      // Trường hợp người dùng tắt WebView hoặc không đăng nhập
      return false;
    } catch (e) {
      print('Login Google WebView Error: $e');
      return false;
    }
  }

  // 2. KIỂM TRA ĐÃ ĐĂNG NHẬP CHƯA (Cho Splash Screen)
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    return token != null && token.isNotEmpty;
  }

  // 3. ĐĂNG XUẤT
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');
  }

  // --- 2. CÁC HÀM HELPER ---

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

  // --- 3. CÁC CHỨC NĂNG USER PROFILE ---

  Future<UserProfile?> getUserProfile() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$_baseUrl/profile'), headers: headers);

      if (response.statusCode == 200) {
        print("Dữ liệu thật từ Server: ${response.body}");
        return UserProfile.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      print('Error Get Profile: $e');
      return null;
    }
  }

  Future<bool> updateProfile(String userName, double height, double weight) async {
    try {
      final headers = await _getHeaders();
      final body = {
        "userName": userName,
        "heightCm": height,
        "weightKg": weight,
        "email": "ignored@email.com"
      };

      final response = await http.put(
        Uri.parse('$_baseUrl/update'),
        headers: headers,
        body: jsonEncode(body),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> uploadAvatar(File imageFile) async {
    try {
      String? token = await _getToken();
      var request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/avatar'));
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('avatar', imageFile.path));
      var response = await request.send();

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<String?> register({
    required String userName,
    required String email,
    required String password,
    required double heightCm,
    required double weightKg,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/register'),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "userName": userName,
          "email": email,
          "password": password,
          "confirmPass": password,
          "heightCm": heightCm,
          "weightKg": weightKg,
          // "userName": "DatTran",
          // "email": "trandat2280600642@gmail.com",
          // "password": "Dat@1912",
          // "confirmPass": "Dat@1912",
          // "heightCm": 179,
          // "weightKg": 78,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return null; // Thành công
      } else {
        // Parse tin nhắn lỗi từ Backend (do ErrorHandlingMiddleware trả về)
        final errorData = jsonDecode(response.body);
        return errorData['message'] ?? "Đã có lỗi xảy ra";
      }
    } catch (e) {
      print("Register error: $e");
      return "Không thể kết nối đến server";
    }
  }
}