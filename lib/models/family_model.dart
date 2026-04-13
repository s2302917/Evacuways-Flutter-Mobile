class FamilyModel {
  final int familyId;
  final String familyName;
  final String primaryContact;
  final String rescueStatus;
  final int? assignedVehicleId;
  final int? assignedCenterId;
  final int headcount;
  final DateTime createdAt;

  FamilyModel({
    required this.familyId,
    required this.familyName,
    required this.primaryContact,
    this.rescueStatus = 'Pending Rescue',
    this.assignedVehicleId,
    this.assignedCenterId,
    this.headcount = 0,
    required this.createdAt,
  });

  factory FamilyModel.fromJson(Map<String, dynamic> json) {
    return FamilyModel(
      familyId: json['family_id'] ?? 0,
      familyName: json['family_name'] ?? '',
      primaryContact: json['primary_contact'] ?? '',
      rescueStatus: json['rescue_status'] ?? 'Pending Rescue',
      assignedVehicleId: json['assigned_vehicle_id'],
      assignedCenterId: json['assigned_center_id'],
      headcount: json['headcount'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'family_id': familyId,
    'family_name': familyName,
    'primary_contact': primaryContact,
    'rescue_status': rescueStatus,
    'assigned_vehicle_id': assignedVehicleId,
    'assigned_center_id': assignedCenterId,
    'headcount': headcount,
    'created_at': createdAt.toIso8601String(),
  };
}
