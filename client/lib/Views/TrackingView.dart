import 'dart:async';
import 'package:flutter/foundation.dart'; // Check Android/iOS
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

// Import Service và Model bạn vừa tạo
import '../Services/RunService.dart';
import '../Services/UserService.dart';

class TrackingView extends StatefulWidget {
  const TrackingView({super.key});

  @override
  State<TrackingView> createState() => _TrackingViewState();
}

class _TrackingViewState extends State<TrackingView> {
  // --- STATE VARIABLES ---
  final MapController _mapController = MapController();
  final RunService _runService = RunService(); // 1. Khởi tạo Service

  // Dữ liệu đường chạy
  List<LatLng> _routePoints = [];
  double _distanceKm = 0.0;
  double _calories = 0.0;
  late DateTime _startTime;
  late DateTime _endTime;

  // Thời gian & Timer
  Duration _elapsed = Duration.zero;
  Timer? _timer;
  StreamSubscription<Position>? _positionStream;

  // Trạng thái lưu dữ liệu
  bool _isSaving = false; // 2. Biến để hiện Loading khi đang gọi API

  // Giả định cân nặng User (Sau này lấy từ Profile)
  final double _userWeightKg = 65.0;

  @override
  void initState() {
    super.initState();
    _startTracking();  }

  @override
  void dispose() {
    _timer?.cancel();
    _positionStream?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  // --- CẤU HÌNH GPS ---
  LocationSettings _getLocationSettings() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
        forceLocationManager: true,
        intervalDuration: const Duration(seconds: 1),
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0,
      timeLimit: Duration(seconds: 2),
    );
  }

  // --- LOGIC TRACKING ---
  Future<void> _startTracking() async {
    _startTime = DateTime.now().toUtc();
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsed = Duration(seconds: _elapsed.inSeconds + 1);
      });
    });

    _positionStream = Geolocator.getPositionStream(
        locationSettings: _getLocationSettings()
    ).listen((Position position) {
      _updatePosition(position);
    });
  }

  void _updatePosition(Position pos) {
    LatLng newPoint = LatLng(pos.latitude, pos.longitude);

    setState(() {
      if (_routePoints.isNotEmpty) {
        final double distBytes = const Distance().as(LengthUnit.Meter, _routePoints.last, newPoint);
        // Lọc nhiễu nhỏ
        if (distBytes > 0.5) {
          _distanceKm += (distBytes / 1000);
          _calories = _userWeightKg * _distanceKm * 1.036;
        }
      }
      _routePoints.add(newPoint);
      _mapController.move(newPoint, 17.0);
    });
  }

  // --- 3. LOGIC KẾT THÚC & GỌI API ---
  Future<void> _stopRun() async {
    // A. Dừng theo dõi ngay lập tức
    _timer?.cancel();
    _positionStream?.cancel();
    _endTime = DateTime.now().toUtc();

    // B. Hiển thị Loading
    setState(() => _isSaving = true);

    // C. Gọi API lưu lên Server (Backend: RunController)
    bool success = await _runService.saveRun(
      distance: _distanceKm,
      calories: _calories,
      duration: _elapsed,
      routePoints: _routePoints,
      startTime: _startTime,
      endTime: _endTime
    );


    // D. Xử lý kết quả
    if (!mounted) return;

    setState(() => _isSaving = false);

    if (success) {
      // Thành công: Quay về Home và báo reload
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đã lưu bài chạy thành công!"), backgroundColor: Colors.green),
      );
    } else {
      // Thất bại: Báo lỗi (Tạm thời vẫn cho thoát, hoặc giữ lại tùy bạn)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lỗi kết nối server! Không thể lưu."), backgroundColor: Colors.red),
      );
      // Navigator.pop(context, true); // Nếu muốn thoát luôn dù lỗi thì mở dòng này
    }
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

          // LỚP 3: NÚT KẾT THÚC (CÓ LOADING)
          Positioned(
            bottom: 40,
            left: 40,
            right: 40,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _stopRun, // Disable nút khi đang lưu
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(vertical: 15),
                elevation: 10,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: _isSaving
                  ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                  SizedBox(width: 10),
                  Text("ĐANG LƯU...", style: TextStyle(color: Colors.white)),
                ],
              )
                  : const Text(
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