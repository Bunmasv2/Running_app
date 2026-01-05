import 'package:flutter/material.dart';
import '../Services/UserService.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final UserService _userService = UserService();

  final _userNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPassController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  void _handleRegister() async {
    if (_passwordController.text != _confirmPassController.text) {
      setState(() => _errorMessage = "Mật khẩu xác nhận không khớp");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    String? success = await _userService.register(
      userName: _userNameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      heightCm: double.tryParse(_heightController.text) ?? 0,
      weightKg: double.tryParse(_weightController.text) ?? 0,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success == null ) {
      Navigator.pop(context); // Quay lại Login
    } else {
      setState(() => _errorMessage = "Đăng ký thất bại, vui lòng kiểm tra lại!");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Đăng ký"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.person_add, size: 80, color: Colors.blue),
            const SizedBox(height: 20),

            _buildInput(_userNameController, "Tên người dùng", Icons.person),
            _buildInput(_emailController, "Email", Icons.email),

            _buildInput(
              _passwordController,
              "Mật khẩu",
              Icons.lock,
              isPassword: true,
            ),
            _buildInput(
              _confirmPassController,
              "Xác nhận mật khẩu",
              Icons.lock_outline,
              isPassword: true,
            ),

            _buildInput(
              _heightController,
              "Chiều cao (cm)",
              Icons.height,
              keyboardType: TextInputType.number,
            ),
            _buildInput(
              _weightController,
              "Cân nặng (kg)",
              Icons.monitor_weight,
              keyboardType: TextInputType.number,
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

            ElevatedButton(
              onPressed: _isLoading ? null : _handleRegister,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                "Đăng ký",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(
      TextEditingController controller,
      String label,
      IconData icon, {
        bool isPassword = false,
        TextInputType keyboardType = TextInputType.text,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}
