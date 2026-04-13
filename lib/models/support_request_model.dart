class SupportRequestModel {
  final int requestId;
  final int? userId;
  final int? cityId;
  final int? barangayId;
  final String? subject;
  final String? message;
  final String? requestType;
  final String? status;
  final DateTime createdAt;

  SupportRequestModel({
    required this.requestId,
    this.userId,
    this.cityId,
    this.barangayId,
    this.subject,
    this.message,
    this.requestType,
    this.status,
    required this.createdAt,
  });

  factory SupportRequestModel.fromJson(Map<String, dynamic> json) {
    return SupportRequestModel(
      requestId: json['request_id'] ?? 0,
      userId: json['user_id'],
      cityId: json['city_id'],
      barangayId: json['barangay_id'],
      subject: json['subject'],
      message: json['message'],
      requestType: json['request_type'],
      status: json['status'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'request_id': requestId,
    'user_id': userId,
    'city_id': cityId,
    'barangay_id': barangayId,
    'subject': subject,
    'message': message,
    'request_type': requestType,
    'status': status,
    'created_at': createdAt.toIso8601String(),
  };
}
