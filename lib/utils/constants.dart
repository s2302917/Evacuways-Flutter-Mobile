library;

/// App Constants
///
/// This file contains all constants used throughout the application
/// including API endpoints, validation patterns, and default values

class AppConstants {
  // API Configuration
  static const String apiBaseUrl =
      'https://5zu.758.mytemp.website/Evacuways/api';
  static const String apiTimeout = '30'; // seconds

  // User roles
  static const String roleAdmin = 'Super Admin';
  static const String roleUser = 'User';
  static const String roleVolunteer = 'Volunteer';

  // Rescue status
  static const String statusPendingRescue = 'Pending Rescue';
  static const String statusInTransit = 'In Transit';
  static const String statusRescued = 'Rescued';
  static const String statusMissing = 'Missing';

  // Alert types
  static const String alertTypeFlood = 'Flood';
  static const String alertTypeTyphoon = 'Typhoon';
  static const String alertTypeEarthquake = 'Earthquake';
  static const String alertTypeLandslide = 'Landslide';
  static const String alertTypeWave = 'Wave';

  // Alert severity levels
  static const String severityWarning = 'Warning';
  static const String severityCritical = 'Critical';
  static const String severityInfo = 'Information';

  // Vehicle status
  static const String vehicleStatusStandby = 'Standby';
  static const String vehicleStatusDeployed = 'Deployed';
  static const String vehicleStatusReturning = 'Returning';

  // Center status
  static const String centerStatusOpen = 'Open';
  static const String centerStatusClosed = 'Closed';
  static const String centerStatusFull = 'Full';

  // Request status
  static const String requestStatusPending = 'Pending';
  static const String requestStatusInProgress = 'In Progress';
  static const String requestStatusResolved = 'Resolved';
  static const String requestStatusCanceled = 'Canceled';

  // Message types
  static const String messageTypeText = 'text';
  static const String messageTypeImage = 'image';
  static const String messageTypeLocation = 'location';

  // Storage keys
  static const String storageKeyUserId = 'user_id';
  static const String storageKeyAuthToken = 'auth_token';
  static const String storageKeyUserData = 'user_data';
  static const String storageKeyLastLocation = 'last_location';
  static const String storageKeyAppTheme = 'app_theme';
  static const String storageKeyAppLanguage = 'app_language';

  // Default values
  static const int defaultPageSize = 20;
  static const int defaultLocationUpdateInterval = 5000; // milliseconds
  static const double defaultMapZoom = 15.0;
  static const double defaultMapPadding = 16.0;

  // Regex patterns
  static const String phonePattern = r'^(09|\+639)\d{9}$';
  static const String emailPattern =
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  static const String namePattern = r"^[a-zA-Z\s\-.']{{2,}}$";

  // Pagination
  static const int itemsPerPage = 20;
  static const int maxResults = 100;

  // Map
  static const int defaultZoomLevel = 15;
  static const double centroidLat = 10.6797237; // Bacolod, Negros Occidental
  static const double centroidLng = 122.9605826;

  // Time durations (in seconds)
  static const int defaultTimeout = 30;
  static const int refreshInterval = 60;
  static const int presenceUpdateInterval = 30;

  // File upload
  static const int maxFileSize = 10485760; // 10 MB
  static const List<String> allowedImageFormats = ['jpg', 'jpeg', 'png', 'gif'];
}
