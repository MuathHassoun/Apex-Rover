import 'package:logger/logger.dart';
// general types (messages, qos, utilities)
import 'package:mqtt5_client/mqtt5_client.dart';
// server client implementation (provides MqttServerClient)
import 'package:mqtt5_client/mqtt5_server_client.dart';
import 'package:typed_data/typed_data.dart' as typed;

import '../config/constants.dart';
import '../models/robot_model.dart';

class MqttService {
  late MqttServerClient _client;
  final Logger _logger = Logger();
  bool _isConnected = false;
  final List<Function(String payload)> _listeners = [];

  Future<bool> connect() async {
    try {
      _client = MqttServerClient(AppConstants.mqttBrokerUrl, AppConstants.mqttClientId);
      _client.port = AppConstants.mqttBrokerPort;
      _client.keepAlivePeriod = 20;
      _client.connectionMessage =
          MqttConnectMessage().withClientIdentifier(AppConstants.mqttClientId).startClean();

      await _client.connect();

      if (_client.connectionStatus?.state == MqttConnectionState.connected) {
        _isConnected = true;
        _logger.i('MQTT Connected successfully');
        _setupSubscriptions();
        return true;
      }
      _logger.e('MQTT connection failed');
      return false;
    } catch (e) {
      _logger.e('MQTT connection error: $e');
      _isConnected = false;
      return false;
    }
  }

  void _setupSubscriptions() {
    // Subscribe to robot status topic
    _client.subscribe(AppConstants.mqttTopicRobotStatus, MqttQos.atMostOnce);
    _client.subscribe(AppConstants.mqttTopicBatteryStatus, MqttQos.atMostOnce);
    _client.subscribe(AppConstants.mqttTopicSensors, MqttQos.atMostOnce);
    _client.subscribe(AppConstants.mqttTopicCommandResponse, MqttQos.atMostOnce);

    // Listen to messages
    _client.updates.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      for (var msg in c) {
        final String payload = MqttUtilities.bytesToStringAsString(
          (msg.payload as MqttPublishMessage).payload.message!,
        );
        _notifyListeners(payload);
      }
    });
  }

  Future<void> publishCommand(ControlCommand command) async {
    if (!_isConnected) {
      _logger.w('MQTT not connected, cannot publish command');
      return;
    }

    try {
      final payload = command.toJson().toString();
      final typed.Uint8Buffer buffer = typed.Uint8Buffer();
      buffer.addAll(payload.codeUnits);
      _client.publishMessage(
        AppConstants.mqttTopicControl,
        MqttQos.atMostOnce,
        buffer,
      );
      _logger.i('Command published: ${command.commandType}');
    } catch (e) {
      _logger.e('Error publishing command: $e');
    }
  }

  void addListener(Function(String payload) listener) {
    _listeners.add(listener);
  }

  void removeListener(Function(String payload) listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners(String payload) {
    for (var listener in _listeners) {
      listener(payload);
    }
  }

  Future<void> disconnect() async {
    try {
      _client.disconnect();
      _isConnected = false;
      _logger.i('MQTT disconnected');
    } catch (e) {
      _logger.e('Error disconnecting MQTT: $e');
    }
  }

  bool get isConnected => _isConnected;
  String get connectionStatus => _client.connectionStatus?.state.toString() ?? 'Unknown';
}
