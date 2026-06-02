class AppConstants {
  // App Info
  static const String appName = 'Apex Rover Control';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';

  // Connection Settings
  static const String mqttBrokerUrl = 'mqtt://localhost';
  static const int mqttBrokerPort = 1883;
  static const String mqttClientId = 'robot_master_control_mobile';
  static const Duration mqttConnectionTimeout = Duration(seconds: 30);
  static const Duration mqttReconnectInterval = Duration(seconds: 5);

  // WebSocket Settings
  // ESP32 Access Point default IP is 192.168.4.1.
  // Mobile phone must be connected to ESP32 WiFi: Apex_Rover_Net.
  static const String webSocketUrl = 'ws://192.168.4.1:81';
  static const Duration webSocketTimeout = Duration(seconds: 30);

  // Raspberry Pi Mode Manager
  // Raspberry should be connected to the ESP32 network.
  // Raspberry expected static IP: 192.168.4.2
  // main_startup.py runs on port 5050.
  static const String raspberryBaseUrl = 'http://192.168.4.2:5050';
  static const Duration raspberryRequestTimeout = Duration(seconds: 20);

  static const String raspberryStatusUrl = '$raspberryBaseUrl/status';
  static const String raspberryManualModeUrl = '$raspberryBaseUrl/mode/manual';
  static const String raspberryAutoModeUrl = '$raspberryBaseUrl/mode/auto';
  static const String raspberryStopModeUrl = '$raspberryBaseUrl/mode/stop';
  static const String raspberryRobotStopUrl = '$raspberryBaseUrl/robot/stop';

  // MQTT Topics
  static const String mqttTopicRobotStatus = 'robot/status';
  static const String mqttTopicSensors = 'robot/sensors/#';
  static const String mqttTopicControl = 'robot/control';
  static const String mqttTopicCommandResponse = 'robot/command_response';

  // Database
  static const String databaseName = 'robot_control.db';
  static const int databaseVersion = 1;

  // Shared Preferences Keys
  static const String prefKeyRobotId = 'robot_id';
  static const String prefKeyConnectionType = 'connection_type';
  static const String prefKeyLastConnection = 'last_connection';
  static const String prefKeyAutoReconnect = 'auto_reconnect';
  static const String prefKeyThemMode = 'theme_mode';
  static const String prefKeyNotificationsEnabled = 'notifications_enabled';

  // Control Settings
  static const int controlUpdateInterval = 100;
  static const double maxSpeed = 100.0;
  static const double minSpeed = 0.0;

  // Polling Intervals
  static const Duration pollIntervalSensors = Duration(seconds: 2);
  static const Duration pollIntervalSystemStatus = Duration(seconds: 10);

  // Error Messages
  static const String errorConnectionFailed = 'Connection failed. Please check your network.';
  static const String errorTimeout = 'Request timed out. Please try again.';
  static const String errorInvalidData = 'Invalid data received from robot.';
  static const String errorDatabaseError = 'Database error occurred.';
  static const String errorUnknownError = 'An unknown error occurred.';

  // Success Messages
  static const String successConnected = 'Successfully connected to robot.';
  static const String successDisconnected = 'Disconnected from robot.';
  static const String successCommandSent = 'Command sent successfully.';
  static const String successDataSynced = 'Data synchronized.';
}

class SensorTypes {
  static const String temperature = 'temperature';
  static const String humidity = 'humidity';
  static const String ultrasonic = 'ultrasonic';
  static const String infrared = 'infrared';
  static const String accelerometer = 'accelerometer';
  static const String gyroscope = 'gyroscope';
  static const String magnetometer = 'magnetometer';
  static const String light = 'light';
  static const String distance = 'distance';
  static const String pressure = 'pressure';
}

class RobotModes {
  static const String idle = 'idle';
  static const String moving = 'moving';
  static const String controlled = 'controlled';
  static const String recording = 'recording';
  static const String playback = 'playback';
  static const String error = 'error';
}

class OperationModes {
  static const String manual = 'MANUAL';
  static const String auto = 'AUTO';
}

class SystemHealthStatus {
  static const String healthy = 'healthy';
  static const String warning = 'warning';
  static const String error = 'error';
}

class ErrorSeverity {
  static const String low = 'low';
  static const String medium = 'medium';
  static const String high = 'high';
  static const String critical = 'critical';
}
