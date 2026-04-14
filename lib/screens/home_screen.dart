import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../controllers/auth_controller.dart';
import '../controllers/resource_controller.dart';
import '../models/alert_model.dart';
// Note: Intl might be needed to format 'time ago', but I will do a simple formatter manually if not imported

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (resourceController.alerts.isEmpty) {
        resourceController.fetchAlerts();
      }
    });
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 0) return '${diff.inDays} day(s) ago';
    if (diff.inHours > 0) return '${diff.inHours} hour(s) ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes} min(s) ago';
    return 'Just now';
  }

  Widget _buildAlertsList() {
    return ListenableBuilder(
      listenable: resourceController,
      builder: (context, _) {
        if (resourceController.isAlertsLoading && resourceController.alerts.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (resourceController.alerts.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                'No active alerts',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          );
        }

        return Column(
           children: resourceController.alerts.map((alert) {
             return Padding(
               padding: const EdgeInsets.only(bottom: 14),
               child: _buildAlertCard(alert),
             );
           }).toList(),
        );
      },
    );
  }

  Widget _buildAlertCard(AlertModel alert) {
    Color labelColor;
    Color labelBg;
    Color borderColor;
    IconData icon;
    Color iconBg;

    // Severity mapping
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

    // Type mapping
    String typeToLower = alert.alertType.toLowerCase();
    if (typeToLower.contains('flood')) {
      icon = Icons.flood;
      iconBg = const Color(0xFF7B3700);
    } else if (typeToLower.contains('typhoon') || typeToLower.contains('storm')) {
      icon = Icons.cyclone;
      iconBg = AppColors.danger;
    } else {
      icon = Icons.warning_amber_rounded;
      iconBg = AppColors.info;
    }

    // Actions
    List<_AlertAction> actions = [
      _AlertAction(
        label: 'Read Full Alert',
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(alert.title),
              content: SingleChildScrollView(
                child: Text(
                  alert.message,
                  style: const TextStyle(height: 1.5),
                ),
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
        filled: true,
        color: labelColor,
      ),
    ];

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
      actions: actions,
    );
  }

  void _showNotificationsSheet() {
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
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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
                  const Divider(),
                  Expanded(
                    child: ListenableBuilder(
                      listenable: resourceController,
                      builder: (context, _) {
                        final alerts = resourceController.alerts;
                        if (alerts.isEmpty) {
                          return const Center(child: Text('No new notifications'));
                        }
                        return ListView.separated(
                          controller: controller,
                          padding: const EdgeInsets.all(20),
                          itemCount: alerts.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            return _buildNotificationItem(alerts[index]);
                          },
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
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: iconBg,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                alert.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                alert.message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _formatTimeAgo(alert.createdAt),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
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
              onRefresh: () async {
                await resourceController.fetchAlerts();
                await resourceController.fetchSosRequests();
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // App Bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () =>
                                  Navigator.pushNamed(context, '/profile'),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.15,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.person,
                                  color: AppColors.primary,
                                  size: 22,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'EvacuWays',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: _showNotificationsSheet,
                          child: Stack(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.notifications_outlined,
                                  color: AppColors.textSecondary,
                                  size: 22,
                                ),
                              ),
                              ListenableBuilder(
                                listenable: resourceController,
                                builder: (context, _) {
                                  if (resourceController.hasUnreadAlerts) {
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
                                  }
                                  return const SizedBox.shrink();
                                }
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Greeting
                SliverToBoxAdapter(
                  child: ListenableBuilder(
                    listenable: authController,
                    builder: (context, _) {
                      final user = authController.currentUser;
                      final String firstName = user?.firstName ?? 'User';
                      final String location = user?.cityCode ?? 'Bacolod City';

                      return Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Stay Safe, $firstName',
                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '$location • Network: Online',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }
                  ),
                ),

                // Current Outlook Banner
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      height: 140,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1A5F7A), Color(0xFF2A7A9B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Stack(
                        children: [
                          // Decorative circles
                          Positioned(
                            right: -20,
                            top: -20,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          Positioned(
                            right: 30,
                            top: 10,
                            child: Icon(
                              Icons.wb_sunny,
                              color: Colors.amber.withValues(alpha: 0.9),
                              size: 60,
                            ),
                          ),
                          Positioned(
                            right: 10,
                            top: 30,
                            child: Icon(
                              Icons.cloud,
                              color: Colors.white.withValues(alpha: 0.5),
                              size: 40,
                            ),
                          ),
                          // Text content
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: ListenableBuilder(
                              listenable: resourceController,
                              builder: (context, _) {
                                final activeAlerts = resourceController.alerts.length;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      'CURRENT OUTLOOK',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white.withValues(alpha: 0.7),
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$activeAlerts Active Alert${activeAlerts == 1 ? '' : 's'}',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                );
                              }
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 20)),

                // Alert Cards (Dynamic list)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildAlertsList(),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 14)),

                // Live Map Preview
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GestureDetector(
                      onTap: () {
                          // Could navigate to map view
                      },
                      child: Container(
                        height: 130,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1A5F7A), Color(0xFF2A8A8A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Stack(
                          children: [
                            // Grid lines overlay to simulate map
                            ...List.generate(
                              5,
                              (i) => Positioned(
                                left: i * 60.0,
                                top: 0,
                                bottom: 0,
                                child: Container(
                                  width: 1,
                                  color: Colors.white.withValues(alpha: 0.1),
                                ),
                              ),
                            ),
                            ...List.generate(
                              3,
                              (i) => Positioned(
                                top: i * 43.0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  height: 1,
                                  color: Colors.white.withValues(alpha: 0.1),
                                ),
                              ),
                            ),
                            Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.4),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      color: Colors.white,
                                      size: 16,
                                    ),
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
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 14)),

                // Information card (static example, could be connected to API later if requested)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _AlertCard(
                      label: 'INFORMATION',
                      labelColor: AppColors.info,
                      labelBg: AppColors.infoLight,
                      borderColor: AppColors.info,
                      time: '3 hours ago',
                      title: 'Relief Distribution Schedule',
                      body: 'Relief goods will be available at the Central Plaza starting 8:00 AM tomorrow. Please bring your family ID.',
                      icon: Icons.volunteer_activism,
                      iconColor: Colors.white,
                      iconBg: AppColors.primary,
                      actions: [
                        _AlertAction(
                          label: 'View Details',
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Relief Distribution Schedule'),
                                content: const SingleChildScrollView(
                                  child: Text(
                                    'Relief goods will be available at the Central Plaza starting 8:00 AM tomorrow. Please bring your family ID.',
                                    style: TextStyle(height: 1.5),
                                  ),
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
                          filled: true,
                          color: AppColors.info,
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom FAB spacing
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
            ),

            // SOS FAB
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
                      Icon(Icons.wifi_tethering, color: Colors.white, size: 18),
                      Icon(Icons.location_on, color: Colors.white, size: 14),
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

class _AlertCard extends StatelessWidget {
  final String label;
  final Color labelColor, labelBg, borderColor;
  final String time, title, body;
  final IconData icon;
  final Color iconColor, iconBg;
  final List<_AlertAction> actions;

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
    required this.actions,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
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
                  Text(
                    time,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          // Short preview instead of full body
          const SizedBox(height: 6),
          Text(
            body,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: actions
                  .map(
                    (a) => Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: GestureDetector(
                        onTap: a.onTap,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: a.filled ? a.color : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: a.filled
                                ? null
                                : Border.all(color: AppColors.divider),
                          ),
                          child: Text(
                            a.label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: a.filled
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _AlertAction {
  final String label;
  final VoidCallback onTap;
  final bool filled;
  final Color color;
  const _AlertAction({
    required this.label,
    required this.onTap,
    required this.filled,
    required this.color,
  });
}
