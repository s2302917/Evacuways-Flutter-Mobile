import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/alert_model.dart';

/// AlertController handles alert management logic
class AlertController {
  static const String baseUrl = 'https://5zu.758.mytemp.website/Evacuways/api';

  // Fetch all active alerts
  Future<List<AlertModel>> getActiveAlerts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/alerts/get_alerts.php'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => AlertModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching alerts: $e');
      return [];
    }
  }

  // Fetch alerts by severity level
  Future<List<AlertModel>> getAlertsBySeverity(String severity) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/alerts/get_alerts_by_severity.php?severity=$severity',
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => AlertModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching severity alerts: $e');
      return [];
    }
  }

  // Create new alert
  Future<Map<String, dynamic>> createAlert(AlertModel alert) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/alerts/create_alert.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(alert.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': data['success'] ?? true,
          'message': data['message'] ?? 'Alert created successfully',
          'alert_id': data['alert_id'],
        };
      }
      return {'success': false, 'message': 'Failed to create alert'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Update alert status
  Future<Map<String, dynamic>> updateAlertStatus(
    int alertId,
    String status,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/alerts/update_alert.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'alert_id': alertId, 'status': status}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': data['success'] ?? true,
          'message': data['message'] ?? 'Alert updated',
        };
      }
      return {'success': false, 'message': 'Failed to update alert'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Delete alert
  Future<Map<String, dynamic>> deleteAlert(int alertId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/alerts/delete_alert.php?alert_id=$alertId'),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Alert deleted successfully'};
      }
      return {'success': false, 'message': 'Failed to delete alert'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
}
