# Apex Rover Control - Setup Checklist

## ✅ Project Created Successfully!

This checklist will help you get the project ready to run.

---

## Phase 1: Environment Setup [ ] 5-10 minutes

- [ ] **Install Flutter** (if not already installed)
  ```bash
  # Check if installed
  flutter --version
  
  # If not, visit https://flutter.dev/docs/get-started/install
  ```

- [ ] **Verify Dart SDK**
  ```bash
  dart --version  # Should be 3.0+
  ```

- [ ] **Install IDE Extension** (Optional but recommended)
  - VS Code: Install "Dart" and "Flutter" extensions
  - Android Studio: Install "Flutter" and "Dart" plugins

---

## Phase 2: Project Setup [ ] 10-15 minutes

- [ ] **Open Project**
  ```bash
  cd /home/muath-hassoun/VS_StormProjects/ApexRover/robot_master_control
  ```

- [ ] **Get Dependencies**
  ```bash
  flutter pub get
  ```
  ⏱ This will take 2-5 minutes first time

- [ ] **Generate Code**
  ```bash
  flutter pub run build_runner build
  ```
  ⏱ Only run if using code generation features

- [ ] **Verify Setup**
  ```bash
  flutter doctor
  # Should show no errors for iOS/Android based on your platform
  ```

---

## Phase 3: Configuration [ ] 5-10 minutes

### MQTT Setup
- [ ] **Choose MQTT Broker**
  - Option A: Local (Mosquitto)
  - Option B: Cloud (CloudMQTT, HiveMQ)
  - Option C: Custom broker

- [ ] **Update Connection Settings**
  Edit `lib/config/constants.dart`:
  ```dart
  static const String mqttBrokerUrl = 'your.broker.address';
  static const int mqttBrokerPort = 1883;
  ```

- [ ] **Test MQTT Connection** (if using local)
  ```bash
  # Install Mosquitto
  brew install mosquitto  # macOS
  # sudo apt-get install mosquitto  # Linux
  
  # Start broker
  mosquitto
  
  # In another terminal, verify
  mosquitto_sub -h localhost -t 'robot/+'
  ```

### App Configuration
- [ ] **Review App Constants**
  - Edit `lib/config/constants.dart`
  - Update `appName`, `appVersion`, etc.

- [ ] **Customize Theme** (Optional)
  - Edit `lib/config/theme.dart`
  - Change primary color, fonts, etc.

- [ ] **Review Feature Flags**
  - Edit `config.json`
  - Enable/disable features as needed

---

## Phase 4: First Run [ ] 10-15 minutes

### Android
- [ ] **Connect Android Device** or **Start Emulator**
  ```bash
  # List devices
  flutter devices
  ```

- [ ] **Run App**
  ```bash
  flutter run
  ```

- [ ] **Verify Features**
  - [ ] Dashboard load
  - [ ] Navigation works
  - [ ] No console errors

### iOS
- [ ] **Open iOS Project**
  ```bash
  open ios/Runner.xcworkspace
  ```

- [ ] **Select Team** in Xcode (if not done)
  - Xcode → Runner → Signing & Capabilities
  - Select your Apple Development Team

- [ ] **Run App**
  ```bash
  flutter run
  ```

### Web
- [ ] **Run Web Version**
  ```bash
  flutter run -d chrome
  ```

---

## Phase 5: Testing & Verification [ ] 15-20 minutes

### Connection Testing
- [ ] **Test MQTT Connection**
  1. Go to Connection screen
  2. Select MQTT
  3. Enter broker address
  4. Click Connect
  5. Should show "Connected" status

- [ ] **Test WebSocket** (if available)
  1. Update `constants.dart` with WebSocket URL
  2. Select WebSocket in Connection screen
  3. Verify connection

### Dashboard Testing
- [ ] **View Dashboard**
  1. Should show battery status mockup
  2. Should show robot state
  3. Check alerts display correctly

- [ ] **Check Controls**
  1. Go to Control screen
  2. Verify buttons are clickable
  3. Test speed slider

### Sensors Testing
- [ ] **Check Sensors Screen**
  1. Use mock data from `mock_data.dart`
  2. Verify sensor cards display
  3. Check status indicators

### All Screens
- [ ] Dashboard displays correctly
- [ ] Control page responsive
- [ ] Sensors show data
- [ ] Connection status updates
- [ ] System page loads
- [ ] About page displays
- [ ] Navigation works between all screens

---

## Phase 6: Integration with Robot [ ] Varies

### Real Robot Connection
- [ ] **Prepare Robot Code**
  - Implement MQTT publisher on robot
  - Use topics from `constants.dart`
  - Send battery/sensor data in specified format

- [ ] **Update Connection Details**
  - Edit `lib/config/constants.dart`
  - Point to real robot broker
  - Verify port and protocol

- [ ] **Test Live Data**
  1. Connect app to robot
  2. Watch real-time updates
  3. Send test commands
  4. Verify robot responds

- [ ] **Monitor Performance**
  - Check battery usage
  - Monitor data bandwidth
  - Review memory usage

---

## Phase 7: Development Customization [ ] Ongoing

### Code Generation (if using Riverpod generator)
- [ ] **Enable Code Generation**
  ```bash
  flutter pub run build_runner watch
  ```

### Add Custom Features
- [ ] **Create New Feature**
  1. Create model in `lib/models/`
  2. Create provider in `lib/providers/`
  3. Create screen in `lib/screens/`
  4. Add to navigation

### Add Database Tables
- [ ] **Extend Database**
  1. Edit `database_service.dart`
  2. Add table in `_createTables()`
  3. Add CRUD methods
  4. Migrate data if needed

---

## Phase 8: Deployment Preparation [ ] Varies

### Android
- [ ] **Get Signing Key**
  ```bash
  keytool -genkey -v -keystore ~/key.jks \
    -keyalg RSA -keysize 2048 -validity 10000 \
    -alias key
  ```

- [ ] **Configure Gradle**
  - Edit `android/key.properties`
  - Edit `android/app/build.gradle`

- [ ] **Build Release APK**
  ```bash
  flutter build apk --release
  ```

### iOS
- [ ] **Create App ID** (Apple Developer)
- [ ] **Set Bundle ID**
  - Edit `ios/Runner/Info.plist`
- [ ] **Select Provisioning Profile**
  - Xcode → Runner → Signing & Capabilities
- [ ] **Build Release IPA**
  ```bash
  flutter build ios --release
  ```

---

## Phase 9: Documentation [ ] 10-15 minutes

- [ ] **Update README** with your robot info
- [ ] **Document Custom Code** with comments
- [ ] **Update CHANGELOG** for your version
- [ ] **Review API_INTEGRATION.md** for robot specs

---

## Phase 10: Quality Assurance [ ] Ongoing

### Code Quality
- [ ] **Run Analyzer**
  ```bash
  flutter analyze
  ```

- [ ] **Format Code**
  ```bash
  dart format lib/
  ```

- [ ] **Run Tests**
  ```bash
  flutter test
  ```

### Performance
- [ ] **Profile App**
  ```bash
  flutter run --profile
  ```

- [ ] **Check Logs**
  - Monitor console for errors
  - Check database size
  - Verify memory usage

### User Testing
- [ ] **Test on Multiple Devices**
- [ ] **Test Different Orientations**
- [ ] **Test Network Conditions**
- [ ] **Test Battery Drain** (background operation)

---

## Common Commands Reference

```bash
# Navigation
cd robot_master_control

# Install/Update
flutter pub get                    # Get dependencies
flutter pub upgrade                # Upgrade packages
flutter pub run build_runner build # Code generation

# Development
flutter run                        # Run in debug
flutter run --release              # Run in release
flutter run -d chrome              # Run on web
flutter run -v                     # Verbose logging

# Analysis
flutter analyze                    # Check for issues
dart format lib/                   # Format code
flutter test                       # Run tests

# Build
flutter build apk --release        # Build Android APK
flutter build appbundle --release  # Build Android Bundle
flutter build ios --release        # Build iOS
flutter build web --release        # Build Web

# Debugging
flutter logs                       # Show device logs
flutter devices                    # List devices
flutter doctor                     # Check environment
```

---

## Troubleshooting Quick Fixes

| Issue | Solution |
|-------|----------|
| `flutter: command not found` | Add Flutter to PATH |
| `Gradle build failed` | `flutter clean` then `flutter pub get` |
| `Package not found` | `flutter pub get` |
| `Android SDK not found` | Run `flutter doctor` and follow instructions |
| `iOS pods error` | `cd ios && pod install && cd ..` |
| `Build cache issues` | `flutter clean && flutter pub get` |
| `MQTT connection fails` | Check broker is running, verify address in constants.dart |
| `WebSocket connection fails` | Verify WebSocket server URL and ensure it's running |

---

## Estimated Timeline

- **Phase 1-2**: 15-25 minutes (Setup)
- **Phase 3**: 5-10 minutes (Configuration)
- **Phase 4**: 10-15 minutes (First Run)
- **Phase 5**: 15-20 minutes (Verification)
- **Phase 6**: Variable (Robot Integration)
- **Phase 7**: Ongoing (Development)
- **Phase 8**: Variable (Deployment)

**Total Initial Setup**: ~1-2 hours

---

## Next Steps

1. ✅ **Run Phase 1-2** for basic setup
2. ✅ **Run Phase 3** to configure MQTT
3. ✅ **Run Phase 4** to see app in action
4. ✅ **Follow Phase 5-6** for testing
5. 📖 **Read** [QUICKSTART.md](QUICKSTART.md) anytime
6. 📖 **Read** [DEVELOPMENT.md](DEVELOPMENT.md) for detailed info
7. 🤝 **Integrate** with your robot in Phase 6

---

## Support & Resources

- 📖 Full Docs: [README.md](README.md)
- ⚡ Quick Start: [QUICKSTART.md](QUICKSTART.md)
- 👨‍💻 Dev Guide: [DEVELOPMENT.md](DEVELOPMENT.md)
- 🔌 API Info: [API_INTEGRATION.md](API_INTEGRATION.md)
- 🐛 Issues: Check project GitHub issues
- 💬 Discussions: Community forum

---

## Final Checklist

Before considering setup complete:

- [ ] Flutter is installed and accessible
- [ ] Project dependencies are installed
- [ ] App runs without errors
- [ ] MQTT/WebSocket is configured
- [ ] All 6 screens load and display
- [ ] Navigation between screens works
- [ ] Database is initialized
- [ ] Logging shows no errors
- [ ] You understand the architecture
- [ ] You've reviewed key documentation

---

**Status**: Ready to Start!  
**estimated Time to First Run**: 30-45 minutes  
**Difficulty Level**: Beginner-Friendly  
**Support Available**: Yes  

### You're all set! Let's build something amazing! 🚀
