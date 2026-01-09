import 'package:flutter/material.dart';
import '../Models/UserProfile.dart';
import 'AppBarActions.dart';

/// Model định nghĩa cho từng Tab: Bao gồm tên hiển thị và Nội dung trang đó
class HeaderTabItem {
  final String label;
  final Widget content; // Nội dung trang (VD: PersonalView, ClubView...)

  const HeaderTabItem({
    required this.label,
    required this.content,
  });
}

/// ScrollableHeaderTabsComponent - Component với hiệu ứng scroll
/// Khi scroll xuống: Header tabs thu gọn, tab đang chọn hiển thị như subtitle
/// Khi scroll lên: Header tabs hiện lại đầy đủ
class ScrollableHeaderTabsComponent extends StatefulWidget {
  final List<HeaderTabItem> tabs;
  final int initialIndex;
  final Color backgroundColor;
  final Color activeColor;
  final ValueChanged<String?>? onTabLabelChanged; // Callback khi tab thay đổi hoặc header thu gọn

  const ScrollableHeaderTabsComponent({
    super.key,
    required this.tabs,
    this.initialIndex = 0,
    this.backgroundColor = const Color(0xFF2D2D2D),
    this.activeColor = Colors.orange,
    this.onTabLabelChanged,
  });

  @override
  State<ScrollableHeaderTabsComponent> createState() => _ScrollableHeaderTabsComponentState();
}

class _ScrollableHeaderTabsComponentState extends State<ScrollableHeaderTabsComponent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;
  bool _isHeaderCollapsed = false;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentTabIndex = widget.initialIndex;
    _tabController = TabController(
      length: widget.tabs.length,
      vsync: this,
      initialIndex: widget.initialIndex,
    );
    _tabController.addListener(_onTabChanged);
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    // Không gọi callback ban đầu vì header chưa thu gọn
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
      // Chỉ cập nhật subtitle nếu header đang thu gọn
      if (_isHeaderCollapsed) {
        widget.onTabLabelChanged?.call(widget.tabs[_currentTabIndex].label);
      }
    }
  }

  void _onScroll() {
    final isCollapsed = _scrollController.offset > 20;
    if (isCollapsed != _isHeaderCollapsed) {
      setState(() {
        _isHeaderCollapsed = isCollapsed;
      });
      // Gửi subtitle khi header thu gọn, null khi header hiện lại
      if (isCollapsed) {
        widget.onTabLabelChanged?.call(widget.tabs[_currentTabIndex].label);
      } else {
        widget.onTabLabelChanged?.call(null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return NestedScrollView(
      controller: _scrollController,
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          // Header tabs với animation
          SliverPersistentHeader(
            pinned: false,
            floating: true,
            delegate: _CollapsibleTabBarDelegate(
              tabBar: _buildTabBar(),
              backgroundColor: widget.backgroundColor,
              maxHeight: 48,
              minHeight: 0,
            ),
          ),
        ];
      },
      body: TabBarView(
        controller: _tabController,
        children: widget.tabs.map((item) => item.content).toList(),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: widget.backgroundColor,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: widget.activeColor,
        indicatorWeight: 2,
        labelColor: widget.activeColor,
        unselectedLabelColor: Colors.white70,
        labelStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
        ),
        dividerColor: Colors.transparent,
        tabAlignment: TabAlignment.center, // Căn giữa
        padding: const EdgeInsets.symmetric(horizontal: 16),
        tabs: widget.tabs.map((item) => Tab(text: item.label)).toList(),
      ),
    );
  }
}

/// Delegate cho SliverPersistentHeader với animation mượt
class _CollapsibleTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget tabBar;
  final Color backgroundColor;
  final double maxHeight;
  final double minHeight;

  _CollapsibleTabBarDelegate({
    required this.tabBar,
    required this.backgroundColor,
    required this.maxHeight,
    required this.minHeight,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    // Tính toán opacity và scale dựa trên shrinkOffset
    final progress = (shrinkOffset / maxHeight).clamp(0.0, 1.0);
    final opacity = 1.0 - progress;
    final height = maxHeight * (1 - progress);

    return Container(
      height: height,
      color: backgroundColor,
      child: Opacity(
        opacity: opacity,
        child: ClipRect(
          child: OverflowBox(
            alignment: Alignment.topCenter,
            maxHeight: maxHeight,
            child: tabBar,
          ),
        ),
      ),
    );
  }

  @override
  double get maxExtent => maxHeight;

  @override
  double get minExtent => minHeight;

  @override
  bool shouldRebuild(covariant _CollapsibleTabBarDelegate oldDelegate) {
    return oldDelegate.tabBar != tabBar ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.maxHeight != maxHeight ||
        oldDelegate.minHeight != minHeight;
  }
}

/// HeaderTabsComponent - Chỉ chứa TabBar và TabBarView (không có scroll effect)
/// Sử dụng khi đã có TopNavBarComponent ở MainScreen
class HeaderTabsComponent extends StatelessWidget {
  final List<HeaderTabItem> tabs;
  final int initialIndex;
  final Color backgroundColor;
  final Color activeColor;

  const HeaderTabsComponent({
    super.key,
    required this.tabs,
    this.initialIndex = 0,
    this.backgroundColor = Colors.black,
    this.activeColor = Colors.orange,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: tabs.length,
      initialIndex: initialIndex,
      child: Column(
        children: [
          // TabBar
          Container(
            color: backgroundColor,
            alignment: Alignment.centerLeft,
            child: TabBar(
              isScrollable: true,
              indicatorColor: activeColor,
              indicatorWeight: 2,
              labelColor: activeColor,
              unselectedLabelColor: Colors.white70,
              labelStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.normal,
              ),
              dividerColor: Colors.transparent,
              tabAlignment: TabAlignment.start,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              tabs: tabs.map((item) => Tab(text: item.label)).toList(),
            ),
          ),
          // TabBarView
          Expanded(
            child: TabBarView(
              children: tabs.map((item) => item.content).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class CollapsibleHeaderLayout extends StatelessWidget {
  // Các thuộc tính giống TopNavBarComponent
  final String title;
  final UserProfile? userProfile;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onNotificationTap;

  // Thuộc tính riêng cho Header Tabs
  final List<HeaderTabItem> tabs;
  final int initialIndex;

  // Màu sắc chủ đạo (lấy theo TopNavBar)
  final Color backgroundColor;
  final Color activeColor;

  const CollapsibleHeaderLayout({
    super.key,
    required this.title,
    required this.tabs,
    this.initialIndex = 0,
    this.userProfile,
    this.onAvatarTap,
    this.onNotificationTap,
    this.backgroundColor = Colors.black,
    this.activeColor = Colors.orange,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Dùng DefaultTabController để quản lý state của TabBar và TabBarView
    return DefaultTabController(
      length: tabs.length,
      initialIndex: initialIndex,
      child: Scaffold(
        backgroundColor: backgroundColor,
        // 2. NestedScrollView cho phép cuộn header và body độc lập nhưng liên kết
        body: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              // 3. SliverAppBar tạo hiệu ứng co giãn
              SliverAppBar(
                backgroundColor: backgroundColor,
                expandedHeight: kToolbarHeight + 50.0, // Chiều cao khi mở rộng (Title + Tabs)
                floating: true, // Khi vuốt lên, header hiện ngay lập tức
                pinned: true,   // Giữ lại thanh Tabs và Title khi cuộn xuống hết
                snap: true,     // Header bung ra trọn vẹn khi vuốt nhẹ
                elevation: 0,
                forceElevated: innerBoxIsScrolled, // Tạo bóng đổ khi nội dung bên dưới cuộn

                // --- PHẦN TITLE & ACTIONS (Giống TopNavBarComponent) ---
                title: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                centerTitle: false,
                actions: buildAppBarActions(
                  userProfile: userProfile,
                  onAvatarTap: onAvatarTap,
                  onNotificationTap: onNotificationTap,
                ),

                // --- PHẦN TABS (HeaderComponent logic) ---
                // Thuộc tính bottom của AppBar giúp widget này "dính" lại dưới Title
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(48),
                  child: Container(
                    color: backgroundColor, // Đảm bảo nền đen khi dính
                    alignment: Alignment.centerLeft, // Căn tab sang trái
                    child: TabBar(
                      isScrollable: true, // Cho phép tab co lại theo nội dung text
                      indicatorColor: activeColor, // Màu gạch chân (Cam)
                      indicatorWeight: 2,
                      labelColor: activeColor, // Màu text khi chọn
                      unselectedLabelColor: Colors.white70, // Màu text khi không chọn
                      labelStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600
                      ),
                      unselectedLabelStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.normal
                      ),
                      dividerColor: Colors.transparent, // Bỏ đường kẻ mờ mặc định của Flutter 3
                      tabAlignment: TabAlignment.start, // Căn lề trái toàn bộ Tab
                      padding: const EdgeInsets.symmetric(horizontal: 8),

                      // Map danh sách label ra Tab widget
                      tabs: tabs.map((item) => Tab(text: item.label)).toList(),
                    ),
                  ),
                ),
              ),
            ];
          },
          // 4. Nội dung bên dưới tương ứng với Tab đang chọn
          body: TabBarView(
            children: tabs.map((item) => item.content).toList(),
          ),
        ),
      ),
    );
  }
}