# Apex Rover Control - Quick Start Guide

## Prerequisites

- Flutter SDK (3.0 or higher)
- Dart SDK (3.0 or higher)
- Android Studio / Xcode (for device compilation)
- Git

## Installation

### 1. Clone the Repository
```bash
git clone https://github.com/apexrover/robot_master_control.git
cd robot_master_control
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Generate Code
```bash
flutter pub run build_runner build
```

### 4. Run the App
```bash
flutter run
```

## Configuration

### MQTT Setup

Edit `lib/config/constants.dart`:

```dart
static const String mqttBrokerUrl = 'mqtt://your.broker.address';
static const int mqttBrokerPort = 1883;
```

### Local Testing

Use Mosquitto for MQTT testing:

```bash
# Install
brew install mosquitto

# Start broker
mosquitto

# In another terminal, subscribe to topics
mosquitto_sub -h localhost -t 'robot/+' -v

# Publish test data
mosquitto_pub -h localhost -t 'robot/battery' -m '{
  "voltage": 12.5,
  "current": 2.3,
  "power": 28.75,
  "percentage": 75,
  "isCharging": false,
  "timestamp": "2024-01-15T10:30:00Z"
}'
```

## Project Structure

```
robot_master_control/
├── android/              # Android native code
├── ios/                  # iOS native code
├── lib/
│   ├── main.dart         # Entry point
│   ├── screens/          # UI screens
│   ├── providers/        # State management
│   ├── services/         # Business logic
│   ├── models/           # Data models
│   ├── widgets/          # Reusable components
│   ├── utils/            # Utilities
│   └── config/           # Configuration
├── test/                 # Tests
├── pubspec.yaml          # Dependencies
└── README.md
```

## Common Commands

```bash
# Run in debug mode
flutter run

# Run in release mode
flutter run --release

# Build APK (Android)
flutter build apk --release

# Build IPA (iOS)
flutter build ios --release

# Run tests
flutter test

# Analyze code
flutter analyze

# Format code
dart format lib/

# Clean build
flutter clean
```

## Troubleshooting

### Flutter not found
```bash
# Add Flutter to PATH
export PATH="$PATH:/path/to/flutter/bin"
```

### Build fails
```bash
# Clean and try again
flutter clean
flutter pub get
flutter run
```

### Dependencies not updating
```bash
# Update pub cache
flutter pub upgrade
```

## Next Steps

1. Read [DEVELOPMENT.md](DEVELOPMENT.md) for development guidelines
2. Check [API_INTEGRATION.md](API_INTEGRATION.md) for API details
3. Review test files in `test/` directory
4. Join our community Slack channel

## Getting Help

- 📖 [Documentation](https://docs.apexrover.com)
- ❓ [FAQ](https://github.com/apexrover/robot_master_control/wiki/FAQ)
- 💬 [Discussions](https://github.com/apexrover/robot_master_control/discussions)
- 🐛 [Report Issues](https://github.com/apexrover/robot_master_control/issues)

Happy coding! 🚀
