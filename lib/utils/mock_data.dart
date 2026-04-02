/// Example robot data for testing and development
/// Remove in production

import '../models/robot_model.dart';
import '../models/system_status_model.dart';

class MockData {
  /// Example robot with complete data
  static Robot mockRobot = Robot(
    id: 'robot_001',
    name: 'ApexRover-1',
    type: 'wheeled',
    firmware: '2.1.0',
    batteryStatus: BatteryStatus(
      voltage: 12.5,
      current: 2.3,
      power: 28.75,
      percentage: 75,
      isCharging: false,
      timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
    ),
    robotState: RobotState(
      isPoweredOn: true,
      isCharging: false,
      robotMode: 'idle',
      robotType: 'wheeled',
      lastUpdate: DateTime.now().subtract(const Duration(seconds: 30)),
    ),
    sensors: _mockSensors,
    lastSync: DateTime.now(),
  );

  /// Example sensor readings
  static List<SensorReading> _mockSensors = [
    SensorReading(
      sensorId: 'temp_01',
      sensorName: 'Temperature Sensor',
      sensorType: 'temperature',
      value: 35.5,
      unit: '°C',
      isActive: true,
      timestamp: DateTime.now().subtract(const Duration(seconds: 5)),
    ),
    SensorReading(
      sensorId: 'humid_01',
      sensorName: 'Humidity Sensor',
      sensorType: 'humidity',
      value: 45.2,
      unit: '%',
      isActive: true,
      timestamp: DateTime.now().subtract(const Duration(seconds: 5)),
    ),
    SensorReading(
      sensorId: 'dist_01',
      sensorName: 'Ultrasonic Distance',
      sensorType: 'ultrasonic',
      value: 25.3,
      unit: 'cm',
      isActive: true,
      timestamp: DateTime.now().subtract(const Duration(seconds: 5)),
    ),
    SensorReading(
      sensorId: 'ir_01',
      sensorName: 'Infrared Sensor',
      sensorType: 'infrared',
      value: 68.5,
      unit: '%',
      isActive: true,
      timestamp: DateTime.now().subtract(const Duration(seconds: 5)),
    ),
    SensorReading(
      sensorId: 'light_01',
      sensorName: 'Light Sensor',
      sensorType: 'light',
      value: 850,
      unit: 'lux',
      isActive: false,
      timestamp: DateTime.now().subtract(const Duration(seconds: 10)),
    ),
  ];

  /// Example system status
  static SystemStatus mockSystemStatus = SystemStatus(
    databaseHealthy: true,
    logCount: 1234,
    lastSync: DateTime.now().subtract(const Duration(minutes: 5)),
    systemHealth: 'healthy',
    errors: [
      SystemError(
        id: 'err_001',
        message: 'Sensor drift detected in ultrasonic sensor',
        severity: 'low',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      ),
    ],
  );

  /// Example audit logs
  static List<AuditLog> mockAuditLogs = [
    AuditLog(
      id: 'log_001',
      action: 'ROBOT_CONNECTED',
      userId: 'user_001',
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      details: {'robotId': 'robot_001', 'connectionType': 'mqtt'},
    ),
    AuditLog(
      id: 'log_002',
      action: 'COMMAND_SENT',
      userId: 'user_001',
      timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
      details: {
        'robotId': 'robot_001',
        'command': 'move_forward',
        'speed': 50,
      },
    ),
    AuditLog(
      id: 'log_003',
      action: 'SENSOR_READ',
      userId: null,
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      details: {
        'sensorId': 'temp_01',
        'value': 35.5,
      },
    ),
  ];

  /// Example control commands
  static ControlCommand mockCommand = ControlCommand(
    commandId: 'cmd_001',
    commandType: 'move_forward',
    parameters: {
      'speed': 50.0,
      'duration': 5000,
      'robotId': 'robot_001',
    },
    timestamp: DateTime.now(),
  );

  /// Get all mock data
  static Map<String, dynamic> getAllMockData() {
    return {
      'robot': mockRobot,
      'sensors': _mockSensors,
      'systemStatus': mockSystemStatus,
      'auditLogs': mockAuditLogs,
      'command': mockCommand,
    };
  }
}
