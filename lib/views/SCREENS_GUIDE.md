# Views Migration Guide

## Screen Organization

The Views folder is organized by feature/functionality for better maintainability.

### Screen Organization Mapping

**Authentication Screens** → `views/screens/auth/`
- `login_screen.dart` - User login
- `registration_screen.dart` - New user registration
- `forgot_password_screen.dart` - Password reset flow

**Home/Dashboard Screens** → `views/screens/home/`
- `home_screen.dart` - Main home page
- `main_shell.dart` - Bottom navigation shell
- `dashboard_screen.dart` - Admin/main dashboard

**Evacuation Screens** → `views/screens/evacuation/`
- `map_screen.dart` - Real-time tracking map
- `sos_screen.dart` - Emergency SOS button & location sharing
- `checklist_screen.dart` - Pre-evacuation checklist
- `centers_screen.dart` - Evacuation centers information & availability

**Communication Screens** → `views/screens/communication/`
- `chat_screen.dart` - Direct messaging between users
- `messages_screen.dart` - Message inbox/thread list
- `support_request_screen.dart` - Support request submission & tracking

**Profile Screens** → `views/screens/profile/`
- `profile_screen.dart` - User profile information
- `settings_screen.dart` - App settings & preferences

### Reusable Components → `views/components/`

Keep commonly used UI components here:
- `buttons/` - Custom buttons, action buttons
- `cards/` - Card widgets, tiles
- `dialogs/` - Dialogs, modals, bottom sheets
- `custom_widgets.dart` - Other reusable widgets

## Best Practices for Views

1. **Import Controllers**
   ```dart
   import '../../../controllers/user_controller.dart';
   ```

2. **Use Model Data**
   ```dart
   import '../../../models/user_model.dart';
   ```

3. **Call Controller Methods**
   ```dart
   final userController = UserController();
   final user = await userController.getUserProfile(userId);
   ```

4. **Error Handling**
   ```dart
   try {
     final result = await controller.someAction();
     if (result['success']) {
       // Update UI
     } else {
       // Show error message
     }
   } catch (e) {
     // Handle exception
   }
   ```

5. **Loading States**
   ```dart
   bool isLoading = false;
   // Show loading indicator while fetching data
   ```

## File Structure Template

```dart
import 'package:flutter/material.dart';
import '../../../models/index.dart';
import '../../../controllers/index.dart';

class MyScreen extends StatefulWidget {
  const MyScreen({Key? key}) : super(key: key);

  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  late final MyController _controller;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = MyController();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Call controller method
    } catch (e) {
      // Handle error
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Title')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : // Build UI
    );
  }
}
```

## Migration Checklist

- [ ] Move screens to appropriate category folders
- [ ] Update import paths
- [ ] Extract reusable widgets to components
- [ ] Add controller usage to all screens
- [ ] Update router/navigation paths
- [ ] Test all screen functionality
- [ ] Update main.dart routes

## Navigation Update

Update your route definitions:

```dart
// old
routes: {
  '/login': (context) => LoginScreen(),
  '/home': (context) => HomeScreen(),
}

// new
routes: {
  '/auth/login': (context) => LoginScreen(),
  '/home': (context) => HomeScreen(),
  '/evacuation/map': (context) => MapScreen(),
  '/communication/chat': (context) => ChatScreen(),
}
```
