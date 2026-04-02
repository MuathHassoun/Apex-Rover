import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../models/robot_model.dart';
import '../providers/connection_provider.dart';

class ConnectionScreen extends ConsumerStatefulWidget {
  const ConnectionScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends ConsumerState<ConnectionScreen> {
  String _selectedConnectionType = 'mqtt';
  final TextEditingController _brokerController = TextEditingController(text: 'localhost');
  final TextEditingController _portController = TextEditingController(text: '1883');

  @override
  void dispose() {
    _brokerController.dispose();
    _portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final connectionStatus = ref.watch(connectionStatusProvider);
    final isConnected = connectionStatus == ConnectionStatus.connected;
    final isConnecting = connectionStatus == ConnectionStatus.connecting;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Connection Status Card
          Card(
            color: isConnected
                ? AppColors.success.withOpacity(0.1)
                : isConnecting
                    ? AppColors.warning.withOpacity(0.1)
                    : AppColors.error.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        isConnected
                            ? Icons.cloud_done
                            : isConnecting
                                ? Icons.cloud_sync
                                : Icons.cloud_off,
                        size: 48,
                        color: isConnected
                            ? AppColors.success
                            : isConnecting
                                ? AppColors.warning
                                : AppColors.error,
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isConnected
                                  ? 'Robot Connected'
                                  : isConnecting
                                      ? 'Connecting...'
                                      : 'Disconnected',
                              style: AppTextStyles.heading3.copyWith(
                                color: isConnected
                                    ? AppColors.success
                                    : isConnecting
                                        ? AppColors.warning
                                        : AppColors.error,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Via $_selectedConnectionType',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: isConnected
                              ? () => _disconnect()
                              : isConnecting
                                  ? null
                                  : () => _connect(),
                          icon: Icon(
                            isConnected
                                // `disconnect_on_exit` isn't available in this SDK; use a compatible icon
                                ? Icons.exit_to_app
                                : isConnecting
                                    ? Icons.pending
                                    : Icons.connect_without_contact,
                          ),
                          label: Text(
                            isConnected
                                ? 'Disconnect'
                                : isConnecting
                                    ? 'Connecting'
                                    : 'Connect',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Connection Type Selection
          Text(
            'Connection Type',
            style: AppTextStyles.heading3,
          ),
          const SizedBox(height: AppSpacing.md),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'mqtt',
                label: Text('MQTT'),
              ),
              ButtonSegment(
                value: 'websocket',
                label: Text('WebSocket'),
              ),
            ],
            selected: <String>{_selectedConnectionType},
            onSelectionChanged: (Set<String> newSelection) {
              setState(() {
                _selectedConnectionType = newSelection.first;
              });
            },
          ),
          const SizedBox(height: AppSpacing.xl),

          // Connection Settings
          Text(
            'Connection Settings',
            style: AppTextStyles.heading3,
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _brokerController,
            decoration: const InputDecoration(
              labelText: 'Broker Address',
              hintText: 'localhost or IP address',
              prefixIcon: Icon(Icons.dns),
            ),
            enabled: !isConnected && !isConnecting,
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _portController,
            decoration: const InputDecoration(
              labelText: 'Port',
              hintText: '1883 (MQTT) or 8080 (WebSocket)',
              prefixIcon: Icon(Icons.numbers),
            ),
            keyboardType: TextInputType.number,
            enabled: !isConnected && !isConnecting,
          ),
          const SizedBox(height: AppSpacing.xl),

          // Signal Strength
          Text(
            'Signal Strength',
            style: AppTextStyles.heading3,
          ),
          const SizedBox(height: AppSpacing.md),
          if (isConnected)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Signal: 85%',
                      style: AppTextStyles.bodyMedium,
                    ),
                    Icon(
                      Icons.signal_cellular_alt,
                      color: AppColors.success,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                LinearProgressIndicator(
                  value: 0.85,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            )
          else
            Text(
              'Not connected',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.grey,
              ),
            ),
          const SizedBox(height: AppSpacing.xl),

          // Device List (Future Feature)
          Text(
            'Available Robots',
            style: AppTextStyles.heading3,
          ),
          const SizedBox(height: AppSpacing.md),
          Card(
            color: Colors.grey[50],
            child: ListTile(
              leading: Icon(Icons.search, color: Colors.grey[400]),
              title: Text(
                'Scanning for robots...',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.grey,
                ),
              ),
              trailing: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.grey[400]!,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _connect() {
    final connectionNotifier = ref.read(connectionStatusProvider.notifier);
    connectionNotifier.connect(connectionType: _selectedConnectionType);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Connecting via $_selectedConnectionType...',
        ),
      ),
    );
  }

  void _disconnect() {
    final connectionNotifier = ref.read(connectionStatusProvider.notifier);
    connectionNotifier.disconnect();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Disconnected from robot'),
      ),
    );
  }
}
