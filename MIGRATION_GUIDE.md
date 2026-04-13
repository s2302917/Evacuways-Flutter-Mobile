# Quick Migration Guide - Move Existing Screens

This guide helps you migrate existing screen files to the new organized structure.

## Step-by-Step Migration

### 1. Existing Screens → New Locations

Move your existing screen files:

```bash
# Move to respective folders
lib/screens/login_screen.dart         → lib/views/screens/auth/
lib/screens/registration_screen.dart  → lib/views/screens/auth/
lib/screens/forgot_password_screen.dart → lib/views/screens/auth/
lib/screens/home_screen.dart          → lib/views/screens/home/
lib/screens/main_shell.dart           → lib/views/screens/home/
lib/screens/map_screen.dart           → lib/views/screens/evacuation/
lib/screens/sos_screen.dart           → lib/views/screens/evacuation/
lib/screens/checklist_screen.dart     → lib/views/screens/evacuation/
lib/screens/chat_screen.dart          → lib/views/screens/communication/
lib/screens/messages_screen.dart      → lib/views/screens/communication/
lib/screens/profile_screen.dart       → lib/views/screens/profile/
```

### 2. Update Import Paths in Files

Before moving, update imports in your screen files:

**Old pattern:**
```dart
import '../models/user_model.dart';
import '../controllers/auth_controller.dart';
```

**New pattern:**
```dart
import '../../../models/user_model.dart';
import '../../../controllers/auth_controller.dart';
```

Or use the index files:
```dart
import '../../../models/index.dart';
import '../../../controllers/index.dart';
```

### 3. Update Routes in main.dart

Update your route definitions:

**Before:**
```dart
routes: {
  '/login': (context) => const LoginScreen(),
  '/home': (context) => const HomeScreen(),
  '/map': (context) => MapScreen(),
  '/chat': (context) => ChatScreen(),
  '/profile': (context) => ProfileScreen(),
}
```

**After:**
```dart
routes: {
  '/auth/login': (context) => const LoginScreen(),
  '/auth/registration': (context) => const RegistrationScreen(),
  '/auth/forgot-password': (context) => const ForgotPasswordScreen(),
  '/home': (context) => const HomeScreen(),
  '/evacuation/map': (context) => const MapScreen(),
  '/evacuation/sos': (context) => const SosScreen(),
  '/evacuation/checklist': (context) => const ChecklistScreen(),
  '/communication/chat': (context) => const ChatScreen(),
  '/communication/messages': (context) => const MessagesScreen(),
  '/profile': (context) => const ProfileScreen(),
}
```

### 4. Extract Reusable Widgets

Move any custom widgets to `views/components/`:

```dart
// Example: Custom button widget
lib/views/components/custom_buttons.dart

// Example: Custom cards
lib/views/components/evacuation_center_card.dart

// Example: Custom dialogs
lib/views/components/dialogs/confirm_dialog.dart
```

### 5. Test Navigation

Verify all routes work correctly:

```dart
// Test navigation
Navigator.pushNamed(context, '/auth/login');
Navigator.pushNamed(context, '/evacuation/map');
Navigator.pushReplacementNamed(context, '/home');
```

## Example: Migrating a Screen File

### Original Location
`lib/screens/chat_screen.dart`

### New Location & Content
`lib/views/screens/communication/chat_screen.dart`

### Code Updates

**Before:**
```dart
import 'package:flutter/material.dart';
import '../models/message_model.dart';
import '../controllers/message_controller.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);
  // ...
}
```

**After:**
```dart
import 'package:flutter/material.dart';
import '../../../models/index.dart';
import '../../../controllers/index.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);
  // ...
}
```

## Checklist for Each Screen

- [ ] Moved to correct subdirectory
- [ ] Updated all import paths
- [ ] Fixed relative path depth (../)
- [ ] Updated route in main.dart
- [ ] Tested navigation to screen
- [ ] Verified all controllers work
- [ ] Checked for any hardcoded paths
- [ ] Extracted reusable widgets

## Automated Import Update (VS Code)

Use VS Code's Find & Replace:

1. Press `Ctrl+H` for Find & Replace
2. Find: `import '../models/`
3. Replace: `import '../../../models/`
4. Replace all in file

## Handling Navigation Parameters

Update screen navigation:

**Before:**
```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => UserDetailScreen(userId: 123)),
);
```

**After - Still Works! No Changes Needed**

## Keeping Old Structure (Legacy)

If you want to keep both structures during transition:

1. Keep new structure for new features
2. Gradually move old screens
3. Update routes to support both
4. Delete old structure once migration is complete

## Rollback Plan

If issues occur:

1. Keep backup of original files
2. Git branches help: `git checkout old-structure` if needed
3. Gradual migration is safer than all-at-once

## Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| Import errors | Check path depth (../ counts) |
| Route not found | Verify route name in main.dart |
| Widget not found | Check if screen is properly exported |
| Style/Theme issues | May need to rebuild app |

---

**Migration Time**: ~15-30 minutes for typical app
**Testing Time**: ~10 minutes
**Total**: ~45 minutes

Good luck with your migration! 🚀
