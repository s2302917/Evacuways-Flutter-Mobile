import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/family_model.dart';

/// UserController handles user management logic
class UserController {
  static const String baseUrl = 'https://5zu.758.mytemp.website/Evacuways/api';

  // Helper to handle responses consistently
  Map<String, dynamic> _handleResponse(http.Response response, String defaultMessage) {
    try {
      if (response.body.isEmpty) {
        return {'success': false, 'message': 'Empty response from server'};
      }
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (data is Map<String, dynamic>) {
          return data;
        } else if (data is List) {
           return {'success': true, 'data': data};
        }
        return {'success': true, 'message': defaultMessage};
      }
      
      if (data is Map<String, dynamic> && data.containsKey('message')) {
        return {'success': false, 'message': data['message']};
      }
      
      return {'success': false, 'message': 'Server error: ${response.statusCode}'};
    } catch (e) {
      debugPrint('JSON Decode Error: $e. Body: ${response.body}');
      return {'success': false, 'message': 'Invalid server response format'};
    }
  }

  // Fetch user profile
  Future<UserModel?> getUserProfile(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/get_user.php?user_id=$userId'),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UserModel.fromJson(data);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      return null;
    }
  }

  // Update user profile
  Future<Map<String, dynamic>> updateUserProfile(UserModel user) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users/update_user.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(user.toJson()),
      ).timeout(const Duration(seconds: 15));

      return _handleResponse(response, 'Profile updated');
    } catch (e) {
      return {'success': false, 'message': 'Connection error: ${e.toString()}'};
    }
  }

  // Fetch all users in a barangay
  Future<List<UserModel>> getUsersByBarangay(String barangayCode) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/users/get_users_by_barangay.php?barangay_code=$barangayCode',
        ),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => UserModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching barangay users: $e');
      return [];
    }
  }

  // Update user rescue status
  Future<Map<String, dynamic>> updateRescueStatus(
    int userId,
    String status,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users/update_rescue_status.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId, 'rescue_status': status}),
      ).timeout(const Duration(seconds: 15));

      return _handleResponse(response, 'Rescue status updated');
    } catch (e) {
      return {'success': false, 'message': 'Connection error: ${e.toString()}'};
    }
  }

  // Update user location
  Future<Map<String, dynamic>> updateUserLocation(
    int userId,
    double latitude,
    double longitude,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users/update_location.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'latitude': latitude,
          'longitude': longitude,
        }),
      ).timeout(const Duration(seconds: 15));

      return _handleResponse(response, 'Location updated');
    } catch (e) {
      return {'success': false, 'message': 'Connection error: ${e.toString()}'};
    }
  }

  // Search users
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/search_users.php?q=$query'),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => UserModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error searching users: $e');
      return [];
    }
  }

  // Create a new family group
  Future<Map<String, dynamic>> createFamily(
    int userId,
    String familyName,
    String primaryContact,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/families/create_family.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'family_name': familyName,
          'primary_contact': primaryContact,
        }),
      ).timeout(const Duration(seconds: 15));

      final result = _handleResponse(response, 'Family created successfully');
      if (result['success'] == true && result['family'] != null) {
        result['family'] = FamilyModel.fromJson(result['family']);
      }
      return result;
    } catch (e) {
      return {'success': false, 'message': 'Connection error: ${e.toString()}'};
    }
  }

  // Add a family member
  Future<Map<String, dynamic>> addFamilyMember(
    int familyId,
    int requesterId,
    String contactNumber,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/families/add_family_member.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'family_id': familyId,
          'requester_id': requesterId,
          'contact_number': contactNumber,
        }),
      ).timeout(const Duration(seconds: 15));

      return _handleResponse(response, 'Member added successfully');
    } catch (e) {
      return {'success': false, 'message': 'Connection error: ${e.toString()}'};
    }
  }

  // Report missing family member
  Future<Map<String, dynamic>> reportMissing(
    int familyId,
    int reporterId,
    int missingCount,
    String notes,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/families/report_missing.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'family_id': familyId,
          'reported_by': reporterId,
          'missing_count': missingCount,
          'notes': notes,
        }),
      ).timeout(const Duration(seconds: 15));

      return _handleResponse(response, 'Missing report submitted');
    } catch (e) {
      return {'success': false, 'message': 'Connection error: ${e.toString()}'};
    }
  }

  // Get family details including members
  Future<Map<String, dynamic>> getFamily(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/families/get_family.php?user_id=$userId'),
      ).timeout(const Duration(seconds: 15));

      final result = _handleResponse(response, 'Family fetched');
      if (result['success'] == true && result['family'] != null) {
        result['family'] = FamilyModel.fromJson(result['family']);
      }
      return result;
    } catch (e) {
      return {'success': false, 'message': 'Connection error: ${e.toString()}'};
    }
  }

}



