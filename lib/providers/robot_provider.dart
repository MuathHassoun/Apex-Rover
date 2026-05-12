import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/robot_model.dart';
import '../services/database_service.dart';

// Robot state provider
final robotProvider = StateNotifierProvider<RobotNotifier, Robot?>((ref) {
  return RobotNotifier();
});

class RobotNotifier extends StateNotifier<Robot?> {
  RobotNotifier() : super(null);

  void updateRobot(Robot robot) {
    state = robot;
    _saveToDatabase(robot);
  }

  void updateRobotState(RobotState robotState) {
    if (state != null) {
      state = Robot(
        id: state!.id,
        name: state!.name,
        type: state!.type,
        firmware: state!.firmware,
        robotState: robotState,
        sensors: state!.sensors,
        lastSync: DateTime.now(),
      );
      _saveToDatabase(state!);
    }
  }

  void updateSensors(List<SensorReading> sensors) {
    if (state != null) {
      state = Robot(
        id: state!.id,
        name: state!.name,
        type: state!.type,
        firmware: state!.firmware,
        robotState: state!.robotState,
        sensors: sensors,
        lastSync: DateTime.now(),
      );
      _saveToDatabase(state!);
    }
  }

  void _saveToDatabase(Robot robot) {
    try {
      DatabaseService().saveRobot(robot);
    } catch (e) {
      print('Error saving to database: $e');
    }
  }

  void clearRobot() {
    state = null;
  }
}

// Sensors provider
final sensorsProvider = StateProvider<List<SensorReading>>((ref) {
  final robot = ref.watch(robotProvider);
  return robot?.sensors ?? [];
});

// Robot state provider
final robotStateProvider = StateProvider<RobotState?>((ref) {
  final robot = ref.watch(robotProvider);
  return robot?.robotState;
});
