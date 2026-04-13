import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/family_model.dart';
import '../models/user_model.dart';

/// FamilyController handles family group management
class FamilyController {
  static const String baseUrl = 'https://5zu.758.mytemp.website/Evacuways/api';

  List<FamilyModel>? families;
  List<UserModel>? availableUsers;
  bool isLoading = false;
  String? errorMessage;

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

  // Create a new family
  Future<Map<String, dynamic>> createFamily(
    String familyName,
    String primaryContact,
    int userId,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/families/create_family.php'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'family_name': familyName,
              'primary_contact': primaryContact,
              'user_id': userId,
            }),
          )
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response, 'Family created successfully');
    } catch (e) {
      return {'success': false, 'message': 'Connection error: ${e.toString()}'};
    }
  }

  // Get families for current user
  Future<List<FamilyModel>> getFamiliesForUser(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/families/get_families.php?user_id=$userId'),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        families = data.map((json) => FamilyModel.fromJson(json)).toList();
        return families ?? [];
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching families: $e');
      return [];
    }
  }

  // Get family members
  Future<List<UserModel>> getFamilyMembers(int familyId) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/families/get_family_members.php?family_id=$familyId',
        ),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => UserModel.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching members: $e');
      return [];
    }
  }

  // Get all available users to add to family (not already in family)
  Future<List<UserModel>> getAllAvailableUsers(int familyId, int page) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/families/search_users.php?query=&family_id=$familyId&page=$page&limit=10',
        ),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        availableUsers = data.map((json) => UserModel.fromJson(json)).toList();
        return availableUsers ?? [];
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching all users: $e');
      return [];
    }
  }

  // Search available users to add to family
  Future<List<UserModel>> searchUsersForFamily(
    String query,
    int familyId,
    int page,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/families/search_users.php?query=$query&family_id=$familyId&page=$page&limit=10',
        ),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        availableUsers = data.map((json) => UserModel.fromJson(json)).toList();
        return availableUsers ?? [];
      }
      return [];
    } catch (e) {
      debugPrint('Error searching users: $e');
      return [];
    }
  }

  // Add user to family
  Future<Map<String, dynamic>> addUserToFamily(int familyId, int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/families/add_member.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'family_id': familyId, 'user_id': userId}),
      ).timeout(const Duration(seconds: 15));

      return _handleResponse(response, 'Member added successfully');
    } catch (e) {
      return {'success': false, 'message': 'Connection error: ${e.toString()}'};
    }
  }

  // Leave family
  Future<Map<String, dynamic>> leaveFamily(int familyId, int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/families/leave_family.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'family_id': familyId, 'user_id': userId}),
      ).timeout(const Duration(seconds: 15));

      return _handleResponse(response, 'Left family successfully');
    } catch (e) {
      return {'success': false, 'message': 'Connection error: ${e.toString()}'};
    }
  }

  // Report missing family member
  Future<Map<String, dynamic>> reportMissingMember(
    int familyId,
    int reporterId,
    int missingMemberId,
    String reason,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/families/report_missing.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'family_id': familyId,
          'reported_by': reporterId,
          'missing_count': 1,
          'notes': 'Member ID: $missingMemberId. Reason: $reason',
        }),
      ).timeout(const Duration(seconds: 15));

      return _handleResponse(response, 'Missing report submitted');
    } catch (e) {
      return {'success': false, 'message': 'Connection error: ${e.toString()}'};
    }
  }

  // Remove family member
  Future<Map<String, dynamic>> removeFamilyMember(
    int familyId,
    int requesterId,
    int targetUserId,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/families/remove_family_member.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'family_id': familyId,
          'requester_id': requesterId,
          'target_user_id': targetUserId,
        }),
      ).timeout(const Duration(seconds: 15));

      return _handleResponse(response, 'Member removed successfully');
    } catch (e) {
      return {'success': false, 'message': 'Connection error: ${e.toString()}'};
    }
  }

  // Update rescue status
  Future<Map<String, dynamic>> updateRescueStatus(
    int userId,
    String rescueStatus,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/update_rescue_status.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId, 'rescue_status': rescueStatus}),
      ).timeout(const Duration(seconds: 15));

      return _handleResponse(response, 'Rescue status updated');
    } catch (e) {
      return {'success': false, 'message': 'Connection error: ${e.toString()}'};
    }
  }
}
