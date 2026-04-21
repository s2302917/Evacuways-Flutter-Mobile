class MessageModel {
  final int messageId;
  final int? requestId;
  final String? senderType;
  final int? senderId;
  final String? receiverType;
  final int? receiverId;
  final String? senderName;
  final String? receiverName;
  final String? messageText;
  final String? imagePath;
  final double? latitude;
  final double? longitude;
  final String? senderRole;
  final DateTime sentAt;
  final bool isRead;

  MessageModel({
    required this.messageId,
    this.requestId,
    this.senderType,
    this.senderId,
    this.receiverType,
    this.receiverId,
    this.senderName,
    this.receiverName,
    this.messageText,
    this.imagePath,
    this.latitude,
    this.longitude,
    this.senderRole,
    required this.sentAt,
    this.isRead = true,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      messageId: json['message_id'] ?? 0,
      requestId: json['request_id'],
      senderType: json['sender_type'],
      senderId: json['sender_id'],
      receiverType: json['receiver_type'],
      receiverId: json['receiver_id'],
      senderName: json['sender_name'],
      receiverName: json['receiver_name'],
      messageText: json['message_text'],
      imagePath: json['image_path'],
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null,
      senderRole: json['sender_role'],
      sentAt: json['sent_at'] != null
          ? DateTime.parse(json['sent_at'])
          : DateTime.now(),
      isRead: (json['is_read']?.toString() == '1'),
    );
  }

  Map<String, dynamic> toJson() => {
    'message_id': messageId,
    'request_id': requestId,
    'sender_type': senderType,
    'sender_id': senderId,
    'receiver_type': receiverType,
    'receiver_id': receiverId,
    'sender_name': senderName,
    'receiver_name': receiverName,
    'message_text': messageText,
    'image_path': imagePath,
    'latitude': latitude,
    'longitude': longitude,
    'sender_role': senderRole,
    'sent_at': sentAt.toIso8601String(),
    'is_read': isRead ? 1 : 0,
  };

  MessageModel copyWith({
    int? messageId,
    int? requestId,
    String? senderType,
    int? senderId,
    String? receiverType,
    int? receiverId,
    String? senderName,
    String? receiverName,
    String? messageText,
    String? imagePath,
    double? latitude,
    double? longitude,
    String? senderRole,
    DateTime? sentAt,
    bool? isRead,
  }) {
    return MessageModel(
      messageId: messageId ?? this.messageId,
      requestId: requestId ?? this.requestId,
      senderType: senderType ?? this.senderType,
      senderId: senderId ?? this.senderId,
      receiverType: receiverType ?? this.receiverType,
      receiverId: receiverId ?? this.receiverId,
      senderName: senderName ?? this.senderName,
      receiverName: receiverName ?? this.receiverName,
      messageText: messageText ?? this.messageText,
      imagePath: imagePath ?? this.imagePath,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      senderRole: senderRole ?? this.senderRole,
      sentAt: sentAt ?? this.sentAt,
      isRead: isRead ?? this.isRead,
    );
  }
}
