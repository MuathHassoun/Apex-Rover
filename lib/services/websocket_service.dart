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
      _channel.sink.add(command.toJson().toString());
      _logger.i('Command sent via WebSocket: ${command.commandType}');
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
