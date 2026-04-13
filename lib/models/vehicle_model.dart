class VehicleModel {
  final int vehicleId;
  final String? vehicleType;
  final String? plateNumber;
  final int? capacity;
  final String? status;
  final DateTime createdAt;
  final String? driverName;
  final String? driverContact;
  final String? barangayName;
  final String? landmark;
  final double? latitude;
  final double? longitude;
  final int? currentOccupants;

  VehicleModel({
    required this.vehicleId,
    this.vehicleType,
    this.plateNumber,
    this.capacity,
    this.status,
    required this.createdAt,
    this.driverName,
    this.driverContact,
    this.barangayName,
    this.landmark,
    this.latitude,
    this.longitude,
    this.currentOccupants,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      vehicleId: json['vehicle_id'] ?? 0,
      vehicleType: json['vehicle_type'],
      plateNumber: json['plate_number'],
      capacity: json['capacity'],
      status: json['status'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      driverName: json['driver_name'],
      driverContact: json['driver_contact'],
      barangayName: json['barangay_name'],
      landmark: json['landmark'],
      latitude: json['latitude'] != null
          ? double.parse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.parse(json['longitude'].toString())
          : null,
      currentOccupants: json['current_occupants'],
    );
  }

  Map<String, dynamic> toJson() => {
    'vehicle_id': vehicleId,
    'vehicle_type': vehicleType,
    'plate_number': plateNumber,
    'capacity': capacity,
    'status': status,
    'created_at': createdAt.toIso8601String(),
    'driver_name': driverName,
    'driver_contact': driverContact,
    'barangay_name': barangayName,
    'landmark': landmark,
    'latitude': latitude,
    'longitude': longitude,
    'current_occupants': currentOccupants,
  };
}
