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

  // --- CHỨC NĂNG CHÍNH: TẢI DỮ LIỆU ---
  Future<void> _loadData() async {
    try {
      // Gọi đồng thời cả 2 API
      final results = await Future.wait([
        _userService.getUserProfile(),
        _runService.getWeeklyRanking(),
      ]);

      final profile = results[0] as dynamic; // UserProfile
      final rankings = results[1] as List<UserRanking>;

      if (mounted) {
        setState(() {
          _currentUsername = profile?.userName ?? "";
          _rankings = rankings;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Lỗi RankingView: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text(
            'Bảng Xếp Hạng', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : RefreshIndicator(
        onRefresh: _loadData,
        backgroundColor: const Color(0xFF2D2D2D),
        color: Colors.orange,
        child: _rankings.isEmpty
            ? _buildEmptyState()
            : _buildRankingList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView( // Dùng ListView để RefreshIndicator hoạt động
      children: const [
        SizedBox(height: 100),
        Center(child: Text("Chưa có dữ liệu xếp hạng tuần này", style: TextStyle(color: Colors.grey))),
      ],
    );
  }

  Widget _buildRankingList() {
    final bool isInTop = _rankings.any((r) => r.username == _currentUsername);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chiến Binh Hệ Chạy – 7 Ngày Trong Tuần',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _rankings.length,
              itemBuilder: (context, index) {
                final user = _rankings[index];
                final isCurrentUser = user.username == _currentUsername;
                return _rankingRow(
                  rank: index + 1,
                  user: user,
                  highlight: isCurrentUser,
                );
              },
            ),
          ),
          if (!isInTop && _currentUsername.isNotEmpty)
            _buildEncouragementBox(),
        ],
      ),
    );
  }

  Widget _buildEncouragementBox() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: const Text(
        '💪 Chưa vào top 10? Bạn đang vô địch chính cuộc đua của riêng mình!',
        textAlign: TextAlign.center,
        style: TextStyle(fontStyle: FontStyle.italic, color: Colors.orange),
      ),
    );
  }

  Widget _rankingRow({
    required int rank,
    required UserRanking user,
    required bool highlight,
  }) {
    Color medalColor = Colors.transparent;
    if (rank == 1)
      medalColor = Colors.amber;
    else if (rank == 2)
      medalColor = Colors.grey.shade400;
    else if (rank == 3) medalColor = Colors.brown.shade300;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlight ? Colors.orange.withValues(alpha: 0.1) : const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(15),
        border: highlight ? Border.all(color: Colors.orange.withValues(alpha: 0.5)) : null,
      ),
      child: Row(
        children: [
          // 🏆 Rank
          SizedBox(
            width: 30,
            child: rank <= 3
                ? Icon(Icons.emoji_events, color: medalColor, size: 24)
                : Text(
              '$rank',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),

          // 🧑 Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey.shade700,
            backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                ? NetworkImage(user.avatarUrl!)
                : null,
            child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                ? const Icon(Icons.person, color: Colors.grey)
                : null,
          ),


          const SizedBox(width: 12),

          // 👤 Username
          Expanded(
            flex: 2,
            child: Text(
              user.username,
              style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // ⏱ TotalTime
          Expanded(
            child: Text(
              user.totalTime,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
          ),

          // 🏃 Distance
          Expanded(
            child: Text(
              '${user.totalDistanceKm.toStringAsFixed(2)} km',
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[400],
              ),
            ),
          ),
        ],
      ),
    );
  }
}