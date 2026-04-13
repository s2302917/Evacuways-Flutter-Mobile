class UserModel {
  final int userId;
  final int? familyId;
  final String firstName;
  final String lastName;
  final String? gender;
  final String? birthDate;
  final String contactNumber;

  final int? cityId;
  final int? barangayId;
  final String? regionCode;
  final String? cityCode;
  final String? barangayCode;
  final int? centerId;

  final int headcount;
  final bool isFamily;
  final int missingCount;
  final String? rescueStatus;

  final int? assignedVehicleId;
  final int? assignedCenterId;
  final double? latitude;
  final double? longitude;

  final String? deviceToken;
  final String? role;
  final String? createdAt;
  final bool mustChangePassword;

  UserModel({
    required this.userId,
    this.familyId,
    required this.firstName,
    required this.lastName,
    this.gender,
    this.birthDate,
    required this.contactNumber,
    this.cityId,
    this.barangayId,
    this.regionCode,
    this.cityCode,
    this.barangayCode,
    this.centerId,
    this.headcount = 1,
    this.isFamily = false,
    this.missingCount = 0,
    this.rescueStatus,
    this.assignedVehicleId,
    this.assignedCenterId,
    this.latitude,
    this.longitude,
    this.deviceToken,
    this.role,
    this.createdAt,
    this.mustChangePassword = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['user_id'] is int
          ? json['user_id']
          : int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
      familyId: json['family_id'] != null
          ? int.tryParse(json['family_id'].toString())
          : null,
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      gender: json['gender'],
      birthDate: json['birth_date'],
      contactNumber: json['contact_number'] ?? '',

      cityId: json['city_id'] != null
          ? int.tryParse(json['city_id'].toString())
          : null,
      barangayId: json['barangay_id'] != null
          ? int.tryParse(json['barangay_id'].toString())
          : null,
      regionCode: json['region_code'],
      cityCode: json['city_code'],
      barangayCode: json['barangay_code'],
      centerId: json['center_id'] != null
          ? int.tryParse(json['center_id'].toString())
          : null,

      headcount: json['headcount'] is int
          ? json['headcount']
          : int.tryParse(json['headcount']?.toString() ?? '1') ?? 1,
      isFamily:
          json['is_family'] == 1 ||
          json['is_family'] == true ||
          json['is_family'] == '1',
      missingCount: json['missing_count'] is int
          ? json['missing_count']
          : int.tryParse(json['missing_count']?.toString() ?? '0') ?? 0,
      rescueStatus: json['rescue_status'],

      assignedVehicleId: json['assigned_vehicle_id'] != null
          ? int.tryParse(json['assigned_vehicle_id'].toString())
          : null,
      assignedCenterId: json['assigned_center_id'] != null
          ? int.tryParse(json['assigned_center_id'].toString())
          : null,
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null,

      deviceToken: json['device_token'],
      role: json['role'],
      createdAt: json['created_at'],
      mustChangePassword:
          json['must_change_password'] == 1 ||
          json['must_change_password'] == true ||
          json['must_change_password'] == '1',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'family_id': familyId,
      'first_name': firstName,
      'last_name': lastName,
      'gender': gender,
      'birth_date': birthDate,
      'contact_number': contactNumber,

      'city_id': cityId,
      'barangay_id': barangayId,
      'region_code': regionCode,
      'city_code': cityCode,
      'barangay_code': barangayCode,
      'center_id': centerId,

      'headcount': headcount,
      'is_family': isFamily ? 1 : 0,
      'missing_count': missingCount,
      'rescue_status': rescueStatus,

      'assigned_vehicle_id': assignedVehicleId,
      'assigned_center_id': assignedCenterId,
      'latitude': latitude,
      'longitude': longitude,

      'device_token': deviceToken,
      'role': role,
      'created_at': createdAt,
      'must_change_password': mustChangePassword ? 1 : 0,
    };
  }

  UserModel copyWith({
    int? userId,
    int? familyId,
    String? firstName,
    String? lastName,
    String? gender,
    String? birthDate,
    String? contactNumber,
    int? cityId,
    int? barangayId,
    String? regionCode,
    String? cityCode,
    String? barangayCode,
    int? centerId,
    int? headcount,
    bool? isFamily,
    int? missingCount,
    String? rescueStatus,
    int? assignedVehicleId,
    int? assignedCenterId,
    double? latitude,
    double? longitude,
    String? deviceToken,
    String? role,
    String? createdAt,
    bool? mustChangePassword,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      familyId: familyId ?? this.familyId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      contactNumber: contactNumber ?? this.contactNumber,
      cityId: cityId ?? this.cityId,
      barangayId: barangayId ?? this.barangayId,
      regionCode: regionCode ?? this.regionCode,
      cityCode: cityCode ?? this.cityCode,
      barangayCode: barangayCode ?? this.barangayCode,
      centerId: centerId ?? this.centerId,
      headcount: headcount ?? this.headcount,
      isFamily: isFamily ?? this.isFamily,
      missingCount: missingCount ?? this.missingCount,
      rescueStatus: rescueStatus ?? this.rescueStatus,
      assignedVehicleId: assignedVehicleId ?? this.assignedVehicleId,
      assignedCenterId: assignedCenterId ?? this.assignedCenterId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      deviceToken: deviceToken ?? this.deviceToken,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      mustChangePassword: mustChangePassword ?? this.mustChangePassword,
    );
  }
}

