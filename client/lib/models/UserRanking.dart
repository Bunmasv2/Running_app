class UserRanking {
  final String username;
  final String? avatarUrl;
  final String totalTime;
  final double caloriesBurned;

  UserRanking({
    required this.username,
    this.avatarUrl,
    required this.totalTime,
    required this.caloriesBurned,
  });

  factory UserRanking.fromJson(Map<String, dynamic> json) {
    return UserRanking(
      username: json['username'],
      avatarUrl: json['avatarUrl'],
      totalTime: json['totalTime'],
      caloriesBurned: (json['caloriesBurned'] as num).toDouble(),
    );
  }
}
