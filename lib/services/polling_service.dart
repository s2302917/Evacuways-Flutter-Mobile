import 'dart:async';
import 'package:flutter/foundation.dart';
import '../controllers/resource_controller.dart';

/// Centralized polling coordinator for all background data fetches.
/// Screens no longer own individual timers — this service manages all of them.
/// This prevents duplicate concurrent requests and reduces server load.
class PollingService {
  static final PollingService _instance = PollingService._internal();
  factory PollingService() => _instance;
  PollingService._internal();

  Timer? _alertsTimer;
  Timer? _inboxTimer;
  Timer? _sosTimer;

  bool _isStarted = false;

  void start() {
    if (_isStarted) return;
    _isStarted = true;

    // Initial fetches
    _fetchAll();

    // Alerts every 30 seconds (emergency data, moderate urgency)
    _alertsTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      resourceController.fetchAlerts();
    });

    // Inbox messages every 15 seconds
    _inboxTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      resourceController.fetchMessages(); // inbox only
      resourceController.fetchContacts();
    });

    // SOS requests every 20 seconds
    _sosTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      resourceController.fetchSosRequests();
    });

    debugPrint('[PollingService] Started');
  }

  void stop() {
    _alertsTimer?.cancel();
    _inboxTimer?.cancel();
    _sosTimer?.cancel();
    _alertsTimer = null;
    _inboxTimer = null;
    _sosTimer = null;
    _isStarted = false;
    debugPrint('[PollingService] Stopped');
  }

  void _fetchAll() {
    resourceController.fetchAlerts();
    resourceController.fetchMessages();
    resourceController.fetchContacts();
    resourceController.fetchSosRequests();
  }

  /// Force-refresh all data immediately (e.g., on pull-to-refresh)
  Future<void> refreshAll() async {
    await Future.wait([
      resourceController.fetchAlerts(),
      resourceController.fetchMessages(),
      resourceController.fetchContacts(),
      resourceController.fetchSosRequests(),
    ]);
  }

  void dispose() {
    stop();
  }
}

/// Global singleton instance
final pollingService = PollingService();
