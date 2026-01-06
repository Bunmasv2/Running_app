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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Bảng Xếp Hạng', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadData,
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
        Center(child: Text("Chưa có dữ liệu xếp hạng tuần này")),
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
            'Chiến Binh Hệ Chạy – 7 Ngày Gần Nhất',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Text(
        '💪 Bạn đang vô địch chính cuộc đua của riêng mình! Cố gắng vào top 10 nhé!',
        textAlign: TextAlign.center,
        style: TextStyle(fontStyle: FontStyle.italic, color: Colors.blue),
      ),
    );
  }

  Widget _rankingRow({required int rank, required UserRanking user, required bool highlight}) {
    Color medalColor = Colors.transparent;
    if (rank == 1) medalColor = Colors.amber;
    else if (rank == 2) medalColor = Colors.grey.shade400;
    else if (rank == 3) medalColor = Colors.brown.shade300;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlight ? Colors.blue.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: highlight ? Border.all(color: Colors.blue.shade200) : null,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 35,
            child: rank <= 3
                ? Icon(Icons.emoji_events, color: medalColor)
                : Text('$rank', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          CircleAvatar(
            backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
            child: user.avatarUrl == null ? const Icon(Icons.person) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(user.username, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(user.totalTime, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
              Text('${user.caloriesBurned.toInt()} kcal', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}