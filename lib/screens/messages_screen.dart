import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/message_model.dart';
import '../controllers/auth_controller.dart';
import '../controllers/resource_controller.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  Timer? _refreshTimer;
  final Set<String> _dismissedKeys = {};

  @override
  void initState() {
    super.initState();
    resourceController.fetchMessages();
    resourceController.fetchContacts();
    
    // Polling for inbox updates every 10 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        resourceController.fetchMessages();
        resourceController.fetchContacts();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person,
                              color: AppColors.primary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Messages',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.search,
                              color: AppColors.textSecondary,
                            ),
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.emergency,
                              color: AppColors.danger,
                            ),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: ListenableBuilder(
                    listenable: resourceController,
                    builder: (context, _) {
                      if (resourceController.isMessagesLoading &&
                          resourceController.inboxMessages.isEmpty) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final user = authController.currentUser;
                      if (user == null) return const SizedBox.shrink();

                      // 1. Extract existing threads
                      final Map<String, MessageModel> lastMessages = {};
                      for (var m in resourceController.inboxMessages) {
                        final isMe = m.senderId == user.userId;
                        final otherId = isMe ? (m.receiverId ?? 0) : (m.senderId ?? 0);
                        final otherType = isMe ? (m.receiverType ?? 'user') : (m.senderType ?? 'user');
                        if (otherId == 0) continue;

                        final key = "${otherId}_$otherType";
                        if (!lastMessages.containsKey(key) || 
                            m.sentAt.isAfter(lastMessages[key]!.sentAt)) {
                          lastMessages[key] = m;
                        }
                      }

                      // 2. Prepare unified list
                      final List<_ConvoData> inboxItems = [];
                      final Set<String> processedPartnerKeys = {};

                      // Add active threads
                      for (var key in lastMessages.keys) {
                        final msg = lastMessages[key]!;
                        final isCurrentUserSender = msg.senderId == user.userId;
                        final partnerType = isCurrentUserSender
                            ? (msg.receiverType ?? 'user')
                            : (msg.senderType ?? 'user');
                        final otherId = isCurrentUserSender ? (msg.receiverId ?? 0) : (msg.senderId ?? 0);
                        final partnerName = isCurrentUserSender
                            ? (msg.receiverName ?? 'User $otherId')
                            : (msg.senderName ?? 'User $otherId');
                        final isAdmin = partnerType == 'admin';
                        
                        // Messenger feature: Unread status
                        final isUnread = !msg.isRead && !isCurrentUserSender;

                        inboxItems.add(_ConvoData(
                          userId: otherId,
                          receiverType: partnerType,
                          name: partnerName,
                          preview: msg.imagePath != null && msg.imagePath!.isNotEmpty
                              ? '📷 Photo'
                              : (msg.messageText?.isNotEmpty == true ? msg.messageText! : 'Sent a message'),
                          time: "${msg.sentAt.hour}:${msg.sentAt.minute.toString().padLeft(2, '0')}",
                          lastInteraction: msg.sentAt,
                          tag: isAdmin ? 'ADMIN' : (msg.senderRole?.toUpperCase() ?? 'USER'),
                          icon: isAdmin ? Icons.admin_panel_settings : Icons.chat_bubble,
                          iconColor: isAdmin ? Colors.red : _getRoleColor(msg.senderRole),
                          iconBg: (isAdmin ? Colors.red : _getRoleColor(msg.senderRole)).withValues(alpha: 0.1),
                          isUnread: isUnread,
                          isCritical: isAdmin,
                        ));
                        processedPartnerKeys.add(key);
                      }

                      // 3. Add Important Personnel (Admins, Volunteers, Drivers) if not messaged
                      void addImportant(String category, IconData icon, Color color, String rType) {
                        final list = resourceController.contacts[category] ?? [];
                        for (var c in list) {
                          int id = int.tryParse(c['user_id'].toString()) ?? 0;
                          final key = "${id}_$rType";
                          if (!processedPartnerKeys.contains(key)) {
                            // For admins, first_name holds full_name; trim trailing space
                            final rawName = "${c['first_name'] ?? ''} ${c['last_name'] ?? ''}".trim();
                            inboxItems.add(_ConvoData(
                              userId: id,
                              receiverType: rType,
                              name: rawName.isEmpty ? 'Unknown' : rawName,
                              preview: "Start a conversation...",
                              time: 'Contact',
                              lastInteraction: DateTime(2000), // Very old for contacts
                              tag: c['role']?.toString().toUpperCase() ?? 'SUPPORT',
                              icon: icon,
                              iconColor: color,
                              iconBg: color.withValues(alpha: 0.1),
                              isUnread: false,
                              isCritical: false,
                              isOfficial: true,
                            ));
                            processedPartnerKeys.add(key);
                          }
                        }
                      }

                      addImportant('admins', Icons.admin_panel_settings, Colors.red, 'admin');
                      addImportant('volunteers', Icons.volunteer_activism, Colors.green, 'user');
                      addImportant('drivers', Icons.local_shipping, Colors.blue, 'user');

                      // 4. Sort: Threads on top (by time), then contacts
                      inboxItems.sort((a, b) => b.lastInteraction.compareTo(a.lastInteraction));

                      // 5. Filter dismissed items locally to prevent "still in tree" error
                      inboxItems.removeWhere((item) {
                        final k = 'convo_${item.userId}_${item.receiverType}';
                        return _dismissedKeys.contains(k);
                      });

                      return RefreshIndicator(
                        onRefresh: () async {
                          await resourceController.fetchMessages();
                          await resourceController.fetchContacts();
                        },
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 100),
                          children: [
                          // INBOX big label
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                            child: Text(
                              'INBOX',
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textHint.withValues(alpha: 0.3),
                                height: 1,
                              ),
                            ),
                          ),

                          if (inboxItems.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(40.0),
                              child: Center(
                                child: Text(
                                  "No messages yet.\nConnect with personnel below.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: AppColors.textSecondary),
                                ),
                              ),
                            ),

                          ...inboxItems.map((item) => Dismissible(
                            // Stable Key: UserID_UserType. Do not include preview text as it changes over time.
                            key: Key('convo_${item.userId}_${item.receiverType}'),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (_) async {
                              return await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete Conversation'),
                                  content: Text('Delete your conversation with ${item.name}? This cannot be undone.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: const Text('CANCEL'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                                      child: const Text('DELETE'),
                                    ),
                                  ],
                                ),
                              ) ?? false;
                            },
                            onDismissed: (_) {
                              final k = 'convo_${item.userId}_${item.receiverType}';
                              setState(() {
                                _dismissedKeys.add(k);
                              });
                              // Trigger backend deletion
                              resourceController.deleteConversation(
                                item.userId,
                                otherUserType: item.receiverType,
                              ).then((_) {
                                // Once done, remove from _dismissedKeys so it can "pop up" again 
                                // if a new message arrives from the API later.
                                if (mounted) {
                                  setState(() {
                                    _dismissedKeys.remove(k);
                                  });
                                }
                              });
                            },
                            background: Container(
                              margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.delete_rounded, color: Colors.white, size: 28),
                                  SizedBox(height: 4),
                                  Text('DELETE', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            child: _ConvoTile(
                              data: item,
                              onTap: () => Navigator.pushNamed(
                                context,
                                '/chat',
                                arguments: {
                                  'otherUserId': item.userId,
                                  'receiverType': item.receiverType,
                                  'name': item.name,
                                  'subtitle': 'ACTIVE NOW',
                                  'color': item.iconColor,
                                },
                              ).then((_) {
                                resourceController.fetchMessages();
                                resourceController.fetchContacts();
                              }),
                            ),
                          )),
                        ],
                      ),
                      );
                    },
                  ),
                ),
              ],
            ),

            // New SOS/Request FAB
            Positioned(
              bottom: 16,
              left: 20,
              right: 20,
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/sos'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.danger,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.danger.withValues(alpha: 0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.wifi_tethering, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'NEW SOS',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/discovery'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_comment, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'NEW MESSAGE',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
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
}

class _ConvoData {
  final int userId;
  final String receiverType;
  final String name, preview, time, tag;
  final DateTime lastInteraction;
  final IconData icon;
  final Color iconColor, iconBg;
  final bool isUnread, isCritical, isOfficial;

  const _ConvoData({
    required this.userId,
    required this.receiverType,
    required this.name,
    required this.preview,
    required this.time,
    required this.lastInteraction,
    required this.tag,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.isUnread,
    required this.isCritical,
    this.isOfficial = false,
  });
}

class _ConvoTile extends StatelessWidget {
  final _ConvoData data;
  final VoidCallback onTap;

  const _ConvoTile({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: data.isCritical
              ? const Border(
                  left: BorderSide(color: AppColors.danger, width: 3),
                )
              : Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: data.iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(data.icon, color: data.iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        data.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: data.isUnread ? FontWeight.w900 : FontWeight.w700,
                          color: data.isUnread ? AppColors.primary : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        data.time,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    data.preview,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F0F0),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          data.tag,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      if (data.isUnread)
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: AppColors.danger,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
