import 'dart:async';
import 'package:flutter/material.dart';
import '../models/RunModels.dart';
import '../Models/UserProfile.dart';
import '../Services/GoalService.dart';
import '../Services/UserService.dart';
import '../models/ChallengeModels.dart';
import '../Services/ChallengeService.dart';
import '../Views/ChallengeView.dart';
import '../models/SlideModel.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final UserService _userService = UserService();
  final GoalService _goalService = GoalService();
  final ChallengeService _challengeService = ChallengeService();

  UserProfile? _userProfile;
  DailyGoal? _dailyGoal;
  bool _isLoading = true;
  List<UserProfile> _suggestedUsers = [];
  List<Challenge> _challenges = [];

  // PageController cho slider
  late PageController _slideController;
  int _currentSlideIndex = 0;
  Timer? _slideTimer;

  @override
  void initState() {
    super.initState();
    _slideController = PageController();
    _startAutoSlide();
    _loadData();
  }

  @override
  void dispose() {
    _slideTimer?.cancel();
    _slideController.dispose();
    super.dispose();
  }

  void _startAutoSlide() {
    _slideTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_slideController.hasClients) {
        int nextPage = (_currentSlideIndex + 1) % _slides.length;
        _slideController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _userService.getUserProfile(),
        _goalService.getTodayGoal(),
        _userService.getSuggestedUser(),
        _challengeService.getAllChallenges()
      ]);
      if (mounted) {
        setState(() {
          _userProfile = results[0] as UserProfile?;
          _dailyGoal = results[1] as DailyGoal?;
          if (results[2] != null) {
            print("DEBUG: Raw Challenges Data: $results[2]");
            _suggestedUsers = List<UserProfile>.from(results[2] as List);
          }

          if (results[3] != null) {
            print("DEBUG: Raw Challenges Data: $results[3]");
            _challenges = List<Challenge>.from(results[3] as List);
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Lỗi load data Home: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Dữ liệu mẫu cho slides
  List<SlideData> get _slides => [
    SlideData(
      title: 'Instant Workouts',
      titleTag: 'PREVIEW',
      linkText: 'See all',
      icon: Icons.sports_gymnastics,
      iconColor: Colors.purple,
      mainText: 'Gentle Flow Yoga',
      subText: 'Gentle yoga will help you recover, improve flexibility, and find men...',
      duration: '30m',
      onLinkTap: () => print('See all workouts'),
      onButtonTap: () => print('Start yoga'),
    ),
    SlideData(
      title: 'Quick Runs',
      titleTag: 'NEW',
      linkText: 'Explore',
      icon: Icons.directions_run,
      iconColor: Colors.orange,
      mainText: 'Morning 5K Run',
      subText: 'Start your day with an energizing 5K run through the city...',
      duration: '25m',
      onLinkTap: () => print('Explore runs'),
      onButtonTap: () => print('Start run'),
    ),
    SlideData(
      title: 'Recovery Sessions',
      titleTag: 'RECOMMENDED',
      linkText: 'View all',
      icon: Icons.self_improvement,
      iconColor: Colors.teal,
      mainText: 'Deep Stretch',
      subText: 'Perfect for post-workout recovery and relaxation...',
      duration: '15m',
      onLinkTap: () => print('View recovery'),
      onButtonTap: () => print('Start stretch'),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ============================================
                  // CONTAINER 1: Instant Workouts Slider
                  // ============================================
                  _buildWorkoutsSlider(),

                  // ============================================
                  // CONTAINER 2: Suggested Challenges (Expanded)
                  // ============================================
                  _buildSuggestedChallenges(),

                  // ============================================
                  // CONTAINER 3: Who to Follow
                  // ============================================
                  _buildWhoToFollow(),

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  // ============================================
  // CONTAINER 1: Instant Workouts Slider
  // ============================================
  Widget _buildWorkoutsSlider() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Slider
          SizedBox(
            height: 160,
            child: PageView.builder(
              controller: _slideController,
              onPageChanged: (index) {
                setState(() {
                  _currentSlideIndex = index;
                });
              },
              itemCount: _slides.length,
              itemBuilder: (context, index) {
                return _buildSlideItem(_slides[index]);
              },
            ),
          ),
            const SizedBox(height: 12),
            // Dots indicator
            SizedBox(
              height: 10,
              child: _buildDotsIndicator(),
            ),
          ],
      ),
    );
  }

  Widget _buildSlideItem(SlideData slide) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Title + Tag + Link
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.flash_on, color: Colors.orange, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    slide.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey[700],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      slide.titleTag,
                      style: const TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: slide.onLinkTap,
                child: Text(
                  slide.linkText,
                  style: const TextStyle(color: Colors.orange, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Row 2: Icon + Text + Button
          Row(
            children: [
              // Icon with duration
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: slide.iconColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    Center(child: Icon(slide.icon, color: slide.iconColor, size: 30)),
                    Positioned(
                      bottom: 4,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            slide.duration,
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      slide.mainText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      slide.subText,
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Arrow button
              GestureDetector(
                onTap: slide.onButtonTap,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: const Icon(Icons.chevron_right, color: Colors.white, size: 24),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDotsIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_slides.length, (index) {
        final isActive = index == _currentSlideIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 8 : 6,
          height: isActive ? 8 : 6,
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.grey[600],
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }

  // ============================================
  // CONTAINER 2: Suggested Challenges
  // ============================================
  Widget _buildSuggestedChallenges() {
    return _SuggestedChallengesWidget(
      challenges: _challenges,
      formatNumber: _formatNumber,
    );
  }

  // ============================================
  // CONTAINER 3: Who to Follow
  // ============================================
  Widget _buildWhoToFollow() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Những người bạn có thể theo dõi',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: () => print('See all users'),
                child: const Text(
                  'Xem tất cả',
                  style: TextStyle(color: Colors.orange, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // User cards horizontal scroll
          SizedBox(
            height: 260,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _suggestedUsers.length,
              itemBuilder: (context, index) {
                return _buildUserCard(_suggestedUsers[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(UserProfile user) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Avatar
          Stack(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.grey[700],
                // Dùng user.avatarUrl từ model của bạn
                backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
                child: user.avatarUrl == null
                    ? Icon(Icons.person, size: 40, color: Colors.grey[500])
                    : null,
              ),
              // Vì model UserProfile không có field isVerified,
              // tạm thời mình check nếu quãng đường > 100km thì hiện badge tích xanh
              if (user.totalDistanceKm > 100)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, color: Colors.white, size: 14),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Name: Sửa từ user.name thành user.userName cho đúng Model
          Text(
            user.userName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          // Subtitle: Model không có subtitle, ta hiển thị quãng đường đã chạy
          Text(
            'Total: ${user.totalDistanceKm.toStringAsFixed(1)} km',
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          // Buttons: Logic xử lý bấm nút đặt tại đây
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text('Theo dõi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.grey),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text('Ẩn hiển thị', style: TextStyle(fontSize: 13)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  // Helper function
  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(0)},${(number % 1000).toString().padLeft(3, '0')}';
    }
    return number.toString();
  }
}

// ============================================
// WIDGET: Suggested Challenges (Stateful để quản lý focus)
// ============================================
class _SuggestedChallengesWidget extends StatefulWidget {
  final List<Challenge> challenges;
  final String Function(int) formatNumber;

  const _SuggestedChallengesWidget({
    required this.challenges,
    required this.formatNumber,
  });

  @override
  State<_SuggestedChallengesWidget> createState() => _SuggestedChallengesWidgetState();
}

class _SuggestedChallengesWidgetState extends State<_SuggestedChallengesWidget> {
  late PageController _pageController;
  double _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);
    _pageController.addListener(_onPageChanged);
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageChanged);
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged() {
    setState(() {
      _currentPage = _pageController.page ?? 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(),
          const SizedBox(height: 16),
          // Challenge cards với hiệu ứng focus
          SizedBox(
            height: 240,
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.challenges.length,
              itemBuilder: (context, index) {
                return _buildAnimatedCard(index);
              },
            ),
          ),
          const SizedBox(height: 16),
          // Explore all link
          _buildExploreLink(context),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gợi ý thử thách cho bạn',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Tạo động lực cho hành trình chạy bộ của bạn với các thử thách hấp dẫn!',
          style: TextStyle(color: Colors.grey[400], fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildAnimatedCard(int index) {
    // Tính toán độ lệch so với card đang focus
    double difference = (index - _currentPage).abs();
    // Scale và opacity dựa trên khoảng cách
    double scale = 1 - (difference * 0.1).clamp(0.0, 0.15);
    double opacity = 1 - (difference * 0.4).clamp(0.0, 0.5);
    double translateY = difference * 20; // Card không focus sẽ chìm xuống

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: scale, end: scale),
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, translateY),
          child: Transform.scale(
            scale: value,
            child: Opacity(
              opacity: opacity,
              child: _ChallengeCard(
                challenge: widget.challenges[index],
                formatNumber: widget.formatNumber,
                isFocused: difference < 0.5,
              ),
            ),
          ),
        );
      },
    );
  }

Widget _buildExploreLink(BuildContext context) {
  return Center(
    child: TextButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ChallengeView()),
        );
      },
      child: const Text(
        'Khám phá tất cả thử thách',
        style: TextStyle(
          color: Colors.orange,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
  );
}
}

// ============================================
// WIDGET: Challenge Card (Stateless, kích thước cố định)
// ============================================
class _ChallengeCard extends StatelessWidget {
  final Challenge challenge; // Dùng trực tiếp class Challenge từ model
  final String Function(int) formatNumber;
  final bool isFocused;

  const _ChallengeCard({
    required this.challenge,
    required this.formatNumber,
    this.isFocused = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(16),
        border: isFocused
            ? Border.all(color: Colors.orange.withOpacity(0.3), width: 1)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Badge hiển thị khoảng cách mục tiêu (VD: 5K, 10K)
                _buildBadge(challenge.targetDistanceKm.toInt().toString()),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        challenge.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        challenge.description,
                        style: TextStyle(color: Colors.grey[400], fontSize: 13),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          _buildJoinButton(context),
        ],
      ),
    );
  }


  Widget _buildBadge(String text) {
    return Container(
      width: 72, height: 72,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.red[900]!, Colors.orange[800]!]),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          "$text\nKM",
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

Widget _buildJoinButton(BuildContext context) {
    return SizedBox(
        width: double.infinity,
        height: 40,
        child: ElevatedButton(
            onPressed: () async {
                final service = ChallengeService();
                final result = await service.joinChallenge(challenge.id);

                if (result['message'] != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(result['message'])),
                  );
                }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.black,
            ),
            child: const Text(
                'Join Challenge',
                style: TextStyle(fontWeight: FontWeight.bold),
            ),
        ),
    );
    }
}

// Custom painter cho badge pattern
class _BadgePatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Vẽ pattern hình sao/medal
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.4;

    for (int i = 0; i < 8; i++) {
      final angle = (i * 45) * 3.14159 / 180;
      final x = center.dx + radius * 0.8 * (i % 2 == 0 ? 1 : 0.6) *
          (angle < 3.14159 ? 1 : -1) * (i < 4 ? 1 : -1);
      final y = center.dy + radius * 0.8 * (i % 2 == 0 ? 1 : 0.6) *
          (i % 4 < 2 ? -1 : 1);
      canvas.drawCircle(Offset(x, y), 2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}




