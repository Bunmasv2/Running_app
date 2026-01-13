import 'package:flutter/material.dart';
import '../Services/UserService.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final UserService _userService = UserService();
  final _formKey = GlobalKey<FormState>();

  final _userNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPassController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  void _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPassController.text) {
      setState(() => _errorMessage = "Mật khẩu xác nhận không khớp");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    String? errorFromBE = await _userService.register(
      userName: _userNameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      heightCm: double.tryParse(_heightController.text) ?? 0,
      weightKg: double.tryParse(_weightController.text) ?? 0,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (errorFromBE == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đăng ký thành công!"), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } else {
      setState(() => _errorMessage = errorFromBE);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text("Tạo tài khoản mới", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: size.width * 0.08),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: size.height * 0.02),
              Icon(Icons.person_add_rounded, size: size.width * 0.2, color: Colors.deepOrange),
              SizedBox(height: size.height * 0.04),

              _buildInput(_userNameController, "Tên người dùng", Icons.person_outline, size),
              _buildInput(_emailController, "Email", Icons.email_outlined, size, keyboardType: TextInputType.emailAddress),

              Row(
                children: [
                  Expanded(child: _buildInput(_heightController, "Cao (cm)", Icons.height, size, keyboardType: TextInputType.number)),
                  const SizedBox(width: 15),
                  Expanded(child: _buildInput(_weightController, "Nặng (kg)", Icons.monitor_weight_outlined, size, keyboardType: TextInputType.number)),
                ],
              ),

              _buildInput(_passwordController, "Mật khẩu", Icons.lock_outline, size, isPassword: true),
              _buildInput(_confirmPassController, "Xác nhận mật khẩu", Icons.lock_reset, size, isPassword: true),

              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 13), textAlign: TextAlign.center),
                ),

              SizedBox(height: size.height * 0.04),

              ElevatedButton(
                onPressed: _isLoading ? null : _handleRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: size.height * 0.02),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("Hoàn tất đăng ký", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              SizedBox(height: size.height * 0.05),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(
      TextEditingController controller,
      String label,
      IconData icon,
      Size size, {
        bool isPassword = false,
        TextInputType keyboardType = TextInputType.text,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        validator: (value) {
          if (value == null || value.trim().isEmpty) return "Nhập $label";
          if (label == "Email" && !value.contains("@")) return "Email không hợp lệ";
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
          prefixIcon: Icon(icon, color: Colors.deepOrange, size: 20),
          filled: true,
          fillColor: const Color(0xFF2C2C2C),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.deepOrange, width: 1)),
          errorStyle: const TextStyle(color: Colors.redAccent),
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}