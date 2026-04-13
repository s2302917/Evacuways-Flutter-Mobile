# EvacuWays Flutter App - MVC Project Structure

## Overview
This project follows the **Model-View-Controller (MVC)** architectural pattern for better code organization, scalability, and maintainability.

## Directory Structure

```
lib/
├── models/                    # Data Models (Database Layer)
│   ├── admin_model.dart
│   ├── alert_model.dart
│   ├── barangay_model.dart
│   ├── center_model.dart
│   ├── checklist_model.dart
│   ├── city_model.dart
│   ├── evacuation_center_model.dart
│   ├── family_model.dart
│   ├── message_model.dart
│   ├── region_model.dart
│   ├── report_model.dart
│   ├── support_request_model.dart
│   ├── user_location_model.dart
│   ├── user_model.dart
│   ├── vehicle_assignment_model.dart
│   ├── vehicle_model.dart
│   ├── volunteer_model.dart
│   └── index.dart             # Model exports
│
├── controllers/               # Business Logic Layer
│   ├── auth_controller.dart                    # Authentication logic
│   ├── alert_controller.dart                   # Alert management
│   ├── user_controller.dart                    # User management
│   ├── evacuation_center_controller.dart       # Center management
│   ├── vehicle_controller.dart                 # Vehicle management
│   ├── message_controller.dart                 # Messaging
│   ├── support_request_controller.dart         # Support requests
│   ├── checklist_controller.dart               # Evacuation checklists
│   ├── location_controller.dart                # Geographic data
│   └── index.dart             # Controller exports
│
├── views/                     # Presentation Layer (UI)
│   ├── screens/
│   │   ├── auth/                               # Authentication screens
│   │   │   ├── login_screen.dart
│   │   │   ├── registration_screen.dart
│   │   │   └── forgot_password_screen.dart
│   │   ├── home/                               # Home/Main screens
│   │   │   ├── home_screen.dart
│   │   │   ├── main_shell.dart
│   │   │   └── dashboard_screen.dart
│   │   ├── evacuation/                         # Evacuation-related screens
│   │   │   ├── map_screen.dart
│   │   │   ├── sos_screen.dart
│   │   │   ├── checklist_screen.dart
│   │   │   └── centers_screen.dart
│   │   ├── communication/                      # Messaging screens
│   │   │   ├── chat_screen.dart
│   │   │   ├── messages_screen.dart
│   │   │   └── support_request_screen.dart
│   │   └── profile/                            # User profile screens
│   │       ├── profile_screen.dart
│   │       └── settings_screen.dart
│   │
│   └── components/                             # Reusable UI components
│       ├── buttons/
│       ├── cards/
│       ├── dialogs/
│       └── custom_widgets.dart
│
├── services/                  # Service Layer (API/Database abstraction)
│   ├── api_service.dart                        # HTTP API calls
│   ├── database_service.dart                   # Local database operations
│   ├── location_service.dart                   # GPS/Location services
│   ├── notification_service.dart               # Push notifications
│   └── storage_service.dart                    # Local storage
│
├── utils/                     # Utility Functions & Constants
│   ├── constants.dart                          # App constants
│   ├── validators.dart                         # Form validators
│   ├── helpers.dart                            # Helper functions
│   └── extensions.dart                         # Dart extensions
│
├── theme/                     # UI Theme & Styling
│   ├── app_colors.dart
│   ├── app_text_styles.dart
│   └── app_theme.dart
│
├── widgets/                   # Custom Widgets (Legacy)
│   └── (Migrate to views/components/)
│
└── main.dart                  # App entry point
```

## Architecture Pattern Explanation

### 1. **Models** 
- Represent data entities from the database
- Handle JSON serialization/deserialization
- Include factory constructors for parsing API responses
- Include toJson() methods for sending data to API

**Example:**
```dart
class UserModel {
  final int userId;
  final String firstName;
  final String lastName;
  // ... other fields
  
  factory UserModel.fromJson(Map<String, dynamic> json) { ... }
  Map<String, dynamic> toJson() { ... }
}
```

### 2. **Controllers**
- Implement business logic
- Handle API communication
- Manage data processing and validation
- Provide methods called by Views

**Example:**
```dart
class UserController {
  Future<UserModel?> getUserProfile(int userId) async { ... }
  Future<Map<String, dynamic>> updateUserProfile(UserModel user) async { ... }
}
```

### 3. **Views (Screens)**
- Display UI elements
- Handle user interactions
- Call appropriate Controller methods
- Update UI based on Controller responses

**Example:**
```dart
class ProfileScreen extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    final userController = UserController();
    // Build UI and call controller methods
  }
}
```

## Best Practices

1. **Models**
   - Keep models focused on data representation
   - Always provide fromJson() and toJson() methods
   - Use immutable fields (final keyword)

2. **Controllers**
   - Separate business logic from UI code
   - Handle all API calls and data processing
   - Return consistent response formats
   - Include error handling

3. **Views**
   - Keep UI code clean and focused on presentation
   - Use controllers for all business logic
   - Avoid direct API calls in UI code
   - Use widgets for reusable components

## Data Flow

```
User Interaction (View)
         ↓
    Controller Method
         ↓
   Business Logic Processing
         ↓
    API/Database Call
         ↓
    Response Parsing to Model
         ↓
   Return to View
         ↓
    UI Update
```

## Migration Guide

### When adding a new feature:

1. **Create Model** (`lib/models/feature_model.dart`)
   - Define data structure
   - Add fromJson() and toJson() methods

2. **Create Controller** (`lib/controllers/feature_controller.dart`)
   - Implement API methods
   - Add business logic
   - Handle error cases

3. **Create Views** (`lib/views/screens/feature/`)
   - Create UI screens
   - Use controller methods
   - Handle state management

4. **Create Components** (`lib/views/components/`)
   - Reusable UI elements for the feature

## Integration with State Management

This structure works well with popular state managers:
- **Provider** - For simple dependency injection
- **Riverpod** - For reactive programming
- **GetX** - For full MVC framework
- **BLoC** - For complex state management

Future iterations may integrate service locator patterns like GetIt for dependency injection.

## Database Tables to Models Reference

| Database Table | Model Class | Controller |
|---|---|---|
| evacuways_users | UserModel | UserController |
| evacuways_admins | AdminModel | AuthController |
| evacuways_alerts | AlertModel | AlertController |
| evacuways_vehicles | VehicleModel | VehicleController |
| evacuways_centers | EvacuationCenterModel | EvacuationCenterController |
| evacuways_messages | MessageModel | MessageController |
| evacuways_support_requests | SupportRequestModel | SupportRequestController |
| evacuways_checklists | ChecklistModel | ChecklistController |
| evacuways_regions | RegionModel | LocationController |
| evacuways_cities | CityModel | LocationController |
| evacuways_barangays | BarangayModel | LocationController |

## File Naming Conventions

- **Models**: `feature_model.dart`
- **Controllers**: `feature_controller.dart`
- **Screens**: `feature_screen.dart`
- **Widgets/Components**: `component_name.dart`
- **Services**: `service_name_service.dart`
- **Utils**: `utils_category.dart`

## Dependencies

Key packages used:
- `http` - For API calls
- `flutter` - UI framework
- `google_fonts` - Typography
- `google_maps_flutter` - Map integration
- `geolocator` - Location services
- `geocoding` - Address conversion

---

## Getting Started

To add a new model/controller pair:

1. Copy an existing model and modify the fields
2. Copy an existing controller and update API endpoints
3. Create views that utilize the new controller
4. Export from index.dart files
5. Use in your screens

Remember: **Keep Models simple, Put logic in Controllers, Keep Views clean!**
