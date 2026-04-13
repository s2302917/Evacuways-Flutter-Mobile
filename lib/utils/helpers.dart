import 'package:intl/intl.dart';

/// Helper Functions
///
/// Utility functions for common operations

class AppHelpers {
  /// Format date time to readable string
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy HH:mm').format(dateTime);
  }

  /// Format date only
  static String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  /// Format time only
  static String formatTime(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }

  /// Get relative time (e.g., "2 hours ago")
  static String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else {
      return formatDate(dateTime);
    }
  }

  /// Format phone number
  static String formatPhoneNumber(String phoneNumber) {
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    // Handle different Philippine phone formats
    if (cleaned.startsWith('0')) {
      cleaned = '+63${cleaned.substring(1)}';
    } else if (!cleaned.startsWith('+')) {
      cleaned = '+63$cleaned';
    }

    return cleaned;
  }

  /// Format currency
  static String formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'fil_PH',
      symbol: '₱',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  /// Format large numbers (1000 => 1K, 1000000 => 1M)
  static String formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  /// Get initials from name
  static String getInitials(String firstName, String lastName) {
    return '${firstName.isNotEmpty ? firstName[0].toUpperCase() : ''}${lastName.isNotEmpty ? lastName[0].toUpperCase() : ''}';
  }

  /// Get full name
  static String getFullName(String firstName, String lastName) {
    return '$firstName $lastName'.trim();
  }

  /// Capitalize first letter
  static String capitalize(String text) {
    if (text.isEmpty) return '';
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  /// Capitalize each word
  static String capitalizeEachWord(String text) {
    return text
        .split(' ')
        .map((word) => word.isEmpty ? '' : capitalize(word))
        .join(' ');
  }

  /// Truncate string with ellipsis
  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - 3)}...';
  }

  /// Check if string is empty or null
  static bool isEmpty(String? value) {
    return value == null || value.trim().isEmpty;
  }

  /// Parse distance in kilometers to readable format
  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)}m';
    }
    return '${(meters / 1000).toStringAsFixed(1)}km';
  }

  /// Parse battery percentage
  static String formatBattery(int percentage) {
    if (percentage >= 75) {
      return 'FULL';
    } else if (percentage >= 50) {
      return 'GOOD';
    } else if (percentage >= 25) {
      return 'LOW';
    }
    return 'CRITICAL';
  }

  /// Generate a unique ID
  static String generateUniqueId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }

  /// Check if device is in portrait mode (mobile)
  static bool isPortraitMode(double width, double height) {
    return height > width;
  }

  /// Convert hex color to dart Color
  static int hexColorToInt(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return int.parse(hexColor, radix: 16);
  }

  /// Get age from birth date
  static int getAgeFromBirthDate(DateTime birthDate) {
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  /// Check if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Check if date is yesterday
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  /// Get plural form of word
  static String pluralize(String word, int count) {
    return count == 1 ? word : '${word}s';
  }
}

/// Number formatting extension
extension NumberFormatting on num {
  String toFormattedString() {
    return AppHelpers.formatNumber(toInt());
  }
}

/// String extension
extension StringFormatting on String {
  String capitalize() {
    return AppHelpers.capitalize(this);
  }

  bool isEmpty() {
    return AppHelpers.isEmpty(this);
  }

  String truncate(int maxLength) {
    return AppHelpers.truncate(this, maxLength);
  }
}

/// DateTime extension
extension DateTimeFormatting on DateTime {
  String formatted() {
    return AppHelpers.formatDateTime(this);
  }

  String formattedDate() {
    return AppHelpers.formatDate(this);
  }

  String relative() {
    return AppHelpers.getRelativeTime(this);
  }
}
