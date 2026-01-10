import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

// Services & Models
import '../Services/RunService.dart';
import '../Services/GoalService.dart';
import '../Services/UserService.dart';
import '../Models/UserProfile.dart';
import '../models/RunModels.dart'; // Chứa DailyGoal

class RecordView extends StatefulWidget {
  const RecordView({super.key});

  @override
  State<RecordView> createState() => _RecordViewState();
}

class _RecordViewState extends State<RecordView> {
  // --- 1. SERVICE & STATE ---
  final RunService _runService = RunService();
  final GoalService _goalService = GoalService();
  final UserService _userService = UserService();
  final MapController _mapController = MapController();

  // Dữ liệu User & Goal
  double _userWeightKg = 60.0; // Mặc định
  DailyGoal? _dailyGoal;

  // Trạng thái chạy
  bool _isTracking = false;
  bool _isSaving = false;

  // Dữ liệu Realtime
  List<LatLng> _routePoints = [];
  double _distanceKm = 0.0;
  double _calories = 0.0;
  Duration _elapsed = Duration.zero;

  // Timer & Stream
  Timer? _timer;
  StreamSubscription<Position>? _positionStream;
  late DateTime _startTime;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _positionStream?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  // --- 2. LOGIC KHỞI TẠO ---
  Future<void> _loadInitialData() async {
    // Lấy Goal và Profile song song
    final results = await Future.wait([
      _userService.getUserProfile(),
      _goalService.getTodayGoal(),
    ]);

    if (mounted) {
      setState(() {
        // 1. Cập nhật cân nặng để tính Calo
        final profile = results[0] as UserProfile?;
        if (profile != null && profile.weightKg > 0) {
          _userWeightKg = profile.weightKg;
        }

        // 2. Cập nhật Goal
        _dailyGoal = results[1] as DailyGoal?;
      });
    }

    // Lấy vị trí hiện tại để center map (nếu cần)
    _getCurrentLocation();
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

  // --- 3. LOGIC TRACKING (START/STOP) ---
  void _toggleTracking() {
    if (_isTracking) {
      _stopRun();
    } else {
      _startRun();
    }
  }

  Future<void> _startRun() async {
    // Reset dữ liệu nếu chạy mới
    setState(() {
      _isTracking = true;
      _routePoints.clear();
      _distanceKm = 0.0;
      _calories = 0.0;
      _elapsed = Duration.zero;
      _startTime = DateTime.now().toUtc();
    });

    // Bắt đầu Timer
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsed = Duration(seconds: _elapsed.inSeconds + 1);
      });
    });

    // Bắt đầu GPS Stream
    final locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );

    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
      _updatePosition(position);
    });
  }

  void _updatePosition(Position pos) {
    if (pos.accuracy > 30.0) return; // Lọc nhiễu

    LatLng newPoint = LatLng(pos.latitude, pos.longitude);

    setState(() {
      if (_routePoints.isNotEmpty) {
        final double distMeters = const Distance().as(LengthUnit.Meter, _routePoints.last, newPoint);
        if (distMeters > 5.0) { // Chỉ tính nếu di chuyển > 5m
          _distanceKm += (distMeters / 1000);
          _calories = _userWeightKg * _distanceKm * 1.036;
          _routePoints.add(newPoint);

          // Cập nhật progress cho Goal (chỉ hiển thị, chưa lưu DB)
          if (_dailyGoal != null) {
            // Cộng dồn tạm thời vào goal hiện tại để hiển thị %
            // Lưu ý: Logic này chỉ để hiển thị UI realtime
          }
        }
      } else {
        _routePoints.add(newPoint);
      }
      _mapController.move(newPoint, 17.0);
    });
  }

  Future<void> _stopRun() async {
    // Dừng timer/stream
    _timer?.cancel();
    _positionStream?.cancel();

    // Validate quãng đường
    if (_distanceKm < 0.01) {
      setState(() => _isTracking = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Quãng đường quá ngắn, không lưu.")));
      return;
    }

    setState(() {
      _isTracking = false; // Đổi icon về Play
      _isSaving = true;    // Hiện loading
    });

    // Gọi API Lưu
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã lưu bài chạy thành công!"), backgroundColor: Colors.green));
        // Reset lại UI hoặc Reload Goal mới
        _loadInitialData();
        // Reset các chỉ số về 0
        setState(() {
          _distanceKm = 0;
          _calories = 0;
          _elapsed = Duration.zero;
          _routePoints.clear();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lỗi lưu bài chạy!"), backgroundColor: Colors.red));
      }
    }
  }

  // --- 4. LOGIC ĐẶT MỤC TIÊU ---
  void _handleSetGoal() {
    if (_isTracking) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng dừng chạy trước khi đặt mục tiêu mới.")));
      return;
    }

    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Đặt mục tiêu (Km)"),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: const InputDecoration(hintText: "Ví dụ: 5.0", suffixText: "km"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () async {
              final double? target = double.tryParse(controller.text);
              if (target != null && target > 0) {
                Navigator.pop(ctx);
                DailyGoal? newGoal = await _goalService.setTodayGoal(target);
                if (mounted) setState(() => _dailyGoal = newGoal);
              }
            },
            child: const Text("Lưu"),
          ),
        ],
      ),
    );
  }

  // --- 5. UI COMPONENTS ---
  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    return "${twoDigits(d.inHours)}:${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";
  }

  @override
  Widget build(BuildContext context) {
    // Tính toán % hoàn thành
    double progress = 0.0;
    if (_dailyGoal != null && _dailyGoal!.targetDistanceKm > 0) {
      // Tổng quãng đường = Quãng đường cũ trong Goal + Quãng đường đang chạy
      double totalKm = _dailyGoal!.currentDistanceKm + (_isTracking ? _distanceKm : 0);
      progress = (totalKm / _dailyGoal!.targetDistanceKm).clamp(0.0, 1.0);
    }

    return Scaffold(
      body: Stack(
        children: [
          // LỚP 1: BẢN ĐỒ
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: LatLng(10.762622, 106.660172),
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              ),
              PolylineLayer(
                polylines: [
                  Polyline(points: _routePoints, strokeWidth: 5.0, color: Colors.blue),
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

          // LỚP 2: PANEL THỐNG KÊ (ĐEN MỜ Ở DƯỚI)
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              height: 280, // Chiều cao khu vực điều khiển
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
                    stops: const [0.0, 0.3]
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // --- STATS ROW (TIME - CALORIES - DISTANCE) ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatItem("Time", _formatDuration(_elapsed)),
                        // Thay Speed bằng Calories
                        _buildStatItem("Calories", "${_calories.toStringAsFixed(0)} kcal"),
                        _buildStatItem("Distance", "${_distanceKm.toStringAsFixed(2)} km"),
                      ],
                    ),
                  ),

                  // --- CONTROL ROW (LEFT ICON - START BTN - RIGHT BTN) ---
                  Padding(
                    padding: const EdgeInsets.only(bottom: 40, left: 30, right: 30),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Nút TRÁI: % Mục tiêu
                        Column(
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 50, height: 50,
                                  child: CircularProgressIndicator(
                                    value: progress,
                                    backgroundColor: Colors.grey,
                                    color: Colors.orangeAccent,
                                    strokeWidth: 4,
                                  ),
                                ),
                                Icon(Icons.flag, color: Colors.white.withOpacity(0.8), size: 24),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              "${(progress * 100).toInt()}% Goal",
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            )
                          ],
                        ),

                        // NÚT GIỮA: START / STOP
                        GestureDetector(
                          onTap: _isSaving ? null : _toggleTracking,
                          child: Container(
                            width: 80, height: 80,
                            decoration: BoxDecoration(
                                color: _isTracking ? Colors.white : Colors.deepOrange,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(color: Colors.orange.withOpacity(0.4), blurRadius: 15, spreadRadius: 5)
                                ]
                            ),
                            child: Center(
                              child: _isSaving
                                  ? const CircularProgressIndicator()
                                  : Icon(
                                _isTracking ? Icons.stop : Icons.play_arrow,
                                size: 40,
                                color: _isTracking ? Colors.red : Colors.white,
                              ),
                            ),
                          ),
                        ),

                        // NÚT PHẢI: ĐẶT MỤC TIÊU
                        GestureDetector(
                          onTap: _handleSetGoal,
                          child: Column(
                            children: [
                              Container(
                                width: 50, height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.grey[800],
                                  shape: BoxShape.circle,
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

          // Nút Re-center (Tùy chọn)
          Positioned(
            bottom: 300, right: 20,
            child: FloatingActionButton.small(
              backgroundColor: Colors.black54,
              child: const Icon(Icons.my_location, color: Colors.white),
              onPressed: () => _getCurrentLocation(),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}