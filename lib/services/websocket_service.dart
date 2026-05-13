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
    String message;

    switch (command.commandType) {
      case 'move_forward':
        message = 'FORWARD';
        break;
      case 'move_backward':
        message = 'BACKWARD';
        break;
      case 'turn_left':
        message = 'LEFT';
        break;
      case 'turn_right':
        message = 'RIGHT';
        break;
      case 'stop':
        message = 'STOP';
        break;
      default:
        message = command.commandType.toUpperCase();
    }

    _channel.sink.add(message);

    if (command.parameters.containsKey('speed')) {
      final speed = command.parameters['speed'].round();
      _channel.sink.add('SPEED:$speed');
    }

    _logger.i('Command sent via WebSocket: $message');
  } catch (e) {
    _logger.e('Error sending command: $e');
  }
}

  void addListener(Function(dynamic message) listener) {
    _listeners.add(listener);
  }

  void removeListener(Function(dynamic message) listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners(dynamic message) {
    for (var listener in _listeners) {
      listener(message);
    }
  }

  Future<void> disconnect() async {
    try {
      await _channel.sink.close();
      _isConnected = false;
      _logger.i('WebSocket disconnected');
    } catch (e) {
      _logger.e('Error disconnecting WebSocket: $e');
    }
  }

  bool get isConnected => _isConnected;
}
