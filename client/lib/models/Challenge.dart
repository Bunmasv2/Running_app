class Challenge {
  final String id;
  final String name;
  final String description;
  final double targetDistanceKm;
  final DateTime startDate;
  final DateTime endDate;
  final int totalParticipants;

  Challenge({
    required this.id,
    required this.name,
    required this.description,
    required this.targetDistanceKm,
    required this.startDate,
    required this.endDate,
    required this.totalParticipants,
  });

  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      targetDistanceKm: (json['targetDistanceKm'] as num?)?.toDouble() ?? 0.0,
      startDate: DateTime.tryParse(json['startDate'] ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(json['endDate'] ?? '') ?? DateTime.now(),
      totalParticipants: json['totalParticipants'] ?? 0,
    );
  }
}
