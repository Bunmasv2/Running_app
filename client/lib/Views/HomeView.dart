import 'package:flutter/material.dart';
import '../models/RunModels.dart';
import '../Services/GoalService.dart';
import '../Services/UserService.dart';
import '../Models/UserProfile.dart';
import '../Components/GoalProgressComponent.dart';
import 'TrackingView.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final UserService _userService = UserService();
  final GoalService _goalService = GoalService();

  UserProfile? _userProfile;
  DailyGoal? _dailyGoal;

  // Các biến thống kê
  double _todayKm = 0.0;
  int _todayMinutes = 0; // Backend chưa trả về cái này trong Goal, cần API thống kê riêng
  double _todayKcal = 0.0; // Backend chưa trả về cái này

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Gọi song song để nhanh hơn
      final results = await Future.wait([
        _userService.getUserProfile(),
        _goalService.getTodayGoal(),
      ]);

      if (mounted) {
        setState(() {
          _userProfile = results[0] as UserProfile?;
          _dailyGoal = results[1] as DailyGoal?;

          // Cập nhật số Km từ Goal (nếu có)
          if (_dailyGoal != null) {
            _todayKm = _dailyGoal!.currentDistanceKm;
          } else {
            _todayKm = 0.0;
          }

          _isLoading = false;
        });
      }
    } catch (e) {
      print("Lỗi load data Home: $e");
      if(mounted) setState(() => _isLoading = false);
    }
  }

  // Xử lý đặt mục tiêu
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
                Navigator.pop(ctx); // Đóng dialog

                setState(() => _isLoading = true); // Hiện loading
                DailyGoal? newGoal = await _goalService.setTodayGoal(target);

                if (mounted) {
                  setState(() {
                    _dailyGoal = newGoal;
                    // Cập nhật lại UI ngay lập tức
                    if (newGoal != null) {
                      _todayKm = newGoal.currentDistanceKm;
                    }
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

  // --- Các phần code UI bên dưới giữ nguyên ---
  // (Start Running, Logout, Build UI...)
  // ...

  // Lưu ý: Nhớ thêm logic Logout để xóa Token thì lần sau vào mới Login lại được
  void _handleLogout() async {
    await _userService.logout(); // Hàm này cần có trong UserService (xóa SharedPreferences)
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    // ... Giữ nguyên code UI của bạn ...
    // Copy lại phần build() từ code cũ của bạn vào đây
    // Chỉ đảm bảo truyền đúng _dailyGoal vào GoalProgressComponent
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
                        "Hi, ${_userProfile?.userName ?? "Runner"}!",
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

              // ... Phần còn lại (Calo, Button Start) giữ nguyên ...
              const SizedBox(height: 15),
              // (Ví dụ thêm nút start)
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const TrackingView()));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("BẮT ĐẦU CHẠY"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({required String title, required String value, required String unit, required IconData icon, required Color color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
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