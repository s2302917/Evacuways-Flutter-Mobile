class CenterModel {
  final int id;
  final String name;
  final String barangay;
  final int capacity;
  final int currentIndividuals;
  final String status;
  final String? contactPerson;
  final String? contactNumber;
  final double? latitude;
  final double? longitude;

  CenterModel({
    required this.id,
    required this.name,
    required this.barangay,
    required this.capacity,
    required this.currentIndividuals,
    required this.status,
    this.contactPerson,
    this.contactNumber,
    this.latitude,
    this.longitude,
  });

  factory CenterModel.fromJson(Map<String, dynamic> json) {
    return CenterModel(
      id: int.parse(json['center_id'].toString()),
      name: json['center_name'],
      barangay: json['barangay_name'],
      capacity: int.parse(json['capacity'].toString()),
      currentIndividuals: json['current_individuals'] != null
          ? int.parse(json['current_individuals'].toString())
          : 0,
      status: json['status'],
      contactPerson: json['contact_person'],
      contactNumber: json['contact_number'],
      latitude: (json['latitude'] != null && json['latitude'] != "")
          ? double.parse(json['latitude'].toString())
          : null,
      longitude: (json['longitude'] != null && json['longitude'] != "")
          ? double.parse(json['longitude'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'center_id': id,
    'center_name': name,
    'barangay_name': barangay,
    'capacity': capacity,
    'current_individuals': currentIndividuals,
    'status': status,
    'contact_person': contactPerson,
    'contact_number': contactNumber,
    'latitude': latitude,
    'longitude': longitude,
  };
}
