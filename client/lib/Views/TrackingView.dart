import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import '../Services/RunService.dart';
import '../Services/GoalService.dart';
import '../Services/UserService.dart';
import '../Models/UserProfile.dart';
import '../models/RunModels.dart';

class TrackingView extends StatefulWidget {
  const TrackingView({super.key});

  @override
  State<TrackingView> createState() => _TrackingViewState();
}

class _TrackingViewState extends State<TrackingView> {
  final MapController _mapController = MapController();
  final RunService _runService = RunService();
  final GoalService _goalService = GoalService();
  final UserService _userService = UserService();

  double _userWeightKg = 60.0;
  DailyGoal? _dailyGoal;

  List<LatLng> _routePoints = [];
  double _distanceKm = 0.0;
  double _calories = 0.0;
  Duration _elapsed = Duration.zero;

  DateTime? _lastPointTime; // Thời gian ghi nhận điểm cuối cùng
  double _currentSpeedKmh = 0.0; // Tốc độ hiện tại để hiển thị (nếu cần)

  // Trạng thái hệ thống
  bool _isTracking = false;
  bool _isSaving = false;

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

  Future<void> _loadInitialData() async {
    try {
      final results = await Future.wait([
        _userService.getUserProfile(),
        _goalService.getTodayGoal(),
      ]);

      if (mounted) {
        setState(() {
          final profile = results[0] as UserProfile?;
          if (profile != null && profile.weightKg > 0) {
            _userWeightKg = profile.weightKg;
          }
          _dailyGoal = results[1] as DailyGoal?;
        });
      }
      _checkPermissionAndLocate();
    } catch (e) {
      print("Lỗi load data tracking: $e");
    }
  }

  Future<void> _checkPermissionAndLocate() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      Position pos = await Geolocator.getCurrentPosition();
      _mapController.move(LatLng(pos.latitude, pos.longitude), 16.0);
    }
  }

  // Hàm kiểm tra quyền chặt chẽ trước khi Start
  Future<bool> _ensurePermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Vui lòng bật GPS (Vị trí) trên điện thoại!")));
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Cần cấp quyền vị trí để tính quãng đường!")));
        return false;
      }
    }
    return true;
  }

  void _toggleTracking() async {
    if (_isTracking) {
      _stopRun();
    } else {
      bool hasPerm = await _ensurePermissions();
      if (hasPerm) _startRun();
    }
  }

  Future<void> _startRun() async {
    // Reset toàn bộ thông số
    setState(() {
      _isTracking = true;
      _routePoints.clear();
      _distanceKm = 0.0;
      _calories = 0.0;
      _elapsed = Duration.zero;
      _currentSpeedKmh = 0.0;
      _startTime = DateTime.now().toUtc();
      _lastPointTime = DateTime.now(); // Mốc thời gian bắt đầu
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsed = Duration(seconds: _elapsed.inSeconds + 1);
      });
    });

    // 2. Cấu hình GPS để nhận diện thay đổi nhỏ & liên tục
    final locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation, // Độ chính xác cao nhất
      distanceFilter: 0, // Nhận mọi thay đổi dù là nhỏ nhất (để vẽ mượt)
    );

    // 3. Lắng nghe stream
    _positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position position) {
      _updatePosition(position);
    });
  }

  // --- LOGIC QUAN TRỌNG: CẬP NHẬT VỊ TRÍ & ANTI-CHEAT ---
  void _updatePosition(Position pos) {
    // 1. Lọc nhiễu GPS cơ bản (Nếu sai số > 30m thì bỏ qua)
    if (pos.accuracy > 30.0) return;

    DateTime now = DateTime.now();
    LatLng newPoint = LatLng(pos.latitude, pos.longitude);

    setState(() {
      if (_routePoints.isNotEmpty) {
        final double distMeters =
            const Distance().as(LengthUnit.Meter, _routePoints.last, newPoint);

        // Tính thời gian trôi qua giữa 2 điểm (tính bằng giây)
        // Dùng _lastPointTime để chính xác hơn so với Timer
        int timeDiffSeconds = now.difference(_lastPointTime!).inSeconds;
        if (timeDiffSeconds == 0) timeDiffSeconds = 1; // Tránh chia cho 0

        // --- ANTI-CHEAT: KIỂM TRA TỐC ĐỘ ---
        // Vận tốc (m/s) = Quãng đường / Thời gian
        double speedMps = distMeters / timeDiffSeconds;
        double speedKmh = speedMps * 3.6; // Đổi sang km/h

        // Cập nhật tốc độ hiện tại lên UI (để user biết)
        _currentSpeedKmh = speedKmh;

        // Nếu tốc độ > 35km/h => Khả năng cao là đi xe hoặc GPS nhảy điểm ảo
        if (speedKmh > 35.0) {
          // Có thể hiện thông báo nhỏ nếu muốn
          // print("Phát hiện di chuyển quá nhanh ($speedKmh km/h) - Bỏ qua");
          return;
        }

        // --- LƯU ĐIỂM HỢP LỆ ---
        // Chỉ cộng dồn nếu di chuyển > 0.5 mét (tránh nhiễu khi đứng yên lắc lư)
        if (distMeters > 0.5) {
          _distanceKm += (distMeters / 1000);
          _calories = _userWeightKg * _distanceKm * 1.036;

          _routePoints.add(newPoint); // Lưu vào list cục bộ
          _lastPointTime = now; // Cập nhật mốc thời gian cho điểm này
        }
      } else {
        // Điểm đầu tiên
        _routePoints.add(newPoint);
        _lastPointTime = now;
      }

      // Camera luôn đi theo
      _mapController.move(newPoint, 17.0);
    });
  }

  Future<void> _stopRun() async {
    _timer?.cancel();
    _positionStream?.cancel();

    // Check chạy quá ngắn
    // if (_distanceKm < 0.05) {
    //   // < 50 mét
    //   setState(() => _isTracking = false);
    //   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
    //       content: Text("Quãng đường quá ngắn (<50m), không lưu.")));
    //   return;
    // }

    setState(() {
      _isTracking = false;
      _isSaving = true;
    });

    // --- GỌI API LƯU 1 LẦN DUY NHẤT ---
    // List<LatLng> _routePoints đang chứa toàn bộ chuỗi JSON các điểm hợp lệ
    bool success = await _runService.saveRun(
      distance: _distanceKm,
      calories: _calories,
      duration: _elapsed,
      routePoints:
          _routePoints, // Truyền list này sang RunService để encode JSON
      startTime: _startTime,
      endTime: DateTime.now().toUtc(),
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        _loadInitialData(); // Reload goal
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Thành tích đã được lưu!"),
            backgroundColor: Colors.green));

        // Reset về 0
        setState(() {
          _distanceKm = 0;
          _calories = 0;
          _elapsed = Duration.zero;
          _routePoints.clear();
          _currentSpeedKmh = 0;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Lỗi lưu dữ liệu. Vui lòng kiểm tra mạng."),
            backgroundColor: Colors.red));
      }
    }
  }

  // --- 5. UI & CÁC WIDGET PHỤ --- (Giữ nguyên hoặc chỉnh sửa nhỏ)

  // Hàm đặt mục tiêu (Logic giữ nguyên như cũ)
  Future<void> _handleSetGoal() async {
    // 1. Không cho đặt mục tiêu khi đang chạy
    if (_isTracking) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Hãy dừng chạy trước khi đặt mục tiêu.")));
      return;
    }

    final TextEditingController controller = TextEditingController();

    // 2. Hiển thị Dialog nhập số km
    await showDialog(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
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
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () async {
              // Parse dữ liệu chặt chẽ
              final double? target = double.tryParse(controller.text);

              if (target != null && target > 0) {
                Navigator.pop(ctx); // Đóng dialog

                // Gọi API set goal
                // (Giả sử bạn muốn hiện loading thì có thể thêm setState _isSaving = true ở đây)
                try {
                  DailyGoal? newGoal = await _goalService.setTodayGoal(target);

                  if (mounted && newGoal != null) {
                    setState(() {
                      _dailyGoal = newGoal;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("Đã cập nhật mục tiêu!"),
                      backgroundColor: Colors.green,
                    ));
                  }
                } catch (e) {
                  print("Lỗi set goal: $e");
                }
              }
            },
            child: const Text("Lưu"),
          ),
        ],
      ),
    );
  }
  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    return "${twoDigits(d.inHours)}:${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";
  }

  @override
  Widget build(BuildContext context) {
    // Tính toán progress Goal
    double progress = 0.0;
    if (_dailyGoal != null && _dailyGoal!.targetDistanceKm > 0) {
      double totalKm =
          _dailyGoal!.currentDistanceKm + (_isTracking ? _distanceKm : 0);
      progress = (totalKm / _dailyGoal!.targetDistanceKm).clamp(0.0, 1.0);
    }

    return Scaffold(
      body: Stack(
        children: [
          // 1. MAP
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: LatLng(10.762622, 106.660172),
              initialZoom: 16.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
                      width: 15,
                      height: 15,
                      child: Container(
                        decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2)),
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // 2. PANEL INFO
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 270,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.95)
                    ],
                    stops: const [
                      0.0,
                      0.3
                    ]),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Hàng hiển thị tốc độ hiện tại (Để user biết mình có đang bị tính là đi xe không)
                  if (_isTracking)
                    Text(
                      "Speed: ${_currentSpeedKmh.toStringAsFixed(1)} km/h",
                      style: TextStyle(
                          color: _currentSpeedKmh > 30
                              ? Colors.red
                              : Colors.greenAccent,
                          fontSize: 14,
                          fontStyle: FontStyle.italic),
                    ),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatItem("Time", _formatDuration(_elapsed)),
                        _buildStatItem(
                            "Calories", "${_calories.toStringAsFixed(0)} kcal"),
                        _buildStatItem(
                            "Distance", "${_distanceKm.toStringAsFixed(2)} km"),
                      ],
                    ),
                  ),

                  // Nút bấm
                  Padding(
                    padding:
                        const EdgeInsets.only(bottom: 30, left: 30, right: 30),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Goal Progress
                        Column(
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 50,
                                  height: 50,
                                  child: CircularProgressIndicator(
                                    value: progress,
                                    backgroundColor: Colors.grey[700],
                                    color: Colors.orangeAccent,
                                    strokeWidth: 4,
                                  ),
                                ),
                                const Icon(Icons.flag,
                                    color: Colors.white70, size: 20),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text("${(progress * 100).toInt()}% Goal",
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 12))
                          ],
                        ),

                        // START / STOP BUTTON
                        GestureDetector(
                          onTap: _isSaving ? null : _toggleTracking,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                                color: _isTracking
                                    ? Colors.white
                                    : Colors.deepOrange,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.deepOrange.withOpacity(0.4),
                                      blurRadius: 20,
                                      spreadRadius: 5)
                                ]),
                            child: Center(
                              child: _isSaving
                                  ? const CircularProgressIndicator()
                                  : Icon(
                                      _isTracking
                                          ? Icons.stop
                                          : Icons.play_arrow,
                                      size: 45,
                                      color: _isTracking
                                          ? Colors.redAccent
                                          : Colors.white),
                            ),
                          ),
                        ),

                        // Set Goal (Giả lập nút, bạn gắn lại hàm _handleSetGoal vào đây)
                        GestureDetector(
                          onTap: () {
                            _handleSetGoal();
                          },
                          child: Column(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                    color: Colors.grey[800],
                                    shape: BoxShape.circle,
                                    border:
                                        Border.all(color: Colors.grey[600]!)),
                                child: const Icon(Icons.add_road,
                                    color: Colors.white),
                              ),
                              const SizedBox(height: 5),
                              const Text("Set Goal",
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 12))
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

          // Nút Re-center
          Positioned(
            bottom: 280,
            right: 20,
            child: FloatingActionButton.small(
              backgroundColor: Colors.black54,
              child: const Icon(Icons.my_location, color: Colors.white),
              onPressed: () => _checkPermissionAndLocate(),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(label.toUpperCase(),
            style: TextStyle(
                color: Colors.grey[400],
                fontSize: 11,
                fontWeight: FontWeight.bold)),
      ],
    );
  }
}
