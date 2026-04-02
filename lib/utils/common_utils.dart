import 'dart:async';

class DateTimeUtils {
  /// Format DateTime to a human-readable relative time string
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  /// Format DateTime to HH:MM format
  static String formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Format DateTime to DD/MM/YYYY format
  static String formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  /// Format DateTime to DD/MM/YYYY HH:MM format
  static String formatDateTime(DateTime dateTime) {
    return '${formatDate(dateTime)} ${formatTime(dateTime)}';
  }
}

class NumberUtils {
  /// Format double to a fixed decimal place
  static String formatDecimal(double value, {int places = 2}) {
    return value.toStringAsFixed(places);
  }

  /// Format number with thousand separator
  static String formatNumber(num value) {
    return value.toString().replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (m) => ',',
        );
  }

  /// Convert bytes to human-readable format
  static String formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }

  /// Clamp value between min and max
  static double clamp(double value, double min, double max) {
    return value.clamp(min, max);
  }
}

class ValidationUtils {
  /// Validate email format
  static bool isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email);
  }

  /// Validate IP address format
  static bool isValidIP(String ip) {
    final pattern = RegExp(
      r'^(\d{1,3}\.){3}\d{1,3}$',
    );
    if (!pattern.hasMatch(ip)) {
      return false;
    }

    final parts = ip.split('.');
    for (final part in parts) {
      final num = int.tryParse(part);
      if (num == null || num < 0 || num > 255) {
        return false;
      }
    }
    return true;
  }

  /// Validate port number
  static bool isValidPort(String port) {
    final num = int.tryParse(port);
    return num != null && num > 0 && num < 65536;
  }

  /// Validate URL
  static bool isValidUrl(String url) {
    try {
      Uri.parse(url);
      return true;
    } catch (e) {
      return false;
    }
  }
}

class StringUtils {
  /// Capitalize first letter of string
  static String capitalize(String s) {
    return '${s[0].toUpperCase()}${s.substring(1)}';
  }

  /// Convert snake_case to camelCase
  static String toCamelCase(String text) {
    List<String> words = text.split('_');
    return words.first +
        words.skip(1).map((word) => capitalize(word)).join('');
  }

  /// Convert camelCase to snake_case
  static String toSnakeCase(String text) {
    return text
        .replaceAllMapped(RegExp(r'(?=[A-Z])'), (match) => '_')
        .toLowerCase();
  }

  /// Truncate text to specified length with ellipsis
  static String truncate(String text, {int length = 50, String suffix = '...'}) {
    if (text.length <= length) {
      return text;
    }
    return '${text.substring(0, length)}$suffix';
  }
}

class DebounceTimer {
  Timer? _debounce;

  void call(Duration delay, Function() function) {
    _debounce?.cancel();
    _debounce = Timer(delay, function);
  }

  void cancel() {
    _debounce?.cancel();
  }
}

class ThrottleTimer {
  DateTime? _lastCall;
  Timer? _lastCallTimer;
  final Duration duration;

  ThrottleTimer({required this.duration});

  bool call(Function() function) {
    final now = DateTime.now();
    final last = _lastCall;

    if (last == null || now.difference(last) >= duration) {
      _lastCall = now;
      function();
      return true;
    }
    return false;
  }
}
