import 'constants.dart';

/// Form Validators
///
/// Collection of validators for common form fields

class AppValidators {
  /// Validate password strength
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain an uppercase letter';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain a lowercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain a number';
    }
    return null;
  }

  /// Validate email format
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final regex = RegExp(AppConstants.emailPattern);
    if (!regex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  /// Validate phone number format (Philippine)
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    final cleanedValue = value.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleanedValue.length < 10) {
      return 'Phone number must be at least 10 digits';
    }
    if (cleanedValue.length > 13) {
      return 'Phone number is too long';
    }
    return null;
  }

  /// Validate name field
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (value.length > 100) {
      return 'Name is too long';
    }
    return null;
  }

  /// Validate first name
  static String? validateFirstName(String? value) {
    if (value == null || value.isEmpty) {
      return 'First name is required';
    }
    if (value.length < 2) {
      return 'First name must be at least 2 characters';
    }
    if (value.length > 50) {
      return 'First name is too long';
    }
    return null;
  }

  /// Validate last name
  static String? validateLastName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Last name is required';
    }
    if (value.length < 2) {
      return 'Last name must be at least 2 characters';
    }
    if (value.length > 50) {
      return 'Last name is too long';
    }
    return null;
  }

  /// Validate required field
  static String? validateRequired(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  /// Validate URL format
  static String? validateUrl(String? value) {
    if (value == null || value.isEmpty) {
      return 'URL is required';
    }
    try {
      Uri.parse(value);
    } catch (_) {
      return 'Please enter a valid URL';
    }
    return null;
  }

  /// Validate address
  static String? validateAddress(String? value) {
    if (value == null || value.isEmpty) {
      return 'Address is required';
    }
    if (value.length < 5) {
      return 'Please enter a valid address';
    }
    if (value.length > 255) {
      return 'Address is too long';
    }
    return null;
  }

  /// Validate message/text length
  static String? validateMessage(
    String? value, {
    int minLength = 1,
    int maxLength = 500,
  }) {
    if (value == null || value.isEmpty) {
      return 'Message is required';
    }
    if (value.length < minLength) {
      return 'Message must be at least $minLength characters';
    }
    if (value.length > maxLength) {
      return 'Message cannot exceed $maxLength characters';
    }
    return null;
  }

  /// Validate confirm password
  static String? validateConfirmPassword(
    String? value,
    String originalPassword,
  ) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != originalPassword) {
      return 'Passwords do not match';
    }
    return null;
  }

  /// Validate numeric input
  static String? validateNumeric(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return 'Please enter a valid number';
    }
    return null;
  }

  /// Validate age (must be 18+)
  static String? validateAge(String? value) {
    if (value == null || value.isEmpty) {
      return 'Age is required';
    }
    final age = int.tryParse(value);
    if (age == null || age < 0 || age > 150) {
      return 'Please enter a valid age';
    }
    if (age < 18) {
      return 'You must be at least 18 years old';
    }
    return null;
  }
}
