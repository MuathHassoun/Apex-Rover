import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/robot_model.dart';
import '../services/mqtt_service.dart';
import '../services/websocket_service.dart';

// Connection status provider
final connectionStatusProvider = StateNotifierProvider<ConnectionNotifier, ConnectionStatus>((ref) {
  return ConnectionNotifier();
});

class ConnectionNotifier extends StateNotifier<ConnectionStatus> {
  late MqttService _mqttService;
  late WebSocketService _wsService;
  String _connectionType = 'mqtt'; // 'mqtt' or 'websocket'

  ConnectionNotifier() : super(ConnectionStatus.disconnected) {
    _mqttService = MqttService();
    _wsService = WebSocketService();
  }

  Future<void> connect({required String connectionType}) async {
    state = ConnectionStatus.connecting;
    _connectionType = connectionType;

    try {
      bool success;
      if (connectionType == 'mqtt') {
        success = await _mqttService.connect();
      } else {
        success = await _wsService.connect();
      }

      state = success ? ConnectionStatus.connected : ConnectionStatus.error;
    } catch (e) {
      state = ConnectionStatus.error;
      print('Connection error: $e');
    }
  }

  Future<void> disconnect() async {
    try {
      if (_connectionType == 'mqtt') {
        await _mqttService.disconnect();
      } else {
        await _wsService.disconnect();
      }
      state = ConnectionStatus.disconnected;
    } catch (e) {
      print('Disconnection error: $e');
    }
  }

  Future<void> sendCommand(ControlCommand command) async {
    if (state != ConnectionStatus.connected) {
      state = ConnectionStatus.error;
      return;
    }

    try {
      if (_connectionType == 'mqtt') {
        await _mqttService.publishCommand(command);
      } else {
        await _wsService.sendCommand(command);
      }
    } catch (e) {
      print('Error sending command: $e');
    }
  }

  String get connectionType => _connectionType;
  bool get isConnected => state == ConnectionStatus.connected;
  MqttService get mqttService => _mqttService;
  WebSocketService get wsService => _wsService;
}

// Reconnect provider
final autoReconnectProvider = StateProvider<bool>((ref) => true);

// Connection signal strength provider
final signalStrengthProvider = StateProvider<int>((ref) => 0);

// Last connection time provider
final lastConnectionTimeProvider = StateProvider<DateTime?>((ref) => null);
