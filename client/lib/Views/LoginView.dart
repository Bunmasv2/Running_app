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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SingleChildScrollView(
        child: Container(
          width: size.width,
          height: size.height,
          padding: EdgeInsets.symmetric(horizontal: size.width * 0.08),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                  Icons.directions_run_rounded,
                  size: size.width * 0.25,
                  color: Colors.deepOrange
              ),
              SizedBox(height: size.height * 0.02),
              Text(
                "RUN TRACKER",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: size.width * 0.07,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 2
                ),
              ),
              SizedBox(height: size.height * 0.01),
              Text(
                "Chinh phục mọi cung đường",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: size.width * 0.035,
                    color: Colors.grey[500]
                ),
              ),
              SizedBox(height: size.height * 0.06),

              _buildTextField(
                controller: _emailController,
                label: "Email",
                icon: Icons.email_outlined,
              ),
              SizedBox(height: size.height * 0.025),

              _buildTextField(
                controller: _passController,
                label: "Mật khẩu",
                icon: Icons.lock_outline_rounded,
                isPassword: true,
              ),

              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 15),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),

              SizedBox(height: size.height * 0.05),

              ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.deepOrange.withOpacity(0.5),
                  padding: EdgeInsets.symmetric(vertical: size.height * 0.02),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? SizedBox(
                    height: size.height * 0.025,
                    width: size.height * 0.025,
                    child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                )
                    : const Text(
                    "Đăng nhập",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                ),
              ),

              SizedBox(height: size.height * 0.03),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Chưa có tài khoản? ", style: TextStyle(color: Colors.grey[400])),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/register'),
                    child: const Text(
                      "Đăng ký ngay",
                      style: TextStyle(
                        color: Colors.deepOrange,
                        fontWeight: FontWeight.bold,
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: Colors.deepOrange, size: 20),
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.deepOrange, width: 1),
        ),
      ),
    );
  }
}