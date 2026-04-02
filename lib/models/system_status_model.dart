class SystemStatus {
  final bool databaseHealthy;
  final int logCount;
  final DateTime lastSync;
  final String systemHealth; // 'healthy', 'warning', 'error'
  final List<SystemError> errors;

  SystemStatus({
    required this.databaseHealthy,
    required this.logCount,
    required this.lastSync,
    required this.systemHealth,
    required this.errors,
  });

  factory SystemStatus.fromJson(Map<String, dynamic> json) {
    return SystemStatus(
      databaseHealthy: json['databaseHealthy'] as bool,
      logCount: json['logCount'] as int,
      lastSync: DateTime.parse(json['lastSync'] as String),
      systemHealth: json['systemHealth'] as String,
      errors: (json['errors'] as List)
          .map((e) => SystemError.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'databaseHealthy': databaseHealthy,
      'logCount': logCount,
      'lastSync': lastSync.toIso8601String(),
      'systemHealth': systemHealth,
      'errors': errors.map((e) => e.toJson()).toList(),
    };
  }
}

class SystemError {
  final String id;
  final String message;
  final String severity; // 'low', 'medium', 'high', 'critical'
  final DateTime timestamp;
  final String? stackTrace;

  SystemError({
    required this.id,
    required this.message,
    required this.severity,
    required this.timestamp,
    this.stackTrace,
  });

  factory SystemError.fromJson(Map<String, dynamic> json) {
    return SystemError(
      id: json['id'] as String,
      message: json['message'] as String,
      severity: json['severity'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      stackTrace: json['stackTrace'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message': message,
      'severity': severity,
      'timestamp': timestamp.toIso8601String(),
      'stackTrace': stackTrace,
    };
  }
}

class AuditLog {
  final String id;
  final String action;
  final String? userId;
  final DateTime timestamp;
  final Map<String, dynamic> details;

  AuditLog({
    required this.id,
    required this.action,
    this.userId,
    required this.timestamp,
    required this.details,
  });

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    return AuditLog(
      id: json['id'] as String,
      action: json['action'] as String,
      userId: json['userId'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      details: json['details'] as Map<String, dynamic>,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'action': action,
      'userId': userId,
      'timestamp': timestamp.toIso8601String(),
      'details': details,
    };
  }
}
