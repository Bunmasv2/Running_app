import 'package:flutter/material.dart';
import 'Views/MainScreen.dart';
import 'Views/TrackingView.dart'; // Import màn hình map đã làm ở bước trước

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

      // Cấu hình Theme theo style hiện đại (Material 3)
      theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.blue, // Màu chủ đạo
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent, // Bỏ hiệu ứng ám màu khi scroll
            elevation: 0,
            centerTitle: false,
          )
      ),

      // Route mặc định là MainScreen (chứa 3 tabs)
      initialRoute: '/',

      // Định nghĩa các Routes
      routes: {
        '/': (context) => const MainScreen(),
        // TrackingView không nằm trong BottomBar nên để route riêng [cite: 83]
        '/tracking': (context) => const TrackingView(),
      },
    );
  }
}