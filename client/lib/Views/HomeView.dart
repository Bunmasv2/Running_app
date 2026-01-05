import 'package:flutter/material.dart';

// 1. CÁC IMPORT QUAN TRỌNG
import '../models/RunModels.dart';
// import '../models/DailyGoalModel.dart';
import '../Services/GoalService.dart'; // Import Service Goal
import '../Services/UserService.dart';
import '../Models/UserProfile.dart';
import '../Components//GoalProgressComponent.dart'; // Đường dẫn tới component vừa sửa
import 'TrackingView.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  // Khởi tạo các Service
  final UserService _userService = UserService();
  final GoalService _goalService = GoalService(); // Thêm GoalService

  UserProfile? _userProfile;
  DailyGoal? _dailyGoal; // Sử dụng class từ RunModels.dart

  // Thống kê hôm nay
  double _todayKm = 0.0;
  int _todayMinutes = 0;
  double _todayKcal = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // Gọi song song các API để tiết kiệm thời gian
    // Lưu ý: Bạn cần đảm bảo UserService.getUserProfile() đã được viết đúng
    final userFuture = _userService.getUserProfile();
    final goalFuture = _goalService.getTodayGoal();

    final results = await Future.wait([userFuture, goalFuture]);

    if (mounted) {
      setState(() {
        _userProfile = results[0] as UserProfile?;
        _dailyGoal = results[1] as DailyGoal?;

        // Nếu có goal, cập nhật luôn số km hiện tại vào biến thống kê (logic tạm)
        if (_dailyGoal != null) {
          _todayKm = _dailyGoal!.currentDistanceKm;
        } else {
          // Nếu chưa có goal, tạm để 0 hoặc lấy từ 1 API thống kê khác
          _todayKm = 0.0;
        }

        // Mock các chỉ số khác (vì chưa có API full thống kê)
        _todayMinutes = 0;
        _todayKcal = 0;

        _isLoading = false;
      });
    }
  }

  void _handleSetGoal() {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Đặt mục tiêu hôm nay"),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: const InputDecoration(
            labelText: "Số Km muốn chạy",
            hintText: "Ví dụ: 5.0",
            suffixText: "km",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () async {
              final double? target = double.tryParse(controller.text);
              if (target != null && target > 0) {
                Navigator.pop(ctx); // Đóng dialog trước

                // Gọi API lưu mục tiêu
                setState(() => _isLoading = true);
                DailyGoal? newGoal = await _goalService.setTodayGoal(target);

                if (mounted) {
                  setState(() {
                    _dailyGoal = newGoal;
                    _isLoading = false;
                  });
                }
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
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TrackingView()),
    );

    // Nếu chạy xong và có kết quả trả về
    if (result == true) {
      // Reload lại toàn bộ dữ liệu từ Server để cập nhật tiến độ mới nhất
      _loadData();

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
      // await _userService.logout(); // Uncomment nếu bạn đã viết hàm logout
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String displayName = _userProfile?.userName ?? "Runner";

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
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
                        "Hi, $displayName!",
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
                      IconButton(
                        onPressed: _handleLogout,
                        icon: const Icon(Icons.logout, color: Colors.redAccent),
                      ),
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

              // GOAL PROGRESS COMPONENT
              Center(
                child: GoalProgressComponent(
                  goal: _dailyGoal,
                  onSetGoal: _handleSetGoal,
                ),
              ),

              const SizedBox(height: 30),

              // THỐNG KÊ
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

              // NÚT BẮT ĐẦU CHẠY
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