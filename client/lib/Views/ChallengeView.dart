import 'package:flutter/material.dart';
import '../models/ChallengeModels.dart';
import '../Services/ChallengeService.dart';

class ChallengeView extends StatefulWidget {
  const ChallengeView({super.key});

  @override
  State<ChallengeView> createState() => _ChallengeViewState();
}

class _ChallengeViewState extends State<ChallengeView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ChallengeService _challengeService = ChallengeService();

  List<Challenge> _allChallenges = [];
  List<UserChallengeProgress> _myChallenges = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // Gọi song song 2 API
    final results = await Future.wait([
      _challengeService.getAllChallenges(),
      _challengeService.getMyChallenges(),
    ]);

    if (mounted) {
      setState(() {
        _allChallenges = results[0] as List<Challenge>;
        _myChallenges = results[1] as List<UserChallengeProgress>;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleJoin(int challengeId) async {
    // 1. Gọi API và nhận về kết quả (Map)
    final result = await _challengeService.joinChallenge(challengeId);

    // 2. Tách dữ liệu ra
    bool isSuccess = result['success'];
    String message = result['message'];

    if (mounted) {
      // 3. Hiển thị SnackBar với nội dung từ Server
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message), // Hiển thị message server trả về
          backgroundColor: isSuccess ? Colors.green : Colors.red, // Xanh nếu OK, Đỏ nếu lỗi
          duration: const Duration(seconds: 2),
        ),
      );

      // 4. Nếu thành công thì reload lại danh sách
      if (isSuccess) {
        _loadData();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Responsive Dimensions
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: Column(
        children: [
          // 1. HEADER TABS
          Container(
            color: Colors.black,
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.deepOrange,
              labelColor: Colors.deepOrange,
              unselectedLabelColor: Colors.grey,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              tabs: const [
                Tab(text: "Danh sách"),
                Tab(text: "Của bạn"),
              ],
            ),
          ),

          // 2. BODY CONTENT
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.deepOrange))
                : TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: DANH SÁCH (GRID VIEW)
                _buildAllChallengesGrid(size),

                // TAB 2: CỦA BẠN (LIST VIEW WITH PROGRESS)
                _buildMyChallengesList(size),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB 1: GRID VIEW ---
  Widget _buildAllChallengesGrid(Size size) {
    if (_allChallenges.isEmpty) {
      return const Center(child: Text("Chưa có thử thách nào", style: TextStyle(color: Colors.grey)));
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: Colors.deepOrange,
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // 2 cột
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.75, // Tỷ lệ chiều cao/rộng của card
        ),
        itemCount: _allChallenges.length,
        itemBuilder: (context, index) {
          final item = _allChallenges[index];
          return _buildChallengeCard(item, size);
        },
      ),
    );
  }

  Widget _buildChallengeCard(Challenge item, Size size) {
    return GestureDetector(
      onTap: () {
        // Mở màn hình chi tiết (ChallengeDetailView)
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ChallengeDetailView(challenge: item)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2C),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ảnh Header
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                    ? Image.network(item.imageUrl!, width: double.infinity, fit: BoxFit.cover)
                    : Container(color: Colors.grey[800], child: const Center(child: Icon(Icons.image, color: Colors.white24))),
              ),
            ),
            // Nội dung
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      "${item.targetDistanceKm} km",
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _handleJoin(item.id),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 0),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          minimumSize: const Size(0, 32), // Chiều cao nút
                        ),
                        child: const Text("Tham gia", style: TextStyle(fontSize: 12)),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- TAB 2: LIST VIEW (PROGRESS) ---
  Widget _buildMyChallengesList(Size size) {
    if (_myChallenges.isEmpty) {
      return const Center(child: Text("Bạn chưa tham gia thử thách nào", style: TextStyle(color: Colors.grey)));
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _myChallenges.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final progressItem = _myChallenges[index];
          return _buildMyProgressCard(progressItem, size);
        },
      ),
    );
  }

  Widget _buildMyProgressCard(UserChallengeProgress item, Size size) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Ảnh nhỏ bên trái
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 60, height: 60,
              color: Colors.grey[800],
              child: item.challengeImage != null
                  ? Image.network(item.challengeImage!, fit: BoxFit.cover)
                  : const Icon(Icons.emoji_events, color: Colors.orange),
            ),
          ),
          const SizedBox(width: 16),
          // Thông tin tiến độ
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.challengeTitle,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                // Thanh Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (item.progressPercent / 100).clamp(0.0, 1.0),
                    backgroundColor: Colors.grey[800],
                    color: item.status == 1 ? Colors.green : Colors.deepOrange, // Xanh nếu xong, Cam nếu đang chạy
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${item.completedDistanceKm.toStringAsFixed(1)} / ${item.targetDistanceKm} km",
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                    Text(
                      "${item.progressPercent.toStringAsFixed(0)}%",
                      style: TextStyle(
                          color: item.status == 1 ? Colors.green : Colors.deepOrange,
                          fontWeight: FontWeight.bold,
                          fontSize: 12
                      ),
                    ),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

// --- MÀN HÌNH DETAIL (Khi bấm vào card trong danh sách) ---
class ChallengeDetailView extends StatelessWidget {
  final Challenge challenge;
  const ChallengeDetailView({super.key, required this.challenge});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text("Chi tiết thử thách", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ảnh cover to
            SizedBox(
              width: double.infinity,
              height: 200,
              child: challenge.imageUrl != null
                  ? Image.network(challenge.imageUrl!, fit: BoxFit.cover)
                  : Container(color: Colors.grey[800], child: const Icon(Icons.image, size: 50, color: Colors.white54)),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      challenge.title,
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.deepOrange, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        "${challenge.startDate.day}/${challenge.startDate.month} - ${challenge.endDate.day}/${challenge.endDate.month}",
                        style: const TextStyle(color: Colors.white70),
                      )
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text("Mô tả", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(
                    challenge.description.isNotEmpty ? challenge.description : "Không có mô tả.",
                    style: const TextStyle(color: Colors.grey, height: 1.5),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        color: const Color(0xFF2C2C2C),
        child: ElevatedButton(
          onPressed: () {
            // Logic tham gia ở đây (hoặc gọi lại service)
            // Vì đây là stateless widget đơn giản, ta có thể pop về và báo user tham gia ở màn ngoài
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepOrange,
            padding: const EdgeInsets.symmetric(vertical: 15),
          ),
          child: const Text("THAM GIA NGAY", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}