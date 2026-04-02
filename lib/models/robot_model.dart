/// Robot Battery Status
class BatteryStatus {
  final double voltage; // in volts
  final double current; // in amperes
  final double power; // in watts
  final int percentage; // 0-100
  final bool isCharging;
  final DateTime timestamp;

  BatteryStatus({
    required this.voltage,
    required this.current,
    required this.power,
    required this.percentage,
    required this.isCharging,
    required this.timestamp,
  });

  factory BatteryStatus.fromJson(Map<String, dynamic> json) {
    return BatteryStatus(
      voltage: (json['voltage'] as num).toDouble(),
      current: (json['current'] as num).toDouble(),
      power: (json['power'] as num).toDouble(),
      percentage: json['percentage'] as int,
      isCharging: json['isCharging'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'voltage': voltage,
      'current': current,
      'power': power,
      'percentage': percentage,
      'isCharging': isCharging,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Robot State
class RobotState {
  final bool isPoweredOn;
  final bool isCharging;
  final String robotMode; // 'idle', 'moving', 'controlled', 'error'
  final String robotType; // 'wheeled', 'legged', 'flying', etc.
  final DateTime lastUpdate;

  RobotState({
    required this.isPoweredOn,
    required this.isCharging,
    required this.robotMode,
    required this.robotType,
    required this.lastUpdate,
  });

  factory RobotState.fromJson(Map<String, dynamic> json) {
    return RobotState(
      isPoweredOn: json['isPoweredOn'] as bool,
      isCharging: json['isCharging'] as bool,
      robotMode: json['robotMode'] as String,
      robotType: json['robotType'] as String,
      lastUpdate: DateTime.parse(json['lastUpdate'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isPoweredOn': isPoweredOn,
      'isCharging': isCharging,
      'robotMode': robotMode,
      'robotType': robotType,
      'lastUpdate': lastUpdate.toIso8601String(),
    };
  }
}

/// Sensor Reading
class SensorReading {
  final String sensorId;
  final String sensorName;
  final String sensorType; // 'temperature', 'ultrasonic', 'ir', etc.
  final double value;
  final String unit;
  final bool isActive;
  final DateTime timestamp;

  SensorReading({
    required this.sensorId,
    required this.sensorName,
    required this.sensorType,
    required this.value,
    required this.unit,
    required this.isActive,
    required this.timestamp,
  });

  factory SensorReading.fromJson(Map<String, dynamic> json) {
    return SensorReading(
      sensorId: json['sensorId'] as String,
      sensorName: json['sensorName'] as String,
      sensorType: json['sensorType'] as String,
      value: (json['value'] as num).toDouble(),
      unit: json['unit'] as String,
      isActive: json['isActive'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sensorId': sensorId,
      'sensorName': sensorName,
      'sensorType': sensorType,
      'value': value,
      'unit': unit,
      'isActive': isActive,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Robot Device
class Robot {
  final String id;
  final String name;
  final String type;
  final String firmware;
  final BatteryStatus batteryStatus;
  final RobotState robotState;
  final List<SensorReading> sensors;
  final DateTime lastSync;

  Robot({
    required this.id,
    required this.name,
    required this.type,
    required this.firmware,
    required this.batteryStatus,
    required this.robotState,
    required this.sensors,
    required this.lastSync,
  });

  factory Robot.fromJson(Map<String, dynamic> json) {
    return Robot(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      firmware: json['firmware'] as String,
      batteryStatus: BatteryStatus.fromJson(json['batteryStatus'] as Map<String, dynamic>),
      robotState: RobotState.fromJson(json['robotState'] as Map<String, dynamic>),
      sensors: (json['sensors'] as List)
          .map((e) => SensorReading.fromJson(e as Map<String, dynamic>))
          .toList(),
      lastSync: DateTime.parse(json['lastSync'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'firmware': firmware,
      'batteryStatus': batteryStatus.toJson(),
      'robotState': robotState.toJson(),
      'sensors': sensors.map((e) => e.toJson()).toList(),
      'lastSync': lastSync.toIso8601String(),
    };
  }

  bool get isBatteryLow => batteryStatus.percentage < 20;
  bool get isBatteryCritical => batteryStatus.percentage < 10;
}

/// Connection Status
enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  error,
}

/// Control Command
class ControlCommand {
  final String commandId;
  final String commandType; // 'move_forward', 'move_backward', 'turn_left', 'turn_right', 'stop'
  final Map<String, dynamic> parameters;
  final DateTime timestamp;

  ControlCommand({
    required this.commandId,
    required this.commandType,
    required this.parameters,
    required this.timestamp,
  });

  factory ControlCommand.fromJson(Map<String, dynamic> json) {
    return ControlCommand(
      commandId: json['commandId'] as String,
      commandType: json['commandType'] as String,
      parameters: json['parameters'] as Map<String, dynamic>,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'commandId': commandId,
      'commandType': commandType,
      'parameters': parameters,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
