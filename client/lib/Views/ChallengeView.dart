import 'package:flutter/material.dart';
import '../models/ChallengeModels.dart';
import '../Services/ChallengeService.dart';
import '../Components/HeaderComponent.dart';

class ChallengeView extends StatefulWidget {
  final ValueChanged<String?>? onSubtitleChanged;

  const ChallengeView({super.key, this.onSubtitleChanged});

  @override
  State<ChallengeView> createState() => _ChallengeViewState();
}

class _ChallengeViewState extends State<ChallengeView> {
  final ChallengeService _challengeService = ChallengeService();
  List<Challenge> _allChallenges = [];
  List<UserChallengeProgress> _myChallenges = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
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
    final result = await _challengeService.joinChallenge(challengeId);
    bool isSuccess = result['success'];
    String message = result['message'];

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isSuccess ? Colors.green : Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
      if (isSuccess) _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF1A1A1A),
        body: Center(child: CircularProgressIndicator(color: Colors.deepOrange)),
      );
    }

    return ScrollableHeaderTabsComponent(
      backgroundColor: const Color(0xFF1A1A1A),
      activeColor: Colors.deepOrange,
      tabs: [
        HeaderTabItem(
          label: "Danh sách",
          content: _buildAllChallengesGrid(size),
        ),
        HeaderTabItem(
          label: "Của bạn",
          content: _buildMyChallengesList(size),
        ),
      ],
      onTabLabelChanged: (label) => widget.onSubtitleChanged?.call(label),
    );
  }

  Widget _buildAllChallengesGrid(Size size) {
    if (_allChallenges.isEmpty) {
      return const Center(child: Text("Chưa có thử thách nào", style: TextStyle(color: Colors.grey)));
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: Colors.deepOrange,
      child: GridView.builder(
        padding: EdgeInsets.all(size.width * 0.03),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: size.width > 600 ? 3 : 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.7,
        ),
        itemCount: _allChallenges.length,
        itemBuilder: (context, index) => _buildChallengeCard(_allChallenges[index], size),
      ),
    );
  }

  Widget _buildChallengeCard(Challenge item, Size size) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ChallengeDetailView(challenge: item)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2C),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                    ? Image.network(item.imageUrl!, width: double.infinity, fit: BoxFit.cover)
                    : Container(color: Colors.grey[800], child: const Center(child: Icon(Icons.image, color: Colors.white24))),
              ),
            ),
            Expanded(
              flex: 6,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Text("${item.targetDistanceKm} km", style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _handleJoin(item.id),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          minimumSize: Size(0, size.height * 0.04),
                        ),
                        child: const Text("Tham gia", style: TextStyle(fontSize: 11)),
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

  Widget _buildMyChallengesList(Size size) {
    if (_myChallenges.isEmpty) {
      return const Center(child: Text("Bạn chưa tham gia thử thách nào", style: TextStyle(color: Colors.grey)));
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.separated(
        padding: EdgeInsets.all(size.width * 0.04),
        itemCount: _myChallenges.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _buildMyProgressCard(_myChallenges[index], size),
      ),
    );
  }

  Widget _buildMyProgressCard(UserChallengeProgress item, Size size) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: size.width * 0.15,
            height: size.width * 0.15,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                color: Colors.grey[800],
                child: item.challengeImage != null
                    ? Image.network(item.challengeImage!, fit: BoxFit.cover)
                    : const Icon(Icons.emoji_events, color: Colors.orange),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.challengeTitle,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (item.progressPercent / 100).clamp(0.0, 1.0),
                    backgroundColor: Colors.grey[800],
                    color: item.status == 1 ? Colors.green : Colors.deepOrange,
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${item.completedDistanceKm.toStringAsFixed(1)}/${item.targetDistanceKm} km",
                      style: TextStyle(color: Colors.grey[400], fontSize: 11),
                    ),
                    Text(
                      "${item.progressPercent.toStringAsFixed(0)}%",
                      style: TextStyle(
                          color: item.status == 1 ? Colors.green : Colors.deepOrange,
                          fontWeight: FontWeight.bold,
                          fontSize: 11
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

class ChallengeDetailView extends StatelessWidget {
  final Challenge challenge;
  const ChallengeDetailView({super.key, required this.challenge});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: challenge.imageUrl != null
                  ? Image.network(challenge.imageUrl!, width: double.infinity, fit: BoxFit.cover)
                  : Container(color: Colors.grey[800], child: const Icon(Icons.image, size: 50, color: Colors.white54)),
            ),
            Padding(
              padding: EdgeInsets.all(size.width * 0.05),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      challenge.title,
                      style: TextStyle(color: Colors.white, fontSize: size.width * 0.06, fontWeight: FontWeight.bold)
                  ),
                  const SizedBox(height: 12),
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
                  const SizedBox(height: 24),
                  const Text("Mô tả", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    challenge.description.isNotEmpty ? challenge.description : "Không có mô tả.",
                    style: const TextStyle(color: Colors.grey, height: 1.5, fontSize: 14),
                  ),
                  SizedBox(height: size.height * 0.1),
                ],
              ),
            )
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: size.width * 0.05, vertical: 12),
          color: const Color(0xFF2C2C2C),
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              padding: EdgeInsets.symmetric(vertical: size.height * 0.018),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("THAM GIA NGAY", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}