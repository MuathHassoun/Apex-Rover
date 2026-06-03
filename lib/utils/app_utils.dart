
// JSON serialization utilities
import 'dart:convert';

class JsonUtils {
  /// Safely decode JSON string
  static Map<String, dynamic>? decodeJson(String jsonString) {
    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      print('Error decoding JSON: $e');
      return null;
    }
  }

  /// Safely encode object to JSON
  static String encodeJson(dynamic object) {
    try {
      return jsonEncode(object);
    } catch (e) {
      print('Error encoding JSON: $e');
      return '{}';
    }
  }

  /// Extract value from nested JSON safely
  static dynamic getNestedValue(
    Map<String, dynamic> json,
    String path, {
    dynamic defaultValue,
  }) {
    try {
      final keys = path.split('.');
      dynamic value = json;

      for (final key in keys) {
        if (value is Map<String, dynamic>) {
          value = value[key];
        } else {
          return defaultValue;
        }
      }
      return value ?? defaultValue;
    } catch (e) {
      return defaultValue;
    }
  }
}

// Logging utilities
class LogUtils {
  static const String _tag = 'RobotControl';

  static void info(String message) {
    print('[$_tag] INFO: $message');
  }

  static void debug(String message) {
    print('[$_tag] DEBUG: $message');
  }

  static void warning(String message) {
    print('[$_tag] WARNING: $message');
  }

  static void error(String message, [Exception? exception]) {
    print('[$_tag] ERROR: $message');
    if (exception != null) {
      print('Exception: $exception');
    }
  }
}

// Error handling
class ErrorHandler {
  static String getErrorMessage(dynamic error) {
    if (error is Exception) {
      return error.toString().replaceFirst('Exception: ', '');
    }
    return error.toString();
  }

  static void handleError(dynamic error, StackTrace stackTrace) {
    LogUtils.error('An error occurred: $error');
    print(stackTrace);
  }
}

// Network utilities
class NetworkUtils {
  static bool isValidBrokerUrl(String url) {
    try {
      Uri.parse(url);
      return !url.isEmpty;
    } catch (e) {
      return false;
    }
  }

  static String formatBrokerUrl(String broker, int port, String protocol) {
    return '$protocol://$broker:$port';
  }

  static bool isValidConnection(String broker, String port) {
    return broker.isNotEmpty && int.tryParse(port) != null;
  }
}
