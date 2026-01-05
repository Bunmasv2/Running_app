import 'dart:async';
import 'package:flutter/foundation.dart'; // Để check Android/iOS
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Run Tracker UI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      home: const TrackingPage(),
    );
  }
}

class TrackingPage extends StatefulWidget {
  const TrackingPage({super.key});

  @override
  State<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage> {
  // Dữ liệu đường chạy
  final List<LatLng> _routePoints = [];

  // Các biến thống kê
  double _totalDistanceKm = 0.0;
  double _burnedCalories = 0.0;
  Duration _elapsedTime = Duration.zero;

  // Cấu hình người dùng (Giả định)
  final double _userWeightKg = 65.0; // Ví dụ 65kg

  // Quản lý trạng thái
  StreamSubscription<Position>? _positionStream;
  Timer? _timer;
  bool _isTracking = false;
  final MapController _mapController = MapController();
  final Distance _distanceCalculator = const Distance(); // Công cụ tính khoảng cách

  // --- 1. CẤU HÌNH GPS ---
  LocationSettings _getLocationSettings() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
        forceLocationManager: true,
        intervalDuration: const Duration(seconds: 3), // Bắt mỗi 3 giây
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0,
      timeLimit: Duration(seconds: 3),
    );
  }

  // --- 2. LOGIC BẮT ĐẦU CHẠY ---
  void _startTracking() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    setState(() {
      _routePoints.clear();
      _totalDistanceKm = 0.0;
      _burnedCalories = 0.0;
      _elapsedTime = Duration.zero;
      _isTracking = true;
    });

    // Bắt đầu đếm giờ (Mỗi giây update UI 1 lần)
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedTime = Duration(seconds: _elapsedTime.inSeconds + 1);
      });
    });

    // Bắt đầu lắng nghe GPS
    _positionStream = Geolocator.getPositionStream(
        locationSettings: _getLocationSettings()
    ).listen((Position position) {
      _updateLocation(position);
    });
  }

  // --- 3. XỬ LÝ KHI CÓ TỌA ĐỘ MỚI ---
  void _updateLocation(Position position) {
    LatLng newPoint = LatLng(position.latitude, position.longitude);

    setState(() {
      // Nếu đã có điểm trước đó, tính khoảng cách cộng dồn
      if (_routePoints.isNotEmpty) {
        double distMeter = _distanceCalculator.as(LengthUnit.Meter, _routePoints.last, newPoint);

        // Chỉ cộng nếu di chuyển > 0.5 mét (lọc nhiễu)
        if (distMeter > 0.5) {
          _totalDistanceKm += (distMeter / 1000); // Đổi ra KM

          // Tính Calo: Weight * Distance(km) * 1.036
          _burnedCalories = _userWeightKg * _totalDistanceKm * 1.036;
        }
      }

      _routePoints.add(newPoint);
      _mapController.move(newPoint, 17.0);
    });
  }

  // --- 4. KẾT THÚC ---
  void _stopTracking() {
    _positionStream?.cancel();
    _timer?.cancel();
    setState(() => _isTracking = false);

    // Zoom out xem toàn cảnh
    if (_routePoints.isNotEmpty) _zoomToFitRoute();
  }

  void _zoomToFitRoute() {
    if (_routePoints.isEmpty) return;
    double minLat = 90, maxLat = -90, minLng = 180, maxLng = -180;
    for (var p in _routePoints) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng)),
        padding: const EdgeInsets.all(50),
      ),
    );
  }

  // Helper format thời gian HH:MM:SS
  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    return "${twoDigits(d.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // LỚP 1: BẢN ĐỒ FULL MÀN HÌNH
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(10.762622, 106.660172),
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.runapp',
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
                      width: 20, height: 20,
                      child: Container(
                        decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3)
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // LỚP 2: BẢNG THÔNG SỐ (GÓC TRÊN TRÁI)
          // Chỉ hiện khi đang chạy hoặc đã chạy xong
          if (_routePoints.isNotEmpty || _isTracking)
            Positioned(
              top: 50, // Cách mép trên (tránh tai thỏ)
              left: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7), // Nền đen bán trong suốt
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(blurRadius: 5, color: Colors.black26)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _statRow(Icons.timer, _formatDuration(_elapsedTime), Colors.yellow),
                    const SizedBox(height: 8),
                    _statRow(Icons.directions_run, "${_totalDistanceKm.toStringAsFixed(2)} km", Colors.blueAccent),
                    const SizedBox(height: 8),
                    _statRow(Icons.local_fire_department, "${_burnedCalories.toStringAsFixed(0)} kcal", Colors.orange),
                  ],
                ),
              ),
            ),

          // LỚP 3: NÚT ĐIỀU KHIỂN (Ở DƯỚI)
          Positioned(
            bottom: 30, left: 20, right: 20,
            child: ElevatedButton(
              onPressed: _isTracking ? _stopTracking : _startTracking,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isTracking ? Colors.red : Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 5,
              ),
              child: Text(
                _isTracking ? 'KẾT THÚC BUỔI CHẠY' : 'BẮT ĐẦU',
                style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget hiển thị 1 dòng thông số
  Widget _statRow(IconData icon, String value, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
              fontFamily: 'monospace' // Font đơn cách số không bị nhảy
          ),
        ),
      ],
    );
  }
}