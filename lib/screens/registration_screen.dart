import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../theme/app_colors.dart';
import '../controllers/auth_controller.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  String? _selectedGender;
  String? _selectedRole = 'Regular User';
  String? _selectedProvince = 'Negros Occidental';
  DateTime? _birthDate;
  double? _latitude;
  double? _longitude;
  bool _isLoading = false;

  final List<String> _roles = [
    'Regular User',
    'Volunteer',
    'Vehicle Driver',
    'Personnel',
    'Admin'
  ];

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _contactController = TextEditingController();
  final _passwordController = TextEditingController();
  final _cityController = TextEditingController();
  final _barangayController = TextEditingController();

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled.')),
        );
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied.')),
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permissions are permanently denied.'),
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });

      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          setState(() {
            if (place.locality != null) _cityController.text = place.locality!;
            if (place.subLocality != null && place.subLocality!.isNotEmpty) {
              _barangayController.text = place.subLocality!;
            } else if (place.name != null) {
              _barangayController.text = place.name!;
            }
          });
        }
      } catch (e) {
        debugPrint('Geocoding error: $e');
      }

      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location Pinned & Details Fetched!')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      String errorMsg = 'Error getting location: $e';
      if (e.toString().contains('timeout')) {
        errorMsg = 'Location request timed out.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg)));
      }
    }
  }

  void _handleRegister() async {
    if (_firstNameController.text.isEmpty ||
        _lastNameController.text.isEmpty ||
        _contactController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final userData = {
      'first_name': _firstNameController.text.trim(),
      'last_name': _lastNameController.text.trim(),
      'role': _selectedRole?.toLowerCase(),
      'password': _passwordController.text,
      'gender': _selectedGender,
      'birth_date': _birthDate?.toIso8601String().split('T')[0],
      'contact_number': _contactController.text.trim(),
      'region_code': '06',
      'city_code': _cityController.text.trim(),
      'barangay_code': _barangayController.text.trim(),
      'latitude': _latitude,
      'longitude': _longitude,
    };

    final result = await authController.register(userData);

    if (mounted) {
      setState(() => _isLoading = false);
      if (result['success'] == true) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Registration failed'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  final List<String> _genders = ['Male', 'Female', 'Prefer not to say'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo row
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.shield,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'EvacuWays',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Hero text
              RichText(
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                    height: 1.1,
                  ),
                  children: [
                    TextSpan(text: 'Your Safety,\n'),
                    TextSpan(
                      text: 'Our Mission.',
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'Join the resilient community of Western Visayas. Register today for real-time alerts and evacuation guidance.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 24),

              // Form card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section: Personal Identity
                    Row(
                      children: [
                        const Icon(
                          Icons.badge_outlined,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'PERSONAL IDENTITY',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildLabel('First Name'),
                    const SizedBox(height: 6),
                    _buildTextField(
                      hint: 'Alex',
                      controller: _firstNameController,
                    ),
                    const SizedBox(height: 14),
                    _buildLabel('Last Name'),
                    const SizedBox(height: 6),
                    _buildTextField(
                      hint: 'Santos',
                      controller: _lastNameController,
                    ),
                    const SizedBox(height: 14),
                    _buildLabel('Gender'),
                    const SizedBox(height: 6),
                    _buildDropdown(
                      hint: 'Select Gender',
                      value: _selectedGender,
                      items: _genders,
                      onChanged: (v) => setState(() => _selectedGender = v),
                    ),
                    const SizedBox(height: 14),
                    _buildLabel('Birth Date'),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime(1990),
                          firstDate: DateTime(1920),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) setState(() => _birthDate = picked);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.inputFill,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _birthDate != null
                                  ? '${_birthDate!.month.toString().padLeft(2, '0')}/${_birthDate!.day.toString().padLeft(2, '0')}/${_birthDate!.year}'
                                  : 'mm/dd/yyyy',
                              style: TextStyle(
                                color: _birthDate != null
                                    ? AppColors.textPrimary
                                    : AppColors.textHint,
                                fontSize: 15,
                              ),
                            ),
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 18,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),
                    _buildLabel('Account Role'),
                    const SizedBox(height: 6),
                    _buildDropdown(
                      hint: 'Select Role',
                      value: _selectedRole,
                      items: _roles,
                      onChanged: (v) => setState(() => _selectedRole = v),
                    ),
                    const SizedBox(height: 24),

                    // Section: Contact & Location
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'CONTACT & LOCATION',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildLabel('Contact Number'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _contactController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: '917 123 4567',
                        hintStyle: const TextStyle(color: AppColors.textHint),
                        prefixIcon: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                          child: const Text(
                            '',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 0,
                        ),
                        filled: true,
                        fillColor: AppColors.inputFill,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildLabel('Password'),
                    const SizedBox(height: 6),
                    _buildTextField(
                      hint: '••••••••',
                      controller: _passwordController,
                      isPassword: true,
                    ),
                    const SizedBox(height: 14),
                    _buildLabel('Province'),
                    const SizedBox(height: 6),
                    _buildDropdown(
                      hint: 'Select Province',
                      value: _selectedProvince,
                      items: [
                        'Aklan',
                        'Antique',
                        'Capiz',
                        'Guimaras',
                        'Iloilo',
                        'Negros Occidental',
                      ],
                      onChanged: (v) => setState(() => _selectedProvince = v),
                    ),
                    const SizedBox(height: 14),
                    _buildLabel('City / Municipality'),
                    const SizedBox(height: 6),
                    _buildTextField(
                      hint: 'Iloilo City',
                      controller: _cityController,
                    ),
                    const SizedBox(height: 14),
                    _buildLabel('Barangay'),
                    const SizedBox(height: 6),
                    _buildTextField(
                      hint: 'Brgy. San Vicente',
                      controller: _barangayController,
                    ),
                    const SizedBox(height: 20),
                    _buildLabel('Location Pin'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.inputFill,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _latitude != null && _longitude != null
                                  ? '${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}'
                                  : 'Pin not set',
                              style: TextStyle(
                                fontSize: 14,
                                color: _latitude != null
                                    ? AppColors.textPrimary
                                    : AppColors.textHint,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _getCurrentLocation,
                          icon: const Icon(
                            Icons.my_location,
                            size: 18,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Pin GPS',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 15,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Create Account button
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _handleRegister,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.arrow_forward, color: Colors.white),
                label: Text(
                  _isLoading ? 'Creating Account...' : 'Create Account',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  disabledBackgroundColor: AppColors.danger.withValues(
                    alpha: 0.6,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),

              const SizedBox(height: 14),

              // Back to Login
              TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                label: const Text(
                  'Back to Login',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Center(
                child: RichText(
                  textAlign: TextAlign.center,
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    children: [
                      TextSpan(text: 'By registering, you agree to our '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      TextSpan(
                        text:
                            '\nregarding emergency data handling in Western Visayas.',
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildTextField({
    required String hint,
    TextEditingController? controller,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textHint),
        filled: true,
        fillColor: AppColors.inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: DropdownButton<String>(
        value: value,
        hint: Text(hint, style: const TextStyle(color: AppColors.textHint)),
        isExpanded: true,
        underline: const SizedBox(),
        icon: const Icon(
          Icons.keyboard_arrow_down,
          color: AppColors.textSecondary,
        ),
        items: items
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}
