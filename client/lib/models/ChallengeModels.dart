import 'dart:convert';

class Challenge {
  final int id;
  final String title;
  final String description;
  final String? imageUrl;
  final double targetDistanceKm;
  final DateTime startDate;
  final DateTime endDate;
  final int status; // 0: Draft, 1: Active, etc.

  Challenge({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.targetDistanceKm,
    required this.startDate,
    required this.endDate,
    required this.status,
  });

  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      id: json['id'] ?? 0,
      title: json['title'] ?? 'Unknown Challenge',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'],
      targetDistanceKm: (json['targetDistanceKm'] as num?)?.toDouble() ?? 0.0,
      startDate: DateTime.tryParse(json['startDate'] ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(json['endDate'] ?? '') ?? DateTime.now(),
      status: json['status'] ?? 0,
    );
  }
}

class UserChallengeProgress {
  final int id;
  final int challengeId;
  final String challengeTitle; // Để hiển thị tên nhanh
  final String? challengeImage;
  final double completedDistanceKm;
  final double targetDistanceKm;
  final double progressPercent; // 0.0 -> 100.0
  final int status; // 0: InProgress, 1: Completed

  UserChallengeProgress({
    required this.id,
    required this.challengeId,
    required this.challengeTitle,
    this.challengeImage,
    required this.completedDistanceKm,
    required this.targetDistanceKm,
    required this.progressPercent,
    required this.status,
  });

  factory UserChallengeProgress.fromJson(Map<String, dynamic> json) {
    // Tùy thuộc vào cấu trúc JSON trả về của API,
    // giả sử API trả về object Challenge lồng bên trong
    final challenge = json['challenge'] != null ? json['challenge'] : {};

    return UserChallengeProgress(
      id: json['id'] ?? 0,
      challengeId: json['challengeId'] ?? 0,
      challengeTitle: challenge['title'] ?? 'Unknown',
      challengeImage: challenge['imageUrl'],
      completedDistanceKm: (json['completedDistanceKm'] as num?)?.toDouble() ?? 0.0,
      // Nếu API không trả target ở ngoài thì lấy trong object challenge
      targetDistanceKm: (challenge['targetDistanceKm'] as num?)?.toDouble() ?? 100.0,
      progressPercent: (json['progressPercent'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 0,
    );
  }
}