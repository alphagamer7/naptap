# NapTap - Project Guide

## Overview
NapTap is a minimalist power nap timer app built with Flutter. It provides a distraction-free black screen during naps with a gentle wake-up alarm.

## Tech Stack
- **Framework**: Flutter (Dart)
- **Platforms**: iOS & Android
- **Database**: SQLite (sqflite) for local nap history
- **Key Packages**:
  - `just_audio` - Alarm sound playback with volume ramp
  - `pedometer` - Step counting for walk-to-dismiss
  - `flutter_foreground_task` - Background timer service
  - `sqflite` - Local database for nap history
  - `vibration` - Haptic feedback

## Project Structure
```
lib/
├── main.dart                     # App entry point
├── screens/
│   ├── home_screen.dart          # Main menu with duration buttons
│   ├── nap_screen.dart           # Nap timer + alarm + step dismiss
│   └── stats_screen.dart         # Weekly nap history/stats
├── services/
│   ├── timer_service.dart        # Countdown timer with foreground task
│   ├── alarm_service.dart        # Sound + vibration + volume ramp
│   ├── settings_service.dart     # SharedPreferences for settings
│   ├── screen_lock_service.dart  # Android screen pinning
│   ├── database_service.dart     # SQLite nap history storage
│   └── step_counter_service.dart # Pedometer for walk-to-dismiss
├── widgets/
│   ├── nap_button.dart           # Duration selection buttons
│   └── settings_modal.dart       # Sound/vibration toggles
└── theme/
    └── app_theme.dart            # Dark theme, colors, typography
```

## Key Features
1. **Quick Presets**: 10, 20, 30-minute nap buttons
2. **Custom Duration**: Picker for 1-120 minute naps
3. **Walk-to-Dismiss**: Must walk 10 steps to turn off alarm
4. **Nap Stats**: Weekly history with charts
5. **Screen Lock**: Android screen pinning during naps
6. **Gentle Alarm**: Volume ramps from 10% to 100% over 20 seconds

## Building
```bash
# Get dependencies
flutter pub get

# Run on device
flutter run

# Build APK
flutter build apk --debug
```

## Native Configuration
- **Android**: `android/app/src/main/kotlin/.../MainActivity.kt` - Screen lock task
- **iOS**: Requires Guided Access for full lock (system limitation)
- **Permissions**: Motion sensors (pedometer), audio playback
