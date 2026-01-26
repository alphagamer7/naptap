# NapTap

A one-tap power nap app with a distraction-free black screen and gentle wake-up alarm.

## Features

- **Quick Nap Presets**: 10, 20, or 30-minute power naps with one tap
- **Custom Duration**: Set any duration from 1-120 minutes
- **Distraction-Free**: Pure black screen keeps you focused on rest
- **Walk-to-Dismiss**: Walk 10 steps to turn off the alarm - ensures you're actually awake!
- **Gentle Wake-Up**: Alarm volume gradually increases from 10% to 100% over 20 seconds
- **Nap Statistics**: Track your nap habits with weekly charts and history
- **Screen Lock**: Prevents accidental exits during your nap (Android)
- **Vibration Support**: Optional vibration alerts

## Screenshots

| Home | Nap Mode | Stats |
|------|----------|-------|
| Duration selection | Black screen with timer | Weekly charts |

## Getting Started

### Prerequisites
- Flutter SDK (^3.9.2)
- iOS/Android device or emulator

### Installation

```bash
# Clone the repository
git clone https://github.com/alphagamer7/naptap.git
cd naptap

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Building

```bash
# Android APK
flutter build apk

# iOS (requires macOS)
flutter build ios
```

## How It Works

1. **Start a Nap**: Select a preset duration or tap "Custom time"
2. **Nap Mode**: Screen goes black, timer runs in background
3. **Wake Up**: When timer ends, alarm plays with increasing volume
4. **Dismiss**: Walk 10 steps to dismiss - no cheating!

## Tech Stack

- Flutter
- SQLite for local storage
- Pedometer for step tracking
- just_audio for alarm playback

## License

MIT License
