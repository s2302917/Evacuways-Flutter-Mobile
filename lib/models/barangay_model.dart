class BarangayModel {
  final int barangayId;
  final int cityId;
  final String? barangayCode;
  final String barangayName;
  final String? riskLevel;

  BarangayModel({
    required this.barangayId,
    required this.cityId,
    this.barangayCode,
    required this.barangayName,
    this.riskLevel,
  });

  factory BarangayModel.fromJson(Map<String, dynamic> json) {
    return BarangayModel(
      barangayId: json['barangay_id'] ?? 0,
      cityId: json['city_id'] ?? 0,
      barangayCode: json['barangay_code'],
      barangayName: json['barangay_name'] ?? '',
      riskLevel: json['risk_level'],
    );
  }

  Map<String, dynamic> toJson() => {
    'barangay_id': barangayId,
    'city_id': cityId,
    'barangay_code': barangayCode,
    'barangay_name': barangayName,
    'risk_level': riskLevel,
  };
}
