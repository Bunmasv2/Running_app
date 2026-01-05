import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Models/UserProfile.dart';

class UserService {
  // URL Server Render của bạn
  // static const String _baseUrl = 'https://running-app-ywpg.onrender.com/User';
  // static const String _baseUrl = 'http://10.0.2.2:5000/User';
  // --- 1. QUẢN LÝ AUTH (ĐĂNG NHẬP / ĐĂNG XUẤT) ---
  static const String _baseUrl = 'http://10.0.2.2:5144/User';

  // 1. GỌI API ĐĂNG NHẬP
  Future<bool> login(String email, String password) async {
    try {
      // Giả định backend bạn có endpoint POST /login
      // Nếu backend chưa có, bạn cần viết thêm API Login nhận Email/Pass trả về Token
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

  Future<bool> loginGoogle() async {
    try {
      // Gọi API /signin-google
      // Lưu ý: API này trả về 302 Redirect, http client sẽ tự động follow redirect
      // nhưng sẽ không hiện giao diện đăng nhập cho user nhập pass được.
      final response = await http.get(
        Uri.parse('$_baseUrl/signin-google'),
        headers: {'Content-Type': 'application/json'},
      );

      print("Google API Status: ${response.statusCode}");
      print("Google API Body: ${response.body}");

      // Logic tạm thời: Nếu server trả về 200 (nghĩa là backend đã xử lý xong token)
      if (response.statusCode == 200) {
        // Cần parse token từ response (Tùy backend trả về JSON hay HTML)
        try {
          final data = jsonDecode(response.body);
          if (data['token'] != null) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('accessToken', data['token']);
            return true;
          }
        } catch(e) {
          print("Lỗi parse JSON Google: $e");
        }
      }
      return false;
    } catch (e) {
      print('Login Google Error: $e');
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

  // [HÀM TẠM] Dùng để lưu token cứng trong lúc chưa làm màn hình Login
  // Bạn gọi hàm này 1 lần duy nhất ở main.dart để nạp token vào máy
  Future<void> saveTokenManually(String hardcodedToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accessToken', hardcodedToken);
    print("Đã lưu token thủ công vào máy!");
  }

  // --- 2. CÁC HÀM HELPER ---

  // Lấy Token từ bộ nhớ máy (Không còn hardcode nữa)
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('accessToken');
  }

  // Tạo Header có chứa Token
  Future<Map<String, String>> _getHeaders() async {
    String? token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token', // Gửi kèm Token
    };
  }

  // --- 3. CÁC CHỨC NĂNG USER PROFILE ---

  // Lấy thông tin User
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

  // Cập nhật thông tin
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

  // Upload Avatar
  Future<bool> uploadAvatar(File imageFile) async {
    try {
      String? token = await _getToken();
      var request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/avatar'));

      // Với Multipart, phải thêm header thủ công như này
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