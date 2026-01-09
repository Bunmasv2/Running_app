class UserProfile {
  final String id;
  final String email;
  final String userName;
  final DateTime createdAt;
  final double heightCm;
  final double weightKg;
  final double totalDistanceKm;
  final double totalTimeSeconds;
  final String? avatarUrl; // Có thể null

  UserProfile({
    required this.id,
    required this.email,
    required this.userName,
    required this.createdAt,
    required this.heightCm,
    required this.weightKg,
    required this.totalDistanceKm,
    required this.totalTimeSeconds,
    this.avatarUrl,
  });

  // Factory parse JSON an toàn, khớp với field bên C#
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      userName: json['userName'] ?? 'Unknown User',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      heightCm: (json['heightCm'] as num?)?.toDouble() ?? 0.0,
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 0.0,
      totalDistanceKm: (json['totalDistanceKm'] as num?)?.toDouble() ?? 0.0,
      totalTimeSeconds: (json['totalTimeSeconds'] as num?)?.toDouble() ?? 0.0,
      avatarUrl: json['avatarUrl'],
    );
  }
}

