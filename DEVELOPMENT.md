## Development Setup

### Environment
- Flutter SDK 3.0+
- Dart 3.0+
- VS Code or Android Studio

### Dependencies
All dependencies are listed in `pubspec.yaml`. Install with:
```bash
flutter pub get
```

### Key Packages

**State Management**
- `flutter_riverpod` (v2.4.0) - Reactive state management
- `riverpod` - Core Riverpod library

**Real-time Communication**
- `mqtt5_client` (v4.4.0) - MQTT protocol support
- `web_socket_channel` (v2.4.3) - WebSocket support

**Database**
- `sqflite` (v2.3.0) - SQLite implementation
- `path` - Database path handling

**UI Components**
- `fl_chart` (v0.65.0) - Charts and graphs
- `shimmer` (v3.0.0) - Loading shimmer effects

**Utilities**
- `logger` (v2.1.0) - Logging
- `uuid` (v4.0.0) - UUID generation
- `connectivity_plus` (v5.0.1) - Network connectivity
- `shared_preferences` (v2.2.2) - Local preferences
- `intl` (v0.19.0) - Internationalization
- `http` / `dio` - HTTP requests

## Running the App

### Development Mode
```bash
flutter run
```

### Release Build
```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release

# Web
flutter build web --release
```

## Code Generation

Some packages require code generation (e.g., Riverpod):
```bash
flutter pub run build_runner build
```

Or watch for changes:
```bash
flutter pub run build_runner watch
```

## Testing

Run all tests:
```bash
flutter test
```

Run specific test:
```bash
flutter test test/widget_test.dart
```

## Debugging

### Enable Debug Mode
```bash
flutter run --debug
```

### DevTools
```bash
flutter pub global activate devtools
devtools
```

Then open `http://localhost:9100` and connect your app.

### Hot Reload
Press `r` in the terminal while `flutter run` is active to reload.

Press `R` to restart the app.

## Architecture Notes

### Folder Structure
- `lib/main.dart` - App entry point
- `lib/screens/` - Page screens (Dashboard, Control, etc.)
- `lib/providers/` - Riverpod state providers
- `lib/services/` - Business logic (MQTT, WebSocket, DB)
- `lib/models/` - Data models
- `lib/widgets/` - Reusable UI components
- `lib/utils/` - Utility functions
- `lib/config/` - App configuration and theme

### State Flow
1. User interactions → UI calls provider methods
2. Provider notifiers update state
3. Widgets rebuild on state changes
4. Services handle communication with backend/database

### Real-time Communication Flow
1. **MQTT**: Publisher/Subscriber model
   - Robot publishes status to `robot/status` topic
   - App listens to `robot/status`, `robot/battery`, `robot/sensors`
   - App publishes commands to `robot/control`

2. **WebSocket**: Bidirectional real-time channel
   - Maintains persistent connection
   - Instant message delivery
   - Suitable for game mode and low-latency control

## Future Enhancements

- [ ] Multi-robot support dashboard
- [ ] Advanced sensor visualization with charts
- [ ] Game mode implementation
- [ ] Push notifications for alerts
- [ ] Cloud synchronization (Firebase)
- [ ] Offline mode with sync queue
- [ ] Robot arm control UI
- [ ] Video streaming from robot camera
- [ ] Advanced analytics
