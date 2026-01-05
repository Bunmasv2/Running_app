import 'package:flutter/material.dart';
import '../Components/GoalProgressComponent.dart'; // Đảm bảo bạn đã có file này (code ở dưới)
import '../Models/UserProfile.dart';
import '../Services/UserService.dart';
import 'TrackingView.dart';

// Model đơn giản cho Mục tiêu (để dùng trong UI)
class DailyGoal {
  final double targetDistanceKm;
  final double currentDistanceKm;

  DailyGoal({required this.targetDistanceKm, required this.currentDistanceKm});

  double get progress => (currentDistanceKm / targetDistanceKm).clamp(0.0, 1.0);
}

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final UserService _userService = UserService();

  // State dữ liệu
  UserProfile? _userProfile;
  DailyGoal? _dailyGoal;

  // Thống kê hôm nay (Mock data - Sau này gọi API /run/today-stats)
  double _todayKm = 0.0;
  int _todayMinutes = 0;
  double _todayKcal = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // 1. Lấy thông tin User (Tên, Avatar)
    UserProfile? user = await _userService.getUserProfile();

    // 2. Giả lập lấy thống kê hôm nay (Hoặc gọi API RunService.getTodayStats)
    // Tạm thời hardcode để test giao diện
    setState(() {
      _userProfile = user;
      _todayKm = 5.2;
      _todayMinutes = 35;
      _todayKcal = 320;
    });
  }

  // --- CHỨC NĂNG 1: ĐẶT MỤC TIÊU ---
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
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () {
              final double? target = double.tryParse(controller.text);
              if (target != null && target > 0) {
                setState(() {
                  _dailyGoal = DailyGoal(
                    targetDistanceKm: target,
                    currentDistanceKm: _todayKm,
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

  // --- CHỨC NĂNG 2: BẮT ĐẦU CHẠY ---
  void _startRunning() async {
    // Chuyển sang màn hình Map
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TrackingView()),
    );

    // Nếu chạy xong và bấm "Kết thúc" (trả về true)
    if (result == true) {
      // Reload lại dữ liệu (Cộng dồn giả lập để thấy thay đổi)
      setState(() {
        _todayKm += 2.5; // Giả sử vừa chạy thêm 2.5km
        _todayKcal += 150;
        _todayMinutes += 15;

        // Cập nhật lại thanh tiến độ
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

  // --- CHỨC NĂNG 3: ĐĂNG XUẤT ---
  void _handleLogout() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Đăng xuất"),
        content: const Text("Bạn có muốn đăng xuất khỏi ứng dụng?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text("Đăng xuất"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _userService.logout(); // Xóa token
      if (!mounted) return;
      // Quay về màn hình Login và xóa hết lịch sử cũ
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lấy tên user hoặc hiển thị mặc định
    String displayName = _userProfile?.userName ?? "Người chạy bộ";

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- HEADER: Chào & Logout ---
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
                        "Xin chào, $displayName!",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Nút Logout
                      IconButton(
                        onPressed: _handleLogout,
                        icon: const Icon(Icons.logout, color: Colors.redAccent),
                        tooltip: "Đăng xuất",
                      ),
                      // Avatar
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.blue[100],
                        backgroundImage: _userProfile?.avatarUrl != null
                            ? NetworkImage(_userProfile!.avatarUrl!)
                            : null,
                        child: _userProfile?.avatarUrl == null
                            ? const Icon(Icons.person, color: Colors.blue)
                            : null,
                      )
                    ],
                  )
                ],
              ),

              const SizedBox(height: 30),

              // --- GOAL PROGRESS ---
              Center(
                child: GoalProgressComponent(
                  goal: _dailyGoal,
                  onSetGoal: _handleSetGoal,
                ),
              ),

              const SizedBox(height: 30),

              // --- DASHBOARD STATS ---
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
              // Card Calo full width
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
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
                          "${_todayKcal.toStringAsFixed(0)} kcal",
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    )
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // --- BUTTON START ---
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _startRunning,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
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
                      Text("BẮT ĐẦU CHẠY", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text("$unit • $title", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}