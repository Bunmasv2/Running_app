class UserRanking {
  final String username;
  final String? avatarUrl;
  final double totalDurationSeconds;
  final double totalDistanceKm;
  final String totalTime;

  UserRanking({
    required this.username,
    this.avatarUrl,
    required this.totalDurationSeconds,
    required this.totalDistanceKm,
    required this.totalTime,
  });

  factory UserRanking.fromJson(Map<String, dynamic> json) {
    return UserRanking(
      username: json['username'],
      avatarUrl: json['avatarUrl'],
      totalDurationSeconds: (json['totalDurationSeconds'] as num).toDouble(),
      totalDistanceKm: (json['totalDistanceKm'] as num).toDouble(),
      totalTime: json['totalTime'],
    );
  }
}
