import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/system_status_model.dart';
import '../services/database_service.dart';

// System status provider
final systemStatusProvider = StateNotifierProvider<SystemStatusNotifier, SystemStatus?>((ref) {
  return SystemStatusNotifier();
});

class SystemStatusNotifier extends StateNotifier<SystemStatus?> {
  final DatabaseService _dbService = DatabaseService();

  SystemStatusNotifier() : super(null);

  void updateSystemStatus(SystemStatus status) {
    state = status;
  }

  void addError(SystemError error) {
    if (state != null) {
      final updatedErrors = [...state!.errors, error];
      state = SystemStatus(
        databaseHealthy: state!.databaseHealthy,
        logCount: state!.logCount,
        lastSync: state!.lastSync,
        systemHealth: _calculateHealth(updatedErrors),
        errors: updatedErrors,
      );
    }
  }

  String _calculateHealth(List<SystemError> errors) {
    if (errors.any((e) => e.severity == 'critical')) {
      return 'error';
    } else if (errors.any((e) => e.severity == 'high')) {
      return 'warning';
    }
    return 'healthy';
  }

  void clearErrors() {
    if (state != null) {
      state = SystemStatus(
        databaseHealthy: state!.databaseHealthy,
        logCount: state!.logCount,
        lastSync: DateTime.now(),
        systemHealth: 'healthy',
        errors: [],
      );
    }
  }
}

// Audit logs provider
final auditLogsProvider = FutureProvider<List<AuditLog>>((ref) async {
  final dbService = DatabaseService();
  await dbService.initialize();
  return dbService.getAuditLogs();
});

// System health provider
final systemHealthProvider = Provider<String>((ref) {
  final status = ref.watch(systemStatusProvider);
  return status?.systemHealth ?? 'healthy';
});

// System errors count provider
final systemErrorsCountProvider = Provider<int>((ref) {
  final status = ref.watch(systemStatusProvider);
  return status?.errors.length ?? 0;
});
