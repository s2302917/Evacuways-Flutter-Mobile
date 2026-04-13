import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/vehicle_model.dart';

/// VehicleController handles vehicle management logic
class VehicleController {
  static const String baseUrl = 'https://5zu.758.mytemp.website/Evacuways/api';

  // Fetch all vehicles
  Future<List<VehicleModel>> getAllVehicles() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/vehicles/get_vehicles.php'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => VehicleModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching vehicles: $e');
      return [];
    }
  }

  // Fetch available vehicles
  Future<List<VehicleModel>> getAvailableVehicles() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/vehicles/get_available_vehicles.php'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => VehicleModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching available vehicles: $e');
      return [];
    }
  }

  // Get vehicle details
  Future<VehicleModel?> getVehicleDetails(int vehicleId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/vehicles/get_vehicle.php?vehicle_id=$vehicleId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return VehicleModel.fromJson(data);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching vehicle details: $e');
      return null;
    }
  }

  // Create new vehicle
  Future<Map<String, dynamic>> createVehicle(VehicleModel vehicle) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/vehicles/create_vehicle.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(vehicle.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': data['success'] ?? true,
          'message': data['message'] ?? 'Vehicle created',
          'vehicle_id': data['vehicle_id'],
        };
      }
      return {'success': false, 'message': 'Failed to create vehicle'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Update vehicle status
  Future<Map<String, dynamic>> updateVehicleStatus(
    int vehicleId,
    String status,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/vehicles/update_status.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'vehicle_id': vehicleId, 'status': status}),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Vehicle status updated'};
      }
      return {'success': false, 'message': 'Failed to update status'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Update vehicle location
  Future<Map<String, dynamic>> updateVehicleLocation(
    int vehicleId,
    double latitude,
    double longitude,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/vehicles/update_location.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'vehicle_id': vehicleId,
          'latitude': latitude,
          'longitude': longitude,
        }),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Location updated'};
      }
      return {'success': false, 'message': 'Failed to update location'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Fetch vehicles by status
  Future<List<VehicleModel>> getVehiclesByStatus(String status) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/vehicles/get_vehicles_by_status.php?status=$status',
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => VehicleModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching vehicles by status: $e');
      return [];
    }
  }

  // Delete vehicle
  Future<Map<String, dynamic>> deleteVehicle(int vehicleId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/vehicles/delete_vehicle.php?vehicle_id=$vehicleId'),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Vehicle deleted successfully'};
      }
      return {'success': false, 'message': 'Failed to delete vehicle'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
}
