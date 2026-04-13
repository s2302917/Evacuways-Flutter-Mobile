class VehicleAssignmentModel {
  final int assignmentId;
  final int? vehicleId;
  final int? alertId;
  final DateTime assignedAt;
  final String? status;

  VehicleAssignmentModel({
    required this.assignmentId,
    this.vehicleId,
    this.alertId,
    required this.assignedAt,
    this.status,
  });

  factory VehicleAssignmentModel.fromJson(Map<String, dynamic> json) {
    return VehicleAssignmentModel(
      assignmentId: json['assignment_id'] ?? 0,
      vehicleId: json['vehicle_id'],
      alertId: json['alert_id'],
      assignedAt: json['assigned_at'] != null
          ? DateTime.parse(json['assigned_at'])
          : DateTime.now(),
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() => {
    'assignment_id': assignmentId,
    'vehicle_id': vehicleId,
    'alert_id': alertId,
    'assigned_at': assignedAt.toIso8601String(),
    'status': status,
  };
}
