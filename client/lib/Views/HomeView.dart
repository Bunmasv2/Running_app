import 'package:flutter/material.dart';
import '../Components/GoalProgressComponent.dart';
import '../Models/RunModel.dart';
import 'TrackingView.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  // 1. Dữ liệu Mock (Giả lập thay vì gọi API lúc này)
  // Trong thực tế, bạn sẽ gọi API GET /api/user/profile và GET /api/goals/today ở đây
  final String _userName = "Tuấn Kiệt";

  // State cho mục tiêu ngày
  DailyGoal? _dailyGoal;

  // State cho Dashboard thống kê hôm nay
  double _todayKm = 0.0;
  int _todayMinutes = 0;
  double _todayKcal = 0.0;

  @override
  void initState() {
    super.initState();
    // Giả lập load dữ liệu ban đầu
    _loadDashboardData();
  }

  void _loadDashboardData() {
    setState(() {
      // Ví dụ: Chưa đặt mục tiêu (để test nút dấu +)
      _dailyGoal = null;

      // Số liệu thống kê ban đầu
      _todayKm = 12.5;
      _todayMinutes = 65;
      _todayKcal = 850;
    });
  }

  // Xử lý khi bấm nút "Đặt mục tiêu" (Dấu +)
  // [cite: 76-77]: Click -> Popup nhập số Km muốn chạy.
  void _handleSetGoal() {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Đặt mục tiêu hôm nay"),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: "Số Km muốn chạy",
            suffixText: "km",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () {
              // Validate và lưu mục tiêu
              final double? target = double.tryParse(controller.text);
              if (target != null && target > 0) {
                setState(() {
                  _dailyGoal = DailyGoal(
                    targetDistanceKm: target,
                    currentDistanceKm: _todayKm, // Map với quãng đường đã chạy
                  );
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text("Lưu"),
          ),
        ],
      ),
    );
  }

  // Xử lý khi bấm "BẮT ĐẦU CHẠY"
  // [cite: 80-81]: Chuyển sang Tracking Mode (Full màn hình).
  void _startRunning() async {
    // Navigator.push trả về kết quả khi màn hình Tracking pop về
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TrackingView()),
    );

    //[cite: 94]: Thành công -> Reload lại data Home
    if (result == true) {
      // Ở đây chúng ta giả lập việc cập nhật lại số liệu sau khi chạy xong
      setState(() {
        _todayKm += 5.0; // Ví dụ chạy thêm được 5km
        _todayKcal += 300;
        _todayMinutes += 30;

        // Cập nhật lại tiến độ mục tiêu nếu có
        if (_dailyGoal != null) {
          _dailyGoal = DailyGoal(
            targetDistanceKm: _dailyGoal!.targetDistanceKm,
            currentDistanceKm: _todayKm,
          );
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đã lưu kết quả chạy thành công!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sử dụng SafeArea để tránh tai thỏ
    return SafeArea(
      child: Scaffold(
        // Background màu trắng xám nhẹ cho hiện đại
        backgroundColor: Colors.grey[50],
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. HEADER [cite: 72] ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Hôm nay, ${DateTime.now().day}/${DateTime.now().month}",
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Xin chào, $_userName!",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  // Avatar nhỏ
                  const CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.blueAccent,
                    child: Icon(Icons.person, color: Colors.white),
                  )
                ],
              ),

              const SizedBox(height: 30),

              // --- 2. MỤC TIÊU NGÀY (Circular Progress) [cite: 73-78] ---
              Center(
                child: GoalProgressComponent(
                  goal: _dailyGoal,
                  onSetGoal: _handleSetGoal,
                ),
              ),

              const SizedBox(height: 30),

              // --- 3. DASHBOARD (3 Ô THỐNG KÊ) [cite: 79] ---
              const Text(
                "Thống kê hôm nay",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),

              Row(
                children: [
                  _buildStatCard(
                    title: "Quãng đường",
                    value: _todayKm.toStringAsFixed(1),
                    unit: "km",
                    icon: Icons.directions_run,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 15),
                  _buildStatCard(
                    title: "Thời gian",
                    value: _todayMinutes.toString(),
                    unit: "phút",
                    icon: Icons.timer,
                    color: Colors.orange,
                  ),
                ],
              ),
              const SizedBox(height: 15),
              // Card Calo nằm ngang full width
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.local_fire_department, color: Colors.red),
                    ),
                    const SizedBox(width: 15),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Calo tiêu thụ", style: TextStyle(color: Colors.grey)),
                        Text(
                          "$_todayKcal kcal",
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    )
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // --- 4. NÚT START [cite: 80] ---
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _startRunning,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87, // Màu tối cho nút chính trông ngầu hơn
                    foregroundColor: Colors.white,
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_arrow),
                      SizedBox(width: 8),
                      Text(
                        "BẮT ĐẦU CHẠY",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget để vẽ ô thống kê nhỏ
  Widget _buildStatCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                // Có thể thêm icon tăng giảm % ở đây nếu muốn
              ],
            ),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text("$unit • $title", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}