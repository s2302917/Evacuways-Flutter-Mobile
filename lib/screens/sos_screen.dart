import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../controllers/resource_controller.dart';
import '../models/sos_request_model.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class SOSScreen extends StatefulWidget {
  const SOSScreen({super.key});

  @override
  State<SOSScreen> createState() => _SOSScreenState();
}

class _SOSScreenState extends State<SOSScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  final TextEditingController _messageController = TextEditingController();
  final Set<String> _selectedNeeds = {'Flooded'};
  final List<_NeedOption> _needs = [
    _NeedOption(label: 'Flooded', icon: Icons.waves),
    _NeedOption(label: 'Need Medical Help', icon: Icons.medical_services_outlined),
    _NeedOption(label: 'Trapped', icon: Icons.fence),
    _NeedOption(label: 'Rescue', icon: Icons.flight),
    _NeedOption(label: 'Food/Water', icon: Icons.fastfood_outlined),
    _NeedOption(label: 'Fire', icon: Icons.local_fire_department_outlined),
    _NeedOption(label: 'Missing Person', icon: Icons.person_search),
  ];

  // Hold-to-send state
  Timer? _holdTimer;
  double _holdProgress = 0;
  bool _isHolding = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnim = Tween(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);

    // Fetch SOS history on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      resourceController.fetchSosRequests();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _messageController.dispose();
    _holdTimer?.cancel();
    super.dispose();
  }

  // ── Hold-to-SOS logic ──────────────────────────────────────────────────────
  void _startHold() {
    setState(() {
      _isHolding = true;
      _holdProgress = 0;
    });
    const totalMs = 3000;
    const tickMs = 50;
    int elapsed = 0;
    _holdTimer = Timer.periodic(const Duration(milliseconds: tickMs), (t) {
      elapsed += tickMs;
      setState(() => _holdProgress = elapsed / totalMs);
      if (elapsed >= totalMs) {
        t.cancel();
        _triggerQuickSOS();
      }
    });
  }

  void _cancelHold() {
    _holdTimer?.cancel();
    setState(() {
      _isHolding = false;
      _holdProgress = 0;
    });
  }

  Future<bool> _checkLocationStatus() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        _showResultDialog(
          "Location services are disabled. Please enable GPS in your device settings to send an SOS with your coordinates.",
          title: "Location Service Off",
        );
      }
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          _showResultDialog(
            "Location permissions are denied. We need your location to help responders find you.",
            title: "Permission Denied",
          );
        }
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        _showResultDialog(
          "Location permissions are permanently denied. Please enable them in your app settings to use SOS tracking.",
          title: "Permission Required",
        );
      }
      return false;
    }

    return true;
  }

  Future<LatLng?> _showLocationPicker() async {
    LatLng currentCenter = const LatLng(10.7202, 122.5621); // Default
    try {
      Position pos = await Geolocator.getCurrentPosition();
      currentCenter = LatLng(pos.latitude, pos.longitude);
    } catch (_) {}

    return await showDialog<LatLng>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        LatLng selected = currentCenter;
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Pin Your Location', style: TextStyle(fontWeight: FontWeight.w800)),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(target: currentCenter, zoom: 16),
                    onMapCreated: (ctrl) {},
                    onCameraMove: (pos) => selected = pos.target,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                  ),
                  const Center(child: Icon(Icons.location_on, color: Colors.red, size: 40)),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, selected),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('CONFIRM PIN', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _triggerQuickSOS() async {
    if (resourceController.isSOSLoading) return;

    if (!await _checkLocationStatus()) return;

    // 1. Show location picker
    final pinned = await _showLocationPicker();
    if (pinned == null) return;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sending Quick SOS with pinned location...')),
      );
    }

    // 2. Submit SOS with pinned location
    String? error = await resourceController.submitSOS(
      requestType: 'Emergency Support', // Standardized type
      subject: 'QUICK SOS - Immediate Rescue Required',
      message: 'User activated Quick SOS hold-button and pinned their specific location.',
      latitude: pinned.latitude,
      longitude: pinned.longitude,
    );

    if (mounted) {
      _showResultDialog(
        error,
        title: error == null ? '🚨 SOS Sent!' : 'SOS Failed',
      );
    }
  }

  // ── Form submit ────────────────────────────────────────────────────────────
  Future<void> _submitSOS() async {
    if (_selectedNeeds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one need.')),
      );
      return;
    }

    // Request permissions before sending
    if (!await _checkLocationStatus()) return;

    String? error = await resourceController.submitSOS(
      requestType: _selectedNeeds.join(', '),
      subject: 'SOS Emergency: ${_selectedNeeds.first}',
      message: _messageController.text.trim(),
    );

    if (mounted) {
      if (error == null) {
        _messageController.clear();
        _showResultDialog(
          null,
          title: 'SOS Sent!',
        );
      } else {
        _showResultDialog(
          error,
          title: 'Failed to Send',
        );
      }
    }
  }

  void _showResultDialog(String? errorMessage, {required String title}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        content: Text(
          errorMessage ?? 'Emergency responders have been notified immediately.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK',
                style: TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelRequest(SosRequestModel req) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel SOS?'),
        content: const Text('Do you want to cancel this SOS request?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('NO')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('YES, CANCEL'),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;
    final success = await resourceController.cancelSosRequest(req.requestId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? 'SOS request cancelled.' : 'Could not cancel. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF0F0),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 22),
                    ),
                    const Text(
                      'Emergency SOS',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    const SizedBox(width: 22),
                  ],
                ),
              ),
            ),

            // Hero title
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Emergency\nSOS',
                      style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: AppColors.danger, height: 1.1),
                    ),
                    SizedBox(height: 8),
                    Text('Help is one tap away.', style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ),

            // ── QUICK SOS button (hold 3s) ──────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 28),
                child: Center(
                  child: GestureDetector(
                    onLongPressStart: (_) => _startHold(),
                    onLongPressEnd: (_) => _cancelHold(),
                    onLongPressCancel: _cancelHold,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer glow ring (pulse)
                        ScaleTransition(
                          scale: _pulseAnim,
                          child: Container(
                            width: 220,
                            height: 220,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.danger.withValues(alpha: 0.08),
                            ),
                          ),
                        ),
                        // Progress ring when holding
                        SizedBox(
                          width: 220,
                          height: 220,
                          child: CircularProgressIndicator(
                            value: _holdProgress,
                            strokeWidth: 6,
                            color: Colors.white,
                            backgroundColor: Colors.transparent,
                          ),
                        ),
                        // Main button
                        Container(
                          width: 190,
                          height: 190,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const RadialGradient(
                              colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
                              radius: 0.8,
                            ),
                            boxShadow: [
                              BoxShadow(color: AppColors.danger.withValues(alpha: 0.4), blurRadius: 32, spreadRadius: 8),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.wifi_tethering, color: Colors.white, size: 44),
                              const Icon(Icons.location_on, color: Colors.white, size: 28),
                              const SizedBox(height: 4),
                              Text(
                                _isHolding ? 'HOLD...' : 'QUICK SOS',
                                style: const TextStyle(
                                  color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Hold hint
            SliverToBoxAdapter(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8)],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.timer_outlined, size: 14, color: AppColors.textSecondary),
                      SizedBox(width: 6),
                      Text('Press and hold for 3 seconds to send Quick SOS',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),

            // ── Identify Critical Needs ─────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text('Identify Critical Needs',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: AppColors.dangerLight, borderRadius: BorderRadius.circular(6)),
                      child: const Text('MULTIPLE CHOICE',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.danger, letterSpacing: 0.5)),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // Need chips
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: _needs.map((need) {
                    final isSelected = _selectedNeeds.contains(need.label);
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: GestureDetector(
                        onTap: () => setState(() {
                          isSelected ? _selectedNeeds.remove(need.label) : _selectedNeeds.add(need.label);
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.dangerLight : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isSelected ? AppColors.danger.withValues(alpha: 0.3) : AppColors.divider),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(need.icon, size: 16, color: isSelected ? AppColors.danger : AppColors.textSecondary),
                              const SizedBox(width: 6),
                              Text(need.label,
                                  style: TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w600,
                                    color: isSelected ? AppColors.danger : AppColors.textPrimary,
                                  )),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // Detailed message
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Detailed Message (Optional)',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _messageController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Describe your situation, number of people, or specific location details...',
                        hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 13),
                        filled: true,
                        fillColor: AppColors.inputFill,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Submit button
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ListenableBuilder(
                  listenable: resourceController,
                  builder: (context, _) => ElevatedButton.icon(
                    onPressed: resourceController.isSOSLoading ? null : _submitSOS,
                    icon: resourceController.isSOSLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.send, color: Colors.white),
                    label: Text(
                      resourceController.isSOSLoading ? 'Submitting...' : 'Submit Request',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            // GPS note
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Your request will be sent to emergency responders immediately.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),

            // ── SOS History ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text('My SOS History',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                    ),
                    ListenableBuilder(
                      listenable: resourceController,
                      builder: (ctx, _) => GestureDetector(
                        onTap: resourceController.isSosHistoryLoading ? null : resourceController.fetchSosRequests,
                        child: const Icon(Icons.refresh, size: 20, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            ListenableBuilder(
              listenable: resourceController,
              builder: (context, _) {
                if (resourceController.isSosHistoryLoading) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  );
                }
                if (resourceController.sosRequests.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(24, 0, 24, 40),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.history_toggle_off, size: 40, color: AppColors.textHint),
                            SizedBox(height: 8),
                            Text('No SOS requests yet.', style: TextStyle(color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final req = resourceController.sosRequests[i];
                      return _SOSHistoryCard(request: req, onCancel: () => _cancelRequest(req));
                    },
                    childCount: resourceController.sosRequests.length,
                  ),
                );
              },
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      // Bottom nav
      bottomNavigationBar: _SOSBottomBar(),
    );
  }
}

// ── History Card ──────────────────────────────────────────────────────────────
class _SOSHistoryCard extends StatelessWidget {
  final SosRequestModel request;
  final VoidCallback onCancel;

  const _SOSHistoryCard({required this.request, required this.onCancel});

  Color get _statusColor {
    switch (request.status.toLowerCase()) {
      case 'pending': return Colors.orange;
      case 'resolved': return Colors.green;
      case 'cancelled': return Colors.grey;
      default: return AppColors.primary;
    }
  }

  IconData get _statusIcon {
    switch (request.status.toLowerCase()) {
      case 'pending': return Icons.hourglass_empty;
      case 'resolved': return Icons.check_circle;
      case 'cancelled': return Icons.cancel;
      default: return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = '${request.createdAt.day}/${request.createdAt.month}/${request.createdAt.year} '
        '${request.createdAt.hour}:${request.createdAt.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _statusColor.withValues(alpha: 0.25)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: _statusColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(_statusIcon, color: _statusColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.subject ?? request.requestType ?? 'SOS Request',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(dateStr, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: _statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(
                  request.status.toUpperCase(),
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: _statusColor),
                ),
              ),
            ],
          ),
          if (request.requestType != null && request.requestType!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: request.requestType!.split(',').map((t) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFFF0F0F0), borderRadius: BorderRadius.circular(20)),
                child: Text(t.trim(), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              )).toList(),
            ),
          ],
          if (request.message != null && request.message!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(request.message!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
          if (request.isPending) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onCancel,
                icon: const Icon(Icons.cancel_outlined, size: 16),
                label: const Text('Cancel Request', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Bottom Bar ────────────────────────────────────────────────────────────────
class _SOSBottomBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE0E7EF))),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              _SOSNavItem(icon: Icons.home_outlined, label: 'HOME', onTap: () => Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false)),
              _SOSNavItem(icon: Icons.checklist_outlined, label: 'CHECKLIST', onTap: () => Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false, arguments: 1)),
              _SOSNavItem(icon: Icons.explore_outlined, label: 'MAP', onTap: () => Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false)),
              _SOSNavItem(icon: Icons.chat_bubble_outline, label: 'MESSAGES', onTap: () => Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SOSNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SOSNavItem({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF90A4AE), size: 22),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF90A4AE), letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }
}

class _NeedOption {
  final String label;
  final IconData icon;
  const _NeedOption({required this.label, required this.icon});
}
