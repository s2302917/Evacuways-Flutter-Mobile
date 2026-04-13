class AdminModel {
  final int adminId;
  final String fullName;
  final String email;
  final String passwordHash;
  final String role;
  final DateTime createdAt;
  final DateTime? lastLogin;
  final double? latitude;
  final double? longitude;
  final String? regionCode;
  final String? cityCode;
  final String? barangayCode;
  final int? cityId;
  final int? barangayId;

  AdminModel({
    required this.adminId,
    required this.fullName,
    required this.email,
    required this.passwordHash,
    required this.role,
    required this.createdAt,
    this.lastLogin,
    this.latitude,
    this.longitude,
    this.regionCode,
    this.cityCode,
    this.barangayCode,
    this.cityId,
    this.barangayId,
  });

  factory AdminModel.fromJson(Map<String, dynamic> json) {
    return AdminModel(
      adminId: json['admin_id'] ?? 0,
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      passwordHash: json['password_hash'] ?? '',
      role: json['role'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      lastLogin: json['last_login'] != null
          ? DateTime.parse(json['last_login'])
          : null,
      latitude: json['latitude'] != null
          ? double.parse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.parse(json['longitude'].toString())
          : null,
      regionCode: json['region_code'],
      cityCode: json['city_code'],
      barangayCode: json['barangay_code'],
      cityId: json['city_id'],
      barangayId: json['barangay_id'],
    );
  }

  Map<String, dynamic> toJson() => {
    'admin_id': adminId,
    'full_name': fullName,
    'email': email,
    'password_hash': passwordHash,
    'role': role,
    'created_at': createdAt.toIso8601String(),
    'last_login': lastLogin?.toIso8601String(),
    'latitude': latitude,
    'longitude': longitude,
    'region_code': regionCode,
    'city_code': cityCode,
    'barangay_code': barangayCode,
    'city_id': cityId,
    'barangay_id': barangayId,
  };
}
