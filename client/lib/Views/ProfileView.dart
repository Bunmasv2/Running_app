import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../Models/UserProfile.dart';
import '../Services/UserService.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final UserService _userService = UserService();
  final ImagePicker _picker = ImagePicker();

  UserProfile? _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    UserProfile? user = await _userService.getUserProfile();
    if (mounted) {
      setState(() {
        _userProfile = user;
        _isLoading = false;
      });
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đang tải ảnh lên...')),
      );

      bool success = await _userService.uploadAvatar(File(image.path));

      if (!mounted) return;
      if (success) {
        await _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đổi avatar thành công!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  void _showEditDialog() {
    if (_userProfile == null) return;

    final nameController = TextEditingController(text: _userProfile!.userName);
    final heightController = TextEditingController(text: _userProfile!.heightCm.toString());
    final weightController = TextEditingController(text: _userProfile!.weightKg.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2E),
        title: const Text("Cập nhật thông tin", style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogField(nameController, "Tên hiển thị", TextInputType.text),
              _buildDialogField(heightController, "Chiều cao (cm)", TextInputType.number),
              _buildDialogField(weightController, "Cân nặng (kg)", TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              double h = double.tryParse(heightController.text) ?? 0;
              double w = double.tryParse(weightController.text) ?? 0;
              bool success = await _userService.updateProfile(nameController.text, h, w);
              if (success) await _loadData();
            },
            child: const Text("Lưu"),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogField(TextEditingController controller, String label, TextInputType type) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        keyboardType: type,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
        ),
      ),
    );
  }

  void _handleLogout() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2E),
        title: const Text("Đăng xuất", style: TextStyle(color: Colors.white)),
        content: const Text("Bạn có muốn đăng xuất khỏi ứng dụng?", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("Đăng xuất", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text("Hồ sơ cá nhân", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : _userProfile == null
          ? _buildErrorState()
          : RefreshIndicator(
        onRefresh: _loadData,
        color: Colors.orange,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: size.width * 0.05),
          child: Column(
            children: [
              SizedBox(height: size.height * 0.02),
              _buildUserHeader(size),
              SizedBox(height: size.height * 0.03),
              _buildStatsBoard(size),
              SizedBox(height: size.height * 0.03),
              _buildInfoSection(),
              SizedBox(height: size.height * 0.04),
              _buildLogoutButton(size),
              SizedBox(height: size.height * 0.05),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserHeader(Size size) {
    return Column(
      children: [
        GestureDetector(
          onTap: _pickAndUploadAvatar,
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.orange, width: 2),
                ),
                child: CircleAvatar(
                  radius: size.width * 0.15,
                  backgroundColor: Colors.grey[800],
                  backgroundImage: _userProfile!.avatarUrl?.isNotEmpty == true
                      ? NetworkImage(_userProfile!.avatarUrl!)
                      : null,
                  child: _userProfile!.avatarUrl?.isEmpty ?? true
                      ? Icon(Icons.person, size: size.width * 0.15, color: Colors.grey)
                      : null,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                ),
              )
            ],
          ),
        ),
        SizedBox(height: size.height * 0.02),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _userProfile!.userName,
              style: TextStyle(fontSize: size.width * 0.06, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.orange, size: 20),
              onPressed: _showEditDialog,
            )
          ],
        ),
        Text(_userProfile!.email, style: TextStyle(color: Colors.grey[400], fontSize: 14)),
        SizedBox(height: size.height * 0.02),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _chipInfo(Icons.height, "${_userProfile!.heightCm} cm"),
            const SizedBox(width: 12),
            _chipInfo(Icons.monitor_weight, "${_userProfile!.weightKg} kg"),
          ],
        )
      ],
    );
  }

  Widget _chipInfo(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.orange),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildStatsBoard(Size size) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: size.height * 0.025),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(child: _statItem("QUÃNG ĐƯỜNG", "${_userProfile!.totalDistanceKm.toStringAsFixed(2)} km", Colors.orange)),
          Container(width: 1, height: 40, color: Colors.white10),
          Expanded(child: _statItem("THỜI GIAN", _formatTotalTime(_userProfile!.totalTimeSeconds), Colors.white)),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500], letterSpacing: 1.1)),
      ],
    );
  }

  Widget _buildInfoSection() {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF2C2C2E), borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: const Icon(Icons.calendar_month, color: Colors.orange),
        title: const Text("Ngày tham gia", style: TextStyle(color: Colors.grey, fontSize: 14)),
        trailing: Text(
          _formatDate(_userProfile!.createdAt),
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(Size size) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.logout, size: 20),
        label: const Text('Đăng xuất', style: TextStyle(fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.redAccent.withOpacity(0.1),
          foregroundColor: Colors.redAccent,
          padding: EdgeInsets.symmetric(vertical: size.height * 0.018),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        onPressed: _handleLogout,
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.orange, size: 48),
          const SizedBox(height: 16),
          const Text("Không thể tải thông tin", style: TextStyle(color: Colors.white)),
          TextButton(onPressed: _loadData, child: const Text("Thử lại", style: TextStyle(color: Colors.orange)))
        ],
      ),
    );
  }

  String _formatTotalTime(double totalSeconds) {
    int s = totalSeconds.toInt();
    return "${s ~/ 3600}h ${(s % 3600) ~/ 60}p";
  }

  String _formatDate(DateTime d) => "${d.day}/${d.month}/${d.year}";
}