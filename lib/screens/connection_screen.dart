// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../config/theme.dart';
// import '../models/robot_model.dart';
// import '../providers/connection_provider.dart';

// class ConnectionScreen extends ConsumerStatefulWidget {
//   const ConnectionScreen({Key? key}) : super(key: key);

//   @override
//   ConsumerState<ConnectionScreen> createState() => _ConnectionScreenState();
// }

// class _ConnectionScreenState extends ConsumerState<ConnectionScreen> {
//   String _selectedConnectionType = 'mqtt';
//   final TextEditingController _brokerController = TextEditingController(text: 'localhost');
//   final TextEditingController _portController = TextEditingController(text: '1883');

//   @override
//   void dispose() {
//     _brokerController.dispose();
//     _portController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final connectionStatus = ref.watch(connectionStatusProvider);
//     final isConnected = connectionStatus == ConnectionStatus.connected;
//     final isConnecting = connectionStatus == ConnectionStatus.connecting;

//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(AppSpacing.md),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Connection Status Card
//           Card(
//             color: isConnected
//                 ? AppColors.success.withOpacity(0.1)
//                 : isConnecting
//                     ? AppColors.warning.withOpacity(0.1)
//                     : AppColors.error.withOpacity(0.1),
//             child: Padding(
//               padding: const EdgeInsets.all(AppSpacing.lg),
//               child: Column(
//                 children: [
//                   Row(
//                     children: [
//                       Icon(
//                         isConnected
//                             ? Icons.cloud_done
//                             : isConnecting
//                                 ? Icons.cloud_sync
//                                 : Icons.cloud_off,
//                         size: 48,
//                         color: isConnected
//                             ? AppColors.success
//                             : isConnecting
//                                 ? AppColors.warning
//                                 : AppColors.error,
//                       ),
//                       const SizedBox(width: AppSpacing.lg),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               isConnected
//                                   ? 'Robot Connected'
//                                   : isConnecting
//                                       ? 'Connecting...'
//                                       : 'Disconnected',
//                               style: AppTextStyles.heading3.copyWith(
//                                 color: isConnected
//                                     ? AppColors.success
//                                     : isConnecting
//                                         ? AppColors.warning
//                                         : AppColors.error,
//                               ),
//                             ),
//                             const SizedBox(height: AppSpacing.sm),
//                             Text(
//                               'Via $_selectedConnectionType',
//                               style: AppTextStyles.bodySmall.copyWith(
//                                 color: Colors.grey,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: AppSpacing.lg),
//                   Row(
//                     children: [
//                       Expanded(
//                         child: FilledButton.icon(
//                           onPressed: isConnected
//                               ? () => _disconnect()
//                               : isConnecting
//                                   ? null
//                                   : () => _connect(),
//                           icon: Icon(
//                             isConnected
//                                 // `disconnect_on_exit` isn't available in this SDK; use a compatible icon
//                                 ? Icons.exit_to_app
//                                 : isConnecting
//                                     ? Icons.pending
//                                     : Icons.connect_without_contact,
//                           ),
//                           label: Text(
//                             isConnected
//                                 ? 'Disconnect'
//                                 : isConnecting
//                                     ? 'Connecting'
//                                     : 'Connect',
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           const SizedBox(height: AppSpacing.xl),

//           // Connection Type Selection
//           Text(
//             'Connection Type',
//             style: AppTextStyles.heading3,
//           ),
//           const SizedBox(height: AppSpacing.md),
//           SegmentedButton<String>(
//             segments: const [
//               ButtonSegment(
//                 value: 'mqtt',
//                 label: Text('MQTT'),
//               ),
//               ButtonSegment(
//                 value: 'websocket',
//                 label: Text('WebSocket'),
//               ),
//             ],
//             selected: <String>{_selectedConnectionType},
//             onSelectionChanged: (Set<String> newSelection) {
//               setState(() {
//                 _selectedConnectionType = newSelection.first;
//               });
//             },
//           ),
//           const SizedBox(height: AppSpacing.xl),

//           // Connection Settings
//           Text(
//             'Connection Settings',
//             style: AppTextStyles.heading3,
//           ),
//           const SizedBox(height: AppSpacing.md),
//           TextField(
//             controller: _brokerController,
//             decoration: const InputDecoration(
//               labelText: 'Broker Address',
//               hintText: 'localhost or IP address',
//               prefixIcon: Icon(Icons.dns),
//             ),
//             enabled: !isConnected && !isConnecting,
//           ),
//           const SizedBox(height: AppSpacing.md),
//           TextField(
//             controller: _portController,
//             decoration: const InputDecoration(
//               labelText: 'Port',
//               hintText: '1883 (MQTT) or 8080 (WebSocket)',
//               prefixIcon: Icon(Icons.numbers),
//             ),
//             keyboardType: TextInputType.number,
//             enabled: !isConnected && !isConnecting,
//           ),
//           const SizedBox(height: AppSpacing.xl),

//           // Signal Strength
//           Text(
//             'Signal Strength',
//             style: AppTextStyles.heading3,
//           ),
//           const SizedBox(height: AppSpacing.md),
//           if (isConnected)
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(
//                       'Signal: 85%',
//                       style: AppTextStyles.bodyMedium,
//                     ),
//                     Icon(
//                       Icons.signal_cellular_alt,
//                       color: AppColors.success,
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: AppSpacing.md),
//                 LinearProgressIndicator(
//                   value: 0.85,
//                   minHeight: 8,
//                   borderRadius: BorderRadius.circular(4),
//                 ),
//               ],
//             )
//           else
//             Text(
//               'Not connected',
//               style: AppTextStyles.bodyMedium.copyWith(
//                 color: Colors.grey,
//               ),
//             ),
//           const SizedBox(height: AppSpacing.xl),

//           // Device List (Future Feature)
//           Text(
//             'Available Robots',
//             style: AppTextStyles.heading3,
//           ),
//           const SizedBox(height: AppSpacing.md),
//           Card(
//             color: Colors.grey[50],
//             child: ListTile(
//               leading: Icon(Icons.search, color: Colors.grey[400]),
//               title: Text(
//                 'Scanning for robots...',
//                 style: AppTextStyles.bodyMedium.copyWith(
//                   color: Colors.grey,
//                 ),
//               ),
//               trailing: SizedBox(
//                 width: 20,
//                 height: 20,
//                 child: CircularProgressIndicator(
//                   strokeWidth: 2,
//                   valueColor: AlwaysStoppedAnimation<Color>(
//                     Colors.grey[400]!,
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   void _connect() {
//     final connectionNotifier = ref.read(connectionStatusProvider.notifier);
//     connectionNotifier.connect(connectionType: _selectedConnectionType);

//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(
//           'Connecting via $_selectedConnectionType...',
//         ),
//       ),
//     );
//   }

//   void _disconnect() {
//     final connectionNotifier = ref.read(connectionStatusProvider.notifier);
//     connectionNotifier.disconnect();

//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text('Disconnected from robot'),
//       ),
//     );
//   }
// }

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
  String _selectedConnectionType = 'websocket';

  final TextEditingController _brokerController = TextEditingController(text: '192.168.4.1');
  final TextEditingController _portController = TextEditingController(text: '81');

  static const Color _bgColor = Color(0xFF020712);
  static const Color _panelColor = Color(0xFF07111F);
  static const Color _panelColor2 = Color(0xFF0D1B2E);
  static const Color _borderColor = Color(0xFF1E3858);
  static const Color _cyanColor = Color(0xFF00B4FF);
  static const Color _textColor = Colors.white;
  static const Color _mutedColor = Color(0xFF9AA8BA);

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

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _bgColor,
            _panelColor,
            Color(0xFF0B1626),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _statusHero(isConnected, isConnecting),
            const SizedBox(height: AppSpacing.lg),
            _connectionTypePanel(isConnected, isConnecting),
            const SizedBox(height: AppSpacing.lg),
            _settingsPanel(isConnected, isConnecting),
            const SizedBox(height: AppSpacing.lg),
            _signalPanel(isConnected),
            const SizedBox(height: AppSpacing.lg),
            _robotInfoPanel(isConnected, isConnecting),
          ],
        ),
      ),
    );
  }

  Widget _statusHero(bool isConnected, bool isConnecting) {
    final Color statusColor = isConnected
        ? Colors.greenAccent
        : isConnecting
            ? Colors.orangeAccent
            : Colors.redAccent;

    final IconData statusIcon = isConnected
        ? Icons.cloud_done
        : isConnecting
            ? Icons.cloud_sync
            : Icons.cloud_off;

    final String title = isConnected
        ? 'Robot Connected'
        : isConnecting
            ? 'Connecting...'
            : 'Disconnected';

    final String subtitle = isConnected
        ? 'Apex Rover is online and ready for manual control'
        : isConnecting
            ? 'Trying to establish connection with the robot'
            : 'Connect to ESP32 WebSocket to start controlling the robot';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            statusColor.withValues(alpha: 0.18),
            _panelColor,
            _panelColor2,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.65),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.13),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor.withValues(alpha: 0.13),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.55),
                    width: 1.4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withValues(alpha: 0.12),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: Icon(
                  statusIcon,
                  size: 35,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.heading3.copyWith(
                        color: _textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: _mutedColor,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _smallChip(_selectedConnectionType.toUpperCase()),
                        const SizedBox(width: 6),
                        _smallChip(isConnected ? 'ONLINE' : 'MANUAL'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: isConnected
                    ? Colors.redAccent.withValues(alpha: 0.95)
                    : statusColor.withValues(alpha: 0.95),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: isConnected
                  ? () => _disconnect()
                  : isConnecting
                      ? null
                      : () => _connect(),
              icon: Icon(
                isConnected
                    ? Icons.exit_to_app
                    : isConnecting
                        ? Icons.pending
                        : Icons.connect_without_contact,
                color: isConnected ? Colors.white : Colors.black,
              ),
              label: Text(
                isConnected
                    ? 'Disconnect'
                    : isConnecting
                        ? 'Connecting...'
                        : 'Connect to Robot',
                style: TextStyle(
                  color: isConnected ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _connectionTypePanel(bool isConnected, bool isConnecting) {
    return _panel(
      title: 'Connection Type',
      subtitle: 'Use WebSocket for ESP32 real-time control',
      icon: Icons.hub,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _connectionTypeCard(
                  title: 'WebSocket',
                  subtitle: 'Recommended',
                  icon: Icons.bolt,
                  value: 'websocket',
                  enabled: !isConnected && !isConnecting,
                  color: _cyanColor,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _connectionTypeCard(
                  title: 'MQTT',
                  subtitle: 'Optional',
                  icon: Icons.cloud_queue,
                  value: 'mqtt',
                  enabled: !isConnected && !isConnecting,
                  color: Colors.purpleAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'For your current robot setup, WebSocket should be selected because the mobile app connects directly to ESP32.',
            style: AppTextStyles.bodySmall.copyWith(
              color: _mutedColor,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _connectionTypeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required String value,
    required bool enabled,
    required Color color,
  }) {
    final bool selected = _selectedConnectionType == value;

    return InkWell(
      onTap: enabled
          ? () {
              setState(() {
                _selectedConnectionType = value;

                if (value == 'websocket') {
                  _brokerController.text = '192.168.4.1';
                  _portController.text = '81';
                } else {
                  _brokerController.text = 'localhost';
                  _portController.text = '1883';
                }
              });
            }
          : null,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.13) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? color.withValues(alpha: 0.75) : Colors.white.withValues(alpha: 0.10),
            width: selected ? 1.5 : 1.0,
          ),
          boxShadow: [
            if (selected)
              BoxShadow(
                color: color.withValues(alpha: 0.12),
                blurRadius: 15,
                offset: const Offset(0, 7),
              ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: selected ? color : _mutedColor,
              size: 30,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: AppTextStyles.bodyMedium.copyWith(
                color: selected ? color : _textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: AppTextStyles.bodySmall.copyWith(
                color: _mutedColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingsPanel(bool isConnected, bool isConnecting) {
    return _panel(
      title: 'Connection Settings',
      subtitle: 'Current ESP32 access point settings',
      icon: Icons.settings_ethernet,
      child: Column(
        children: [
          _darkTextField(
            controller: _brokerController,
            label: _selectedConnectionType == 'websocket' ? 'ESP32 IP Address' : 'Broker Address',
            hint:
                _selectedConnectionType == 'websocket' ? '192.168.4.1' : 'localhost or IP address',
            icon: Icons.dns,
            enabled: !isConnected && !isConnecting,
          ),
          const SizedBox(height: AppSpacing.md),
          _darkTextField(
            controller: _portController,
            label: 'Port',
            hint: _selectedConnectionType == 'websocket' ? '81' : '1883',
            icon: Icons.numbers,
            keyboardType: TextInputType.number,
            enabled: !isConnected && !isConnecting,
          ),
          const SizedBox(height: AppSpacing.md),
          _infoRow(
            icon: Icons.wifi,
            title: 'Robot WiFi',
            value: 'Apex_Rover_Net',
            color: _cyanColor,
          ),
          const SizedBox(height: AppSpacing.sm),
          _infoRow(
            icon: Icons.router,
            title: 'ESP32 Gateway',
            value: '192.168.4.1',
            color: Colors.greenAccent,
          ),
        ],
      ),
    );
  }

  Widget _darkTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool enabled = true,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      enabled: enabled,
      style: const TextStyle(
        color: _textColor,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: _cyanColor),
        labelStyle: const TextStyle(color: _mutedColor),
        hintStyle: TextStyle(
          color: _mutedColor.withValues(alpha: 0.55),
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: enabled ? 0.06 : 0.03),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.12),
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.07),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: _cyanColor,
            width: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _signalPanel(bool isConnected) {
    return _panel(
      title: 'Signal Strength',
      subtitle:
          isConnected ? 'Connection quality estimate' : 'Connect first to view signal information',
      icon: Icons.signal_cellular_alt,
      child: isConnected
          ? Column(
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.signal_cellular_alt,
                      color: Colors.greenAccent,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Signal: 85%',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: _textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      'Strong',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: 0.85,
                    minHeight: 9,
                    backgroundColor: Colors.white.withValues(alpha: 0.10),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.greenAccent,
                    ),
                  ),
                ),
              ],
            )
          : _emptyState(
              icon: Icons.signal_cellular_off,
              title: 'Not connected',
              subtitle: 'Signal data will appear after connecting to ESP32',
            ),
    );
  }

  Widget _robotInfoPanel(bool isConnected, bool isConnecting) {
    return _panel(
      title: 'Available Robots',
      subtitle: 'Nearby robot connection target',
      icon: Icons.smart_toy,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isConnected
              ? Colors.greenAccent.withValues(alpha: 0.08)
              : _cyanColor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isConnected
                ? Colors.greenAccent.withValues(alpha: 0.30)
                : _cyanColor.withValues(alpha: 0.22),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isConnected
                    ? Colors.greenAccent.withValues(alpha: 0.12)
                    : _cyanColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                isConnected ? Icons.smart_toy : Icons.search,
                color: isConnected ? Colors.greenAccent : _cyanColor,
                size: 28,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isConnected ? 'Apex Rover Connected' : 'Apex Rover',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: _textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isConnected
                        ? 'WebSocket link is active'
                        : 'Connect to ESP32 access point first',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: _mutedColor,
                    ),
                  ),
                ],
              ),
            ),
            if (isConnecting)
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(_cyanColor),
                ),
              )
            else
              Icon(
                isConnected ? Icons.check_circle : Icons.wifi_find,
                color: isConnected ? Colors.greenAccent : _cyanColor,
              ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: _mutedColor, size: 28),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: _textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: _mutedColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: 0.20),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.bodySmall.copyWith(
                color: _mutedColor,
              ),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.16),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _panel({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_panelColor, _panelColor2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _borderColor.withValues(alpha: 0.9),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _cyanColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: _cyanColor.withValues(alpha: 0.25),
                  ),
                ),
                child: Icon(icon, color: _cyanColor, size: 22),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.heading3.copyWith(
                        color: _textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: _mutedColor,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }

  void _connect() {
    final connectionNotifier = ref.read(connectionStatusProvider.notifier);
    connectionNotifier.connect(connectionType: _selectedConnectionType);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _panelColor2,
        content: Text(
          'Connecting via $_selectedConnectionType...',
          style: const TextStyle(color: Colors.white),
        ),
        duration: const Duration(milliseconds: 900),
      ),
    );
  }

  void _disconnect() {
    final connectionNotifier = ref.read(connectionStatusProvider.notifier);
    connectionNotifier.disconnect();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: _panelColor2,
        content: Text(
          'Disconnected from robot',
          style: TextStyle(color: Colors.white),
        ),
        duration: Duration(milliseconds: 900),
      ),
    );
  }
}
