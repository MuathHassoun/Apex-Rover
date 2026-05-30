
import 'package:logger/logger.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../config/constants.dart';
import '../models/robot_model.dart';

class WebSocketService {
  late WebSocketChannel _channel;
  final Logger _logger = Logger();
  bool _isConnected = false;
  final List<Function(dynamic message)> _listeners = [];

  Future<bool> connect() async {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(AppConstants.webSocketUrl));
      _isConnected = true;
      _logger.i('WebSocket connected');

      _setupListening();
      return true;
    } catch (e) {
      _logger.e('WebSocket connection error: $e');
      _isConnected = false;
      return false;
    }
  }

  void _setupListening() {
    _channel.stream.listen(
      (message) {
        _logger.i('Message from ESP32: $message');
        _notifyListeners(message);
      },
      onError: (error) {
        _logger.e('WebSocket error: $error');
        _isConnected = false;
      },
      onDone: () {
        _logger.i('WebSocket closed');
        _isConnected = false;
      },
    );
  }

  Future<void> sendCommand(ControlCommand command) async {
    if (!_isConnected) {
      _logger.w('WebSocket not connected, cannot send command');
      return;
    }

    try {
      final message = _mapCommandType(command.commandType);

      _channel.sink.add(message);
      _logger.i('Command sent via WebSocket: $message');

      // Do not send SPEED with system, mode, arm, jack, or camera commands.
      if (message.startsWith('SYS:') ||
          message.startsWith('MODE:') ||
          message.startsWith('ARM:') ||
          message.startsWith('JACK:') ||
          message.startsWith('CAM:')) {
        return;
      }

      if (command.parameters.containsKey('speed')) {
        final dynamic rawSpeed = command.parameters['speed'];
        final int speed = rawSpeed is num ? rawSpeed.round() : 50;
        final int safeSpeed = speed.clamp(0, 100);

        final speedMessage = 'SPEED:$safeSpeed';
        _channel.sink.add(speedMessage);
        _logger.i('Speed sent via WebSocket: $speedMessage');
      }
    } catch (e) {
      _logger.e('Error sending command: $e');
    }
  }

  String _mapCommandType(String commandType) {
    if (commandType.startsWith('SYS:')) return commandType;
    if (commandType.startsWith('MODE:')) return commandType;
    if (commandType.startsWith('ARM:')) return commandType;
    if (commandType.startsWith('JACK:')) return commandType;
    if (commandType.startsWith('CAM:')) return commandType;

    switch (commandType) {
      case 'move_forward':
        return 'FORWARD';
      case 'move_backward':
        return 'BACKWARD';
      case 'turn_left':
        return 'LEFT';
      case 'turn_right':
        return 'RIGHT';
      case 'stop':
        return 'STOP';

      // For Drive Mode shortcuts
      case 'forward':
        return 'FORWARD';
      case 'backward':
        return 'BACKWARD';
      case 'left':
        return 'LEFT';
      case 'right':
        return 'RIGHT';

      default:
        return commandType.toUpperCase();
    }
  }

  void addListener(Function(dynamic message) listener) {
    _listeners.add(listener);
  }

  void removeListener(Function(dynamic message) listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners(dynamic message) {
    for (final listener in _listeners) {
      listener(message);
    }
  }

  Future<void> disconnect() async {
    try {
      if (_isConnected) {
        _channel.sink.add('STOP');
        _channel.sink.add('JACK:FRONT:STOP');
        _channel.sink.add('JACK:REAR:STOP');
        _channel.sink.add('CAM:STOP');
        await Future.delayed(const Duration(milliseconds: 100));
      }

      await _channel.sink.close();
      _isConnected = false;
      _logger.i('WebSocket disconnected');
    } catch (e) {
      _logger.e('Error disconnecting WebSocket: $e');
    }
  }

  bool get isConnected => _isConnected;
}
