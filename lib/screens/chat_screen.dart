import 'package:flutter/material.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../theme/app_colors.dart';
import '../controllers/resource_controller.dart';
import '../controllers/auth_controller.dart';
import '../models/message_model.dart';

class ChatScreen extends StatefulWidget {
  final int? otherUserId;
  final String receiverType;
  final String name;
  final String subtitle;
  final Color color;

  const ChatScreen({
    super.key,
    this.otherUserId,
    this.receiverType = 'user',
    required this.name,
    required this.subtitle,
    required this.color,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    // Initial fetch — polling is now handled by PollingService but we need
    // the chat-specific fetch (with otherUserId) to load this conversation.
    _fetchMessages();
    // Listen to chatNotifier to auto-scroll on new messages
    resourceController.chatNotifier.addListener(_onChatUpdated);
  }

  @override
  void dispose() {
    resourceController.chatNotifier.removeListener(_onChatUpdated);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onChatUpdated() {
    // Scroll to bottom when new messages arrive
    _scrollToBottom();
    // Smart mark-as-read: only fire if there are unread messages from partner
    if (widget.otherUserId != null) {
      final hasUnread = resourceController.chatMessages.any((m) =>
          m.senderId == widget.otherUserId &&
          m.senderType == widget.receiverType &&
          !m.isRead);
      if (hasUnread) {
        resourceController.markAsRead(widget.otherUserId!,
            otherUserType: widget.receiverType);
      }
    }
  }

  Future<void> _fetchMessages() async {
    await resourceController.fetchMessages(
      otherUserId: widget.otherUserId,
      otherUserType: widget.receiverType,
    );
    _scrollToBottom();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    // Optimistic send — message appears immediately in UI (handled in controller)
    await resourceController.sendMessage(
      text,
      receiverId: widget.otherUserId,
      receiverType: widget.receiverType,
    );
    _scrollToBottom();
  }

  Future<void> _pickImage() async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Image Source',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _SourceOption(
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    color: Colors.blue,
                    onTap: () => Navigator.pop(context, ImageSource.camera),
                  ),
                  _SourceOption(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    color: Colors.purple,
                    onTap: () => Navigator.pop(context, ImageSource.gallery),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (source != null) {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null && mounted) {
        _showImagePreview(image);
      }
    }
  }

  void _showImagePreview(XFile file) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Text(
                  'Send Image',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.file(
                      File(file.path),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (_isSending)
                  const Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('Uploading...',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('CANCEL'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            setDialogState(() => _isSending = true);
                            final success = await resourceController.sendImage(
                              file.path,
                              receiverId: widget.otherUserId,
                              receiverType: widget.receiverType,
                            );
                            if (mounted) {
                              setDialogState(() => _isSending = false);
                              Navigator.pop(context);
                              if (success) _scrollToBottom();
                            }
                          },
                          icon: const Icon(Icons.send, color: Colors.white),
                          label: const Text('SEND',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding:
                                const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _sendLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Location permissions are permanently denied. Enable in settings.')),
          );
        }
        return;
      }

      setState(() => _isSending = true);
      final position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final success = await resourceController.sendLocation(
        lat: position.latitude,
        lng: position.longitude,
        receiverId: widget.otherUserId,
        receiverType: widget.receiverType,
      );
      if (mounted) {
        setState(() => _isSending = false);
        if (success) _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $e')),
        );
      }
    }
  }

  Color _getRoleColor(String? role) {
    if (role == null) return AppColors.primary;
    switch (role.toLowerCase()) {
      case 'admin':
        return const Color(0xFFD32F2F);
      case 'volunteer':
        return const Color(0xFF388E3C);
      case 'vehicle driver':
      case 'driver':
        return const Color(0xFF1976D2);
      case 'personnel':
        return const Color(0xFFF57C00);
      default:
        return AppColors.primary;
    }
  }

  void _openMap(double lat, double lng) async {
    final url =
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final nameDisplay = widget.name.length >= 3
        ? widget.name.substring(0, 3).toUpperCase()
        : widget.name.toUpperCase();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            // ── App Bar ────────────────────────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(4, 10, 12, 10),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back,
                        color: AppColors.textPrimary),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        nameDisplay,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: widget.color,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                widget.subtitle,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.green,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.emergency,
                        color: AppColors.danger, size: 22),
                    onPressed: () =>
                        Navigator.pushNamed(context, '/sos'),
                  ),
                ],
              ),
            ),

            // ── Message List ───────────────────────────────────────────────
            Expanded(
              child: ValueListenableBuilder<List<MessageModel>>(
                valueListenable: resourceController.chatNotifier,
                builder: (context, messages, _) {
                  if (resourceController.isMessagesLoading &&
                      messages.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (messages.isEmpty) {
                    return const Center(
                      child: Text(
                        'No messages yet.\nSay hello! 👋',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: _fetchMessages,
                    child: ListView.builder(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      itemCount: messages.length,
                      itemBuilder: (context, i) =>
                          _buildMessage(messages[i]),
                    ),
                  );
                },
              ),
            ),

            // ── Input Bar ──────────────────────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _InputAction(
                      icon: Icons.image_outlined, onTap: _pickImage),
                  const SizedBox(width: 6),
                  _InputAction(
                      icon: Icons.location_on_outlined,
                      onTap: _sendLocation),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 120),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.inputFill,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TextField(
                          controller: _messageController,
                          maxLines: null,
                          decoration: const InputDecoration(
                            hintText: 'Type your message...',
                            hintStyle: TextStyle(
                                color: AppColors.textHint, fontSize: 14),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _isSending ? null : _sendMessage,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle),
                      child: _isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.send,
                              color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(MessageModel msg) {
    final user = authController.currentUser;
    final isMe = msg.senderId == user?.userId;
    // Optimistic messages have negative IDs — style them slightly dimmed
    final isOptimistic = msg.messageId < 0;
    final timeStr =
        "${msg.sentAt.hour}:${msg.sentAt.minute.toString().padLeft(2, '0')}";
    final bubbleColor =
        isMe ? AppColors.primary : _getRoleColor(msg.senderRole);

    // ── Image message ────────────────────────────────────────────────────
    if (msg.imagePath != null && msg.imagePath!.isNotEmpty) {
      const baseUrl = 'https://5zu.758.mytemp.website/Evacuways';
      final path = msg.imagePath!;
      final fullImagePath = path.startsWith('http')
          ? path
          : '$baseUrl/${path.startsWith('/') ? path.substring(1) : path}';

      return Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: EdgeInsets.only(
              bottom: 12, left: isMe ? 60 : 0, right: isMe ? 0 : 60),
          width: 220,
          decoration: BoxDecoration(
            color: bubbleColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: bubbleColor.withValues(alpha: 0.2)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Image.network(
                  fullImagePath,
                  height: 160,
                  fit: BoxFit.cover,
                  errorBuilder: (context, err, trace) => Container(
                    height: 100,
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image,
                        color: Colors.grey),
                  ),
                ),
                if (msg.messageText != null &&
                    msg.messageText!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(msg.messageText!,
                        style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textPrimary)),
                  ),
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(10, 0, 10, 8),
                  child: Text(timeStr,
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.textHint),
                      textAlign: TextAlign.right),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ── Location message ─────────────────────────────────────────────────
    if (msg.latitude != null && msg.longitude != null) {
      return Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: GestureDetector(
          onTap: () => _openMap(msg.latitude!, msg.longitude!),
          child: Container(
            margin: EdgeInsets.only(
                bottom: 12, left: isMe ? 60 : 0, right: isMe ? 0 : 60),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: bubbleColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text('SHARED LOCATION',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                            letterSpacing: 1)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Lat: ${msg.latitude!.toStringAsFixed(4)}, '
                  'Lng: ${msg.longitude!.toStringAsFixed(4)}',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 13),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 6, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('OPEN IN MAPS',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 11)),
                      SizedBox(width: 4),
                      Icon(Icons.open_in_new,
                          color: Colors.white, size: 14),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Text(timeStr,
                      style: const TextStyle(
                          fontSize: 10, color: Colors.white70)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ── Text message ─────────────────────────────────────────────────────
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Opacity(
        opacity: isOptimistic ? 0.6 : 1.0,
        child: Container(
          margin: EdgeInsets.only(
              bottom: 12, left: isMe ? 60 : 0, right: isMe ? 0 : 60),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMe ? 16 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 16),
            ),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 6),
            ],
          ),
          child: Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isMe && msg.senderRole != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    msg.senderRole!.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: Colors.white70,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              Text(
                msg.messageText ?? '',
                style: const TextStyle(
                    fontSize: 14, color: Colors.white, height: 1.4),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(timeStr,
                      style: const TextStyle(
                          fontSize: 10, color: Colors.white70)),
                  if (isOptimistic) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.access_time,
                        size: 10, color: Colors.white54),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Reusable sub-widgets ──────────────────────────────────────────────────────

class _InputAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _InputAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
            color: AppColors.inputFill, shape: BoxShape.circle),
        child: Icon(icon, color: AppColors.textSecondary, size: 18),
      ),
    );
  }
}

class _SourceOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SourceOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}
