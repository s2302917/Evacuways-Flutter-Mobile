import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/support_request_model.dart';

/// SupportRequestController handles support and help request management
class SupportRequestController {
  static const String baseUrl = 'https://5zu.758.mytemp.website/Evacuways/api';

  // Create support request
  Future<Map<String, dynamic>> createSupportRequest(
    SupportRequestModel request,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/support/create_request.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': data['success'] ?? true,
          'message': data['message'] ?? 'Request submitted',
          'request_id': data['request_id'],
        };
      }
      return {'success': false, 'message': 'Failed to submit request'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Get user support requests
  Future<List<SupportRequestModel>> getUserRequests(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/support/get_user_requests.php?user_id=$userId'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => SupportRequestModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching support requests: $e');
      return [];
    }
  }

  // Get all support requests (admin)
  Future<List<SupportRequestModel>> getAllRequests() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/support/get_requests.php'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => SupportRequestModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching all requests: $e');
      return [];
    }
  }

  // Update request status
  Future<Map<String, dynamic>> updateRequestStatus(
    int requestId,
    String status,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/support/update_request_status.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'request_id': requestId, 'status': status}),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Request status updated'};
      }
      return {'success': false, 'message': 'Failed to update status'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Get requests by status
  Future<List<SupportRequestModel>> getRequestsByStatus(String status) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/support/get_requests_by_status.php?status=$status'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => SupportRequestModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching requests by status: $e');
      return [];
    }
  }

  // Get request details
  Future<SupportRequestModel?> getRequestDetails(int requestId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/support/get_request.php?request_id=$requestId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return SupportRequestModel.fromJson(data);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching request details: $e');
      return null;
    }
  }
}
