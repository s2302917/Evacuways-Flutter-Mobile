import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../controllers/checklist_controller.dart';
import '../controllers/user_controller.dart';
import '../controllers/auth_controller.dart';
import '../models/family_model.dart';
import '../models/user_model.dart';
import 'family_list_screen.dart';

class ChecklistScreen extends StatefulWidget {
  const ChecklistScreen({super.key});

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  late ChecklistController _checklistController;
  late UserController _userController;
  final Map<int, bool> _expandedState = {};
  bool _isLoading = true;
  String? _errorMessage;

  // Family state
  FamilyModel? _myFamily;
  List<dynamic> _familyMembers = [];
  bool _isFamilyLoading = false;
  final TextEditingController _familyNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checklistController = ChecklistController();
    _userController = UserController();
    _loadAllData();
  }

  @override
  void dispose() {
    _familyNameController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    await Future.wait([_loadChecklists(), _loadFamilyData()]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadChecklists() async {
    try {
      await _checklistController.fetchAllChecklists();
      // Initialize expansion state
      if (_checklistController.checklists != null) {
        for (var i = 0; i < _checklistController.checklists!.length; i++) {
          if (!_expandedState.containsKey(i)) {
            _expandedState[i] = i == 0;
          }
        }
      }
    } catch (e) {
      debugPrint('EXCEPTION LOADING CHECKLISTS: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load checklists: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _loadFamilyData() async {
    final currentUser = authController.currentUser;
    if (currentUser == null) return;

    try {
      final result = await _userController.getFamily(currentUser.userId);
      if (result['success']) {
        if (mounted) {
          setState(() {
            _myFamily = result['family'];
            _familyMembers = result['members'] ?? [];
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _myFamily = null;
            _familyMembers = [];
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading family data: $e');
    }
  }

  double _calculateProgress() {
    if (_checklistController.checklists == null ||
        _checklistController.checklists!.isEmpty) {
      return 0.0;
    }

    int totalItems = 0;
    int completedItems = 0;

    for (var checklist in _checklistController.checklists!) {
      totalItems += checklist.items?.length ?? 0;
      for (var item in checklist.items ?? []) {
        if (item is Map && item['completed'] == true) {
          completedItems++;
        }
      }
    }

    return totalItems == 0 ? 0.0 : completedItems / totalItems;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final progress = _calculateProgress();

    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF0F4F8),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
              const SizedBox(height: 16),
              const Text('Loading readiness data...'),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF0F4F8),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: AppColors.danger,
              ),
              const SizedBox(height: 16),
              Text(_errorMessage ?? 'Unknown error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadAllData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadAllData,
          color: AppColors.primary,
          child: CustomScrollView(
            slivers: [
              // AppBar
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    screenWidth * 0.05,
                    screenHeight * 0.02,
                    screenWidth * 0.05,
                    0,
                  ),
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
                          SizedBox(width: screenWidth * 0.03),
                          Text(
                            'EvacuWays',
                            style: TextStyle(
                              fontSize: screenWidth > 600 ? 24 : 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
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
                    ],
                  ),
                ),
              ),

              // Readiness Banner
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    screenWidth * 0.05,
                    screenHeight * 0.025,
                    screenWidth * 0.05,
                    0,
                  ),
                  child: Container(
                    padding: EdgeInsets.all(screenWidth * 0.05),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '${(progress * 100).toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: screenWidth > 600 ? 48 : 40,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primary,
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.02),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'READINESS',
                                  style: TextStyle(
                                    fontSize: screenWidth > 600 ? 13 : 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.5,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  'PROGRESS CHECK',
                                  style: TextStyle(
                                    fontSize: screenWidth > 600 ? 11 : 9,
                                    letterSpacing: 1.2,
                                    color: AppColors.textHint,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: screenHeight * 0.015),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 8,
                            backgroundColor: const Color(0xFFE0E7EF),
                            valueColor: const AlwaysStoppedAnimation(
                              AppColors.primary,
                            ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.015),
                        Text(
                          'Your resilience depends on preparation. Ensure every essential is verified before an emergency occurs.',
                          style: TextStyle(
                            fontSize: screenWidth > 600 ? 14 : 13,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(child: SizedBox(height: screenHeight * 0.02)),

              // Checklists from API
              if (_checklistController.checklists != null &&
                  _checklistController.checklists!.isNotEmpty)
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final checklist = _checklistController.checklists![index];
                    final isExpanded = _expandedState[index] ?? false;
                    final items = checklist.items ?? [];
                    final completedCount = items
                        .where((i) => i is Map && i['completed'] == true)
                        .length;

                    return Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.05,
                        vertical: screenHeight * 0.01,
                      ),
                      child: _CategoryCard(
                        icon: _getIconForCategory(index),
                        iconBg: _getBackgroundColorForCategory(index),
                        iconColor: _getIconColorForCategory(index),
                        title: checklist.checklistName ?? 'Checklist',
                        subtitle:
                            '$completedCount of ${items.length} tasks completed',
                        isExpanded: isExpanded,
                        onToggle: () =>
                            setState(() => _expandedState[index] = !isExpanded),
                        items: items,
                        onItemChecked: (itemIndex, value) {
                          setState(() {
                            if (items[itemIndex] is Map) {
                              items[itemIndex]['completed'] = value;
                            }
                          });
                        },
                        onDelete: () {
                          _showDeleteConfirmation(
                            index,
                            checklist.checklistName ?? 'Checklist',
                          );
                        },
                      ),
                    );
                  }, childCount: _checklistController.checklists?.length ?? 0),
                )
              else
                SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(screenHeight * 0.05),
                      child: const Text('No checklists available'),
                    ),
                  ),
                ),

              SliverToBoxAdapter(child: SizedBox(height: screenHeight * 0.02)),

              // Share Progress
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                  child: Container(
                    padding: EdgeInsets.all(screenWidth * 0.045),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.wifi_tethering,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.03),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Share Progress',
                                style: TextStyle(
                                  fontSize: screenWidth > 600 ? 18 : 16,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Update your family circle',
                                style: TextStyle(
                                  fontSize: screenWidth > 600 ? 13 : 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.send,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(child: SizedBox(height: screenHeight * 0.02)),

              // Family Group Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                  child: _buildFamilyGroupSection(),
                ),
              ),

              SliverToBoxAdapter(child: SizedBox(height: screenHeight * 0.05)),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // Family Group UI Components
  // ==========================================

  Widget _buildFamilyGroupSection() {
    if (_myFamily != null) {
      return _buildActiveFamilySection();
    } else {
      return _buildCreateFamilyPrompt();
    }
  }

  Widget _buildCreateFamilyPrompt() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.family_restroom, color: Colors.blue[800], size: 28),
              const SizedBox(width: 10),
              Text(
                "Group As Family",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[900],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            "Create a family group to coordinate rescue efforts and share preparedness progress with your loved ones.",
            style: TextStyle(fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _familyNameController,
            decoration: InputDecoration(
              labelText: "Family Name",
              hintText: "e.g., Semiller's Family",
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.check_circle, color: AppColors.primary),
                onPressed: _createFamily,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _createFamily,
              child: _isFamilyLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      "CREATE FAMILY GROUP",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFamilySection() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _myFamily?.familyName ?? "My Family",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      "${_familyMembers.length} Members • ${_myFamily?.rescueStatus ?? 'Pending'}",
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _showAddMemberDialog,
                icon: const Icon(
                  Icons.person_add_alt_1,
                  color: AppColors.primary,
                ),
                tooltip: "Add Member",
              ),
            ],
          ),
          const Divider(height: 30),

          // Members List
          ...List.generate(_familyMembers.length, (index) {
            final member = _familyMembers[index];
            final bool isMe =
                member['user_id'] == authController.currentUser?.userId;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: isMe
                        ? AppColors.primary
                        : Colors.grey[200],
                    radius: 18,
                    child: Text(
                      member['first_name']?[0] ?? "?",
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.grey[800],
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${member['first_name']} ${member['last_name']} ${isMe ? '(Me)' : ''}",
                          style: TextStyle(
                            fontWeight: isMe
                                ? FontWeight.bold
                                : FontWeight.w500,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          member['role'] ?? "Member",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _getStatusBadge(member['rescue_status']),
                ],
              ),
            );
          }),

          const Divider(height: 30),

          // View Full Family Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                final userId = authController.currentUser?.userId;
                if (userId != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FamilyListScreen(userId: userId),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.groups),
              label: const Text(
                "VIEW FULL FAMILY",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          const Divider(height: 30),

          // Emergency Action
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.red,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                "Emergency Action",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _showReportMissingDialog,
              icon: const Icon(Icons.campaign),
              label: const Text(
                "REPORT MISSING MEMBER",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getStatusBadge(String? status) {
    Color color = Colors.grey;
    if (status == 'Rescued') color = Colors.green;
    if (status == 'Pending Rescue') color = Colors.orange;
    if (status == 'Missing') color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status ?? 'Standard',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  // ==========================================
  // Family Operations Logic
  // ==========================================

  Future<void> _createFamily() async {
    final user = authController.currentUser;
    if (user == null || _familyNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a family name")),
      );
      return;
    }

    setState(() => _isFamilyLoading = true);

    try {
      final result = await _userController.createFamily(
        user.userId,
        _familyNameController.text.trim(),
        user.contactNumber,
      );

      if (mounted) {
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Family group created!")),
          );
          // Refresh user data (user now has familyId)
          final updatedUser = await _userController.getUserProfile(user.userId);
          if (updatedUser != null) {
            authController.currentUser = updatedUser;
          }
          await _loadFamilyData();
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(result['message'])));
        }
      }
    } finally {
      if (mounted) setState(() => _isFamilyLoading = false);
    }
  }

  void _showAddMemberDialog() {
    if (_myFamily == null) return;
    
    showDialog(
      context: context,
      builder: (context) => _AddMemberDialog(
        userController: _userController,
        familyId: _myFamily!.familyId,
        headId: authController.currentUser!.userId,
        onMemberAdded: _loadFamilyData,
      ),
    );
  }

  void _showReportMissingDialog() {
    final reporter = authController.currentUser;
    if (reporter == null || _myFamily == null) return;

    showDialog(
      context: context,
      builder: (context) => _ReportMissingDialog(
        userController: _userController,
        familyId: _myFamily!.familyId,
        reporterId: reporter.userId,
        onReported: _loadFamilyData,
      ),
    );
  }

  void _showDeleteConfirmation(int index, String checklistName) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Checklist'),
          content: Text('Are you sure you want to delete "$checklistName"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _deleteChecklist(index);
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: AppColors.danger),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteChecklist(int index) async {
    try {
      final checklist = _checklistController.checklists![index];
      final result = await _checklistController.deleteChecklist(
        checklist.checklistId,
      );

      if (result['success']) {
        setState(() {
          _checklistController.checklists!.removeAt(index);
          _expandedState.remove(index);
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Checklist deleted successfully')),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: ${result['message']}')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete checklist: $e')));
    }
  }

  IconData _getIconForCategory(int index) {
    final categoryName =
        (_checklistController.checklists?[index].checklistName ?? '')
            .toLowerCase();
    if (categoryName.contains('typhoon')) return Icons.waves;
    if (categoryName.contains('medical')) return Icons.medical_services;
    if (categoryName.contains('elderly')) return Icons.elderly;
    if (categoryName.contains('pwd')) return Icons.accessibility;
    if (categoryName.contains('children')) return Icons.child_care;
    if (categoryName.contains('emergency')) return Icons.warning;
    if (categoryName.contains('pet')) return Icons.pets;
    if (categoryName.contains('document')) return Icons.description;
    return Icons.checklist;
  }

  Color _getBackgroundColorForCategory(int index) {
    final categoryName =
        (_checklistController.checklists?[index].checklistName ?? '')
            .toLowerCase();
    if (categoryName.contains('typhoon')) return const Color(0xFFFFEBEE);
    if (categoryName.contains('medical')) return const Color(0xFFE3F2FD);
    if (categoryName.contains('elderly')) return const Color(0xFFFFF3E0);
    if (categoryName.contains('pwd')) return const Color(0xFFE8F5E9);
    if (categoryName.contains('children')) return const Color(0xFFFCE4EC);
    if (categoryName.contains('emergency')) return const Color(0xFFFFF3E0);
    if (categoryName.contains('pet')) return const Color(0xFFE0F2F1);
    if (categoryName.contains('document')) return const Color(0xFFF3E5F5);
    return const Color(0xFFEEEEEE);
  }

  Color _getIconColorForCategory(int index) {
    final categoryName =
        (_checklistController.checklists?[index].checklistName ?? '')
            .toLowerCase();
    if (categoryName.contains('typhoon')) return AppColors.danger;
    if (categoryName.contains('medical')) return AppColors.info;
    if (categoryName.contains('elderly')) return AppColors.warning;
    if (categoryName.contains('pwd')) return const Color(0xFF4CAF50);
    if (categoryName.contains('children')) return const Color(0xFFE91E63);
    if (categoryName.contains('emergency')) return AppColors.warning;
    if (categoryName.contains('pet')) return const Color(0xFF009688);
    if (categoryName.contains('document')) return const Color(0xFF9C27B0);
    return AppColors.primary;
  }
}

class _CategoryCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg, iconColor;
  final String title, subtitle;
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback? onDelete;
  final List<dynamic> items;
  final Function(int, bool) onItemChecked;

  const _CategoryCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.isExpanded,
    required this.onToggle,
    required this.items,
    required this.onItemChecked,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: onToggle,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: EdgeInsets.all(screenWidth * 0.04),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                  SizedBox(width: screenWidth * 0.03),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: screenWidth > 600 ? 17 : 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: screenWidth > 600 ? 13 : 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.textSecondary,
                  ),
                  if (onDelete != null)
                    GestureDetector(
                      onTap: onDelete,
                      child: Padding(
                        padding: EdgeInsets.only(left: screenWidth * 0.02),
                        child: Icon(
                          Icons.delete_outline,
                          color: AppColors.danger,
                          size: 20,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (isExpanded && items.isNotEmpty)
            ...List.generate(items.length, (i) {
              final item = items[i];
              final isCompleted = item is Map && item['completed'] == true;
              final description = item is Map
                  ? (item['item_description'] ?? '')
                  : '';

              return Padding(
                padding: EdgeInsets.fromLTRB(
                  screenWidth * 0.04,
                  0,
                  screenWidth * 0.04,
                  screenWidth * 0.035,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => onItemChecked(i, !isCompleted),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? AppColors.primary
                              : Colors.transparent,
                          shape: BoxShape.circle,
                          border: isCompleted
                              ? null
                              : Border.all(color: AppColors.divider, width: 2),
                        ),
                        child: isCompleted
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 14,
                              )
                            : null,
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.03),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            description.split(' - ')[0],
                            style: TextStyle(
                              fontSize: screenWidth > 600 ? 15 : 14,
                              fontWeight: FontWeight.w600,
                              color: isCompleted
                                  ? AppColors.textSecondary
                                  : AppColors.textPrimary,
                              decoration: isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          if (description.contains(' - '))
                            Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Text(
                                description.split(' - ').sublist(1).join(' - '),
                                style: TextStyle(
                                  fontSize: screenWidth > 600 ? 13 : 12,
                                  color: AppColors.textSecondary,
                                  height: 1.3,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _AddMemberDialog extends StatefulWidget {
  final UserController userController;
  final int familyId;
  final int headId;
  final Function onMemberAdded;

  const _AddMemberDialog({
    required this.userController,
    required this.familyId,
    required this.headId,
    required this.onMemberAdded,
  });

  @override
  State<_AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends State<_AddMemberDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<UserModel> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Add Family Member"),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Search for a user by first name or contact number to add them to your family.",
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: "First Name or Contact Number",
                hintText: "e.g., John or 0912...",
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => _performSearch(),
                ),
              ),
              onSubmitted: (_) => _performSearch(),
            ),
            const SizedBox(height: 20),
            if (_isSearching)
              const Center(child: CircularProgressIndicator())
            else if (_searchResults.isEmpty && _searchController.text.isNotEmpty)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  "No users found.",
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final user = _searchResults[index];
                    return ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.person),
                      ),
                      title: Text("${user.firstName} ${user.lastName}"),
                      subtitle: Text(user.contactNumber),
                      trailing: ElevatedButton(
                        onPressed: () => _addMember(user.contactNumber),
                        child: const Text("Add"),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Close"),
        ),
      ],
    );
  }

  Future<void> _performSearch() async {
    if (_searchController.text.isEmpty) return;
    setState(() => _isSearching = true);
    final results = await widget.userController.searchUsers(_searchController.text);
    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  Future<void> _addMember(String contactNumber) async {
    final result = await widget.userController.addFamilyMember(
      widget.familyId,
      widget.headId,
      contactNumber,
    );

    if (mounted) {
      if (result['success']) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
        widget.onMemberAdded();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? "Error adding member")),
        );
      }
    }
  }
}

class _ReportMissingDialog extends StatefulWidget {
  final UserController userController;
  final int familyId;
  final int reporterId;
  final Function onReported;

  const _ReportMissingDialog({
    required this.userController,
    required this.familyId,
    required this.reporterId,
    required this.onReported,
  });

  @override
  State<_ReportMissingDialog> createState() => _ReportMissingDialogState();
}

class _ReportMissingDialogState extends State<_ReportMissingDialog> {
  late TextEditingController _countController;
  final TextEditingController _notesController = TextEditingController();
  int _missingCount = 1;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _countController = TextEditingController(text: _missingCount.toString());
  }

  @override
  void dispose() {
    _countController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Report Missing Member(s)"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Please provide details to alert the admin."),
            const SizedBox(height: 15),
            TextField(
              controller: _countController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "How many members are missing?",
                border: OutlineInputBorder(),
              ),
              onChanged: (val) {
                _missingCount = int.tryParse(val) ?? 1;
              },
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Additional Notes (Names, last seen, etc.)",
                border: OutlineInputBorder(),
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
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          onPressed: _isSubmitting ? null : _submitReport,
          child: const Text("Submit Report"),
        ),
      ],
    );
  }

  Future<void> _submitReport() async {
    setState(() => _isSubmitting = true);
    try {
      final result = await widget.userController.reportMissing(
        widget.familyId,
        widget.reporterId,
        _missingCount,
        _notesController.text,
      );

      if (mounted) {
        if (result['success'] == true) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Alert sent to Admin immediately.")),
          );
          widget.onReported();
        } else {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Error reporting missing')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
