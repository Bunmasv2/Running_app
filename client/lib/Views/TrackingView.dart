import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

// --- IMPORT CÁC SERVICE VÀ MODEL ---
import '../Services/RunService.dart';
import '../Services/GoalService.dart';
import '../Services/UserService.dart';
import '../Models/UserProfile.dart';
// Đảm bảo đường dẫn này đúng với nơi bạn lưu class DailyGoal
import '../models/RunModels.dart';

class TrackingView extends StatefulWidget {
  const TrackingView({super.key});

  @override
  State<TrackingView> createState() => _TrackingViewState();
}

class _TrackingViewState extends State<TrackingView> {
  // --- 1. KHỞI TẠO SERVICE & CONTROLLER ---
  final MapController _mapController = MapController();
  final RunService _runService = RunService();
  final GoalService _goalService = GoalService();
  final UserService _userService = UserService();

  // --- 2. BIẾN DỮ LIỆU (STATE) ---
  // Dữ liệu User & Mục tiêu
  double _userWeightKg = 60.0; // Mặc định 60kg (sẽ cập nhật từ API)
  DailyGoal? _dailyGoal;

  // Dữ liệu Chạy Realtime
  List<LatLng> _routePoints = [];
  double _distanceKm = 0.0;
  double _calories = 0.0;
  Duration _elapsed = Duration.zero;

  // Trạng thái hệ thống
  bool _isTracking = false; // Đang chạy hay dừng
  bool _isSaving = false;   // Đang gọi API lưu

  // Timer & GPS Stream
  Timer? _timer;
  StreamSubscription<Position>? _positionStream;
  late DateTime _startTime;

  @override
  void initState() {
    super.initState();
    _loadInitialData(); // Load dữ liệu ngay khi vào màn hình
  }

  @override
  void dispose() {
    _timer?.cancel();
    _positionStream?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  // --- 3. LOGIC LOAD DỮ LIỆU TỪ SERVER ---
  Future<void> _loadInitialData() async {
    try {
      // Gọi song song 2 API để tiết kiệm thời gian
      final results = await Future.wait([
        _userService.getUserProfile(),
        _goalService.getTodayGoal(),
      ]);

      if (mounted) {
        setState(() {
          // 1. Lấy cân nặng thật để tính Calo
          final profile = results[0] as UserProfile?;
          if (profile != null && profile.weightKg > 0) {
            _userWeightKg = profile.weightKg;
          }

          // 2. Lấy Mục tiêu hôm nay (nếu có)
          _dailyGoal = results[1] as DailyGoal?;
        });
      }

      // Tự động di chuyển map về vị trí hiện tại
      _getCurrentLocation();
    } catch (e) {
      print("Lỗi load data tracking: $e");
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if(permission == LocationPermission.denied) return;
    }

    Position pos = await Geolocator.getCurrentPosition();
    _mapController.move(LatLng(pos.latitude, pos.longitude), 16.0);
  }

  // --- 4. LOGIC CHẠY BỘ (START/STOP) ---
  void _toggleTracking() {
    if (_isTracking) {
      _stopRun(); // Đang chạy -> Bấm thì Dừng
    } else {
      _startRun(); // Đang dừng -> Bấm thì Chạy
    }
  }

  Future<void> _startRun() async {
    // Reset thông số cho phiên chạy mới
    setState(() {
      _isTracking = true;
      _routePoints.clear();
      _distanceKm = 0.0;
      _calories = 0.0;
      _elapsed = Duration.zero;
      _startTime = DateTime.now().toUtc();
    });

    // Bắt đầu đếm giờ (Timer)
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsed = Duration(seconds: _elapsed.inSeconds + 1);
      });
    });

    // Bắt đầu lắng nghe GPS
    final locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // Chỉ cập nhật nếu di chuyển > 5m (Lọc nhiễu đứng yên)
    );

    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
      _updatePosition(position);
    });
  }

  void _updatePosition(Position pos) {
    // 1. Lọc tín hiệu GPS yếu (Độ chính xác > 30m thì bỏ qua)
    if (pos.accuracy > 30.0) return;

    LatLng newPoint = LatLng(pos.latitude, pos.longitude);

    setState(() {
      if (_routePoints.isNotEmpty) {
        final double distMeters = const Distance().as(LengthUnit.Meter, _routePoints.last, newPoint);

        // 2. Chỉ tính cộng dồn nếu di chuyển thực sự (> 5m)
        if (distMeters > 5.0) {
          _distanceKm += (distMeters / 1000);

          // Công thức Calo: Cân nặng x Km x 1.036
          _calories = _userWeightKg * _distanceKm * 1.036;

          _routePoints.add(newPoint);
        }
      } else {
        _routePoints.add(newPoint); // Điểm xuất phát
      }

      // Camera luôn đi theo người dùng
      _mapController.move(newPoint, 17.0);
    });
  }

  Future<void> _stopRun() async {
    _timer?.cancel();
    _positionStream?.cancel();

    // Kiểm tra nếu chạy quá ít (lỡ bấm nhầm)
    if (_distanceKm < 0.01) {
      setState(() => _isTracking = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Quãng đường quá ngắn, hủy kết quả.")));
      return;
    }

    setState(() {
      _isTracking = false;
      _isSaving = true; // Hiện loading quay quay
    });

    // --- GỌI API LƯU KẾT QUẢ ---
    bool success = await _runService.saveRun(
      distance: _distanceKm,
      calories: _calories,
      duration: _elapsed,
      routePoints: _routePoints,
      startTime: _startTime,
      endTime: DateTime.now().toUtc(),
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        // Reload lại Goal để cập nhật tiến độ mới lên vòng tròn
        _loadInitialData();

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã lưu bài chạy thành công!"), backgroundColor: Colors.green));

        // Reset màn hình về trạng thái chờ
        setState(() {
          _distanceKm = 0;
          _calories = 0;
          _elapsed = Duration.zero;
          _routePoints.clear();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lỗi kết nối server! Không thể lưu."), backgroundColor: Colors.red));
      }
    }
  }

  // --- 5. LOGIC ĐẶT MỤC TIÊU (SET GOAL) ---
  void _handleSetGoal() {
    // Không cho đặt mục tiêu khi đang chạy dở
    if (_isTracking) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng dừng chạy trước khi đặt mục tiêu.")));
      return;
    }

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
              labelText: "Mục tiêu (Km)",
              hintText: "VD: 5.0",
              suffixText: "km",
              border: OutlineInputBorder()
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () async {
              final double? target = double.tryParse(controller.text);
              if (target != null && target > 0) {
                Navigator.pop(ctx);

                // Gọi API set goal
                DailyGoal? newGoal = await _goalService.setTodayGoal(target);

                // Cập nhật lại state để vòng tròn % thay đổi
                if (mounted) {
                  setState(() => _dailyGoal = newGoal);
                }
              }
            },
            child: const Text("Lưu"),
          ),
        ],
      ),
    );
  }

  // --- 6. GIAO DIỆN (UI) ---
  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    return "${twoDigits(d.inHours)}:${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";
  }

  @override
  Widget build(BuildContext context) {
    // Tính toán % hoàn thành cho vòng tròn bên trái
    double progress = 0.0;
    if (_dailyGoal != null && _dailyGoal!.targetDistanceKm > 0) {
      // Tổng = Đã chạy trước đó (từ server) + Đang chạy hiện tại (realtime)
      double totalKm = _dailyGoal!.currentDistanceKm + (_isTracking ? _distanceKm : 0);
      progress = (totalKm / _dailyGoal!.targetDistanceKm).clamp(0.0, 1.0);
    }

    return Scaffold(
      // Dùng Stack để Map nằm dưới, Panel điều khiển nằm đè lên trên
      body: Stack(
        children: [
          // LỚP 1: BẢN ĐỒ
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: LatLng(10.762622, 106.660172), // Mặc định HCM
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                // userAgentPackageName: 'com.example.runningapp', // Mở dòng này nếu cần thiết
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _routePoints,
                    strokeWidth: 6.0,
                    color: Colors.blueAccent,
                  ),
                ],
              ),
              if (_routePoints.isNotEmpty)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _routePoints.last,
                      width: 15, height: 15,
                      child: Container(
                        decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2)
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // LỚP 2: PANEL ĐIỀU KHIỂN (Gradient đen mờ ở dưới)
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              height: 260, // Chiều cao bảng điều khiển
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.9) // Đen mờ đậm dần xuống dưới
                    ],
                    stops: const [0.0, 0.3]
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // HÀNG 1: THÔNG SỐ (Time - Calories - Distance)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatItem("Time", _formatDuration(_elapsed)),
                        _buildStatItem("Calories", "${_calories.toStringAsFixed(0)} kcal"), // Đã sửa Speed -> Calories
                        _buildStatItem("Distance", "${_distanceKm.toStringAsFixed(2)} km"),
                      ],
                    ),
                  ),

                  // HÀNG 2: CÁC NÚT BẤM (Goal - Start - SetGoal)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 30, left: 30, right: 30),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [

                        // NÚT TRÁI: VÒNG TRÒN % GOAL
                        Column(
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 50, height: 50,
                                  child: CircularProgressIndicator(
                                    value: progress,
                                    backgroundColor: Colors.grey[700],
                                    color: Colors.orangeAccent,
                                    strokeWidth: 4,
                                  ),
                                ),
                                // Icon cờ hiệu
                                const Icon(Icons.flag, color: Colors.white70, size: 20),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              "${(progress * 100).toInt()}% Goal",
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            )
                          ],
                        ),

                        // NÚT GIỮA: START / STOP (To nhất)
                        GestureDetector(
                          onTap: _isSaving ? null : _toggleTracking,
                          child: Container(
                            width: 80, height: 80,
                            decoration: BoxDecoration(
                                color: _isTracking ? Colors.white : Colors.deepOrange, // Chạy: Trắng, Dừng: Cam
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.deepOrange.withOpacity(0.4),
                                      blurRadius: 20,
                                      spreadRadius: 5
                                  )
                                ]
                            ),
                            child: Center(
                              child: _isSaving
                                  ? const CircularProgressIndicator()
                                  : Icon(
                                _isTracking ? Icons.stop : Icons.play_arrow,
                                size: 45,
                                color: _isTracking ? Colors.redAccent : Colors.white,
                              ),
                            ),
                          ),
                        ),

                        // NÚT PHẢI: SET GOAL (Đặt mục tiêu)
                        GestureDetector(
                          onTap: _handleSetGoal,
                          child: Column(
                            children: [
                              Container(
                                width: 50, height: 50,
                                decoration: BoxDecoration(
                                    color: Colors.grey[800],
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.grey[600]!)
                                ),
                                child: const Icon(Icons.add_road, color: Colors.white),
                              ),
                              const SizedBox(height: 5),
                              const Text("Set Goal", style: TextStyle(color: Colors.white70, fontSize: 12))
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),

          // Nút Re-center bản đồ (Nằm ở góc phải, trên panel đen)
          Positioned(
            bottom: 280, right: 20,
            child: FloatingActionButton.small(
              backgroundColor: Colors.black54,
              heroTag: "recenter_tracking",
              child: const Icon(Icons.my_location, color: Colors.white),
              onPressed: () => _getCurrentLocation(),
            ),
          )
        ],
      ),
    );
  }

  // Widget hiển thị từng thông số (Số to, chữ nhỏ)
  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 0.5)
        ),
        const SizedBox(height: 4),
        Text(
            label.toUpperCase(),
            style: TextStyle(color: Colors.grey[400], fontSize: 11, fontWeight: FontWeight.bold)
        ),
      ],
    );
  }
}