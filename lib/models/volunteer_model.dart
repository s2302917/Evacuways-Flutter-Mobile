class VolunteerModel {
  final int volunteerId;
  final int? userId;
  final String? skills;
  final String? availabilityStatus;

  VolunteerModel({
    required this.volunteerId,
    this.userId,
    this.skills,
    this.availabilityStatus,
  });

  factory VolunteerModel.fromJson(Map<String, dynamic> json) {
    return VolunteerModel(
      volunteerId: json['volunteer_id'] ?? 0,
      userId: json['user_id'],
      skills: json['skills'],
      availabilityStatus: json['availability_status'],
    );
  }

  Map<String, dynamic> toJson() => {
    'volunteer_id': volunteerId,
    'user_id': userId,
    'skills': skills,
    'availability_status': availabilityStatus,
  };
}
