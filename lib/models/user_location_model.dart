class UserLocationModel {
  final int locationId;
  final int? userId;
  final double? latitude;
  final double? longitude;
  final DateTime timestamp;

  UserLocationModel({
    required this.locationId,
    this.userId,
    this.latitude,
    this.longitude,
    required this.timestamp,
  });

  factory UserLocationModel.fromJson(Map<String, dynamic> json) {
    return UserLocationModel(
      locationId: json['location_id'] ?? 0,
      userId: json['user_id'],
      latitude: json['latitude'] != null
          ? double.parse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.parse(json['longitude'].toString())
          : null,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'location_id': locationId,
    'user_id': userId,
    'latitude': latitude,
    'longitude': longitude,
    'timestamp': timestamp.toIso8601String(),
  };
}
