import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

// Helper class to ignore invalid SSL certificates
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

/// ApiService handles all HTTP API communication
/// This service provides a centralized location for all API calls
class ApiService {
  static const String baseUrl = 'https://5zu.758.mytemp.website/Evacuways/api';
  static final ApiService _instance = ApiService._internal();

  // HTTP client instance
  late http.Client _client;

  ApiService._internal() {
    _client = http.Client();
  }

  // Singleton pattern
  factory ApiService() {
    return _instance;
  }

  /// GET request
  Future<http.Response> get(String endpoint) async {
    try {
      final response = await _client.get(Uri.parse('$baseUrl$endpoint'));
      return response;
    } catch (e) {
      debugPrint('GET Error: $e');
      rethrow;
    }
  }

  /// POST request
  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      return response;
    } catch (e) {
      debugPrint('POST Error: $e');
      rethrow;
    }
  }

  /// PUT request
  Future<http.Response> put(String endpoint, Map<String, dynamic> body) async {
    try {
      final response = await _client.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      return response;
    } catch (e) {
      debugPrint('PUT Error: $e');
      rethrow;
    }
  }

  /// DELETE request
  Future<http.Response> delete(String endpoint) async {
    try {
      final response = await _client.delete(Uri.parse('$baseUrl$endpoint'));
      return response;
    } catch (e) {
      debugPrint('DELETE Error: $e');
      rethrow;
    }
  }

  /// Multipart POST request (for file uploads)
  Future<http.StreamedResponse> multipartPost(
    String endpoint,
    Map<String, String> fields,
    List<http.MultipartFile> files,
  ) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl$endpoint'),
      );
      request.fields.addAll(fields);
      request.files.addAll(files);
      final response = await request.send();
      return response;
    } catch (e) {
      debugPrint('Multipart POST Error: $e');
      rethrow;
    }
  }

  /// Check if response is successful
  static bool isSuccessful(int statusCode) {
    return statusCode >= 200 && statusCode < 300;
  }

  /// Parse JSON response
  static Map<String, dynamic> parseResponse(http.Response response) {
    try {
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Invalid response format'};
    }
  }
}

// ------------------------------------------------------------------
// REFACTORED FUNCTION BELOW
// ------------------------------------------------------------------

/// Reports missing individuals using the ApiService
Future<bool> reportMissing(int familyId, int reporterId, int missingCount, String notes) async {
  try {
    // 1. Get the singleton instance of your ApiService
    final apiService = ApiService();

    // 2. Pass the relative endpoint and the body
    final response = await apiService.post(
      '/families/report_missing.php',
      {
        'family_id': familyId,
        'reported_by': reporterId,
        'missing_count': missingCount,
        'notes': notes,
      },
    );

    // 3. Utilize the helper method you already built to check status
    return ApiService.isSuccessful(response.statusCode);
    
  } catch (e) {
    // Swapped print for debugPrint to match your ApiService error handling style
    debugPrint("Error reporting missing: $e");
    return false;
  }
}