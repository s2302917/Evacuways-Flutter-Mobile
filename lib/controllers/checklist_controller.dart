import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/checklist_model.dart';

/// ChecklistController handles checklist management
class ChecklistController {
  static const String baseUrl = 'https://5zu.758.mytemp.website/Evacuways/api';

  List<ChecklistModel>? checklists;
  bool isLoading = false;
  String? errorMessage;

  // Fetch and store all checklists
  Future<void> fetchAllChecklists() async {
    try {
      isLoading = true;
      errorMessage = null;
      checklists = await getAllChecklists();
      isLoading = false;
    } catch (e) {
      errorMessage = e.toString();
      isLoading = false;
      rethrow;
    }
  }

  // Fetch all checklists
  Future<List<ChecklistModel>> getAllChecklists() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/checklists/get_checklist.php'),
      );

      debugPrint('CHECKLIST API RESPONSE STATUS: ${response.statusCode}');
      debugPrint('CHECKLIST API RESPONSE BODY: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        debugPrint('PARSED CHECKLISTS COUNT: ${data.length}');
        final result = data
            .map((json) => ChecklistModel.fromJson(json))
            .toList();
        debugPrint('FINAL CHECKLISTS COUNT: ${result.length}');
        return result;
      }
      debugPrint('API returned status: ${response.statusCode}');
      return [];
    } catch (e) {
      debugPrint('Error fetching checklists: $e');
      rethrow;
    }
  }

  // Get checklist for children
  Future<List<ChecklistModel>> getChecklistsForChildren() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/checklists/get_checklists_for_children.php'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => ChecklistModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Get checklist for elderly
  Future<List<ChecklistModel>> getChecklistsForElderly() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/checklists/get_checklists_for_elderly.php'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => ChecklistModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Get checklist for PWD
  Future<List<ChecklistModel>> getChecklistsForPWD() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/checklists/get_checklists_for_pwd.php'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => ChecklistModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Get checklist details with items
  Future<Map<String, dynamic>?> getChecklistDetails(int checklistId) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/checklists/get_checklist.php?checklist_id=$checklistId',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching checklist details: $e');
      return null;
    }
  }

  // Mark user checklist as completed
  Future<Map<String, dynamic>> markChecklistCompleted(
    int userId,
    int checklistId,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/checklists/mark_completed.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId, 'checklist_id': checklistId}),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Checklist marked as completed'};
      }
      return {'success': false, 'message': 'Failed to update checklist'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Get user checklist progress
  Future<int?> getUserChecklistProgress(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/checklists/get_user_progress.php?user_id=$userId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['completed_count'] ?? 0;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Delete checklist
  Future<Map<String, dynamic>> deleteChecklist(int checklistId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/checklists/delete_checklist.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'checklist_id': checklistId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true, 
          'message': data['message'] ?? 'Checklist deleted successfully' 
        };
      }
      return {'success': false, 'message': 'Failed to delete checklist'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
}
