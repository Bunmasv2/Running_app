import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../Services/RunService.dart';
import '../models/RunModels.dart';

class RunDetailView extends StatefulWidget {
  final int runId;
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
    final data = await _runService.getRunDetail(widget.runId);
    if (mounted) {
      setState(() {
        _detail = data;
        _isLoading = false;
      });
    }
  }

  LatLngBounds _getBounds(List<LatLng> points) {
    if (points.isEmpty) {
      return LatLngBounds(const LatLng(10.7, 106.6), const LatLng(10.8, 106.7));
    }
    return LatLngBounds.fromPoints(points);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text("Chi tiết buổi chạy",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.deepOrange))
          : _detail == null
          ? _buildErrorState()
          : Column(
        children: [
          Expanded(
            flex: 5,
            child: FlutterMap(
              options: MapOptions(
                initialCameraFit: CameraFit.bounds(
                  bounds: _getBounds(_detail!.routePoints),
                  padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 50),
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  tileBuilder: (context, tileWidget, tile) => ColorFiltered(
                    colorFilter: const ColorFilter.matrix([
                      -1, 0, 0, 0, 255,
                      0, -1, 0, 0, 255,
                      0, 0, -1, 0, 255,
                      0, 0, 0, 1, 0,
                    ]),
                    child: tileWidget,
                  ),
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _detail!.routePoints,
                      strokeWidth: 5.0,
                      color: Colors.deepOrange,
                    ),
                  ],
                ),
                if (_detail!.routePoints.isNotEmpty)
                  MarkerLayer(markers: [
                    Marker(
                        point: _detail!.routePoints.first,
                        child: const Icon(Icons.location_on, color: Colors.greenAccent, size: 30)
                    ),
                    Marker(
                        point: _detail!.routePoints.last,
                        child: const Icon(Icons.flag_rounded, color: Colors.redAccent, size: 30)
                    ),
                  ])
              ],
            ),
          ),

          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(24, 30, 24, size.height * 0.05),
            decoration: const BoxDecoration(
              color: Color(0xFF2C2C2E),
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey[700], borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(height: 20),
                const Text("KẾT QUẢ CUỐI CÙNG",
                    style: TextStyle(fontSize: 12, letterSpacing: 1.5, color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStat(size, "Quãng đường", "${_detail!.distanceKm.toStringAsFixed(2)}", "km"),
                    _buildStat(size, "Thời gian", "${(_detail!.durationSeconds / 60).toStringAsFixed(0)}", "phút"),
                    _buildStat(size, "Calo", "${_detail!.calories.toStringAsFixed(0)}", "kcal"),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(Size size, String label, String value, String unit) {
    return Column(
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                  text: value,
                  style: TextStyle(fontSize: size.width * 0.065, fontWeight: FontWeight.w900, color: Colors.white)
              ),
              TextSpan(
                  text: " $unit",
                  style: const TextStyle(fontSize: 12, color: Colors.deepOrange, fontWeight: FontWeight.bold)
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(label.toUpperCase(), style: TextStyle(color: Colors.grey[500], fontSize: 10, letterSpacing: 0.5)),
      ],
    );
  }

  Widget _buildErrorState() {
    return const Center(
      child: Text("Không tìm thấy dữ liệu", style: TextStyle(color: Colors.white70)),
    );
  }
}