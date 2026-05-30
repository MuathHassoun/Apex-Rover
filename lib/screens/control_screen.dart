import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../config/theme.dart';
import '../models/robot_model.dart';
import '../providers/connection_provider.dart';

import 'drive_mode_screen.dart';
import 'arm_control_screen.dart';
import 'camera_control_screen.dart';
import 'remote_control_screen.dart';

class ControlScreen extends ConsumerStatefulWidget {
  const ControlScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends ConsumerState<ControlScreen> {
  double _speedValue = 50.0;
  bool _isMoving = false;

  final String _commandId = const Uuid().v4();

  @override
  Widget build(BuildContext context) {
    final isConnected =
        ref.watch(connectionStatusProvider) == ConnectionStatus.connected;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Connection Status
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isConnected
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.error.withValues(alpha: 0.1),
              border: Border.all(
                color: isConnected ? AppColors.success : AppColors.error,
              ),
              borderRadius: BorderRadius.circular(AppBorderRadius.lg),
            ),
            child: Row(
              children: [
                Icon(
                  isConnected ? Icons.check_circle : Icons.error,
                  color: isConnected ? AppColors.success : AppColors.error,
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  isConnected ? 'Connected & Ready' : 'Not Connected',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isConnected ? AppColors.success : AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Drive Mode button
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (_) => const DriveModeScreen(),
                ),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D1421), Color(0xFF1A2540)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                border: Border.all(
                  color: const Color(0xFF00B4FF).withValues(alpha: 0.6),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00B4FF).withValues(alpha: 0.15),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF00B4FF).withValues(alpha: 0.15),
                      border: Border.all(
                        color: const Color(0xFF00B4FF).withValues(alpha: 0.7),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.sports_esports,
                      color: Color(0xFF00B4FF),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Drive Mode',
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: const Color(0xFF00B4FF),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Steering wheel · Gas pedal · Brake',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: const Color(0xFF00B4FF).withValues(alpha: 0.7),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Movement Controls
          Text('Movement Control', style: AppTextStyles.heading3),
          const SizedBox(height: AppSpacing.lg),

          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 3),
                color: Colors.grey[100],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ControlButton(
                    icon: Icons.arrow_upward,
                    onPressed:
                        isConnected ? () => _sendCommand('move_forward') : null,
                    tooltip: 'Forward',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ControlButton(
                        icon: Icons.arrow_back,
                        onPressed: isConnected
                            ? () => _sendCommand('turn_left')
                            : null,
                        tooltip: 'Turn Left',
                      ),
                      const SizedBox(width: AppSpacing.md),
                      _ControlButton(
                        icon: Icons.stop_circle,
                        onPressed:
                            isConnected ? () => _sendCommand('stop') : null,
                        tooltip: 'Stop',
                        isPrimary: true,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      _ControlButton(
                        icon: Icons.arrow_forward,
                        onPressed: isConnected
                            ? () => _sendCommand('turn_right')
                            : null,
                        tooltip: 'Turn Right',
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _ControlButton(
                    icon: Icons.arrow_downward,
                    onPressed: isConnected
                        ? () => _sendCommand('move_backward')
                        : null,
                    tooltip: 'Backward',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Speed Control
          Text(
            'Speed: ${_speedValue.toStringAsFixed(0)}%',
            style: AppTextStyles.heading3,
          ),
          const SizedBox(height: AppSpacing.md),
          Slider(
            value: _speedValue,
            min: 0,
            max: 100,
            divisions: 10,
            label: '${_speedValue.toStringAsFixed(0)}%',
            onChanged: isConnected
                ? (value) => setState(() => _speedValue = value)
                : null,
          ),

          const SizedBox(height: AppSpacing.xl),

          // Advanced Controls
          Text('Advanced Controls', style: AppTextStyles.heading3),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      fullscreenDialog: true,
                      builder: (_) => const ArmControlScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.pan_tool),
                label: const Text('Arm Control'),
              ),

              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      fullscreenDialog: true,
                      builder: (_) => const CameraControlScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.videocam),
                label: const Text('Camera Control'),
              ),

              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      fullscreenDialog: true,
                      builder: (_) => const RemoteControlScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.screen_rotation),
                label: const Text('Remote Control'),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          // Status
          Center(
            child: Text(
              _isMoving ? 'Robot is moving...' : 'Ready',
              style: AppTextStyles.bodyMedium.copyWith(
                color: _isMoving ? AppColors.success : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _sendCommand(String commandType) {
    final command = ControlCommand(
      commandId: _commandId,
      commandType: commandType,
      parameters: {
        'speed': _speedValue,
        'robotId': 'robot_001',
      },
      timestamp: DateTime.now(),
    );

    ref.read(connectionStatusProvider.notifier).sendCommand(command);

    setState(() {
      _isMoving = commandType != 'stop';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Command sent: $commandType'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final bool isPrimary;

  const _ControlButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: FloatingActionButton(
        onPressed: onPressed,
        backgroundColor: isPrimary ? AppColors.error : AppColors.primary,
        child: Icon(icon),
      ),
    );
  }
}