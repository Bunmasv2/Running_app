import 'package:flutter/material.dart';
import '../models/UserRanking.dart';
import '../Services/UserService.dart';
import '../Services/RunService.dart';

class RankingView extends StatefulWidget {
  const RankingView({super.key});

  @override
  State<RankingView> createState() => _RankingViewState();
}

class _RankingViewState extends State<RankingView> {
  final RunService _runService = RunService();
  final UserService _userService = UserService();

  List<UserRanking> _rankings = [];
  String _currentUsername = "";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _userService.getUserProfile(),
        _runService.getWeeklyRanking(),
      ]);

      final profile = results[0] as dynamic;
      final rankings = results[1] as List<UserRanking>;

      if (mounted) {
        setState(() {
          _currentUsername = profile?.userName ?? "";
          _rankings = rankings;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Lỗi RankingView: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text('Bảng Xếp Hạng',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : RefreshIndicator(
        onRefresh: _loadData,
        backgroundColor: const Color(0xFF2D2D2D),
        color: Colors.orange,
        child: _rankings.isEmpty ? _buildEmptyState() : _buildRankingList(size),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        const Center(
          child: Text("Chưa có dữ liệu xếp hạng tuần này",
              style: TextStyle(color: Colors.grey)),
        ),
      ],
    );
  }

  Widget _buildRankingList(Size size) {
    final bool isInTop = _rankings.any((r) => r.username == _currentUsername);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: size.width * 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Chiến Binh Hệ Chạy – 7 Ngày Qua',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[400]),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _rankings.length,
              padding: const EdgeInsets.only(bottom: 20),
              itemBuilder: (context, index) {
                final user = _rankings[index];
                return _rankingRow(
                  rank: index + 1,
                  user: user,
                  highlight: user.username == _currentUsername,
                  size: size,
                );
              },
            ),
          ),
          if (!isInTop && _currentUsername.isNotEmpty)
            _buildEncouragementBox(size),
        ],
      ),
    );
  }

  Widget _buildEncouragementBox(Size size) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: EdgeInsets.only(bottom: size.height * 0.02),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.bolt, color: Colors.orange, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Chua vào top 10? Bạn đang vô địch cuộc đua của riêng mình!',
              style: TextStyle(
                  fontSize: 13, color: Colors.orange, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rankingRow({
    required int rank,
    required UserRanking user,
    required bool highlight,
    required Size size,
  }) {
    Color? medalColor;
    if (rank == 1) medalColor = Colors.amber;
    if (rank == 2) medalColor = const Color(0xFFC0C0C0);
    if (rank == 3) medalColor = const Color(0xFFCD7F32);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: highlight ? Colors.orange.withOpacity(0.15) : const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(12),
        border: highlight ? Border.all(color: Colors.orange.withOpacity(0.5)) : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: size.width * 0.08,
            child: rank <= 3
                ? Icon(Icons.emoji_events, color: medalColor, size: 22)
                : Text(
              '$rank',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.white54),
            ),
          ),
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey[800],
            backgroundImage: user.avatarUrl?.isNotEmpty == true
                ? NetworkImage(user.avatarUrl!)
                : null,
            child: user.avatarUrl?.isEmpty ?? true
                ? const Icon(Icons.person, color: Colors.white24, size: 20)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              user.username,
              style: TextStyle(
                  fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
                  color: Colors.white,
                  fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  user.totalTime,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 13),
                ),
                Text(
                  '${user.totalDistanceKm.toStringAsFixed(1)} km',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}