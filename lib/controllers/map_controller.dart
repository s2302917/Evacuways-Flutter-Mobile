import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart';
import '../models/center_model.dart';
import '../models/vehicle_model.dart';

class AdminModel {
  final int id;
  final String name;
  final String role;
  final double latitude;
  final double longitude;

  AdminModel({
    required this.id,
    required this.name,
    required this.role,
    required this.latitude,
    required this.longitude,
  });

  factory AdminModel.fromJson(Map<String, dynamic> json) {
    return AdminModel(
      id: int.parse(json['admin_id'].toString()),
      name: json['full_name'],
      role: json['role'] ?? 'Admin',
      latitude: double.parse(json['latitude'].toString()),
      longitude: double.parse(json['longitude'].toString()),
    );
  }
}

class MapController extends ChangeNotifier {
  static const String baseUrl = 'https://5zu.758.mytemp.website/Evacuways/api';

  List<CenterModel> centers = [];
  List<VehicleModel> vehicles = [];
  List<AdminModel> admins = [];
  bool isLoading = false;
  String currentLocationName = "Locating...";

  Future<void> updateLocationName(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        // Priority: Locality (City) + SubLocality (Barangay)
        currentLocationName =
            "${place.locality ?? ''}${place.subLocality != null ? ', ${place.subLocality}' : ''}";
        if (currentLocationName.isEmpty || currentLocationName == ", ") {
          currentLocationName = place.administrativeArea ?? "Unknown Location";
        }
      }
    } catch (e) {
      debugPrint('GEOCODING ERROR: $e');
      currentLocationName = "Unknown Location";
    }
    notifyListeners();
  }

  Map<String, dynamic>? currentPresence;

  Future<void> fetchResources() async {
    isLoading = true;
    notifyListeners();

    try {
      // 1. Fetch User Presence (Hardcoded user_id 1 for now)
      final presenceRes = await http.get(
        Uri.parse('$baseUrl/map/get_user_presence.php?user_id=1'),
      );
      if (presenceRes.statusCode == 200) {
        final presenceData = jsonDecode(presenceRes.body);
        currentPresence = presenceData['presence'];
      }

      // 2. Fetch Resources
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final response = await http.get(
        Uri.parse('$baseUrl/map/get_resources.php?t=$timestamp'),
      );

      if (response.statusCode == 200) {
        debugPrint('MAP FETCH RAW BODY: ${response.body}');
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          centers = (data['centers'] as List)
              .map((c) => CenterModel.fromJson(c))
              .toList();
          vehicles = (data['vehicles'] as List)
              .map((v) => VehicleModel.fromJson(v))
              .toList();
          admins = (data['admins'] as List)
              .map((a) => AdminModel.fromJson(a))
              .toList();
          debugPrint('MAP FETCH SUCCESS: ${centers.length} centers, ${vehicles.length} vehicles, ${admins.length} admins');
        } else {
          debugPrint('MAP FETCH DATA ERROR: ${data['message']}');
        }
      } else {
        debugPrint('MAP FETCH HTTP ERROR: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('MAP FETCH EXCEPTION: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> checkIn({
    required int resourceId,
    required String resourceType,
    required int headcount,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/map/check_in.php'),
        body: jsonEncode({
          'user_id': 1, // Default user_id 1
          'resource_id': resourceId,
          'resource_type': resourceType,
          'headcount': headcount,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          await fetchResources(); // Refresh
          return true;
        }
      }
    } catch (e) {
      debugPrint('CHECK-IN EXCEPTION: $e');
    }
    return false;
  }

  Future<bool> checkOut() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/map/cancel_check_in.php'),
        body: jsonEncode({
          'user_id': 1, // Default user_id 1
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          await fetchResources(); // Refresh
          return true;
        }
      }
    } catch (e) {
      debugPrint('CHECK-OUT EXCEPTION: $e');
    }
    return false;
  }
}

final MapController mapController = MapController();
