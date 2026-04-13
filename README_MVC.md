# EvacuWays Flutter App - MVC Architecture Implementation

## 🎯 Project Overview

EvacuWays is a disaster management and evacuation coordination application built with Flutter. It follows a **Model-View-Controller (MVC)** architectural pattern to ensure clean, maintainable, and scalable code.

## 📁 Project Structure

```
lib/
├── models/                      # Data Models (M)
├── controllers/                 # Business Logic Controllers (C)
├── views/                       # UI Views & Screens (V)
├── services/                    # Service Layer
├── utils/                       # Helper Functions & Constants
├── theme/                       # App Theming
├── widgets/                     # Custom Widgets
├── main.dart                    # App Entry Point
└── MVC_STRUCTURE.md            # Architecture Documentation
```

## 🧠 Architecture Explanation

### Model Layer (`lib/models/`)
**Purpose**: Represent data structures and handle serialization/deserialization

**Key Files**:
- `user_model.dart` - User profile data
- `alert_model.dart` - Emergency alerts
- `vehicle_model.dart` - Rescue vehicles
- `evacuation_center_model.dart` - Evacuation centers
- And 14+ more model classes

**Features**:
- fromJson() factory methods for API parsing
- toJson() methods for sending data to server
- Immutable properties (final keyword)
- Type-safe data handling

### Controller Layer (`lib/controllers/`)
**Purpose**: Handle business logic and API communication

**Key Controllers**:
- `AuthController` - User login, registration, password reset
- `UserController` - User profile operations
- `AlertController` - Alert management
- `VehicleController` - Vehicle tracking & management
- `EvacuationCenterController` - Center information
- `MessageController` - Messaging system
- `SupportRequestController` - Help requests
- `ChecklistController` - Evacuation checklists
- `LocationController` - Geographic data

**Features**:
- Centralized API communication
- Business logic processing
- Error handling & validation
- Consistent response formats

### View Layer (`lib/views/`)
**Purpose**: Present UI and handle user interactions

**Screen Organization**:
```
views/screens/
├── auth/                   # Login, Registration, Password Reset
├── home/                   # Home & Dashboard
├── evacuation/             # Maps, SOS, Checklists, Centers
├── communication/          # Chat, Messages, Support
└── profile/               # User Profile, Settings
```

**Features**:
- Clean UI code
- User interaction handling
- Controller method calls
- Loading & error state management

### Service Layer (`lib/services/`)
**Purpose**: Provide abstracted access to external resources

**Services**:
- `ApiService` - HTTP API communication
- `LocationService` - GPS/Geolocation
- `StorageService` - Local data persistence

### Utility Layer (`lib/utils/`)
**Purpose**: Shared constants, validators, and helper functions

**Utilities**:
- `constants.dart` - App-wide constants
- `validators.dart` - Form field validators
- `helpers.dart` - Helper functions & extensions

## 🔄 Data Flow

```
┌─────────────────┐
│  User Taps UI   │
│   in View       │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│    Controller   │◄──┐
│   Method Call   │   │
└────────┬────────┘   │
         │            │
         ▼            │
┌─────────────────┐   │
│  API Service    │   │
│  / Business     │   │
│   Logic         │   │
└────────┬────────┘   │
         │            │
         ▼            │
┌─────────────────┐   │
│  Model Object   │   │
│ (Data Entity)   │───┘
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Update View    │
│   with Results  │
└─────────────────┘
```

## 📋 Database Tables → Model Classes

| Database Table | Model Class | Controller |
|---|---|---|
| Users | `UserModel` | `UserController` |
| Admins | `AdminModel` | `AuthController` |
| Alerts | `AlertModel` | `AlertController` |
| Vehicles | `VehicleModel` | `VehicleController` |
| Centers | `EvacuationCenterModel` | `EvacuationCenterController` |
| Messages | `MessageModel` | `MessageController` |
| Support Requests | `SupportRequestModel` | `SupportRequestController` |
| Checklists | `ChecklistModel` | `ChecklistController` |
| Regions | `RegionModel` | `LocationController` |
| Cities | `CityModel` | `LocationController` |
| Barangays | `BarangayModel` | `LocationController` |

## 🚀 Usage Examples

### Creating a User Profile Screen

1. **Create/Import Model**:
```dart
import 'package:evacuways/models/user_model.dart';
```

2. **Create/Import Controller**:
```dart
import 'package:evacuways/controllers/user_controller.dart';
```

3. **Build View**:
```dart
class ProfileScreen extends StatefulWidget {
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final UserController _userController;
  UserModel? _user;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _userController = UserController();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      _user = await _userController.getUserProfile(userId);
      setState(() {});
    } catch (e) {
      // Handle error
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _user != null
              ? UserProfileContent(user: _user!)
              : const Center(child: Text('No data')),
    );
  }
}
```

### Adding an Alert

1. **Prepare Data**:
```dart
AlertModel newAlert = AlertModel(
  alertId: 0,
  title: 'Flash Flood Warning',
  message: 'Evacuation ordered',
  alertType: 'Flood',
  severityLevel: 'Critical',
  createdAt: DateTime.now(),
  status: 'Active',
);
```

2. **Call Controller**:
```dart
final alertController = AlertController();
final result = await alertController.createAlert(newAlert);

if (result['success']) {
  // Show success message
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(result['message'])),
  );
} else {
  // Show error
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Error: ${result['message']}')),
  );
}
```

## 🔒 Best Practices

### ✅ DO:
- Keep models simple and focused on data
- Put all business logic in controllers
- Keep views focused on UI
- Use type-safe code (avoid dynamic types)
- Handle errors gracefully
- Use model.toJson() when sending to API
- Use ModelClass.fromJson() when receiving from API
- Use StateManagement solution (Provider/Riverpod/GetX) for larger apps

### ❌ DON'T:
- Make API calls directly from views
- Put business logic in UI code
- Create complex models with methods
- Use untyped responses
- Ignore error cases
- Hardcode strings in views
- Import multiple modules in views directly

## 📝 Adding New Features

### Checklist:

1. **Create Model** (`lib/models/feature_model.dart`)
   - [ ] Define data class with fields
   - [ ] Add fromJson() factory
   - [ ] Add toJson() method
   - [ ] Export from models/index.dart

2. **Create Controller** (`lib/controllers/feature_controller.dart`)
   - [ ] Define controller class
   - [ ] Add API methods (GET, POST, PUT, DELETE)
   - [ ] Handle responses
   - [ ] Add error handling
   - [ ] Export from controllers/index.dart

3. **Create Views** (`lib/views/screens/feature/`)
   - [ ] Create screen files
   - [ ] Import models & controllers
   - [ ] Implement UI
   - [ ] Call controller methods
   - [ ] Handle state management
   - [ ] Export from views/index.dart

4. **Update Routes** (`main.dart`)
   - [ ] Add route definitions
   - [ ] Update navigation

## 🛠️ Development Workflow

### Typical Feature Development:

```
1. DEFINE → Create Model (data structure)
   ↓
2. CONNECT → Create Controller (business logic)
   ↓
3. DISPLAY → Create View (user interface)
   ↓
4. INTEGRATE → Update routes & navigation
   ↓
5. TEST → Verify feature works end-to-end
```

## 📦 Dependencies

Key packages used:
```yaml
flutter:
  sdk: flutter

http: ^1.1.0                      # API calls
google_fonts: ^6.1.0              # Typography
google_maps_flutter: ^2.5.0        # Maps
geolocator: ^10.0.0               # Location services
geocoding: ^3.0.0                 # Address conversion
shared_preferences: ^2.2.0        # Local storage
intl: ^0.19.0                     # Internationalization
```

## 🔍 Testing

When testing the architecture:

1. **Test Models**: Verify JSON serialization
   ```dart
   test('UserModel fromJson', () {
     final json = {'user_id': 1, 'first_name': 'Juan'};
     final user = UserModel.fromJson(json);
     expect(user.userId, 1);
   });
   ```

2. **Test Controllers**: Mock API responses
   ```dart
   test('AuthController login', () async {
     final auth = AuthController();
     final result = await auth.login('09171234567', 'password');
     expect(result['success'], true);
   });
   ```

3. **Test Views**: Verify UI interactions
   ```dart
   testWidgets('Login screen shows fields', (tester) async {
     await tester.pumpWidget(const EvacuWaysApp());
     expect(find.byType(TextField), findsWidgets);
   });
   ```

## 📚 Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Dart Language Guide](https://dart.dev/guides)
- [MVC Pattern](https://www.geeksforgeeks.org/mvc-model-view-controller/)
- [RESTful API Design](https://restfulapi.net/)

## 🚨 Troubleshooting

### Models not found?
- Check `models/index.dart` exports
- Verify file names match import statements

### Controllers not responding?
- Check API endpoint URLs in constants
- Verify network connectivity
- Check response status codes (log them)

### Views not updating?
- Use `setState(() {})` for local state
- Consider state management solution for complex apps
- Check if controller method is actually being called

## 📞 Support

For issues or questions about the MVC structure:
1. Check `MVC_STRUCTURE.md` for detailed docs
2. Review example implementations in existing screens
3. Check controller methods for API endpoints

---

**Last Updated**: March 2026
**Architecture Pattern**: MVC (Model-View-Controller)
**Target Platform**: Cross-platform (iOS, Android, Web, Desktop)
