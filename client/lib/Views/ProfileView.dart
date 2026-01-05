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
    // Không set isLoading = true ở đây để tránh nháy màn hình khi update xong
    UserProfile? user = await _userService.getUserProfile();
    if (mounted) {
      setState(() {
        _userProfile = user;
        _isLoading = false;
      });
    }
  }

  // --- CHỨC NĂNG 1: UPLOAD AVATAR ---
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
        await _loadData(); // Load lại để thấy ảnh mới
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đổi avatar thành công!'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lỗi tải ảnh.'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      print(e);
    }
  }

  // --- CHỨC NĂNG 2: SỬA THÔNG TIN ---
  void _showEditDialog() {
    if (_userProfile == null) return;

    final nameController = TextEditingController(text: _userProfile!.userName);
    final heightController = TextEditingController(text: _userProfile!.heightCm.toString());
    final weightController = TextEditingController(text: _userProfile!.weightKg.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cập nhật thông tin"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Tên hiển thị"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: heightController,
                decoration: const InputDecoration(labelText: "Chiều cao (cm)"),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: weightController,
                decoration: const InputDecoration(labelText: "Cân nặng (kg)"),
                keyboardType: TextInputType.number,
              ),
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
              Navigator.pop(context); // Đóng dialog trước

              double h = double.tryParse(heightController.text) ?? 0;
              double w = double.tryParse(weightController.text) ?? 0;

              bool success = await _userService.updateProfile(nameController.text, h, w);

              if (!mounted) return;
              if (success) {
                await _loadData(); // Load lại data
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cập nhật thành công!'), backgroundColor: Colors.green));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cập nhật thất bại'), backgroundColor: Colors.red));
              }
            },
            child: const Text("Lưu"),
          ),
        ],
      ),
    );
  }

  // --- HELPER FORMAT ---
  String _formatTotalTime(double totalSeconds) {
    int seconds = totalSeconds.toInt();
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    return "${hours}h ${minutes}p";
  }

  String _formatDate(DateTime d) {
    return "${d.day}/${d.month}/${d.year}";
  }

  // --- UI CHÍNH ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Hồ sơ", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blue),
            onPressed: _showEditDialog,
            tooltip: "Sửa thông tin",
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userProfile == null
          ? _buildErrorState()
          : RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              const SizedBox(height: 20),
              _buildUserHeader(),
              const SizedBox(height: 20),
              _buildStatsBoard(),
              const SizedBox(height: 25),
              _buildInfoSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 50),
          const SizedBox(height: 10),
          const Text("Lỗi kết nối hoặc không tìm thấy User"),
          ElevatedButton(onPressed: () {
            setState(() => _isLoading = true);
            _loadData();
          }, child: const Text("Thử lại"))
        ],
      ),
    );
  }

  Widget _buildUserHeader() {
    return Column(
      children: [
        GestureDetector(
          onTap: _pickAndUploadAvatar,
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                ),
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: _userProfile!.avatarUrl != null && _userProfile!.avatarUrl!.isNotEmpty
                      ? NetworkImage(_userProfile!.avatarUrl!)
                      : null,
                  child: _userProfile!.avatarUrl == null
                      ? const Icon(Icons.person, size: 60, color: Colors.grey)
                      : null,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                ),
              )
            ],
          ),
        ),
        const SizedBox(height: 15),
        Text(
          _userProfile!.userName,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(
          _userProfile!.email,
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _chipInfo(Icons.height, "${_userProfile!.heightCm} cm"),
            const SizedBox(width: 15),
            _chipInfo(Icons.monitor_weight, "${_userProfile!.weightKg} kg"),
          ],
        )
      ],
    );
  }

  Widget _chipInfo(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.blueGrey),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildStatsBoard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem("QUÃNG ĐƯỜNG", "${_userProfile!.totalDistanceKm.toStringAsFixed(2)} km", Colors.blue),
          Container(width: 1, height: 50, color: Colors.grey[200]),
          _statItem("THỜI GIAN", _formatTotalTime(_userProfile!.totalTimeSeconds), Colors.orange),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 5),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500], letterSpacing: 1.2)),
      ],
    );
  }

  Widget _buildInfoSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.calendar_month, color: Colors.purple),
          ),
          title: const Text("Ngày tham gia"),
          trailing: Text(
            _formatDate(_userProfile!.createdAt),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}