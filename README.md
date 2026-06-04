# Apex Rover Mobile Control App

A professional Flutter mobile application for controlling, monitoring, and operating the Apex Rover robot in real time.

The app is designed to work with the Apex Rover hardware system:

```text
Mobile App → ESP32 → Mega / UNO
Raspberry Pi → Camera Streaming + Sensor Relay + Auto Mode Manager
```

The ESP32 is the main command gateway.
The Raspberry Pi is used for camera streaming, sensor relay, and automatic stair-climbing mode management.

---

## Main Features

### Dashboard Page

The Dashboard provides a central overview of the robot and system state.

Features:

* Robot connection status
* Manual / Auto operation mode switching
* Raspberry Pi service status
* Emergency stop button
* System overview
* Communication flow explanation
* Quick access to Control and Remote Control pages

Operation modes:

```text
Manual Mode:
Mobile App controls the robot through ESP32.
Raspberry Pi runs dual camera streaming and sensor relay.

Auto Mode:
Raspberry Pi controls stair climbing using front camera + MPU.
Commands are still routed through ESP32.
```

---

### Remote Control Page

The Remote Control page provides a full-screen camera-based control experience.

Features:

* Landscape full-screen camera view
* Front camera view in Basic, Rear Jack, and Front Jack modes
* Arm camera view in Arm mode
* Transparent overlay controls
* Sensor status overlay
* Manual movement controls
* Camera stand controls
* Front and rear jack controls
* Arm controls split between left and right hands
* AUX servo controls

Remote modes:

```text
Basic:
Robot movement + camera stand control

Rear Jack:
Rear linear actuator + camera stand control

Front Jack:
Front linear actuator + camera stand control

Arm:
Arm base, shoulder, elbow, wrist, gripper, AUX, and home control
```

Supported command examples:

```text
FORWARD
BACKWARD
LEFT
RIGHT
STOP

CAM:UP
CAM:DOWN
CAM:LEFT
CAM:RIGHT
CAM:CENTER
CAM:STOP

JACK:REAR:EXTEND
JACK:REAR:RETRACT
JACK:REAR:STOP

JACK:FRONT:EXTEND
JACK:FRONT:RETRACT
JACK:FRONT:STOP

ARM:BASE:LEFT
ARM:BASE:RIGHT
ARM:BASE:STOP
ARM:SHOULDER:UP
ARM:SHOULDER:DOWN
ARM:ELBOW:UP
ARM:ELBOW:DOWN
ARM:WRIST:UP
ARM:WRIST:DOWN
ARM:GRIPPER:OPEN
ARM:GRIPPER:CLOSE
ARM:AUX:UP
ARM:AUX:DOWN
ARM:HOME
ARM:STOP
```

---

### Control Page

The Control page provides traditional manual robot control.

Features:

* Movement control
* Speed control
* Jack controls
* Camera stand controls
* Arm command support
* WebSocket command sending through ESP32

---

### Sensors Page

The Sensors page displays real-time sensor data received from the robot.

Displayed sensor data:

* Pitch
* Roll
* Front ultrasonic distance
* Rear ultrasonic distance
* Balance status

Balance states:

```text
STABLE
WARNING
DANGER
NO DATA
```

Sensor message format expected by the app:

```text
SENSOR:PITCH=2.4;ROLL=-1.1;FRONT=35.6;REAR=18.2;BALANCE=STABLE
```

Important note:

```text
In Manual Mode:
MPU and ultrasonic values are displayed for monitoring.

In Auto Mode:
Only front camera + MPU are used for decisions.
Ultrasonic values may still be displayed, but they are not used for automatic stair-climbing logic.
```

---

### Connection Page

The Connection page manages the connection between the mobile app and ESP32.

Features:

* Connect to ESP32 WebSocket
* Disconnect safely
* Show connection status
* Auto-reconnect support
* Send STOP command on disconnect for safety

Default ESP32 WebSocket:

```dart
ws://192.168.4.1:81
```

The mobile phone must be connected to the ESP32 Wi-Fi network.

Example network:

```text
Wi-Fi SSID: Apex_Rover_Net
ESP32 IP: 192.168.4.1
Raspberry Pi IP: 192.168.4.2
Mobile IP: 192.168.4.x
```

---

### About Page

The About page displays general information about the Apex Rover project.

It can include:

* App version
* Project description
* Robot system overview
* Team information
* Support information

---

## System Architecture

### Manual Mode

In Manual Mode, the mobile app controls the robot directly through ESP32.

```text
Mobile App
   ↓ WebSocket
ESP32
   ↓ Serial
Mega / UNO
```

Raspberry Pi runs:

```text
Raspberry/Manual/dual_camera_server.py
Raspberry/Manual/sensor_bridge.py
```

Manual Mode responsibilities:

```text
Mobile App:
- Sends movement, jack, camera, and arm commands

ESP32:
- Receives WebSocket commands
- Routes movement and jack commands to Mega
- Routes camera and arm commands to UNO

Mega:
- Controls motors and linear actuators
- Reads MPU and ultrasonic sensors
- Sends SENSOR data

UNO:
- Controls camera stand
- Controls robotic arm
- Controls AUX servo

Raspberry Pi:
- Streams front and arm cameras
- Relays sensor data to ESP32/mobile app
```

---

### Auto Mode

In Auto Mode, Raspberry Pi runs the automatic stair-climbing logic.

```text
Raspberry Auto Brain
   ↓ WebSocket
ESP32
   ↓ Serial
Mega / UNO
```

Raspberry Pi runs:

```text
Raspberry/Auto/front_camera_server.py
Raspberry/Manual/sensor_bridge.py
Raspberry/Auto/auto_stair_climb.py
```

Auto Mode responsibilities:

```text
Raspberry Pi:
- Uses front camera only
- Reads latest MPU data from sensor bridge
- Decides when to move, stop, and use rear jack
- Sends commands to ESP32

ESP32:
- Routes commands to Mega / UNO

Mega:
- Executes movement, jack, and PULSE commands
- Sends fast MPU sensor data

UNO:
- Keeps camera stand and arm command support available
```

Auto Mode decision inputs:

```text
Used:
- Front camera
- MPU pitch
- MPU roll

Ignored for decisions:
- Front ultrasonic
- Rear ultrasonic
```

---

## Raspberry Pi Integration

The mobile app communicates with Raspberry Pi through the Raspberry Mode Manager.

Default Raspberry Mode Manager URL:

```dart
http://192.168.4.2:5050
```

Required endpoints:

```text
GET /status
GET /mode/manual
GET /mode/auto
GET /mode/stop
GET /robot/stop
```

Expected Raspberry status response:

```json
{
  "ok": true,
  "mode": "MANUAL",
  "manual_dual_camera_running": true,
  "sensor_bridge_running": true,
  "auto_front_camera_running": false,
  "auto_brain_running": false
}
```

---

## Camera Streaming

Default Raspberry camera server:

```dart
http://192.168.4.2:5000
```

Camera endpoints:

```text
/front_snapshot
/arm_snapshot
```

Usage:

```text
Manual Mode:
- /front_snapshot
- /arm_snapshot

Auto Mode:
- /front_snapshot only
```

The Remote Control screen refreshes camera snapshots periodically to simulate live video without requiring MJPEG packages.

---

## Technical Stack

* **Framework:** Flutter + Dart
* **State Management:** Riverpod
* **Real-time Communication:** WebSocket
* **Sensor Display:** WebSocket sensor messages
* **Raspberry Communication:** HTTP requests
* **UI Design:** Dark theme, Material Design, custom responsive controls
* **Target Platforms:** Android, with possible iOS support

---

## Project Structure

```text
lib/
├── main.dart
│
├── config/
│   ├── constants.dart
│   └── theme.dart
│
├── models/
│   └── robot_model.dart
│
├── providers/
│   ├── connection_provider.dart
│   ├── robot_provider.dart
│   └── sensor_status_provider.dart
│
├── screens/
│   ├── navigation_screen.dart
│   ├── dashboard_screen.dart
│   ├── control_screen.dart
│   ├── remote_control_screen.dart
│   ├── sensors_screen.dart
│   ├── connection_screen.dart
│   └── about_screen.dart
│
├── services/
│   ├── websocket_service.dart
│   └── raspberry_mode_service.dart
│
└── widgets/
    ├── status_card.dart
    └── other reusable widgets
```

---

## Important Configuration

Edit:

```text
lib/config/constants.dart
```

### ESP32 WebSocket

```dart
static const String webSocketUrl = 'ws://192.168.4.1:81';
```

### Raspberry Mode Manager

```dart
static const String raspberryBaseUrl = 'http://192.168.4.2:5050';
```

### Raspberry Camera Server

In `remote_control_screen.dart`:

```dart
static const String raspberryBaseUrl = 'http://192.168.4.2:5000';
```

If Raspberry Pi gets a different IP address, update these values.

---

## Getting Started

### Prerequisites

* Flutter SDK
* Dart SDK
* Android Studio or VS Code
* Android phone connected by USB or Wi-Fi debugging
* ESP32 running Apex Rover firmware
* Raspberry Pi connected to ESP32 Wi-Fi network
* Mega and UNO connected to ESP32 / Raspberry according to the hardware plan

---

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

3. Run static analysis:

```bash
flutter analyze
```

4. Run the app:

```bash
flutter run
```

---

## Testing Checklist

### 1. ESP32 Connection

* Connect phone to ESP32 Wi-Fi.
* Open the app.
* Go to Connection page.
* Press Connect.
* Confirm status becomes Connected.

---

### 2. Manual Movement Test

Test:

```text
FORWARD
BACKWARD
LEFT
RIGHT
STOP
```

---

### 3. Camera Test

In Remote Control page:

```text
Basic Mode → Front Camera
Arm Mode → Arm Camera
```

Make sure Raspberry camera server is running.

---

### 4. Jack Test

Test:

```text
Rear Jack Extend / Stop / Retract
Front Jack Extend / Stop / Retract
```

---

### 5. Arm Test

Test:

```text
Base Left / Right / Stop
Shoulder Up / Down
Elbow Up / Down
Wrist Up / Down
Gripper Open / Close
AUX Up / Down
Home
```

---

### 6. Sensor Test

Confirm the app receives:

```text
Pitch
Roll
Front distance
Rear distance
Balance status
```

---

### 7. Raspberry Mode Test

From Dashboard:

```text
Refresh
Manual
Auto
Emergency Stop
```

Manual should show:

```text
Dual Cam: ON
Sensors: ON
Front Cam: OFF
Auto Brain: OFF
```

Auto should show:

```text
Dual Cam: OFF
Sensors: ON
Front Cam: ON
Auto Brain: ON
```

---

## Safety Notes

* Always test Manual Mode before Auto Mode.
* Keep the robot lifted or supported during first motor tests.
* Use Emergency Stop if the robot behaves unexpectedly.
* Do not test Auto Mode on stairs without someone standing near the robot.
* Auto Mode should only use front camera and MPU for stair-climbing decisions.
* Ultrasonic sensors are for display and monitoring only in the current Auto logic.

---

## Roadmap

* Improve automatic stair-climbing logic
* Add better camera calibration controls
* Add sensor charts
* Add command history
* Add battery monitoring
* Add live video streaming using MJPEG or WebRTC
* Add configurable Raspberry IP from the app UI
* Add logs viewer for Raspberry Auto Mode
* Add multiple robot profiles

---

## Troubleshooting

### App cannot connect to ESP32

Check:

```text
Phone is connected to ESP32 Wi-Fi
ESP32 is powered on
WebSocket URL is correct
ESP32 WebSocket server is running
```

---

### Raspberry status is offline

Check:

```text
Raspberry Pi is connected to ESP32 Wi-Fi
Raspberry IP is 192.168.4.2
main_startup.py is running
Port 5050 is reachable
```

Test from browser:

```text
http://192.168.4.2:5050/status
```

---

### Camera not showing

Check:

```text
Raspberry camera server is running
Camera device paths are correct
Port 5000 is reachable
```

Test:

```text
http://192.168.4.2:5000/front_snapshot
http://192.168.4.2:5000/arm_snapshot
```

---

### Sensors show NO DATA

Check:

```text
Mega is connected
Mega is sending SENSOR messages
sensor_bridge.py is running
ESP32 receives /sensor_update or SENSOR message
Mobile app is connected to ESP32 WebSocket
```

Expected sensor format:

```text
SENSOR:PITCH=2.4;ROLL=-1.1;FRONT=35.6;REAR=18.2;BALANCE=STABLE
```

---

## License

This project is part of the Apex Rover robotics system.

---

## Acknowledgments

* Flutter community
* Riverpod community
* Arduino ecosystem
* Raspberry Pi ecosystem
* Apex Rover development team
