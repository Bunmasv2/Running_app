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

  DateTime? _lastPointTime;
  double _currentSpeedKmh = 0.0;

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
    setState(() {
      _isTracking = true;
      _routePoints.clear();
      _distanceKm = 0.0;
      _calories = 0.0;
      _elapsed = Duration.zero;
      _currentSpeedKmh = 0.0;
      _startTime = DateTime.now();
      _lastPointTime = DateTime.now();
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsed = Duration(seconds: _elapsed.inSeconds + 1);
      });
    });

    final locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 0,
    );

    _positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position position) {
      _updatePosition(position);
    });
  }

  void _updatePosition(Position pos) {
    if (pos.accuracy > 30.0) return;

    DateTime now = DateTime.now();
    LatLng newPoint = LatLng(pos.latitude, pos.longitude);

    setState(() {
      if (_routePoints.isNotEmpty) {
        final double distMeters =
            const Distance().as(LengthUnit.Meter, _routePoints.last, newPoint);

        int timeDiffSeconds = now.difference(_lastPointTime!).inSeconds;
        if (timeDiffSeconds == 0) timeDiffSeconds = 1;

        double speedMps = distMeters / timeDiffSeconds;
        double speedKmh = speedMps * 3.6;

        _currentSpeedKmh = speedKmh;

        if (speedKmh > 35.0) {
          return;
        }

        if (distMeters > 0.5) {
          _distanceKm += (distMeters / 1000);
          _calories = _userWeightKg * _distanceKm * 1.036;

          _routePoints.add(newPoint);
          _lastPointTime = now;
        }
      } else {
        _routePoints.add(newPoint);
        _lastPointTime = now;
      }

      _mapController.move(newPoint, 17.0);
    });
  }

  Future<void> _stopRun() async {
    _timer?.cancel();
    _positionStream?.cancel();

    setState(() {
      _isTracking = false;
      _isSaving = true;
    });

    bool success = await _runService.saveRun(
      distance: _distanceKm,
      calories: _calories,
      duration: _elapsed,
      routePoints:
          _routePoints,
      startTime: _startTime,
      endTime: DateTime.now(),
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        _loadInitialData();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Thành tích đã được lưu!"),
            backgroundColor: Colors.green));

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

  Future<void> _handleSetGoal() async {
    if (_isTracking) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Hãy dừng chạy trước khi đặt mục tiêu.")));
      return;
    }

    final TextEditingController controller = TextEditingController();

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
              final double? target = double.tryParse(controller.text);

              if (target != null && target > 0) {
                Navigator.pop(ctx);

                try {
                  DailyGoal? newGoal = await _goalService.setTodayGoal(target, "dailyGoal");

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
    double progress = 0.0;
    if (_dailyGoal != null && _dailyGoal!.targetDistanceKm > 0) {
      double totalKm =
          _dailyGoal!.currentDistanceKm + (_isTracking ? _distanceKm : 0);
      progress = (totalKm / _dailyGoal!.targetDistanceKm).clamp(0.0, 1.0);
    }

    return Scaffold(
      body: Stack(
        children: [
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

                  Padding(
                    padding:
                        const EdgeInsets.only(bottom: 30, left: 30, right: 30),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
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
                            Text("${(progress * 100).toInt()}% Mục tiêu",
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 12))
                          ],
                        ),

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
                              const Text("Đặt mục tiêu",
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
