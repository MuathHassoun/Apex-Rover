import 'package:logger/logger.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../config/constants.dart';
import '../models/robot_model.dart';
import '../models/system_status_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  late Database _database;
  final Logger _logger = Logger();

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  Future<void> initialize() async {
    try {
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, AppConstants.databaseName);

      _database = await openDatabase(
        path,
        version: AppConstants.databaseVersion,
        onCreate: _createTables,
        onUpgrade: _onUpgrade,
      );
      _logger.i('Database initialized successfully');
    } catch (e) {
      _logger.e('Error initializing database: $e');
      rethrow;
    }
  }

  Future<void> _createTables(Database db, int version) async {
    // Robot data table
    await db.execute(
      '''CREATE TABLE IF NOT EXISTS robots (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        firmware TEXT NOT NULL,
        data TEXT NOT NULL,
        lastSync TEXT NOT NULL
      )''',
    );

    // Sensor readings table
    await db.execute(
      '''CREATE TABLE IF NOT EXISTS sensor_readings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sensorId TEXT NOT NULL,
        sensorName TEXT NOT NULL,
        sensorType TEXT NOT NULL,
        value REAL NOT NULL,
        unit TEXT NOT NULL,
        isActive INTEGER NOT NULL,
        timestamp TEXT NOT NULL
      )''',
    );

    // Audit logs table
    await db.execute(
      '''CREATE TABLE IF NOT EXISTS audit_logs (
        id TEXT PRIMARY KEY,
        action TEXT NOT NULL,
        userId TEXT,
        timestamp TEXT NOT NULL,
        details TEXT NOT NULL
      )''',
    );

    // Control commands table
    await db.execute(
      '''CREATE TABLE IF NOT EXISTS control_commands (
        id TEXT PRIMARY KEY,
        commandType TEXT NOT NULL,
        parameters TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        status TEXT NOT NULL
      )''',
    );

    _logger.i('Database tables created');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades here
    _logger.i('Database upgraded from $oldVersion to $newVersion');
  }

  // Robot operations
  Future<void> saveRobot(Robot robot) async {
    try {
      await _database.insert(
        'robots',
        {
          'id': robot.id,
          'name': robot.name,
          'type': robot.type,
          'firmware': robot.firmware,
          'data': robot.toJson().toString(),
          'lastSync': robot.lastSync.toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      _logger.i('Robot saved: ${robot.id}');
    } catch (e) {
      _logger.e('Error saving robot: $e');
    }
  }

  Future<Robot?> getRobot(String robotId) async {
    try {
      final maps = await _database.query(
        'robots',
        where: 'id = ?',
        whereArgs: [robotId],
      );

      if (maps.isNotEmpty) {
        return Robot.fromJson(Map<String, dynamic>.from(maps.first));
      }
      return null;
    } catch (e) {
      _logger.e('Error getting robot: $e');
      return null;
    }
  }

  // Sensor readings operations
  Future<void> saveSensorReading(SensorReading reading) async {
    try {
      await _database.insert(
        'sensor_readings',
        {
          'sensorId': reading.sensorId,
          'sensorName': reading.sensorName,
          'sensorType': reading.sensorType,
          'value': reading.value,
          'unit': reading.unit,
          'isActive': reading.isActive ? 1 : 0,
          'timestamp': reading.timestamp.toIso8601String(),
        },
      );
    } catch (e) {
      _logger.e('Error saving sensor reading: $e');
    }
  }

  Future<List<SensorReading>> getSensorReadings(String sensorId, {int limit = 100}) async {
    try {
      final maps = await _database.query(
        'sensor_readings',
        where: 'sensorId = ?',
        whereArgs: [sensorId],
        orderBy: 'timestamp DESC',
        limit: limit,
      );

      return maps.map((map) => SensorReading.fromJson(Map<String, dynamic>.from(map))).toList();
    } catch (e) {
      _logger.e('Error getting sensor readings: $e');
      return [];
    }
  }

  // Audit log operations
  Future<void> saveAuditLog(AuditLog log) async {
    try {
      await _database.insert(
        'audit_logs',
        {
          'id': log.id,
          'action': log.action,
          'userId': log.userId,
          'timestamp': log.timestamp.toIso8601String(),
          'details': log.details.toString(),
        },
      );
    } catch (e) {
      _logger.e('Error saving audit log: $e');
    }
  }

  Future<List<AuditLog>> getAuditLogs({int limit = 50}) async {
    try {
      final maps = await _database.query(
        'audit_logs',
        orderBy: 'timestamp DESC',
        limit: limit,
      );

      return maps.map((map) => AuditLog.fromJson(Map<String, dynamic>.from(map))).toList();
    } catch (e) {
      _logger.e('Error getting audit logs: $e');
      return [];
    }
  }

  // Control commands operations
  Future<void> saveControlCommand(ControlCommand command) async {
    try {
      await _database.insert(
        'control_commands',
        {
          'id': command.commandId,
          'commandType': command.commandType,
          'parameters': command.parameters.toString(),
          'timestamp': command.timestamp.toIso8601String(),
          'status': 'pending',
        },
      );
    } catch (e) {
      _logger.e('Error saving control command: $e');
    }
  }

  Future<void> clearOldData(Duration olderThan) async {
    try {
      final cutoffDate = DateTime.now().subtract(olderThan);
      await _database.delete(
        'sensor_readings',
        where: 'timestamp < ?',
        whereArgs: [cutoffDate.toIso8601String()],
      );
      _logger.i('Old data cleared');
    } catch (e) {
      _logger.e('Error clearing old data: $e');
    }
  }

  Future<void> close() async {
    try {
      await _database.close();
      _logger.i('Database closed');
    } catch (e) {
      _logger.e('Error closing database: $e');
    }
  }
}
