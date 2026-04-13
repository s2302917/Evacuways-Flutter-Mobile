import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../controllers/family_controller.dart';
import '../models/user_model.dart';
import '../models/family_model.dart';

class FamilyListScreen extends StatefulWidget {
  final int userId;

  const FamilyListScreen({super.key, required this.userId});

  @override
  State<FamilyListScreen> createState() => _FamilyListScreenState();
}

class _FamilyListScreenState extends State<FamilyListScreen> {
  late FamilyController _familyController;
  List<FamilyModel> _families = [];
  bool _isLoading = true;
  int? _expandedFamilyId;

  @override
  void initState() {
    super.initState();
    _familyController = FamilyController();
    _loadFamilies();
  }

  Future<void> _loadFamilies() async {
    setState(() => _isLoading = true);

    final families = await _familyController.getFamiliesForUser(widget.userId);

    setState(() {
      _families = families;
      _isLoading = false;
    });
  }

  Future<void> _loadFamilyMembers(int familyId) async {
    setState(() {
      _expandedFamilyId = _expandedFamilyId == familyId ? null : familyId;
    });
  }

  Future<void> _leaveFamily(int familyId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Family'),
        content: const Text(
          'Are you sure you want to leave this family group?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Leave', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final ctx = context;
      final result = await _familyController.leaveFamily(
        familyId,
        widget.userId,
      );

      if (result['success']) {
        if (mounted) {
          ScaffoldMessenger.of(
            ctx,
          ).showSnackBar(const SnackBar(content: Text('You left the family')));
          _loadFamilies();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Error leaving family'),
            ),
          );
        }
      }
    }
  }

  Future<void> _removeMember(int familyId, UserModel member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text(
          'Are you sure you want to remove ${member.firstName} from this family group?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final ctx = context;
      final result = await _familyController.removeFamilyMember(
        familyId,
        widget.userId,
        member.userId,
      );

      if (result['success']) {
        if (mounted) {
          ScaffoldMessenger.of(
            ctx,
          ).showSnackBar(const SnackBar(content: Text('Member removed')));
          _loadFamilies();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Error removing member'),
            ),
          );
        }
      }
    }
  }

  Future<void> _toggleStatus() async {
    // Basic toggle between Rescued and Pending
    // In a real app, this could be a bottom sheet with more options

    final newStatus = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.timer, color: AppColors.warning),
              title: const Text('Pending Rescue'),
              onTap: () => Navigator.pop(context, 'Pending'),
            ),
            ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: const Text('Already Rescued'),
              onTap: () => Navigator.pop(context, 'Rescued'),
            ),
          ],
        ),
      ),
    );

    if (newStatus != null) {
      final ctx = context;
      final result = await _familyController.updateRescueStatus(
        widget.userId,
        newStatus,
      );

      if (result['success']) {
        if (mounted) {
          ScaffoldMessenger.of(
            ctx,
          ).showSnackBar(const SnackBar(content: Text('Status updated')));
          _loadFamilies();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Error updating status'),
            ),
          );
        }
      }
    }
  }

  Future<void> _reportMissing(int familyId, UserModel member) async {
    showDialog(
      context: context,
      builder: (context) => _ReportMissingDialog(
        familyController: _familyController,
        familyId: familyId,
        reporterId: widget.userId,
        member: member,
        onReported: _loadFamilies,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          'My Family Groups',
          style: TextStyle(color: Colors.white),
        ),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _families.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.group_off,
                    size: 80,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  Text(
                    'No families created yet',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(screenWidth * 0.04),
              itemCount: _families.length,
              itemBuilder: (context, index) {
                final family = _families[index];
                final isExpanded = _expandedFamilyId == family.familyId;

                return Card(
                  margin: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
                  child: Column(
                    children: [
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary,
                          child: Icon(Icons.group, color: Colors.white),
                        ),
                        title: Text(
                          family.familyName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text('Contact: ${family.primaryContact}'),
                        trailing: Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                        ),
                        onTap: () => _loadFamilyMembers(family.familyId),
                      ),
                      if (isExpanded)
                        FutureBuilder<List<UserModel>>(
                          future: _familyController.getFamilyMembers(
                            family.familyId,
                          ),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(),
                              );
                            }

                            final members = snapshot.data ?? [];

                            return Column(
                              children: [
                                const Divider(),
                                Padding(
                                  padding: EdgeInsets.all(screenWidth * 0.04),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Members (${members.length})',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: screenWidth > 600 ? 16 : 14,
                                        ),
                                      ),
                                      SizedBox(height: screenHeight * 0.02),
                                      ...(members.map((member) {
                                        final missingCount =
                                            member.missingCount;
                                        return Container(
                                          margin: EdgeInsets.only(
                                            bottom: screenHeight * 0.015,
                                          ),
                                          padding: EdgeInsets.all(
                                            screenWidth * 0.03,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: AppColors.divider,
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Row(
                                                          children: [
                                                            Text(
                                                              '${member.firstName} ${member.lastName}',
                                                              style:
                                                                  const TextStyle(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                  ),
                                                            ),
                                                            if (member.userId ==
                                                                widget.userId)
                                                              const Text(
                                                                ' (You)',
                                                                style: TextStyle(
                                                                  fontSize: 10,
                                                                  fontStyle:
                                                                      FontStyle
                                                                          .italic,
                                                                  color: Colors
                                                                      .blue,
                                                                ),
                                                              ),
                                                          ],
                                                        ),
                                                        Text(
                                                          member.contactNumber,
                                                          style: TextStyle(
                                                            color: AppColors
                                                                .textSecondary,
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  if (member.userId !=
                                                      widget.userId)
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.delete_outline,
                                                        color: AppColors.danger,
                                                        size: 20,
                                                      ),
                                                      onPressed: () =>
                                                          _removeMember(
                                                            family.familyId,
                                                            member,
                                                          ),
                                                    ),
                                                  if (missingCount > 0)
                                                    Container(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 4,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: AppColors.danger
                                                            .withValues(
                                                              alpha: 0.2,
                                                            ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              6,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        'Missing: $missingCount',
                                                        style: TextStyle(
                                                          color:
                                                              AppColors.danger,
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              SizedBox(
                                                height: screenHeight * 0.01,
                                              ),
                                                Row(
                                                  children: [
                                                    GestureDetector(
                                                      onTap: member.userId ==
                                                              widget.userId
                                                          ? _toggleStatus
                                                          : null,
                                                      behavior: HitTestBehavior.opaque,
                                                      child: Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          ChartContainer(
                                                            label:
                                                                member.rescueStatus ??
                                                                'Pending',
                                                            color:
                                                                member.rescueStatus ==
                                                                    'Rescued'
                                                                ? Colors.green
                                                                : AppColors.warning,
                                                          ),
                                                          if (member.userId ==
                                                              widget.userId)
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .only(left: 6),
                                                              child: Icon(
                                                                Icons.edit,
                                                                size: 16,
                                                                color: AppColors
                                                                    .textSecondary,
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      width: screenWidth * 0.02,
                                                    ),
                                                    if (member.userId !=
                                                        widget.userId)
                                                      Expanded(
                                                        child: ElevatedButton(
                                                          onPressed: () =>
                                                              _reportMissing(
                                                                family.familyId,
                                                                member,
                                                              ),
                                                          style:
                                                              ElevatedButton.styleFrom(
                                                                backgroundColor:
                                                                    AppColors
                                                                        .danger,
                                                              ),
                                                          child: const Text(
                                                            'Report Missing',
                                                            style: TextStyle(
                                                              color: Colors.white,
                                                              fontSize: 12,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                            ],
                                          ),
                                        );
                                      })),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(screenWidth * 0.04),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () =>
                                          _leaveFamily(family.familyId),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.danger,
                                      ),
                                      child: const Text(
                                        'Leave Family',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class ChartContainer extends StatelessWidget {
  final String label;
  final Color color;

  const ChartContainer({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ReportMissingDialog extends StatefulWidget {
  final FamilyController familyController;
  final int familyId;
  final int reporterId;
  final UserModel member;
  final VoidCallback onReported;

  const _ReportMissingDialog({
    required this.familyController,
    required this.familyId,
    required this.reporterId,
    required this.member,
    required this.onReported,
  });

  @override
  State<_ReportMissingDialog> createState() => _ReportMissingDialogState();
}

class _ReportMissingDialogState extends State<_ReportMissingDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Report Missing'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Report ${widget.member.firstName} ${widget.member.lastName} as missing?'),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Additional details...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            if (_isSubmitting)
              const Padding(
                padding: EdgeInsets.only(top: 15),
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _isSubmitting ? null : _submit,
          child: const Text('Report'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    final messenger = ScaffoldMessenger.of(context);
    
    try {
      final result = await widget.familyController.reportMissingMember(
        widget.familyId,
        widget.reporterId,
        widget.member.userId,
        _controller.text,
      );

      if (mounted) {
        if (result['success']) {
          Navigator.pop(context);
          messenger.showSnackBar(
            const SnackBar(content: Text('Missing person reported to admin')),
          );
          widget.onReported();
        } else {
          setState(() => _isSubmitting = false);
          messenger.showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Error reporting')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        messenger.showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
