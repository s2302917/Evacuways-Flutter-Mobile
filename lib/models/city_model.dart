class CityModel {
  final int cityId;
  final int regionId;
  final String cityName;
  final String? cityCode;

  CityModel({
    required this.cityId,
    required this.regionId,
    required this.cityName,
    this.cityCode,
  });

  factory CityModel.fromJson(Map<String, dynamic> json) {
    return CityModel(
      cityId: json['city_id'] ?? 0,
      regionId: json['region_id'] ?? 0,
      cityName: json['city_name'] ?? '',
      cityCode: json['city_code'],
    );
  }

  Map<String, dynamic> toJson() => {
    'city_id': cityId,
    'region_id': regionId,
    'city_name': cityName,
    'city_code': cityCode,
  };
}
