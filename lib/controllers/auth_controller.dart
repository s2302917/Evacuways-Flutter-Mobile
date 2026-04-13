import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

// Helper class to ignore invalid SSL certificates from temporary GoDaddy URLs
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

class AuthController extends ChangeNotifier {
  // TODO: Replace with your actual GoDaddy domain
  static const String baseUrl = 'https://5zu.758.mytemp.website/Evacuways/api';

  UserModel? _currentUser;
  
  UserModel? get currentUser => _currentUser;
  
  set currentUser(UserModel? user) {
    _currentUser = user;
    notifyListeners();
  }

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

  Future<Map<String, dynamic>> login(
    String contactNumber,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contact_number': contactNumber,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 30));

      final result = _handleResponse(response, 'Login successful');
      if (result['success'] == true && (result['user'] != null || result['user_id'] != null)) {
        currentUser = UserModel.fromJson(result['user'] ?? result);
        return {
          'success': true,
          'message': 'Login successful',
          'user': currentUser,
        };
      }
      return {
        'success': false,
        'message': result['message'] ?? 'Login failed. Please check your credentials.',
      };
    } on TimeoutException {
      return {'success': false, 'message': 'Server is taking too long to respond. Please check your internet connection and try again.'};
    } catch (e) {
      debugPrint('LOGIN ERROR: $e');
      return {'success': false, 'message': 'Connection error. Please ensure you have internet access.'};
    }
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(userData),
      ).timeout(const Duration(seconds: 15));

      final result = _handleResponse(response, 'Registration successful');
      if (result['success'] == true && result['user'] != null) {
        currentUser = UserModel.fromJson(result['user']);
        return {
          'success': true,
          'message': 'Registration successful',
          'user': currentUser,
        };
      }
      return {
        'success': false,
        'message': result['message'] ?? 'Registration failed.',
      };
    } catch (e) {
      return {'success': false, 'message': 'Connection error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> sendForgotPasswordOTP(
    String contactNumber,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/forgot_password.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'contact_number': contactNumber}),
      ).timeout(const Duration(seconds: 15));

      return _handleResponse(response, 'OTP sent successfully');
    } catch (e) {
      return {'success': false, 'message': 'Connection error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> verifyOTP(
    String contactNumber,
    String otp,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify_otp.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'contact_number': contactNumber, 'otp': otp}),
      ).timeout(const Duration(seconds: 15));

      return _handleResponse(response, 'OTP verified successfully');
    } catch (e) {
      return {'success': false, 'message': 'Connection error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> resetPassword(
    String contactNumber,
    String otp,
    String newPassword,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/reset_password.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contact_number': contactNumber,
          'otp': otp,
          'new_password': newPassword,
        }),
      ).timeout(const Duration(seconds: 15));

      return _handleResponse(response, 'Password reset successfully');
    } catch (e) {
      return {'success': false, 'message': 'Connection error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> changePassword(
    int userId,
    String newPassword,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/change_password.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'new_password': newPassword,
        }),
      ).timeout(const Duration(seconds: 15));

      final result = _handleResponse(response, 'Password updated successfully');
      if (result['success'] == true) {
        // Update local state to reflect that the change is no longer mandatory
        if (currentUser != null && currentUser!.userId == userId) {
          currentUser = UserModel(
            userId: currentUser!.userId,
            familyId: currentUser!.familyId,
            firstName: currentUser!.firstName,
            lastName: currentUser!.lastName,
            gender: currentUser!.gender,
            birthDate: currentUser!.birthDate,
            contactNumber: currentUser!.contactNumber,
            cityId: currentUser!.cityId,
            barangayId: currentUser!.barangayId,
            regionCode: currentUser!.regionCode,
            cityCode: currentUser!.cityCode,
            barangayCode: currentUser!.barangayCode,
            centerId: currentUser!.centerId,
            headcount: currentUser!.headcount,
            isFamily: currentUser!.isFamily,
            missingCount: currentUser!.missingCount,
            rescueStatus: currentUser!.rescueStatus,
            assignedVehicleId: currentUser!.assignedVehicleId,
            assignedCenterId: currentUser!.assignedCenterId,
            latitude: currentUser!.latitude,
            longitude: currentUser!.longitude,
            deviceToken: currentUser!.deviceToken,
            role: currentUser!.role,
            createdAt: currentUser!.createdAt,
            mustChangePassword: false,
          );
        }
      }
      return result;
    } catch (e) {
      return {'success': false, 'message': 'Connection error: ${e.toString()}'};
    }
  }

  void logout() {
    currentUser = null;
  }
}

// Global instance for simple state management (or use Provider/Riverpod later)
final AuthController authController = AuthController();
