class AdminLogModel {
  final int logId;
  final int adminId;
  final String action;
  final String? details;
  final String? ipAddress;
  final DateTime createdAt;

  AdminLogModel({
    required this.logId,
    required this.adminId,
    required this.action,
    this.details,
    this.ipAddress,
    required this.createdAt,
  });

  factory AdminLogModel.fromJson(Map<String, dynamic> json) {
    return AdminLogModel(
      logId: json['log_id'] ?? 0,
      adminId: json['admin_id'] ?? 0,
      action: json['action'] ?? '',
      details: json['details'],
      ipAddress: json['ip_address'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'log_id': logId,
    'admin_id': adminId,
    'action': action,
    'details': details,
    'ip_address': ipAddress,
    'created_at': createdAt.toIso8601String(),
  };
}
