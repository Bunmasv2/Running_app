import 'package:flutter/material.dart';
import '../Services/UserService.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  void _checkLoginStatus() async {
    final userService = UserService();
    bool loggedIn = await userService.isLoggedIn();

    if (!mounted) return;

    if (loggedIn) {
      // Đã đăng nhập -> Vào Main
      Navigator.pushReplacementNamed(context, '/main');
    } else {
      // Chưa đăng nhập -> Vào Login
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()), // Xoay xoay chờ check token
    );
  }
}