import 'dart:async';
import 'package:flutter/foundation.dart'; // Cần thiết để check Android/iOS
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class TrackingView extends StatefulWidget {
  const TrackingView({super.key});

  @override
  State<TrackingView> createState() => _TrackingViewState();
}

class _TrackingViewState extends State<TrackingView> {
  // --- STATE VARIABLES ---
  final MapController _mapController = MapController();

  // Dữ liệu đường chạy
  List<LatLng> _routePoints = [];
  double _distanceKm = 0.0;
  double _calories = 0.0;

  // Thời gian & Timer
  Duration _elapsed = Duration.zero;
  Timer? _timer;
  StreamSubscription<Position>? _positionStream;

  // Giả định cân nặng User (Sau này lấy từ Profile)
  final double _userWeightKg = 65.0;

  @override
  void initState() {
    super.initState();
    _startTracking();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _positionStream?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  // --- CẤU HÌNH GPS (QUAN TRỌNG ĐỂ VẼ MƯỢT) ---
  LocationSettings _getLocationSettings() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0, // Bắt mọi di chuyển dù nhỏ nhất
        forceLocationManager: true, // Ép dùng chip GPS để ổn định hơn trên Android
        intervalDuration: const Duration(seconds: 1), // Cập nhật mỗi 1 giây
        // foregroundNotificationConfig: ... (Cấu hình chạy nền nếu cần sau này)
      );
    }
    // Cấu hình cho iOS
    return const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0,
      timeLimit: Duration(seconds: 2),
    );
  }

  // --- LOGIC XỬ LÝ ---
  Future<void> _startTracking() async {
    // 1. Check Service GPS có bật không
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Có thể show dialog nhắc user bật GPS tại đây
      return;
    }

    // 2. Check Quyền
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    // 3. Start Timer (Đếm giờ)
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsed = Duration(seconds: _elapsed.inSeconds + 1);
      });
    });

    // 4. Start GPS Stream (Lắng nghe vị trí)
    _positionStream = Geolocator.getPositionStream(
        locationSettings: _getLocationSettings() // Sử dụng cấu hình mượt
    ).listen((Position position) {
      _updatePosition(position);
    });
  }

  void _updatePosition(Position pos) {
    LatLng newPoint = LatLng(pos.latitude, pos.longitude);

    setState(() {
      // Tính toán khoảng cách và calo
      if (_routePoints.isNotEmpty) {
        final double distBytes = const Distance().as(LengthUnit.Meter, _routePoints.last, newPoint);

        // Chỉ cộng dồn nếu di chuyển thực sự (> 0.5m) để tránh nhiễu khi đứng yên
        if (distBytes > 0.5) {
          _distanceKm += (distBytes / 1000);
          _calories = _userWeightKg * _distanceKm * 1.036;
        }
      }

      // Luôn thêm điểm mới vào đường vẽ để tạo cảm giác mượt
      _routePoints.add(newPoint);

      // Di chuyển camera theo người chạy
      _mapController.move(newPoint, 17.0);
    });
  }

  void _stopRun() {
    _timer?.cancel();
    _positionStream?.cancel();
    // Trả về true để báo cho màn hình trước biết là đã chạy xong
    Navigator.pop(context, true);
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    return "${twoDigits(d.inHours)}:${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";
  }

  // --- UI ---
  @override
  Widget build(BuildContext context) {
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
                userAgentPackageName: 'com.example.runningapp',
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _routePoints,
                    strokeWidth: 5.0,
                    color: Colors.blue,
                  ),
                ],
              ),
              // Marker hiện tại (tùy chọn, để biết mình đang ở đâu chính xác)
              if (_routePoints.isNotEmpty)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _routePoints.last,
                      width: 20,
                      height: 20,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // LỚP 2: LIVE STATS
          Positioned(
            top: 50,
            left: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _liveStatRow(Icons.timer, _formatDuration(_elapsed), Colors.yellow),
                  const SizedBox(height: 5),
                  _liveStatRow(Icons.directions_run, "${_distanceKm.toStringAsFixed(2)} km", Colors.blue),
                  const SizedBox(height: 5),
                  _liveStatRow(Icons.local_fire_department, "${_calories.toStringAsFixed(0)} kcal", Colors.orange),
                ],
              ),
            ),
          ),

          // LỚP 3: NÚT KẾT THÚC
          Positioned(
            bottom: 40,
            left: 40,
            right: 40,
            child: ElevatedButton(
              onPressed: _stopRun,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(vertical: 15),
                elevation: 10,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                "KẾT THÚC",
                style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _liveStatRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
        ),
      ],
    );
  }
}