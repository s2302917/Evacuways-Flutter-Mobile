import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/region_model.dart';
import '../models/city_model.dart';
import '../models/barangay_model.dart';

/// LocationController handles geolocation and administrative divisions
class LocationController {
  static const String baseUrl = 'https://5zu.758.mytemp.website/Evacuways/api';

  // Fetch all regions
  Future<List<RegionModel>> getRegions() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/locations/get_regions.php'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => RegionModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching regions: $e');
      return [];
    }
  }

  // Fetch cities by region
  Future<List<CityModel>> getCitiesByRegion(int regionId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/locations/get_cities.php?region_id=$regionId'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => CityModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching cities: $e');
      return [];
    }
  }

  // Fetch barangays by city
  Future<List<BarangayModel>> getBarangaysByCity(int cityId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/locations/get_barangays.php?city_id=$cityId'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => BarangayModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching barangays: $e');
      return [];
    }
  }

  // Get city details
  Future<CityModel?> getCityDetails(int cityId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/locations/get_city.php?city_id=$cityId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return CityModel.fromJson(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get barangay details
  Future<BarangayModel?> getBarangayDetails(int barangayId) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/locations/get_barangay.php?barangay_id=$barangayId',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return BarangayModel.fromJson(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get barangay by code
  Future<BarangayModel?> getBarangayByCode(String barangayCode) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/locations/get_barangay_by_code.php?code=$barangayCode',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return BarangayModel.fromJson(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Search locations by name
  Future<List<Map<String, dynamic>>> searchLocations(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/locations/search.php?q=$query'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
