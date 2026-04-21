import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../controllers/auth_controller.dart';
import '../controllers/resource_controller.dart';
import '../models/alert_model.dart';
import '../services/polling_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _HomeView();
  }
}

class _HomeView extends StatefulWidget {
  const _HomeView();

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  void _showNotificationsSheet(BuildContext context) {
    resourceController.markAlertsAsRead();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          builder: (_, controller) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    height: 5,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Notifications',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Icon(Icons.done_all, color: AppColors.primary),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ValueListenableBuilder<List<AlertModel>>(
                      valueListenable: resourceController.alertsNotifier,
                      builder: (context, alerts, _) {
                        if (alerts.isEmpty) {
                          return const Center(
                              child: Text('No notifications'));
                        }
                        return ListView.separated(
                          controller: controller,
                          padding: const EdgeInsets.all(20),
                          itemCount: alerts.length,
                          separatorBuilder: (_, _s) =>
                              const SizedBox(height: 16),
                          itemBuilder: (context, index) =>
                              _buildNotificationItem(alerts[index]),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNotificationItem(AlertModel alert) {
    Color iconBg;
    IconData icon;
    Color iconColor;
    if (alert.severityLevel == 'Critical') {
      iconBg = AppColors.dangerLight;
      iconColor = AppColors.danger;
      icon = Icons.warning_rounded;
    } else if (alert.severityLevel == 'Warning') {
      iconBg = AppColors.warningLight;
      iconColor = AppColors.warning;
      icon = Icons.warning_amber_rounded;
    } else {
      iconBg = AppColors.infoLight;
      iconColor = AppColors.info;
      icon = Icons.info_outline;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                alert.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                alert.message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4),
              ),
              const SizedBox(height: 4),
              Text(
                _formatTimeAgo(alert.createdAt),
                style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAlertCard(AlertModel alert) {
    Color labelColor;
    Color labelBg;
    Color borderColor;
    IconData icon;
    Color iconBg;

    if (alert.severityLevel == 'Critical') {
      labelColor = AppColors.danger;
      labelBg = AppColors.dangerLight;
      borderColor = AppColors.danger;
    } else if (alert.severityLevel == 'Warning') {
      labelColor = AppColors.warning;
      labelBg = AppColors.warningLight;
      borderColor = AppColors.warning;
    } else {
      labelColor = AppColors.info;
      labelBg = AppColors.infoLight;
      borderColor = AppColors.info;
    }

    final typeToLower = alert.alertType.toLowerCase();
    if (typeToLower.contains('flood')) {
      icon = Icons.flood;
      iconBg = const Color(0xFF7B3700);
    } else if (typeToLower.contains('typhoon') ||
        typeToLower.contains('storm')) {
      icon = Icons.cyclone;
      iconBg = AppColors.danger;
    } else {
      icon = Icons.warning_amber_rounded;
      iconBg = AppColors.info;
    }

    return _AlertCard(
      label: alert.severityLevel.toUpperCase(),
      labelColor: labelColor,
      labelBg: labelBg,
      borderColor: borderColor,
      time: _formatTimeAgo(alert.createdAt),
      title: alert.title,
      body: alert.message,
      icon: icon,
      iconColor: Colors.white,
      iconBg: iconBg,
      onReadAlert: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(alert.title),
            content: SingleChildScrollView(
              child: Text(alert.message,
                  style: const TextStyle(height: 1.5)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
      readLabelColor: labelColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: () => pollingService.refreshAll(),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // ── App Bar ─────────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () =>
                                Navigator.pushNamed(context, '/profile'),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.primary
                                    .withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.person,
                                  color: AppColors.primary, size: 22),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'EvacuWays',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                          // Notification bell — only rebuild the badge
                          GestureDetector(
                            onTap: () =>
                                _showNotificationsSheet(context),
                            child: Stack(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius:
                                        BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                      Icons.notifications_outlined,
                                      color: AppColors.textSecondary,
                                      size: 22),
                                ),
                                ValueListenableBuilder<bool>(
                                  valueListenable: resourceController
                                      .hasUnreadAlertsNotifier,
                                  builder: (_, hasUnread, _w) {
                                    if (!hasUnread) {
                                      return const SizedBox.shrink();
                                    }
                                    return Positioned(
                                      right: 6,
                                      top: 6,
                                      child: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: const BoxDecoration(
                                          color: AppColors.danger,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Greeting ───────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: ListenableBuilder(
                      listenable: authController,
                      builder: (context, _) {
                        final user = authController.currentUser;
                        final firstName = user?.firstName ?? 'User';
                        final location =
                            user?.cityCode ?? 'Bacolod City';
                        return Padding(
                          padding:
                              const EdgeInsets.fromLTRB(20, 20, 20, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Stay Safe, $firstName',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      '$location • Network: Online',
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textSecondary),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // ── Outlook Banner ─────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        height: 130,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF1A5F7A),
                              Color(0xFF2A7A9B)
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Stack(
                          clipBehavior: Clip.hardEdge,
                          children: [
                            Positioned(
                              right: -20,
                              top: -20,
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color:
                                      Colors.white.withValues(alpha: 0.08),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            Positioned(
                              right: 30,
                              top: 10,
                              child: Icon(Icons.wb_sunny,
                                  color:
                                      Colors.amber.withValues(alpha: 0.9),
                                  size: 55),
                            ),
                            Positioned(
                              right: 10,
                              top: 32,
                              child: Icon(Icons.cloud,
                                  color:
                                      Colors.white.withValues(alpha: 0.45),
                                  size: 36),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: ValueListenableBuilder<List<AlertModel>>(
                                valueListenable:
                                    resourceController.alertsNotifier,
                                builder: (_, alerts, _s) {
                                  final count = alerts.length;
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text(
                                        'CURRENT OUTLOOK',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white
                                              .withValues(alpha: 0.7),
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '$count Active Alert${count == 1 ? '' : 's'}',
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 20)),

                  // ── Alert Cards ─────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ValueListenableBuilder<List<AlertModel>>(
                        valueListenable: resourceController.alertsNotifier,
                        builder: (context, alerts, _) {
                          return ValueListenableBuilder<bool>(
                            valueListenable:
                                resourceController.isAlertsLoadingNotifier,
                            builder: (context, isLoading, _) {
                              if (isLoading && alerts.isEmpty) {
                                return const Padding(
                                  padding:
                                      EdgeInsets.symmetric(vertical: 40),
                                  child: Center(
                                      child: CircularProgressIndicator()),
                                );
                              }
                              if (alerts.isEmpty) {
                                return const Padding(
                                  padding:
                                      EdgeInsets.symmetric(vertical: 30),
                                  child: Center(
                                    child: Text('No active alerts',
                                        style: TextStyle(
                                            color:
                                                AppColors.textSecondary)),
                                  ),
                                );
                              }
                              return ListView.builder(
                                shrinkWrap: true,
                                physics:
                                    const NeverScrollableScrollPhysics(),
                                itemCount: alerts.length,
                                itemBuilder: (context, index) => Padding(
                                  padding:
                                      const EdgeInsets.only(bottom: 14),
                                  child: _buildAlertCard(alerts[index]),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 14)),

                  // ── Map Preview ─────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        height: 120,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF1A5F7A),
                              Color(0xFF2A8A8A)
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Stack(
                          clipBehavior: Clip.hardEdge,
                          children: [
                            // Grid lines overlay
                            ...List.generate(
                              5,
                              (i) => Positioned(
                                left: i * 60.0,
                                top: 0,
                                bottom: 0,
                                child: Container(
                                  width: 1,
                                  color:
                                      Colors.white.withValues(alpha: 0.1),
                                ),
                              ),
                            ),
                            ...List.generate(
                              3,
                              (i) => Positioned(
                                top: i * 40.0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  height: 1,
                                  color:
                                      Colors.white.withValues(alpha: 0.1),
                                ),
                              ),
                            ),
                            Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color:
                                      Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: Colors.white
                                          .withValues(alpha: 0.4)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.location_on,
                                        color: Colors.white, size: 16),
                                    SizedBox(width: 6),
                                    Text(
                                      'Live Map View',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 14)),

                  // ── Static Info Card ────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _AlertCard(
                        label: 'INFORMATION',
                        labelColor: AppColors.info,
                        labelBg: AppColors.infoLight,
                        borderColor: AppColors.info,
                        time: '3h ago',
                        title: 'Relief Distribution Schedule',
                        body:
                            'Relief goods will be available at the Central Plaza starting 8:00 AM tomorrow. Please bring your family ID.',
                        icon: Icons.volunteer_activism,
                        iconColor: Colors.white,
                        iconBg: AppColors.primary,
                        onReadAlert: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Relief Distribution'),
                              content: const SingleChildScrollView(
                                child: Text(
                                  'Relief goods will be available at the Central Plaza starting 8:00 AM tomorrow. Please bring your family ID.',
                                  style: TextStyle(height: 1.5),
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context),
                                  child: const Text('Close'),
                                ),
                              ],
                            ),
                          );
                        },
                        readLabelColor: AppColors.info,
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),

            // ── SOS FAB ─────────────────────────────────────────────────
            Positioned(
              right: 20,
              bottom: 20,
              child: GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/sos'),
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.danger,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.danger.withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.wifi_tethering,
                          color: Colors.white, size: 18),
                      Icon(Icons.location_on,
                          color: Colors.white, size: 14),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Alert Card Widget ─────────────────────────────────────────────────────────

class _AlertCard extends StatelessWidget {
  final String label;
  final Color labelColor, labelBg, borderColor;
  final String time, title, body;
  final IconData icon;
  final Color iconColor, iconBg;
  final VoidCallback onReadAlert;
  final Color readLabelColor;

  const _AlertCard({
    required this.label,
    required this.labelColor,
    required this.labelBg,
    required this.borderColor,
    required this.time,
    required this.title,
    required this.body,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.onReadAlert,
    required this.readLabelColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: borderColor, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: labelBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: labelColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  time,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 17),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            body,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onReadAlert,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              decoration: BoxDecoration(
                color: readLabelColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Read Full Alert',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
