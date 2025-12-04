# Trimline Parcel - Quick Start Guide

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.35.5 or higher
- Android Studio / VS Code
- Android SDK (for Android builds)
- Java JDK 11 or higher

### Installation

1. **Clone and Navigate**
   ```bash
   cd d:\Flutter\Parcel\trimline_parcel
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Run on Device/Emulator**
   ```bash
   flutter run
   ```

4. **Build APK**
   ```bash
   # Debug build
   flutter build apk --debug
   
   # Release build (requires keystore setup)
   flutter build apk --release
   ```

## 🔑 Key Features

### User Management
- Multi-role authentication (Admin, User, Supervisor, Depot, Fuel, Parcel)
- Local SQLite caching with API synchronization
- See `USER_MANAGEMENT.md` for detailed usage

### Parcel Management
- Create, edit, and track parcels
- Status workflow: Pending → In Transit → Received → Collected
- Draft saving for incomplete entries
- Bulk operations and filtering

### Printing
- Bluetooth thermal printer integration
- Receipt generation for parcels
- Multiple printer brand support

### Offline Support
- Local SQLite database
- Automatic sync when online
- Draft management

## 📋 Common Tasks

### Running the App
```bash
# Debug mode with hot reload
flutter run

# Release mode
flutter run --release

# Specific device
flutter run -d <device-id>
```

### Building
```bash
# Android APK
flutter build apk --release

# Windows executable
flutter build windows --release

# Check available devices
flutter devices
```

### Code Quality
```bash
# Analyze code
flutter analyze

# Run automated fixes
dart fix --apply

# Format code
dart format lib/
```

### Cleaning Build
```bash
# Clean build artifacts
flutter clean

# Reinstall dependencies
flutter pub get
```

## 🔧 Configuration

### API Endpoint
Location: `lib/utilities/Apis.dart`
```dart
String baseUrl = "http://nav.trimline.co.ke:4010/api/Parcel/";
```

**⚠️ For Production:** Move to environment variables

### Database
Location: `lib/database/`
- SQLite database auto-initializes on first run
- Schema migrations handled automatically

## 📱 Testing

### Unit Tests
```bash
flutter test
```

### Integration Tests
```bash
flutter test integration_test/
```

### Widget Tests
```bash
flutter test test/widget_test.dart
```

## 🐛 Troubleshooting

### Common Issues

**1. Build Fails with Gradle Error**
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter build apk
```

**2. Package Version Conflicts**
```bash
flutter pub upgrade
flutter pub get
```

**3. Android License Issues**
```bash
flutter doctor --android-licenses
```

**4. Hot Reload Not Working**
- Press `R` in terminal for hot reload
- Press `Shift + R` for hot restart
- Restart IDE if issues persist

### Checking Status
```bash
# Check Flutter environment
flutter doctor -v

# Check for issues
flutter analyze

# Get device info
flutter devices
```

## 📁 Project Structure Reference

```
lib/
├── main.dart                 # Entry point - initialize services here
├── controllers/              # Business logic (GetX controllers)
├── models/                   # Data structures
├── pages/                    # UI screens
├── services/                 # API & business services
├── database/                 # SQLite operations
├── widgets/                  # Reusable components
├── utilities/                # API client & helpers
└── utils/                    # Validation & utilities
```

## 🔐 Security Notes

### Before Production:
1. ✅ Use HTTPS for API endpoints
2. ✅ Implement certificate pinning
3. ✅ Encrypt sensitive database fields
4. ✅ Move API keys to environment variables
5. ✅ Add ProGuard rules for Android
6. ✅ Enable code obfuscation

## 📞 Support

For issues or questions:
- Check `PROJECT_STATUS.md` for known issues
- Review `USER_MANAGEMENT.md` for user system details
- Run `flutter doctor` to diagnose environment issues

## 🎯 Next Steps

1. Review `PROJECT_STATUS.md` for complete project analysis
2. Configure production API endpoint
3. Set up app signing for release builds
4. Test on physical devices
5. Set up crash reporting (Firebase/Sentry)

---

**Last Updated:** November 11, 2025  
**Flutter Version:** 3.35.5  
**Minimum SDK:** Android 21+ (Lollipop)
