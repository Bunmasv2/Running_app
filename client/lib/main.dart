import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart'; // Bản đồ OSM miễn phí
import 'package:latlong2/latlong.dart'; // Xử lý tọa độ
import 'package:geolocator/geolocator.dart'; // Bắt GPS
import 'package:flutter/foundation.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Realtime GPS Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
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
  // 1. DỮ LIỆU RAM: Lưu toàn bộ điểm chạy tại đây
  final List<LatLng> _routePoints = [];

  // Quản lý trạng thái
  StreamSubscription<Position>? _positionStream;
  bool _isTracking = false;
  final MapController _mapController = MapController();

  // --- CẤU HÌNH GPS CHUYÊN SÂU (3 GIÂY/LẦN) ---
  LocationSettings _getLocationSettings() {
    // Cấu hình riêng cho Android để bắt buộc lấy mẫu mỗi 3s
    // Kể cả khi đứng yên (distanceFilter = 0)
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0, // Bắt kể cả khi di chuyển 0 mét
        forceLocationManager: true,
        intervalDuration: const Duration(seconds: 3), // Quan trọng: 3 giây/lần
        // foregroundNotificationConfig: ... (Cần nếu muốn chạy ngầm bền bỉ)
      );
    }

    // Cấu hình cho iOS và các nền tảng khác
    return const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0,
      timeLimit: Duration(seconds: 3), // Cố gắng trả về sau mỗi 3s
    );
  }

  // --- BẮT ĐẦU CHẠY ---
  void _startTracking() async {
    // 1. Xin quyền (Code tối giản, thực tế nên check kỹ hơn)
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    // 2. Xóa dữ liệu cũ, đổi trạng thái
    setState(() {
      _routePoints.clear();
      _isTracking = true;
    });

    // 3. Bắt đầu lắng nghe Stream
    _positionStream = Geolocator.getPositionStream(
        locationSettings: _getLocationSettings()
    ).listen((Position position) {

      // LOGIC CHẠY MỖI 3 GIÂY KHI CÓ TỌA ĐỘ MỚI
      print("GPS Update: ${position.latitude}, ${position.longitude}");

      setState(() {
        // Lưu vào RAM
        LatLng newPoint = LatLng(position.latitude, position.longitude);
        _routePoints.add(newPoint);

        // Di chuyển Camera theo người chạy
        _mapController.move(newPoint, 17.0);
      });
    });
  }

  // --- KẾT THÚC CHẠY ---
  void _stopTracking() {
    // 1. Hủy lắng nghe GPS -> Dừng cập nhật vị trí
    _positionStream?.cancel();
    _positionStream = null;

    setState(() {
      _isTracking = false;
    });

    // 2. Zoom out để nhìn thấy toàn bộ quãng đường vừa chạy
    if (_routePoints.isNotEmpty) {
      _zoomToFitRoute();
    }

    // Tại đây dữ liệu vẫn nằm trong biến _routePoints
    // Bạn có thể xem lại trên map thoải mái
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Đã kết thúc! Tổng quãng đường: ${_routePoints.length} điểm GPS"))
    );
  }

  // Hàm phụ trợ: Zoom bản đồ để thấy hết đường đi
  void _zoomToFitRoute() {
    // Tính toán khung bao (Bounds)
    double minLat = 90, maxLat = -90, minLng = 180, maxLng = -180;
    for (var p in _routePoints) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    // Fit bounds
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng)),
        padding: const EdgeInsets.all(50),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isTracking ? 'Đang ghi hình (3s/lần)...' : 'Kết quả chạy bộ'),
        backgroundColor: _isTracking ? Colors.redAccent : Colors.blueAccent,
        foregroundColor: Colors.white,
        actions: [
          // Nút hiển thị số điểm GPS đang có trong RAM
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text("${_routePoints.length} pts", style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
      body: Stack(
        children: [
          // 1. BẢN ĐỒ
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(10.762622, 106.660172), // Mặc định HCM
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.running_app',
              ),

              // Vẽ đường màu xanh
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _routePoints,
                    strokeWidth: 5.0,
                    color: Colors.blue,
                  ),
                ],
              ),

              // Vẽ điểm đầu (Xanh) và điểm cuối/hiện tại (Đỏ)
              if (_routePoints.isNotEmpty)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _routePoints.first,
                      width: 40, height: 40,
                      child: const Icon(Icons.location_on, color: Colors.green, size: 40),
                    ),
                    Marker(
                      point: _routePoints.last,
                      width: 40, height: 40,
                      child: const Icon(Icons.directions_run, color: Colors.red, size: 40),
                    ),
                  ],
                ),
            ],
          ),

          // 2. NÚT ĐIỀU KHIỂN
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: _isTracking ? _stopTracking : _startTracking,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isTracking ? Colors.red : Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                _isTracking ? 'KẾT THÚC' : 'BẮT ĐẦU CHẠY',
                style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}