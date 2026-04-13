import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/evacuation_center_model.dart';

/// EvacuationCenterController handles evacuation center management
class EvacuationCenterController {
  static const String baseUrl = 'https://5zu.758.mytemp.website/Evacuways/api';

  // Fetch all evacuation centers
  Future<List<EvacuationCenterModel>> getAllCenters() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/centers/get_centers.php'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .map((json) => EvacuationCenterModel.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching centers: $e');
      return [];
    }
  }

  // Fetch centers by barangay
  Future<List<EvacuationCenterModel>> getCentersByBarangay(
    String barangayName,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/centers/get_centers_by_barangay.php?barangay=$barangayName',
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .map((json) => EvacuationCenterModel.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching barangay centers: $e');
      return [];
    }
  }

  // Get center details
  Future<EvacuationCenterModel?> getCenterDetails(int centerId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/centers/get_center.php?center_id=$centerId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return EvacuationCenterModel.fromJson(data);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching center details: $e');
      return null;
    }
  }

  // Create new center
  Future<Map<String, dynamic>> createCenter(
    EvacuationCenterModel center,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/centers/create_center.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(center.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': data['success'] ?? true,
          'message': data['message'] ?? 'Center created',
          'center_id': data['center_id'],
        };
      }
      return {'success': false, 'message': 'Failed to create center'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Update center occupancy
  Future<Map<String, dynamic>> updateOccupancy(
    int centerId,
    int individuals,
    int families,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/centers/update_occupancy.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'center_id': centerId,
          'current_individuals': individuals,
          'current_families': families,
        }),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Occupancy updated'};
      }
      return {'success': false, 'message': 'Failed to update occupancy'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Update center status
  Future<Map<String, dynamic>> updateCenterStatus(
    int centerId,
    String status,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/centers/update_status.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'center_id': centerId, 'status': status}),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Center status updated'};
      }
      return {'success': false, 'message': 'Failed to update status'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Get available capacity
  Future<int?> getAvailableCapacity(int centerId) async {
    try {
      final center = await getCenterDetails(centerId);
      if (center != null) {
        return center.capacity - center.currentIndividuals;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
