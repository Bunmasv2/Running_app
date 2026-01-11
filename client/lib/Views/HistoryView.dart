import 'package:flutter/material.dart';
import '../Services/RunService.dart';
import '../models/RunModels.dart';
import 'RunDetailView.dart';

class HistoryView extends StatefulWidget {
  const HistoryView({super.key});

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  // Khởi tạo Service
  final RunService _runService = RunService();

  List<RunHistoryDto> _historyList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  // Hàm load dữ liệu (sẽ gọi Mock Data từ Service)
  Future<void> _loadHistory() async {
    setState(() => _isLoading = true); // Hiện loading khi refresh

    final data = await _runService.getRunHistory();

    if (mounted) {
      setState(() {
        _historyList = data;
        _isLoading = false;
      });
    }
  }

  // Helper: Format giây sang giờ:phút
  String _formatDuration(int seconds) {
    int h = seconds ~/ 3600;
    int m = (seconds % 3600) ~/ 60;
    int s = seconds % 60;

    if (h > 0) return "${h}h ${m}p";
    if (m > 0) return "${m}p ${s}s";
    return "${s}s";
  }

  // Helper: Format ngày tháng
  String _formatDate(DateTime dt) {
    return "Ngày ${dt.day}/${dt.month}/${dt.year} • ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Màu nền xám nhẹ
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _historyList.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
        onRefresh: _loadHistory,
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(), // Để có thể kéo refresh kể cả khi list ngắn
          padding: const EdgeInsets.all(16),
          itemCount: _historyList.length,
          separatorBuilder: (ctx, index) => const SizedBox(height: 12),
          itemBuilder: (ctx, index) {
            final item = _historyList[index];
            return _buildHistoryCard(item);
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.directions_run_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text("Bạn chưa chạy lần nào", style: TextStyle(color: Colors.grey[600], fontSize: 16)),
          const SizedBox(height: 10),
          TextButton.icon(
              onPressed: _loadHistory,
              icon: const Icon(Icons.refresh),
              label: const Text("Tải lại")
          )
        ],
      ),
    );
  }

  Widget _buildHistoryCard(RunHistoryDto item) {
    return Card(
      elevation: 0, // Flat style hiện đại hơn
      color: Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade200) // Viền mỏng
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // Chuyển sang trang chi tiết (Nhớ là bạn phải có file RunDetailView.dart nhé)
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => RunDetailView(runId: item.id)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Icon + Ngày tháng
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.directions_run, color: Colors.blue, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _formatDate(item.endTime),
                    style: TextStyle(
                        color: Colors.grey[800],
                        fontSize: 14,
                        fontWeight: FontWeight.w600
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1),
              ),

              // Body: 3 Thông số chính
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statItem(
                      "${item.distanceKm.toStringAsFixed(2)}", "km",
                      Colors.black
                  ),
                  Container(width: 1, height: 30, color: Colors.grey[300]), // Vạch ngăn cách
                  _statItem(
                      _formatDuration(item.durationSeconds), "Thời gian",
                      Colors.black
                  ),
                  Container(width: 1, height: 30, color: Colors.grey[300]), // Vạch ngăn cách
                  _statItem(
                      "${item.calories.toStringAsFixed(0)}", "Kcal",
                      Colors.black
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _statItem(String value, String label, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
      ],
    );
  }
}