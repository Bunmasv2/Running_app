import 'package:flutter/material.dart';
import '../Services/UserService.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final UserService _userService = UserService();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  // Xử lý đăng nhập thường
  void _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    bool success = await _userService.login(
        _emailController.text,
        _passController.text
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Navigator.pushReplacementNamed(context, '/main');
    } else {
      setState(() => _errorMessage = "Email hoặc mật khẩu không đúng!");
    }
  }

  // Xử lý đăng nhập Google (Dùng WebView)
  void _handleGoogleLogin() async {
    setState(() => _isLoading = true);

    // TRUYỀN CONTEXT VÀO ĐÂY ĐỂ MỞ WEBVIEW
    bool success = await _userService.loginGoogle(context);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Navigator.pushReplacementNamed(context, '/main');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đăng nhập thất bại hoặc bạn đã hủy thao tác.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 60.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.directions_run, size: 80, color: Colors.blue),
              const SizedBox(height: 20),
              const Text(
                "ĐĂNG NHẬP",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),

              // Email Input
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 20),

              // Password Input
              TextField(
                controller: _passController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Mật khẩu",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),

              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),

              const SizedBox(height: 30),

              // Login Button
              ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("Đăng nhập", style: TextStyle(fontSize: 18, color: Colors.white)),
              ),

              const SizedBox(height: 30),

              // Dòng kẻ "Hoặc"
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey[400])),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text("Hoặc đăng nhập bằng", style: TextStyle(color: Colors.grey[600])),
                  ),
                  Expanded(child: Divider(color: Colors.grey[400])),
                ],
              ),

              const SizedBox(height: 20),

              // Nút Google
              OutlinedButton(
                onPressed: _isLoading ? null : _handleGoogleLogin,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  backgroundColor: Colors.white,
                  elevation: 2,
                  shadowColor: Colors.black12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.network(
                      'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1200px-Google_%22G%22_logo.svg.png',
                      height: 24,
                      width: 24,
                      errorBuilder: (ctx, err, stack) => const Icon(Icons.public, color: Colors.red),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "Google",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Chưa có tài khoản? "),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/register');
                    },
                    child: const Text(
                      "Đăng ký",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),

            ],
          ),
        ),
      ),
    );
  }
}