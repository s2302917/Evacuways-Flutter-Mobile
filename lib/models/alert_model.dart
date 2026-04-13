class AlertModel {
  final int alertId;
  final String title;
  final String message;
  final String alertType;
  final String severityLevel;
  final int? cityId;
  final int? barangayId;
  final String? barangayCode;
  final String? barangayName;
  final int? createdBy;
  final DateTime createdAt;
  final DateTime? scheduledAt;
  final String status;

  AlertModel({
    required this.alertId,
    required this.title,
    required this.message,
    required this.alertType,
    required this.severityLevel,
    this.cityId,
    this.barangayId,
    this.barangayCode,
    this.barangayName,
    this.createdBy,
    required this.createdAt,
    this.scheduledAt,
    required this.status,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      alertId: json['alert_id'] ?? 0,
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      alertType: json['alert_type'] ?? '',
      severityLevel: json['severity_level'] ?? '',
      cityId: json['city_id'],
      barangayId: json['barangay_id'],
      barangayCode: json['barangay_code'],
      barangayName: json['barangay_name'],
      createdBy: json['created_by'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      scheduledAt: json['scheduled_at'] != null
          ? DateTime.parse(json['scheduled_at'])
          : null,
      status: json['status'] ?? 'Active',
    );
  }

  Map<String, dynamic> toJson() => {
    'alert_id': alertId,
    'title': title,
    'message': message,
    'alert_type': alertType,
    'severity_level': severityLevel,
    'city_id': cityId,
    'barangay_id': barangayId,
    'barangay_code': barangayCode,
    'barangay_name': barangayName,
    'created_by': createdBy,
    'created_at': createdAt.toIso8601String(),
    'scheduled_at': scheduledAt?.toIso8601String(),
    'status': status,
  };
}
