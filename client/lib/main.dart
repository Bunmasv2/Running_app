// import 'package:client/Views/RegisterView.dart';
import 'package:flutter/material.dart';
import 'Views/MainScreen.dart';
import 'Views/TrackingView.dart';
import 'Views/LoginView.dart';  // Cần import LoginView (nếu chưa có file này thì tạo tạm)
import 'Views/SplashView.dart'; // Cần import SplashView (nếu chưa có file này thì tạo tạm)
import 'Views/RegisterView.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Running Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),

      // SỬA Ở ĐÂY: Thay vì vào thẳng Main, hãy vào Splash để check token
      home: const SplashView(),

      routes: {
        '/login': (context) => const LoginView(),
        '/register': (context) => const RegisterView(),
        '/main': (context) => const MainScreen(),
      },
    );
  }
}