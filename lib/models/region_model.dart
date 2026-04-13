class RegionModel {
  final int regionId;
  final String regionName;

  RegionModel({required this.regionId, required this.regionName});

  factory RegionModel.fromJson(Map<String, dynamic> json) {
    return RegionModel(
      regionId: json['region_id'] ?? 0,
      regionName: json['region_name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'region_id': regionId,
    'region_name': regionName,
  };
}
