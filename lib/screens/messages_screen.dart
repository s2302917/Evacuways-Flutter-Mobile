import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../controllers/resource_controller.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final Set<String> _dismissedKeys = {};

  // No local Timer — PollingService handles all background fetches

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person,
                        color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Messages',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh,
                        color: AppColors.textSecondary),
                    onPressed: () {
                      resourceController.fetchMessages();
                      resourceController.fetchContacts();
                    },
                  ),
                ],
              ),
            ),

            // ── Inbox List ────────────────────────────────────────────────
            Expanded(
              child: ValueListenableBuilder<List<Map<String, dynamic>>>(
                valueListenable: resourceController.processedInboxNotifier,
                builder: (context, allItems, _) {
                  return ValueListenableBuilder<bool>(
                    valueListenable: resourceController.isMessagesLoadingNotifier,
                    builder: (context, isLoading, _) {
                      if (isLoading && allItems.isEmpty) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }

                      final inboxItems = allItems
                          .where((item) => !_dismissedKeys.contains(
                              'convo_${item['userId']}_${item['partnerType']}'))
                          .toList();

                      return RefreshIndicator(
                        onRefresh: () async {
                          await resourceController.fetchMessages();
                          await resourceController.fetchContacts();
                        },
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(
                              top: 4, bottom: 100),
                          itemCount:
                              inboxItems.isEmpty ? 2 : inboxItems.length + 1,
                          itemBuilder: (context, index) {
                            // ── INBOX watermark header ────────────────────
                            if (index == 0) {
                              return Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 0, 20, 10),
                                child: Text(
                                  'INBOX',
                                  style: TextStyle(
                                    fontSize: 44,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.textHint
                                        .withValues(alpha: 0.25),
                                    height: 1,
                                  ),
                                ),
                              );
                            }

                            // ── Empty state ───────────────────────────────
                            if (inboxItems.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.all(40),
                                child: Center(
                                  child: Text(
                                    'No messages yet.\nConnect with personnel below.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: AppColors.textSecondary),
                                  ),
                                ),
                              );
                            }

                            final item = inboxItems[index - 1];
                            final userId = item['userId'] as int;
                            final partnerType = item['partnerType'] as String;
                            final name = item['name'] as String;
                            final isUnread = item['isUnread'] as bool;
                            final role = item['role'] as String?;
                            final isAdmin = partnerType == 'admin';
                            final sentAt = item['sentAt'] as DateTime;
                            final timeStr = sentAt.year == 2000
                                ? 'Contact'
                                : "${sentAt.hour}:${sentAt.minute.toString().padLeft(2, '0')}";
                            final iconColor =
                                isAdmin ? Colors.red : _getRoleColor(role);

                            return Dismissible(
                              key: Key(
                                  'convo_${userId}_$partnerType'),
                              direction: DismissDirection.endToStart,
                              confirmDismiss: (_) async {
                                return await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title:
                                        const Text('Delete Conversation'),
                                    content: Text(
                                        'Delete conversation with $name? This cannot be undone.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: const Text('CANCEL'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        style: TextButton.styleFrom(
                                            foregroundColor: Colors.red),
                                        child: const Text('DELETE'),
                                      ),
                                    ],
                                  ),
                                ) ??
                                    false;
                              },
                              onDismissed: (_) {
                                final k =
                                    'convo_${userId}_$partnerType';
                                setState(() => _dismissedKeys.add(k));
                                resourceController
                                    .deleteConversation(userId,
                                        otherUserType: partnerType)
                                    .then((_) {
                                  if (mounted) {
                                    setState(
                                        () => _dismissedKeys.remove(k));
                                  }
                                });
                              },
                              background: Container(
                                margin: const EdgeInsets.fromLTRB(
                                    20, 0, 20, 12),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                alignment: Alignment.centerRight,
                                padding:
                                    const EdgeInsets.only(right: 20),
                                child: const Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.delete_rounded,
                                        color: Colors.white, size: 26),
                                    SizedBox(height: 4),
                                    Text('DELETE',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight:
                                                FontWeight.bold)),
                                  ],
                                ),
                              ),
                              child: _ConvoTile(
                                userId: userId,
                                partnerType: partnerType,
                                name: name,
                                preview: item['preview'] as String,
                                time: timeStr,
                                tag: isAdmin
                                    ? 'ADMIN'
                                    : (role?.toUpperCase() ?? 'USER'),
                                isUnread: isUnread,
                                isCritical: isAdmin,
                                icon: isAdmin
                                    ? Icons.admin_panel_settings
                                    : Icons.chat_bubble,
                                iconColor: iconColor,
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  '/chat',
                                  arguments: {
                                    'otherUserId': userId,
                                    'receiverType': partnerType,
                                    'name': name,
                                    'subtitle': 'ACTIVE NOW',
                                    'color': iconColor,
                                  },
                                ).then((_) {
                                  resourceController.fetchMessages();
                                  resourceController.fetchContacts();
                                }),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // ── New Message FAB ────────────────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            Navigator.pushNamed(context, '/discovery'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_comment, color: Colors.white),
        label: const Text(
          'NEW MESSAGE',
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12),
        ),
      ),
    );
  }
}

// ─── Conversation Tile ─────────────────────────────────────────────────────────

class _ConvoTile extends StatelessWidget {
  final int userId;
  final String partnerType;
  final String name, preview, time, tag;
  final bool isUnread, isCritical;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _ConvoTile({
    required this.userId,
    required this.partnerType,
    required this.name,
    required this.preview,
    required this.time,
    required this.tag,
    required this.isUnread,
    required this.isCritical,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: isCritical
              ? const Border(
                  left: BorderSide(color: AppColors.danger, width: 3))
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
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isUnread
                                ? FontWeight.w900
                                : FontWeight.w700,
                            color: isUnread
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        time,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    preview,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F0F0),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (isUnread)
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
