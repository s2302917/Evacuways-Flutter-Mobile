# EvacuWays Flutter Project - Complete Directory Tree

```
evacuways/
├── android/                          # Android platform code
├── ios/                              # iOS platform code
├── linux/                            # Linux platform code
├── macos/                            # macOS platform code
├── web/                              # Web platform code
├── windows/                          # Windows platform code
├── build/                            # Build output (auto-generated)
│
├── lib/                              # ⭐ Main Dart application code
│   │
│   ├── 📁 models/                    # MODEL LAYER - Data Entities
│   │   ├── admin_model.dart          # Admin user model
│   │   ├── admin_log_model.dart      # Admin action logging
│   │   ├── alert_model.dart          # Emergency alerts
│   │   ├── barangay_model.dart       # Barangay (district) entity
│   │   ├── center_model.dart         # Evacuation center (legacy)
│   │   ├── checklist_model.dart      # Pre-evacuation checklist
│   │   ├── city_model.dart           # City entity
│   │   ├── evacuation_center_model.dart # Evacuation center (schema-based)
│   │   ├── family_model.dart         # Family grouping
│   │   ├── message_model.dart        # Messages/chat
│   │   ├── region_model.dart         # Geographic region
│   │   ├── report_model.dart         # System reports
│   │   ├── support_request_model.dart # Help requests
│   │   ├── user_location_model.dart  # User GPS location
│   │   ├── user_model.dart           # User profile
│   │   ├── vehicle_assignment_model.dart # Vehicle assignments
│   │   ├── vehicle_model.dart        # Rescue vehicles
│   │   ├── volunteer_model.dart      # Volunteer info
│   │   └── index.dart                # Model exports
│   │
│   ├── 📁 controllers/               # CONTROLLER LAYER - Business Logic
│   │   ├── auth_controller.dart      # Authentication & user login
│   │   ├── alert_controller.dart     # Alert management ops
│   │   ├── user_controller.dart      # User profile operations
│   │   ├── evacuation_center_controller.dart # Center management
│   │   ├── vehicle_controller.dart   # Vehicle tracking & ops
│   │   ├── message_controller.dart   # Messaging operations
│   │   ├── support_request_controller.dart # Help request handling
│   │   ├── checklist_controller.dart # Checklist management
│   │   ├── location_controller.dart  # Geographic data ops
│   │   ├── resource_controller.dart  # Resource management (legacy)
│   │   ├── map_controller.dart       # Map operations (legacy)
│   │   └── index.dart                # Controller exports
│   │
│   ├── 📁 views/                     # VIEW LAYER - User Interface
│   │   │
│   │   ├── screens/                  # Application Screens
│   │   │   │
│   │   │   ├── 📁 auth/              # Authentication Screens
│   │   │   │   ├── login_screen.dart
│   │   │   │   ├── registration_screen.dart
│   │   │   │   └── forgot_password_screen.dart
│   │   │   │
│   │   │   ├── 📁 home/              # Home/Dashboard Screens
│   │   │   │   ├── home_screen.dart
│   │   │   │   ├── main_shell.dart   # Bottom navigation
│   │   │   │   └── dashboard_screen.dart
│   │   │   │
│   │   │   ├── 📁 evacuation/        # Evacuation-Specific Screens
│   │   │   │   ├── map_screen.dart   # Real-time map tracking
│   │   │   │   ├── sos_screen.dart   # Emergency SOS
│   │   │   │   ├── checklist_screen.dart # Pre-evacuation checklist
│   │   │   │   └── centers_screen.dart # Evacuation centers list
│   │   │   │
│   │   │   ├── 📁 communication/     # Communication Screens
│   │   │   │   ├── chat_screen.dart  # Direct messaging
│   │   │   │   ├── messages_screen.dart # Message threads
│   │   │   │   └── support_request_screen.dart # Help requests
│   │   │   │
│   │   │   └── 📁 profile/           # User Profile Screens
│   │   │       ├── profile_screen.dart
│   │   │       └── settings_screen.dart
│   │   │
│   │   ├── 📁 components/            # Reusable UI Components
│   │   │   ├── 📁 buttons/           # Custom button widgets
│   │   │   ├── 📁 cards/             # Card/tile components
│   │   │   ├── 📁 dialogs/           # Dialog & modal components
│   │   │   └── custom_widgets.dart   # Other reusable widgets
│   │   │
│   │   ├── SCREENS_GUIDE.md          # View organization documentation
│   │   └── index.dart                # View exports
│   │
│   ├── 📁 services/                  # SERVICE LAYER - External Resources
│   │   ├── api_service.dart          # Centralized HTTP API
│   │   ├── location_service.dart     # GPS/Geolocation operations
│   │   ├── storage_service.dart      # Local data persistence
│   │   └── index.dart                # Service exports
│   │
│   ├── 📁 utils/                     # UTILITIES - Helpers & Constants
│   │   ├── constants.dart            # App-wide constants
│   │   ├── validators.dart           # Form field validators
│   │   ├── helpers.dart              # Utility functions & extensions
│   │   └── index.dart                # Utility exports
│   │
│   ├── 📁 theme/                     # THEMING - Visual Styling
│   │   ├── app_colors.dart
│   │   ├── app_text_styles.dart
│   │   └── app_theme.dart
│   │
│   ├── 📁 widgets/                   # LEGACY - Custom Widgets (to migrate)
│   │   └── *.dart files
│   │
│   ├── main.dart                     # 🚀 App Entry Point
│   │
│   ├── 📄 README_MVC.md              # Complete Architecture Guide
│   ├── 📄 MVC_STRUCTURE.md           # Detailed Structure Documentation
│   └── 📄 models/index.dart          # Model exports
│
├── test/                             # Unit & Widget Tests
│   └── widget_test.dart
│
├── 📄 pubspec.yaml                   # Flutter dependencies & config
├── 📄 pubspec.lock                   # Locked dependency versions
├── 📄 analysis_options.yaml           # Dart analyzer rules
├── 📄 README.md                      # Project readme
│
├── MIGRATION_GUIDE.md                # Step-by-step migration instructions
├── RESTRUCTURING_SUMMARY.md          # Summary of all changes
└── [Other config files]              # .gitignore, etc.
```

## 📊 Architecture Layers

```
┌──────────────────────────────────────────┐
│           VIEWS (User Interface)         │
│  ├─ Screens           (10+ screens)      │
│  └─ Components        (Reusable widgets) │
└──────────────────────────────────────────┘
                    ↕
┌──────────────────────────────────────────┐
│      CONTROLLERS (Business Logic)        │
│  ├─ AuthController                       │
│  ├─ AlertController                      │
│  ├─ UserController                       │
│  ├─ VehicleController                    │
│  ├─ EvacuationCenterController           │
│  ├─ MessageController                    │
│  ├─ SupportRequestController             │
│  ├─ ChecklistController                  │
│  └─ LocationController                   │
└──────────────────────────────────────────┘
                    ↕
┌──────────────────────────────────────────┐
│        SERVICES (External Resources)     │
│  ├─ ApiService        (HTTP calls)       │
│  ├─ LocationService   (GPS/Maps)         │
│  └─ StorageService    (Local storage)    │
└──────────────────────────────────────────┘
                    ↕
┌──────────────────────────────────────────┐
│         MODELS (Data Entities)           │
│  17 Model Classes representing all       │
│  database tables with JSON serialization │
└──────────────────────────────────────────┘
```

## 📈 File Organization Benefits

| Aspect | Old Structure | New Structure |
|--------|---------------|---------------|
| **Finding code** | Search all files | Search by feature |
| **Adding features** | Unclear placement | Clear folder structure |
| **Code reuse** | Mixed concerns | Separated concerns |
| **Testing** | Coupled components | Independent layers |
| **Team work** | Conflicts likely | Clear responsibilities |
| **Scaling** | Becomes messy | Grows cleanly |

## 🗂️ Quick Navigation

**Need to modify user login?**
- Model: `lib/models/user_model.dart`
- Logic: `lib/controllers/auth_controller.dart`
- UI: `lib/views/screens/auth/login_screen.dart`

**Need to change validation rules?**
- Check: `lib/utils/validators.dart`

**Need to access API?**
- Use: `lib/services/api_service.dart`

**Need to add utility function?**
- Add to: `lib/utils/helpers.dart`

**Need constants?**
- Find in: `lib/utils/constants.dart`

---

Generated: March 25, 2026
MVC Architecture Version: 1.0
