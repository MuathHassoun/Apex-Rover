import 'package:flutter_riverpod/flutter_riverpod.dart';

class SensorStatus {
  final double? pitch;
  final double? roll;
  final double? frontDistance;
  final double? rearDistance;
  final String balanceStatus;
  final DateTime? lastUpdate;

  const SensorStatus({
    this.pitch,
    this.roll,
    this.frontDistance,
    this.rearDistance,
    this.balanceStatus = 'NO DATA',
    this.lastUpdate,
  });

  bool get isWarning => balanceStatus.toUpperCase() == 'WARNING';
  bool get isDanger => balanceStatus.toUpperCase() == 'DANGER';
  bool get isStable => balanceStatus.toUpperCase() == 'STABLE';

  SensorStatus copyWith({
    double? pitch,
    double? roll,
    double? frontDistance,
    double? rearDistance,
    String? balanceStatus,
    DateTime? lastUpdate,
  }) {
    return SensorStatus(
      pitch: pitch ?? this.pitch,
      roll: roll ?? this.roll,
      frontDistance: frontDistance ?? this.frontDistance,
      rearDistance: rearDistance ?? this.rearDistance,
      balanceStatus: balanceStatus ?? this.balanceStatus,
      lastUpdate: lastUpdate ?? this.lastUpdate,
    );
  }
}

class SensorStatusNotifier extends StateNotifier<SensorStatus> {
  SensorStatusNotifier() : super(const SensorStatus());

  void updateFromMessage(dynamic rawMessage) {
    final message = rawMessage.toString().trim();

    if (!message.startsWith('SENSOR:')) {
      return;
    }

    final payload = message.substring('SENSOR:'.length);
    final parts = payload.split(';');

    double? pitch = state.pitch;
    double? roll = state.roll;
    double? front = state.frontDistance;
    double? rear = state.rearDistance;
    String balance = state.balanceStatus;

    for (final part in parts) {
      final pair = part.split('=');
      if (pair.length != 2) continue;

      final key = pair[0].trim().toUpperCase();
      final value = pair[1].trim();

      switch (key) {
        case 'PITCH':
          pitch = double.tryParse(value);
          break;

        case 'ROLL':
          roll = double.tryParse(value);
          break;

        case 'FRONT':
        case 'UF':
        case 'FRONT_DISTANCE':
          front = double.tryParse(value);
          break;

        case 'REAR':
        case 'UR':
        case 'REAR_DISTANCE':
          rear = double.tryParse(value);
          break;

        case 'BALANCE':
        case 'STATUS':
          balance = value.toUpperCase();
          break;
      }
    }

    state = state.copyWith(
      pitch: pitch,
      roll: roll,
      frontDistance: front,
      rearDistance: rear,
      balanceStatus: balance,
      lastUpdate: DateTime.now(),
    );
  }
}

final sensorStatusProvider =
    StateNotifierProvider<SensorStatusNotifier, SensorStatus>(
  (ref) => SensorStatusNotifier(),
);