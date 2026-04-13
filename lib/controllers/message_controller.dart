import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/message_model.dart';

/// MessageController handles messaging and communication logic
class MessageController {
  static const String baseUrl = 'https://5zu.758.mytemp.website/Evacuways/api';

  // Helper method to handle HTTP responses
  Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      if (response.body.isEmpty) {
        return {'success': false, 'message': 'Empty server response'};
      }
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return {'success': true, 'data': decoded};
    } catch (e) {
      return {
        'success': false,
        'message': 'Invalid server response format'
      };
    }
  }

  // Fetch messages between users
  Future<List<MessageModel>> getMessages(int userId, int otherUserId) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/messages/get_messages.php?user_id=$userId&other_user_id=$otherUserId',
        ),
      ).timeout(const Duration(seconds: 15));

      final result = _handleResponse(response);
      if (result['success'] == true && result['messages'] != null) {
        final List<dynamic> messagesJson = result['messages'];
        return messagesJson.map((json) => MessageModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching messages: $e');
      return [];
    }
  }

  // Send message
  Future<Map<String, dynamic>> sendMessage(MessageModel message) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/messages/send_message.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(message.toJson()),
      ).timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Send message with image
  Future<Map<String, dynamic>> sendMessageWithImage(
    int senderId,
    String senderType,
    int receiverId,
    String receiverType,
    String? messageText,
    String imagePath,
    {String? senderRole}
  ) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/messages/upload_chat_image.php'),
      );

      request.files.add(await http.MultipartFile.fromPath('image', imagePath));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      final result = _handleResponse(response);
      
      if (result['success'] == true && result['image_path'] != null) {
        // Now send the actual message with the image path
        final message = MessageModel(
          messageId: 0,
          senderId: senderId,
          senderType: senderType,
          receiverId: receiverId,
          receiverType: receiverType,
          messageText: messageText,
          imagePath: result['image_path'],
          senderRole: senderRole,
          sentAt: DateTime.now(),
        );
        return await sendMessage(message);
      }
      
      return result;
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Get conversation list
  Future<List<Map<String, dynamic>>> getConversations(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/messages/get_conversations.php?user_id=$userId'),
      ).timeout(const Duration(seconds: 15));

      final result = _handleResponse(response);
      if (result['success'] == true && result['conversations'] != null) {
        return List<Map<String, dynamic>>.from(result['conversations']);
      }
      // Fallback if the API returns a direct list
      if (result['data'] is List) {
        return List<Map<String, dynamic>>.from(result['data']);
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching conversations: $e');
      return [];
    }
  }

  // Delete message
  Future<Map<String, dynamic>> deleteMessage(int messageId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/messages/delete_message.php?message_id=$messageId'),
      ).timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }
}
