class EvacuationCenterModel {
  final int centerId;
  final String centerName;
  final String barangayName;
  final int capacity;
  final int currentIndividuals;
  final int currentFamilies;
  final String assignedVehicles;
  final String status;
  final String? contactPerson;
  final String? contactNumber;
  final DateTime createdAt;
  final double? latitude;
  final double? longitude;

  EvacuationCenterModel({
    required this.centerId,
    required this.centerName,
    required this.barangayName,
    required this.capacity,
    this.currentIndividuals = 0,
    this.currentFamilies = 0,
    this.assignedVehicles = 'None',
    this.status = 'Open',
    this.contactPerson,
    this.contactNumber,
    required this.createdAt,
    this.latitude,
    this.longitude,
  });

  factory EvacuationCenterModel.fromJson(Map<String, dynamic> json) {
    return EvacuationCenterModel(
      centerId: json['center_id'] ?? 0,
      centerName: json['center_name'] ?? '',
      barangayName: json['barangay_name'] ?? '',
      capacity: json['capacity'] ?? 0,
      currentIndividuals: json['current_individuals'] ?? 0,
      currentFamilies: json['current_families'] ?? 0,
      assignedVehicles: json['assigned_vehicles'] ?? 'None',
      status: json['status'] ?? 'Open',
      contactPerson: json['contact_person'],
      contactNumber: json['contact_number'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      latitude: json['latitude'] != null
          ? double.parse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.parse(json['longitude'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'center_id': centerId,
    'center_name': centerName,
    'barangay_name': barangayName,
    'capacity': capacity,
    'current_individuals': currentIndividuals,
    'current_families': currentFamilies,
    'assigned_vehicles': assignedVehicles,
    'status': status,
    'contact_person': contactPerson,
    'contact_number': contactNumber,
    'created_at': createdAt.toIso8601String(),
    'latitude': latitude,
    'longitude': longitude,
  };
}
