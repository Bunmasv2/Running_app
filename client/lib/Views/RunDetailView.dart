// lib/Views/RunDetailView.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../Services/RunService.dart';
import '../models/RunModels.dart';

class RunDetailView extends StatefulWidget {
  final int runId; // Nhận ID từ màn hình danh sách
  const RunDetailView({super.key, required this.runId});

  @override
  State<RunDetailView> createState() => _RunDetailViewState();
}

class _RunDetailViewState extends State<RunDetailView> {
  final RunService _runService = RunService();
  RunDetailDto? _detail;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    //[cite: 102]: Gọi API lấy chi tiết
    final data = await _runService.getRunDetail(widget.runId);
    if (mounted) {
      setState(() {
        _detail = data;
        _isLoading = false;
      });
    }
  }

  // Tính toán khung nhìn bản đồ để bao trọn toàn bộ đường chạy
  LatLngBounds _getBounds(List<LatLng> points) {
    if (points.isEmpty) {
      return LatLngBounds(const LatLng(10.7, 106.6), const LatLng(10.8, 106.7));
    }
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (var p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    return LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Chi tiết buổi chạy")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _detail == null
          ? const Center(child: Text("Không tìm thấy dữ liệu"))
          : Column(
        children: [
          // PHẦN 1: BẢN ĐỒ TĨNH
          Expanded(
            flex: 2, // Map chiếm 2/3 màn hình
            child: FlutterMap(
              options: MapOptions(
                // Tự động zoom vừa khít đường chạy
                initialCameraFit: CameraFit.bounds(
                  bounds: _getBounds(_detail!.routePoints),
                  padding: const EdgeInsets.all(50),
                ),
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all, // Vẫn cho phép zoom/pan xem lại
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.runningapp',
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _detail!.routePoints,
                      strokeWidth: 5.0,
                      color: Colors.redAccent,
                    ),
                  ],
                ),
                // Marker điểm đầu và cuối
                if (_detail!.routePoints.isNotEmpty)
                  MarkerLayer(markers: [
                    Marker(point: _detail!.routePoints.first, child: const Icon(Icons.trip_origin, color: Colors.green)),
                    Marker(point: _detail!.routePoints.last, child: const Icon(Icons.flag, color: Colors.red)),
                  ])
              ],
            ),
          ),

          // PHẦN 2: THÔNG SỐ CHI TIẾT [cite: 104]
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -5))],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  const Text("Tổng kết", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _detailItem("Quãng đường", "${_detail!.distanceKm.toStringAsFixed(2)} km"),
                      _detailItem("Thời gian", "${(_detail!.durationSeconds / 60).toStringAsFixed(0)} phút"),
                      _detailItem("Calo", "${_detail!.calories.toStringAsFixed(0)} kcal"),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
        const SizedBox(height: 5),
        Text(label, style: TextStyle(color: Colors.grey[600])),
      ],
    );
  }
}