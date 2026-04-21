import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../models/message_model.dart';
import '../models/sos_request_model.dart';
import '../models/alert_model.dart';
import 'auth_controller.dart';

// ─── Isolate helpers (run JSON parsing off the UI thread) ────────────────────

List<MessageModel> _parseMessages(String body) {
  final data = jsonDecode(body);
  if (data is Map && data['success'] == true && data['messages'] != null) {
    return (data['messages'] as List)
        .map((m) => MessageModel.fromJson(m))
        .toList();
  }
  return [];
}

List<AlertModel> _parseAlerts(String body) {
  final data = jsonDecode(body);
  if (data is List) {
    return data.map((e) => AlertModel.fromJson(e)).toList();
  }
  return [];
}

List<SosRequestModel> _parseSosRequests(String body) {
  final data = jsonDecode(body);
  if (data is Map && data['success'] == true && data['requests'] != null) {
    return (data['requests'] as List)
        .map((r) => SosRequestModel.fromJson(r))
        .toList();
  }
  return [];
}

Map<String, dynamic> _parseContacts(String body) {
  final data = jsonDecode(body);
  if (data is Map && data['success'] == true && data['contacts'] != null) {
    return data['contacts'] as Map<String, dynamic>;
  }
  return {};
}

// ─── Fast equality: compare by ID only, O(1) for same-length same-order lists ─

bool _messageListsEqual(List<MessageModel> a, List<MessageModel> b) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i].messageId != b[i].messageId || a[i].isRead != b[i].isRead) {
      return false;
    }
  }
  return true;
}

bool _alertListsEqual(List<AlertModel> a, List<AlertModel> b) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i].alertId != b[i].alertId) return false;
  }
  return true;
}

bool _sosListsEqual(List<SosRequestModel> a, List<SosRequestModel> b) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i].requestId != b[i].requestId || a[i].status != b[i].status) {
      return false;
    }
  }
  return true;
}

// ─── ResourceController ───────────────────────────────────────────────────────

class ResourceController {
  static const String baseUrl = 'https://5zu.758.mytemp.website/Evacuways/api';

  // Persistent HTTP client — reuses TCP connections, much faster than one-off calls
  final http.Client _client = http.Client();

  // ── Granular notifiers: each screen listens to ONLY its relevant notifier ──
  final ValueNotifier<List<AlertModel>> alertsNotifier =
      ValueNotifier<List<AlertModel>>([]);
  final ValueNotifier<List<MessageModel>> inboxNotifier =
      ValueNotifier<List<MessageModel>>([]);
  final ValueNotifier<List<MessageModel>> chatNotifier =
      ValueNotifier<List<MessageModel>>([]);
  final ValueNotifier<List<SosRequestModel>> sosNotifier =
      ValueNotifier<List<SosRequestModel>>([]);
  final ValueNotifier<Map<String, List<Map<String, dynamic>>>> contactsNotifier =
      ValueNotifier<Map<String, List<Map<String, dynamic>>>>({
    "admins": [],
    "volunteers": [],
    "drivers": [],
    "personnel": [],
    "community": [],
  });

  // Loading states (granular, to prevent full rebuild on each)
  final ValueNotifier<bool> isAlertsLoadingNotifier = ValueNotifier(false);
  final ValueNotifier<bool> isMessagesLoadingNotifier = ValueNotifier(false);
  final ValueNotifier<bool> isSosLoadingNotifier = ValueNotifier(false);
  final ValueNotifier<bool> isSOSSubmittingNotifier = ValueNotifier(false);

  // Pre-processed inbox items (consumed by MessagesScreen)
  final ValueNotifier<List<Map<String, dynamic>>> processedInboxNotifier =
      ValueNotifier([]);

  // Unread alerts
  final ValueNotifier<bool> hasUnreadAlertsNotifier = ValueNotifier(false);
  List<int> _seenAlertIds = [];

  // In-flight de-duplication flags — prevents concurrent duplicate requests
  bool _isFetchingAlerts = false;
  bool _isFetchingInbox = false;
  bool _isFetchingChat = false;
  bool _isFetchingContacts = false;
  bool _isFetchingSos = false;

  // ── Convenience getters for backwards compatibility ────────────────────────
  List<AlertModel> get alerts => alertsNotifier.value;
  List<MessageModel> get inboxMessages => inboxNotifier.value;
  List<MessageModel> get chatMessages => chatNotifier.value;
  List<SosRequestModel> get sosRequests => sosNotifier.value;
  Map<String, List<Map<String, dynamic>>> get contacts => contactsNotifier.value;
  List<Map<String, dynamic>> get processedInboxItems => processedInboxNotifier.value;
  bool get hasUnreadAlerts => hasUnreadAlertsNotifier.value;
  bool get isAlertsLoading => isAlertsLoadingNotifier.value;
  bool get isMessagesLoading => isMessagesLoadingNotifier.value;
  bool get isSosHistoryLoading => isSosLoadingNotifier.value;
  bool get isSOSLoading => isSOSSubmittingNotifier.value;

  void markAlertsAsRead() {
    _seenAlertIds = alerts.map((a) => a.alertId).toList();
    hasUnreadAlertsNotifier.value = false;
  }

  // ── HTTP helper with timeout ───────────────────────────────────────────────

  Future<http.Response> _get(String url) async {
    return _client
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 10));
  }

  Future<http.Response> _post(String url, Map<String, dynamic> body) async {
    return _client
        .post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 10));
  }

  // ── Fetch Alerts ──────────────────────────────────────────────────────────

  Future<void> fetchAlerts() async {
    if (_isFetchingAlerts) return; // Skip if already in-flight
    _isFetchingAlerts = true;

    if (alerts.isEmpty) isAlertsLoadingNotifier.value = true;

    try {
      final response = await _get('$baseUrl/alerts/get_alerts.php');
      if (response.statusCode == 200) {
        final fetched = await compute(_parseAlerts, response.body);
        if (!_alertListsEqual(alerts, fetched)) {
          alertsNotifier.value = fetched;
          // Update unread badge
          final hasNew = fetched.any((a) => !_seenAlertIds.contains(a.alertId));
          hasUnreadAlertsNotifier.value = hasNew;
        }
      }
    } catch (e) {
      debugPrint('[ResourceController] fetchAlerts error: $e');
    } finally {
      _isFetchingAlerts = false;
      if (isAlertsLoadingNotifier.value) isAlertsLoadingNotifier.value = false;
    }
  }

  // ── Fetch Contacts ────────────────────────────────────────────────────────

  Future<void> fetchContacts() async {
    final user = authController.currentUser;
    if (user == null || _isFetchingContacts) return;
    _isFetchingContacts = true;

    try {
      final response = await _get(
          '$baseUrl/messages/get_contacts.php?user_id=${user.userId}');
      if (response.statusCode == 200) {
        final raw = await compute(_parseContacts, response.body);
        if (raw.isNotEmpty) {
          final newContacts = raw.map((key, value) => MapEntry(
                key,
                (value as List)
                    .map((e) => Map<String, dynamic>.from(e))
                    .toList(),
              ));

          if (jsonEncode(contacts) != jsonEncode(newContacts)) {
            contactsNotifier.value = newContacts;
            _processInboxItems();
          }
        }
      }
    } catch (e) {
      debugPrint('[ResourceController] fetchContacts error: $e');
    } finally {
      _isFetchingContacts = false;
    }
  }

  // ── Fetch Messages (inbox or chat) ────────────────────────────────────────

  Future<void> fetchMessages({int? otherUserId, String otherUserType = 'user'}) async {
    final user = authController.currentUser;
    if (user == null) return;

    final isChat = otherUserId != null;

    // De-duplicate
    if (isChat && _isFetchingChat) return;
    if (!isChat && _isFetchingInbox) return;

    if (isChat) {
      _isFetchingChat = true;
      if (chatMessages.isEmpty) isMessagesLoadingNotifier.value = true;
    } else {
      _isFetchingInbox = true;
      if (inboxMessages.isEmpty) isMessagesLoadingNotifier.value = true;
    }

    try {
      String url = '$baseUrl/messages/get_messages.php?user_id=${user.userId}';
      if (isChat) {
        url += '&other_user_id=$otherUserId&other_user_type=$otherUserType';
      }

      final response = await _get(url);
      if (response.statusCode == 200) {
        final fetched = await compute(_parseMessages, response.body);

        if (isChat) {
          if (!_messageListsEqual(chatMessages, fetched)) {
            chatNotifier.value = fetched;
          }
        } else {
          if (!_messageListsEqual(inboxMessages, fetched)) {
            inboxNotifier.value = fetched;
            _processInboxItems();
          }
        }
      }
    } catch (e) {
      debugPrint('[ResourceController] fetchMessages error: $e');
    } finally {
      if (isChat) {
        _isFetchingChat = false;
      } else {
        _isFetchingInbox = false;
      }
      if (isMessagesLoadingNotifier.value) {
        isMessagesLoadingNotifier.value = false;
      }
    }
  }

  // ── Fetch SOS History ─────────────────────────────────────────────────────

  Future<void> fetchSosRequests() async {
    final user = authController.currentUser;
    if (user == null || _isFetchingSos) return;
    _isFetchingSos = true;

    if (sosRequests.isEmpty) isSosLoadingNotifier.value = true;

    try {
      final response = await _get(
          '$baseUrl/sos/get_sos_requests.php?user_id=${user.userId}');
      if (response.statusCode == 200) {
        final fetched = await compute(_parseSosRequests, response.body);
        if (!_sosListsEqual(sosRequests, fetched)) {
          sosNotifier.value = fetched;
        }
      }
    } catch (e) {
      debugPrint('[ResourceController] fetchSosRequests error: $e');
    } finally {
      _isFetchingSos = false;
      if (isSosLoadingNotifier.value) isSosLoadingNotifier.value = false;
    }
  }

  // ── Submit SOS ────────────────────────────────────────────────────────────

  Future<String?> submitSOS({
    required String requestType,
    required String subject,
    required String message,
    double? latitude,
    double? longitude,
  }) async {
    final user = authController.currentUser;
    if (user == null) return "User session not found. Please log in again.";

    isSOSSubmittingNotifier.value = true;

    try {
      Position? position;
      if (latitude == null || longitude == null) {
        try {
          position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
            ),
          ).timeout(const Duration(seconds: 5));
        } catch (e) {
          debugPrint('[ResourceController] Location fetch error: $e');
        }
      }

      final response = await _post('$baseUrl/sos/submit_request.php', {
        'user_id': user.userId,
        'request_type': requestType,
        'subject': subject,
        'message': message,
        'latitude': latitude ?? position?.latitude,
        'longitude': longitude ?? position?.longitude,
      });

      final data = jsonDecode(response.body);
      if (response.statusCode == 201 || response.statusCode == 200) {
        await fetchSosRequests();
        return null;
      }
      return data['message'] ?? 'Failed to submit SOS request';
    } catch (e) {
      return "Network error: $e";
    } finally {
      isSOSSubmittingNotifier.value = false;
    }
  }

  // ── Cancel SOS ────────────────────────────────────────────────────────────

  Future<bool> cancelSosRequest(int requestId) async {
    final user = authController.currentUser;
    if (user == null) return false;

    try {
      final response = await _post('$baseUrl/sos/cancel_sos.php', {
        'request_id': requestId,
        'user_id': user.userId,
      });
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // Optimistic local update
          final updated = sosRequests.map((r) {
            if (r.requestId == requestId) {
              return SosRequestModel(
                requestId: r.requestId,
                userId: r.userId,
                subject: r.subject,
                message: r.message,
                requestType: r.requestType,
                status: 'Cancelled',
                createdAt: r.createdAt,
              );
            }
            return r;
          }).toList();
          sosNotifier.value = updated;
          return true;
        }
      }
    } catch (e) {
      debugPrint('[ResourceController] cancelSos error: $e');
    }
    return false;
  }

  // ── Send Message (with optimistic UI update) ──────────────────────────────

  Future<bool> sendMessage(String text,
      {int? receiverId,
      String receiverType = 'user',
      String? senderRole}) async {
    final user = authController.currentUser;
    if (user == null) return false;

    // Optimistic: add to chatMessages immediately so UI feels instant
    final optimisticMsg = MessageModel(
      messageId: -DateTime.now().millisecondsSinceEpoch, // temp negative ID
      senderId: user.userId,
      senderType: 'user',
      receiverId: receiverId,
      receiverType: receiverType,
      messageText: text,
      sentAt: DateTime.now(),
      isRead: true,
      senderRole: senderRole ?? user.role,
    );
    chatNotifier.value = [...chatMessages, optimisticMsg];

    try {
      final response = await _post('$baseUrl/messages/send_message.php', {
        'sender_id': user.userId,
        'receiver_id': receiverId,
        'sender_type': 'user',
        'receiver_type': receiverType,
        'message_text': text,
        'sender_role': senderRole ?? user.role,
      });

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Replace optimistic with real data
        await fetchMessages(otherUserId: receiverId, otherUserType: receiverType);
        return true;
      }
    } catch (e) {
      debugPrint('[ResourceController] sendMessage error: $e');
      // Rollback optimistic update on failure
      chatNotifier.value =
          chatMessages.where((m) => m.messageId != optimisticMsg.messageId).toList();
    }
    return false;
  }

  // ── Send Location ─────────────────────────────────────────────────────────

  Future<bool> sendLocation(
      {int? receiverId,
      String receiverType = 'user',
      required double lat,
      required double lng}) async {
    final user = authController.currentUser;
    if (user == null) return false;

    try {
      final response = await _post('$baseUrl/messages/send_message.php', {
        'sender_id': user.userId,
        'receiver_id': receiverId,
        'sender_type': 'user',
        'receiver_type': receiverType,
        'message_text': 'Shared my location',
        'latitude': lat,
        'longitude': lng,
        'sender_role': user.role,
      });

      if (response.statusCode == 201 || response.statusCode == 200) {
        await fetchMessages(otherUserId: receiverId, otherUserType: receiverType);
        return true;
      }
    } catch (e) {
      debugPrint('[ResourceController] sendLocation error: $e');
    }
    return false;
  }

  // ── Send Image ────────────────────────────────────────────────────────────

  Future<bool> sendImage(String imagePath,
      {int? receiverId,
      String receiverType = 'user',
      String? text}) async {
    final user = authController.currentUser;
    if (user == null) return false;

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/messages/upload_chat_image.php'),
      );
      request.files
          .add(await http.MultipartFile.fromPath('image', imagePath));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['image_path'] != null) {
          final msgRes = await _post('$baseUrl/messages/send_message.php', {
            'sender_id': user.userId,
            'receiver_id': receiverId,
            'sender_type': 'user',
            'receiver_type': receiverType,
            'message_text': text ?? 'Sent an image',
            'image_path': data['image_path'],
            'sender_role': user.role,
          });

          if (msgRes.statusCode == 201 || msgRes.statusCode == 200) {
            await fetchMessages(
                otherUserId: receiverId, otherUserType: receiverType);
            return true;
          }
        }
      }
    } catch (e) {
      debugPrint('[ResourceController] sendImage error: $e');
    }
    return false;
  }

  // ── Delete Conversation ───────────────────────────────────────────────────

  Future<bool> deleteConversation(int otherUserId,
      {String otherUserType = 'user'}) async {
    final user = authController.currentUser;
    if (user == null) return false;

    try {
      final response =
          await _post('$baseUrl/messages/delete_conversation.php', {
        'user_id': user.userId,
        'other_user_id': otherUserId,
        'other_user_type': otherUserType,
      });
      if (response.statusCode == 200) {
        // Optimistic: remove locally
        inboxNotifier.value = inboxMessages
            .where((m) =>
                !((m.senderId == user.userId && m.receiverId == otherUserId) ||
                    (m.senderId == otherUserId && m.receiverId == user.userId)))
            .toList();
        chatNotifier.value = [];
        _processInboxItems();
        return true;
      }
    } catch (e) {
      debugPrint('[ResourceController] deleteConversation error: $e');
    }
    return false;
  }

  // ── Mark As Read ──────────────────────────────────────────────────────────

  Future<void> markAsRead(int otherUserId,
      {String otherUserType = 'user'}) async {
    final user = authController.currentUser;
    if (user == null) return;

    bool changed = false;

    final updatedInbox = inboxMessages.map((m) {
      if (m.senderId == otherUserId &&
          m.senderType == otherUserType &&
          !m.isRead) {
        changed = true;
        return m.copyWith(isRead: true);
      }
      return m;
    }).toList();

    final updatedChat = chatMessages.map((m) {
      if (m.senderId == otherUserId &&
          m.senderType == otherUserType &&
          !m.isRead) {
        return m.copyWith(isRead: true);
      }
      return m;
    }).toList();

    if (changed) {
      inboxNotifier.value = updatedInbox;
      chatNotifier.value = updatedChat;
      _processInboxItems();

      // Fire-and-forget backend update
      _post('$baseUrl/messages/mark_read.php', {
        'user_id': user.userId,
        'other_user_id': otherUserId,
        'other_user_type': otherUserType,
      }).catchError((Object e) {
        debugPrint('[ResourceController] markAsRead error: $e');
        return http.Response('', 500);
      });
    }
  }

  // ── Process Inbox Items (pre-compute for MessagesScreen) ──────────────────

  void _processInboxItems() {
    final user = authController.currentUser;
    if (user == null) return;

    final Map<String, MessageModel> lastMessages = {};
    for (var m in inboxMessages) {
      final isMe = m.senderId == user.userId;
      final otherId = isMe ? (m.receiverId ?? 0) : (m.senderId ?? 0);
      final otherType =
          isMe ? (m.receiverType ?? 'user') : (m.senderType ?? 'user');
      if (otherId == 0) continue;

      final key = "${otherId}_$otherType";
      if (!lastMessages.containsKey(key) ||
          m.sentAt.isAfter(lastMessages[key]!.sentAt)) {
        lastMessages[key] = m;
      }
    }

    final List<Map<String, dynamic>> items = [];
    final Set<String> processedKeys = {};

    for (var key in lastMessages.keys) {
      final msg = lastMessages[key]!;
      final isMe = msg.senderId == user.userId;
      final partnerType =
          isMe ? (msg.receiverType ?? 'user') : (msg.senderType ?? 'user');
      final otherId =
          isMe ? (msg.receiverId ?? 0) : (msg.senderId ?? 0);
      final partnerName = isMe
          ? (msg.receiverName ?? 'User $otherId')
          : (msg.senderName ?? 'User $otherId');

      items.add({
        'userId': otherId,
        'receiverType': partnerType,
        'name': partnerName,
        'preview': (msg.imagePath != null && msg.imagePath!.isNotEmpty)
            ? '📷 Photo'
            : (msg.messageText?.isNotEmpty == true
                ? msg.messageText!
                : 'Sent a message'),
        'sentAt': msg.sentAt,
        'isUnread': !msg.isRead && !isMe,
        'role': isMe ? null : msg.senderRole,
        'partnerType': partnerType,
      });
      processedKeys.add(key);
    }

    // Add important contacts not yet in threads
    void addContact(String category, String rType) {
      final list = contacts[category] ?? [];
      for (var c in list) {
        final id = int.tryParse(c['user_id'].toString()) ?? 0;
        final key = "${id}_$rType";
        if (!processedKeys.contains(key)) {
          final n =
              "${c['first_name'] ?? ''} ${c['last_name'] ?? ''}".trim();
          items.add({
            'userId': id,
            'receiverType': rType,
            'name': n.isEmpty ? 'Unknown' : n,
            'preview': 'Start a conversation...',
            'sentAt': DateTime(2000),
            'isUnread': false,
            'role': c['role']?.toString(),
            'partnerType': rType,
            'isOfficial': true,
          });
          processedKeys.add(key);
        }
      }
    }

    addContact('admins', 'admin');
    addContact('volunteers', 'user');
    addContact('drivers', 'user');

    items.sort(
        (a, b) => (b['sentAt'] as DateTime).compareTo(a['sentAt'] as DateTime));
    processedInboxNotifier.value = items;
  }

  void dispose() {
    _client.close();
    alertsNotifier.dispose();
    inboxNotifier.dispose();
    chatNotifier.dispose();
    sosNotifier.dispose();
    contactsNotifier.dispose();
    processedInboxNotifier.dispose();
    isAlertsLoadingNotifier.dispose();
    isMessagesLoadingNotifier.dispose();
    isSosLoadingNotifier.dispose();
    isSOSSubmittingNotifier.dispose();
    hasUnreadAlertsNotifier.dispose();
  }
}

final ResourceController resourceController = ResourceController();
