# Apex Rover Control

A professional Flutter mobile application for controlling and monitoring Apex Rover robots in real-time.

## Features

### Dashboard Page
- Live battery status (Voltage, Current, Power)
- Robot state monitoring (ON/OFF, Charging/Not Charging)
- Expandable widgets for additional metrics
- Interactive alerts for critical values

### Control Page
- Real-time robot movement control
- Buttons/joystick for forward/backward/turn
- Future-ready for robot arm control
- Smooth UI for low-latency commands

### Sensors Page
- Live data from all sensors (IR, ultrasonic, temperature, etc.)
- Graphical and numeric visualization
- Optional sensor logging to review history

### Connection Page
- Pairing with the robot via Wi-Fi / Bluetooth / MQTT
- Connection status and signal strength
- Reconnect functionality if robot goes offline

### System Page
- Monitor database & system status
- Display last updates, audit logs, and errors
- Options for sync and manual refresh

### About Page
- App version information
- Robot info
- Credits and support links

## Technical Stack

- **Framework**: Flutter + Dart
- **Real-time Communication**: WebSockets and MQTT
- **State Management**: Riverpod
- **Database**: SQLite (local logs), optional Firebase (cloud sync)
- **UI Design**: Material Design 3

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── robot_model.dart
│   └── system_status_model.dart
├── screens/                  # App screens
│   ├── navigation_screen.dart
│   ├── dashboard_screen.dart
│   ├── control_screen.dart
│   ├── sensors_screen.dart
│   ├── connection_screen.dart
│   ├── system_screen.dart
│   └── about_screen.dart
├── services/                 # Business logic
│   ├── mqtt_service.dart
│   ├── websocket_service.dart
│   └── database_service.dart
├── providers/                # State management (Riverpod)
│   ├── robot_provider.dart
│   ├── connection_provider.dart
│   └── system_provider.dart
├── widgets/                  # Reusable components
│   ├── battery_card.dart
│   ├── status_card.dart
│   └── alert_widget.dart
├── utils/                    # Utility functions
│   ├── common_utils.dart
│   └── app_utils.dart
├── config/                   # Configuration
│   ├── theme.dart
│   └── constants.dart
└── test/                     # Test files
```

## Getting Started

### Prerequisites
- Flutter SDK (3.0 or higher)
- Dart SDK (3.0 or higher)
- iOS 11+ or Android 5.0+

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd robot_master_control
```

2. Install dependencies:
```bash
flutter pub get
```

3. Generate code (if using code generation):
```bash
flutter pub run build_runner build
```

4. Run the app:
```bash
flutter run
```

## Configuration

### MQTT Settings
Edit `lib/config/constants.dart`:
```dart
static const String mqttBrokerUrl = 'mqtt://your.broker.address';
static const int mqttBrokerPort = 1883;
```

### WebSocket Settings
```dart
static const String webSocketUrl = 'ws://your.server.address:8080/ws';
```

## Features Roadmap

- [ ] Game mode for controlling robot like a toy
- [ ] Alerts/notifications on battery or sensor anomalies
- [ ] Cloud dashboard for multiple robots
- [ ] Data analytics on robot usage and performance
- [ ] Robot arm control integration
- [ ] Advanced sensor visualization with charts
- [ ] Offline mode with data synchronization

## Architecture

### State Management (Riverpod)
The app uses Riverpod for state management:
- `RobotNotifier`: Manages robot data and battery status
- `ConnectionNotifier`: Handles connection status and real-time communication
- `SystemStatusNotifier`: Manages system health and error tracking

### Services
- **MqttService**: Handles MQTT protocol communication
- **WebSocketService**: Handles WebSocket communication
- **DatabaseService**: SQLite database operations for local storage

### Real-time Communication
- MQTT for persistent connections and pub/sub messaging
- WebSocket for bidirectional real-time communication
- Automatic reconnection with configurable intervals

### Database
- SQLite for local data persistence
- Tables for robots, sensor readings, audit logs, and control commands
- Automatic data cleanup for old records

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

MIT License © 2024 ApexRover. All rights reserved.

## Support

For support, email: support@apexrover.com
Or visit our documentation: https://docs.apexrover.com

## Acknowledgments

- Flutter community
- Material Design team
- Riverpod for state management
