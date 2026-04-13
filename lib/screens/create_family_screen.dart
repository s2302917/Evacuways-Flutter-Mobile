import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../controllers/family_controller.dart';
import '../models/user_model.dart';

class CreateFamilyScreen extends StatefulWidget {
  final int userId;

  const CreateFamilyScreen({super.key, required this.userId});

  @override
  State<CreateFamilyScreen> createState() => _CreateFamilyScreenState();
}

class _CreateFamilyScreenState extends State<CreateFamilyScreen> {
  late FamilyController _familyController;
  final TextEditingController _familyNameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  int _selectedFamilyId = 0;
  List<UserModel> _allUsers = [];
  List<UserModel> _foundUsers = [];
  bool _isLoading = false;
  int _currentPage = 1;
  bool _isAddingMember = false;
  String _step = 'create'; // 'create' or 'add_members'

  @override
  void initState() {
    super.initState();
    _familyController = FamilyController();
  }

  Future<void> _createFamily() async {
    if (_familyNameController.text.isEmpty || _contactController.text.isEmpty) {
      _showSnackBar('Please fill all fields');
      return;
    }

    try {
      final result = await _familyController.createFamily(
        _familyNameController.text,
        _contactController.text,
        widget.userId,
      );

      if (result['success'] == true) {
        final familyId = result['family_id'];
        if (familyId != null) {
          if (mounted) {
            setState(() {
              _selectedFamilyId = familyId;
              _step = 'add_members';
            });
            _loadInitialUsers();
          }
        } else {
          _showSnackBar('No family ID returned from server');
        }
      } else {
        _showSnackBar(result['message'] ?? 'Error creating family', 4);
      }
    } catch (e) {
      debugPrint('CreateFamily Exception: $e');
      _showSnackBar('Unexpected error: $e', 4);
    }
  }

  Future<void> _loadInitialUsers() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    final users = await _familyController.getAllAvailableUsers(
      _selectedFamilyId,
      1,
    );

    if (mounted) {
      setState(() {
        _allUsers = users;
        _foundUsers = users;
        _currentPage = 1;
        _isLoading = false;
      });
    }
  }

  void _filterUsers(String searchTerm) {
    if (searchTerm.isEmpty) {
      setState(() {
        _foundUsers = _allUsers;
        _currentPage = 1;
      });
    } else {
      setState(() {
        _foundUsers = _allUsers
            .where(
              (user) =>
                  '${user.firstName} ${user.lastName}'.toLowerCase().contains(
                    searchTerm.toLowerCase(),
                  ) ||
                  user.contactNumber.toLowerCase().contains(
                    searchTerm.toLowerCase(),
                  ),
            )
            .toList();
        _currentPage = 1;
      });
    }
  }

  Future<void> _searchUsersOnServer(String query) async {
    if (query.isEmpty) {
      _loadInitialUsers();
      return;
    }

    if (!mounted) return;

    final users = await _familyController.searchUsersForFamily(
      query,
      _selectedFamilyId,
      1,
    );

    if (mounted) {
      setState(() {
        _foundUsers = users;
        _currentPage = 1;
      });
    }
  }

  Future<void> _addUserToFamily(UserModel user) async {
    setState(() => _isAddingMember = true);

    final result = await _familyController.addUserToFamily(
      _selectedFamilyId,
      user.userId,
    );

    if (mounted) {
      if (result['success']) {
        _showSnackBar('User added to family!');
        // Remove the added user from the list
        setState(() {
          _allUsers.removeWhere((u) => u.userId == user.userId);
          _foundUsers.removeWhere((u) => u.userId == user.userId);
          _isAddingMember = false;
        });
      } else {
        setState(() => _isAddingMember = false);
        _showSnackBar(result['message'] ?? 'Error adding user');
      }
    }
  }

  void _previousPage() {
    if (_currentPage > 1) {
      setState(() => _currentPage--);
      _searchUsersOnServer(_searchController.text);
    }
  }

  void _nextPage() {
    if (_foundUsers.length >= 10) {
      setState(() => _currentPage++);
      _searchUsersOnServer(_searchController.text);
    }
  }

  void _showSnackBar(String message, [int duration = 2]) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: duration),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    if (_step == 'create') {
      return Scaffold(
        backgroundColor: const Color(0xFFF0F4F8),
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          title: const Text(
            'Create Family Group',
            style: TextStyle(color: Colors.white),
          ),
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(screenWidth * 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: screenHeight * 0.02),
              Text(
                'Family Name',
                style: TextStyle(
                  fontSize: screenWidth > 600 ? 16 : 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: screenHeight * 0.01),
              TextField(
                controller: _familyNameController,
                decoration: InputDecoration(
                  hintText: "e.g., Semiller's Family",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.divider),
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.03),
              Text(
                'Primary Contact Number',
                style: TextStyle(
                  fontSize: screenWidth > 600 ? 16 : 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: screenHeight * 0.01),
              TextField(
                controller: _contactController,
                decoration: InputDecoration(
                  hintText: "09",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.divider),
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.05),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _createFamily,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Create Family',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return Scaffold(
        backgroundColor: const Color(0xFFF0F4F8),
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          title: const Text(
            'Add Family Members',
            style: TextStyle(color: Colors.white),
          ),
          elevation: 0,
        ),
        body: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(screenWidth * 0.04),
              child: TextField(
                controller: _searchController,
                onChanged: _filterUsers,
                decoration: InputDecoration(
                  hintText: 'Search by name',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.divider),
                  ),
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _foundUsers.isEmpty
                  ? Center(
                      child: Text(
                        _searchController.text.isEmpty
                            ? 'No users available to add'
                            : 'No users found',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.04,
                      ),
                      itemCount: _foundUsers.length,
                      itemBuilder: (context, index) {
                        final user = _foundUsers[index];
                        return Card(
                          margin: EdgeInsets.symmetric(
                            vertical: screenHeight * 0.01,
                          ),
                          child: ListTile(
                            title: Text(
                              '${user.firstName} ${user.lastName}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(user.contactNumber),
                            trailing: _isAddingMember
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : ElevatedButton(
                                    onPressed: () => _addUserToFamily(user),
                                    child: const Text('Add'),
                                  ),
                          ),
                        );
                      },
                    ),
            ),
            if (_foundUsers.isNotEmpty)
              Padding(
                padding: EdgeInsets.all(screenWidth * 0.04),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: _currentPage > 1 ? _previousPage : null,
                      child: const Text('Previous'),
                    ),
                    Text('Page $_currentPage'),
                    ElevatedButton(
                      onPressed: _foundUsers.length >= 10 ? _nextPage : null,
                      child: const Text('Next'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    _familyNameController.dispose();
    _contactController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
