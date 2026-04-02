import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../providers/system_provider.dart';

class SystemScreen extends ConsumerWidget {
  const SystemScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final systemStatus = ref.watch(systemStatusProvider);
    final systemHealth = ref.watch(systemHealthProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // System Health
          Text(
            'System Health',
            style: AppTextStyles.heading3,
          ),
          const SizedBox(height: AppSpacing.md),
          Card(
            color: _getHealthColor(systemHealth).withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Icon(
                    _getHealthIcon(systemHealth),
                    size: 48,
                    color: _getHealthColor(systemHealth),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Status: ${systemHealth.toUpperCase()}',
                          style: AppTextStyles.heading3.copyWith(
                            color: _getHealthColor(systemHealth),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          systemHealth == 'healthy'
                              ? 'All systems operational'
                              : systemHealth == 'warning'
                                  ? 'Some issues detected'
                                  : 'Critical errors detected',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // System Stats
          Text(
            'System Statistics',
            style: AppTextStyles.heading3,
          ),
          const SizedBox(height: AppSpacing.md),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  _StatRow(
                    label: 'Database Status',
                    value: systemStatus?.databaseHealthy == true
                        ? 'Healthy'
                        : 'Error',
                    status: systemStatus?.databaseHealthy ?? false,
                  ),
                  _divider,
                  _StatRow(
                    label: 'Total Logs',
                    value: '${systemStatus?.logCount ?? 0}',
                    status: true,
                  ),
                  _divider,
                  _StatRow(
                    label: 'Last Sync',
                    value: systemStatus != null
                        ? _formatTime(systemStatus.lastSync)
                        : 'Never',
                    status: true,
                  ),
                  _divider,
                  _StatRow(
                    label: 'Active Errors',
                    value: '${systemStatus?.errors.length ?? 0}',
                    status: (systemStatus?.errors.isEmpty ?? true),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Errors/Issues
          if (systemStatus?.errors.isNotEmpty ?? false) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Errors',
                  style: AppTextStyles.heading3,
                ),
                FilledButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Errors cleared'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: (systemStatus?.errors.length ?? 0).clamp(0, 5),
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final error = systemStatus!.errors[index];
                return _ErrorCard(error: error);
              },
            ),
            const SizedBox(height: AppSpacing.xl),
          ],

          // Actions
          Text(
            'Actions',
            style: AppTextStyles.heading3,
          ),
          const SizedBox(height: AppSpacing.md),
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Syncing data...')),
                    );
                  },
                  icon: const Icon(Icons.sync),
                  label: const Text('Sync Data'),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Reset System'),
                        content: const Text(
                          'Are you sure you want to reset the system?'
                        ),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'System reset',
                                  ),
                                ),
                              );
                            },
                            child: const Text('Reset'),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('Reset System'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getHealthColor(String health) {
    return health == 'healthy'
        ? AppColors.success
        : health == 'warning'
            ? AppColors.warning
            : AppColors.error;
  }

  IconData _getHealthIcon(String health) {
    return health == 'healthy'
        ? Icons.check_circle
        : health == 'warning'
            ? Icons.warning
            : Icons.error;
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }

  Widget get _divider => const Divider(height: 16);
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final bool status;

  const _StatRow({
    required this.label,
    required this.value,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium,
        ),
        Row(
          children: [
            Text(
              value,
              style: AppTextStyles.labelLarge,
            ),
            const SizedBox(width: AppSpacing.sm),
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: status
                    ? AppColors.success
                    : Colors.grey,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final dynamic error;

  const _ErrorCard({required this.error});

  @override
  Widget build(BuildContext context) {
    final severity = error.severity;
    final severityColor = severity == 'critical'
        ? AppColors.error
        : severity == 'high'
            ? AppColors.warning
            : Colors.blue;

    return Card(
      color: severityColor.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: severityColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    error.message,
                    style: AppTextStyles.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Severity: ${severity.toUpperCase()}',
              style: AppTextStyles.caption.copyWith(
                color: severityColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
