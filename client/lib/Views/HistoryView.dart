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
  final RunService _runService = RunService();

  List<RunHistoryDto> _historyList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);

    final data = await _runService.getRunHistory();

    if (mounted) {
      setState(() {
        _historyList = data;
        _isLoading = false;
      });
    }
  }

  String _formatDuration(int seconds) {
    int h = seconds ~/ 3600;
    int m = (seconds % 3600) ~/ 60;
    int s = seconds % 60;

    if (h > 0) return "${h}h ${m}p";
    if (m > 0) return "${m}p ${s}s";
    return "${s}s";
  }

  String _formatDate(DateTime dt) {
    return "Ngày ${dt.day}/${dt.month}/${dt.year} • ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : _historyList.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
        onRefresh: _loadHistory,
        color: Colors.orange,
        backgroundColor: const Color(0xFF2D2D2D),
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
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
          Icon(Icons.directions_run_outlined, size: 80, color: Colors.grey[700]),
          const SizedBox(height: 16),
          Text("Bạn chưa chạy lần nào", style: TextStyle(color: Colors.grey[500], fontSize: 16)),
          const SizedBox(height: 10),
          TextButton.icon(
              onPressed: _loadHistory,
              icon: const Icon(Icons.refresh, color: Colors.orange),
              label: const Text("Tải lại", style: TextStyle(color: Colors.orange))
          )
        ],
      ),
    );
  }

  Widget _buildHistoryCard(RunHistoryDto item) {
    return Card(
      elevation: 0,
      color: const Color(0xFF2D2D2D),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.white10)
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.directions_run, color: Colors.orange, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _formatDate(item.endTime),
                    style: const TextStyle(
                        color: Colors.white,
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
                child: Divider(height: 1, color: Colors.white12),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statItem(
                      "${item.distanceKm.toStringAsFixed(2)}", "km",
                      Colors.white
                  ),
                  Container(width: 1, height: 30, color: Colors.white12),
                  _statItem(
                      _formatDuration(item.durationSeconds), "Thời gian",
                      Colors.white
                  ),
                  Container(width: 1, height: 30, color: Colors.white12),
                  _statItem(
                      "${item.calories.toStringAsFixed(0)}", "Kcal",
                      Colors.white
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