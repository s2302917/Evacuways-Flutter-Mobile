class SosRequestModel {
  final int requestId;
  final int? userId;
  final String? subject;
  final String? message;
  final String? requestType;
  final String status;
  final DateTime createdAt;

  SosRequestModel({
    required this.requestId,
    this.userId,
    this.subject,
    this.message,
    this.requestType,
    required this.status,
    required this.createdAt,
  });

  factory SosRequestModel.fromJson(Map<String, dynamic> json) {
    return SosRequestModel(
      requestId: int.tryParse(json['request_id'].toString()) ?? 0,
      userId: json['user_id'] != null ? int.tryParse(json['user_id'].toString()) : null,
      subject: json['subject'],
      message: json['message'],
      requestType: json['request_type'],
      status: json['status'] ?? 'Pending',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  bool get isPending => status == 'Pending';
  bool get isCancelled => status == 'Cancelled';
  bool get isResolved => status == 'Resolved';
}
