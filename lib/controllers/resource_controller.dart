import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../models/message_model.dart';
import '../models/sos_request_model.dart';
import '../models/alert_model.dart';
import 'auth_controller.dart';

class ResourceController extends ChangeNotifier {
  static const String baseUrl = 'https://5zu.758.mytemp.website/Evacuways/api';

  bool isSOSLoading = false;
  bool isSosHistoryLoading = false;
  bool isMessagesLoading = false;
  bool isContactsLoading = false;
  bool isAlertsLoading = false;
  List<MessageModel> inboxMessages = [];
  List<MessageModel> chatMessages = [];
  List<SosRequestModel> sosRequests = [];
  List<AlertModel> alerts = [];
  List<int> seenAlertIds = [];

  bool get hasUnreadAlerts => alerts.any((a) => !seenAlertIds.contains(a.alertId));

  void markAlertsAsRead() {
    seenAlertIds = alerts.map((a) => a.alertId).toList();
    notifyListeners();
  }
  Map<String, List<Map<String, dynamic>>> contacts = {
    "admins": [],
    "volunteers": [],
    "drivers": [],
    "personnel": [],
    "community": []
  };

  // Fetch categorized contacts for new conversations
  Future<void> fetchContacts() async {
    final user = authController.currentUser;
    if (user == null) return;

    isContactsLoading = true;
    notifyListeners();

    try {
      final response = await http.get(Uri.parse('$baseUrl/messages/get_contacts.php?user_id=${user.userId}'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['contacts'] != null) {
          final raw = data['contacts'] as Map<String, dynamic>;
          contacts = raw.map((key, value) => MapEntry(
            key, 
            (value as List).map((e) => Map<String, dynamic>.from(e)).toList()
          ));
        }
      }
    } catch (e) {
      debugPrint('FETCH CONTACTS ERROR: $e');
    } finally {
      isContactsLoading = false;
      notifyListeners();
    }
  }

  // Fetch Alerts
  Future<void> fetchAlerts() async {
    isAlertsLoading = true;
    notifyListeners();

    try {
      final response = await http.get(Uri.parse('$baseUrl/alerts/get_alerts.php'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          alerts = data.map((e) => AlertModel.fromJson(e)).toList();
        }
      }
    } catch (e) {
      debugPrint('FETCH ALERTS ERROR: $e');
    } finally {
      isAlertsLoading = false;
      notifyListeners();
    }
  }

  // SOS Submission
  Future<String?> submitSOS({
    required String requestType,
    required String subject,
    required String message,
    double? latitude,
    double? longitude,
  }) async {
    final user = authController.currentUser;
    if (user == null) return "User session not found. Please log in again.";
    
    isSOSLoading = true;
    notifyListeners();
    
    try {
      // 1. Fetch Location if not provided
      Position? position;
      if (latitude == null || longitude == null) {
        try {
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 5),
          );
        } catch (e) {
          debugPrint('LOCATION FETCH ERROR FOR SOS: $e');
        }
      }

      final response = await http.post(
        Uri.parse('$baseUrl/sos/submit_request.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': user.userId,
          'request_type': requestType,
          'subject': subject,
          'message': message,
          'latitude': latitude ?? position?.latitude,
          'longitude': longitude ?? position?.longitude,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 201 || response.statusCode == 200) {
        await fetchSosRequests(); // refresh history immediately
        return null; // success
      }
      return data['message'] ?? 'Failed to submit SOS request';
    } catch (e) {
      return "Network error: $e";
    } finally {
      isSOSLoading = false;
      notifyListeners();
    }
  }

  // Fetch SOS History
  Future<void> fetchSosRequests() async {
    final user = authController.currentUser;
    if (user == null) return;

    isSosHistoryLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/sos/get_sos_requests.php?user_id=${user.userId}'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['requests'] != null) {
          sosRequests = (data['requests'] as List)
              .map((r) => SosRequestModel.fromJson(r))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('FETCH SOS HISTORY ERROR: $e');
    } finally {
      isSosHistoryLoading = false;
      notifyListeners();
    }
  }

  // Cancel SOS
  Future<bool> cancelSosRequest(int requestId) async {
    final user = authController.currentUser;
    if (user == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/sos/cancel_sos.php'),
        body: jsonEncode({
          'request_id': requestId,
          'user_id': user.userId,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // Update local list
          final idx = sosRequests.indexWhere((r) => r.requestId == requestId);
          if (idx != -1) {
            sosRequests[idx] = SosRequestModel(
              requestId: sosRequests[idx].requestId,
              userId: sosRequests[idx].userId,
              subject: sosRequests[idx].subject,
              message: sosRequests[idx].message,
              requestType: sosRequests[idx].requestType,
              status: 'Cancelled',
              createdAt: sosRequests[idx].createdAt,
            );
            notifyListeners();
          }
          return true;
        }
      }
    } catch (e) {
      debugPrint('CANCEL SOS ERROR: $e');
    }
    return false;
  }

  // Fetch Messages
  Future<void> fetchMessages({int? otherUserId, String otherUserType = 'user'}) async {
    final user = authController.currentUser;
    if (user == null) return;

    isMessagesLoading = true;
    notifyListeners();

    try {
      String url = '$baseUrl/messages/get_messages.php?user_id=${user.userId}';
      if (otherUserId != null) {
        url += '&other_user_id=$otherUserId&other_user_type=$otherUserType';
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['messages'] != null) {
          final fetched = (data['messages'] as List)
              .map((m) => MessageModel.fromJson(m))
              .toList();
          
          if (otherUserId != null) {
            chatMessages = fetched;
          } else {
            inboxMessages = fetched;
          }
        }
      }
    } catch (e) {
      debugPrint('FETCH MESSAGES ERROR: $e');
    } finally {
      isMessagesLoading = false;
      notifyListeners();
    }
  }

  // Send Message
  Future<bool> sendMessage(String text, {int? receiverId, String receiverType = 'user', String? senderRole}) async {
    final user = authController.currentUser;
    if (user == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/messages/send_message.php'),
        body: jsonEncode({
          'sender_id': user.userId,
          'receiver_id': receiverId,
          'sender_type': 'user',
          'receiver_type': receiverType,
          'message_text': text,
          'sender_role': senderRole ?? user.role,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        await fetchMessages(otherUserId: receiverId, otherUserType: receiverType);
        return true;
      }
    } catch (e) {
      debugPrint('SEND MESSAGE ERROR: $e');
    }
    return false;
  }

  // Send Location
  Future<bool> sendLocation({int? receiverId, String receiverType = 'user', required double lat, required double lng}) async {
    final user = authController.currentUser;
    if (user == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/messages/send_message.php'),
        body: jsonEncode({
          'sender_id': user.userId,
          'receiver_id': receiverId,
          'sender_type': 'user',
          'receiver_type': receiverType,
          'message_text': 'Shared my location',
          'latitude': lat,
          'longitude': lng,
          'sender_role': user.role,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        await fetchMessages(otherUserId: receiverId, otherUserType: receiverType);
        return true;
      }
    } catch (e) {
      debugPrint('SEND LOCATION ERROR: $e');
    }
    return false;
  }

  // Send Image
  Future<bool> sendImage(String imagePath, {int? receiverId, String receiverType = 'user', String? text}) async {
    final user = authController.currentUser;
    if (user == null) return false;

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/messages/upload_chat_image.php'),
      );
      request.files.add(await http.MultipartFile.fromPath('image', imagePath));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['image_path'] != null) {
          final msgRes = await http.post(
            Uri.parse('$baseUrl/messages/send_message.php'),
            body: jsonEncode({
              'sender_id': user.userId,
              'receiver_id': receiverId,
              'sender_type': 'user',
              'receiver_type': receiverType,
              'message_text': text ?? 'Sent an image',
              'image_path': data['image_path'],
              'sender_role': user.role,
            }),
          );
          
          if (msgRes.statusCode == 201 || msgRes.statusCode == 200) {
            await fetchMessages(otherUserId: receiverId, otherUserType: receiverType);
            return true;
          }
        }
      }
    } catch (e) {
      debugPrint('SEND IMAGE ERROR: $e');
    }
    return false;
  }

  // Delete Conversation
  Future<bool> deleteConversation(int otherUserId, {String otherUserType = 'user'}) async {
    final user = authController.currentUser;
    if (user == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/messages/delete_conversation.php'),
        body: jsonEncode({
          'user_id': user.userId,
          'other_user_id': otherUserId,
          'other_user_type': otherUserType,
        }),
      );
      if (response.statusCode == 200) {
        inboxMessages.removeWhere((m) =>
            (m.senderId == user.userId && m.receiverId == otherUserId) ||
            (m.senderId == otherUserId && m.receiverId == user.userId));
        chatMessages.clear(); // If we delete the conversation we are viewing
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('DELETE CONVERSATION ERROR: $e');
    }
    return false;
  }

  // Mark Read
  Future<void> markAsRead(int otherUserId, {String otherUserType = 'user'}) async {
    final user = authController.currentUser;
    if (user == null) return;

    try {
      // Local update first for responsiveness
      bool changed = false;
      // Update both lists
      for (int i = 0; i < inboxMessages.length; i++) {
        var m = inboxMessages[i];
        if (m.senderId == otherUserId && m.senderType == otherUserType && !m.isRead) {
          inboxMessages[i] = m.copyWith(isRead: true);
          changed = true;
        }
      }
      for (int i = 0; i < chatMessages.length; i++) {
        var m = chatMessages[i];
        if (m.senderId == otherUserId && m.senderType == otherUserType && !m.isRead) {
          chatMessages[i] = m.copyWith(isRead: true);
          changed = true;
        }
      }
      if (changed) notifyListeners();

      // Backend update
      await http.post(
        Uri.parse('$baseUrl/messages/mark_read.php'),
        body: jsonEncode({
          'user_id': user.userId,
          'other_user_id': otherUserId,
          'other_user_type': otherUserType,
        }),
      );
    } catch (e) {
      debugPrint('MARK READ ERROR: $e');
    }
  }
}

final ResourceController resourceController = ResourceController();
