import 'package:flutter/material.dart';
import 'arm_control_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../models/robot_model.dart';
import '../providers/connection_provider.dart';
import 'drive_mode_screen.dart';
import 'package:uuid/uuid.dart';

class ControlScreen extends ConsumerStatefulWidget {
  const ControlScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends ConsumerState<ControlScreen> {
  double _speedValue = 50.0;
  bool _isMoving = false;

  // NORMAL: regular driving with safety sensors
  // CLIMB: stairs mode, stairs should not be treated as normal obstacle
  String _currentMode = 'NORMAL';

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

          // Operation Mode
          Text('Operation Mode', style: AppTextStyles.heading3),
          const SizedBox(height: AppSpacing.md),

          Container(
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
                color: _currentMode == 'CLIMB'
                    ? Colors.orange.withValues(alpha: 0.8)
                    : AppColors.success.withValues(alpha: 0.8),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: (_currentMode == 'CLIMB'
                          ? Colors.orange
                          : AppColors.success)
                      .withValues(alpha: 0.15),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _ModeButton(
                        title: 'Normal',
                        subtitle: 'Obstacle safety',
                        icon: Icons.shield,
                        isSelected: _currentMode == 'NORMAL',
                        color: AppColors.success,
                        onPressed: () => _changeMode('NORMAL'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _ModeButton(
                        title: 'Climb',
                        subtitle: 'Stairs mode',
                        icon: Icons.stairs,
                        isSelected: _currentMode == 'CLIMB',
                        color: Colors.orange,
                        onPressed: () => _changeMode('CLIMB'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(AppBorderRadius.md),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        _currentMode == 'CLIMB'
                            ? Icons.warning_amber_rounded
                            : Icons.verified_user,
                        color: _currentMode == 'CLIMB'
                            ? Colors.orange
                            : AppColors.success,
                        size: 22,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          _currentMode == 'CLIMB'
                              ? 'Climb Mode: used for stairs. The robot should not stop just because the stairs are detected as a front obstacle.'
                              : 'Normal Mode: used for regular driving. Safety sensors can stop the robot when an obstacle is detected.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isConnected) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Connect to the robot to send mode commands.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Movement Controls
          Text('Movement Control', style: AppTextStyles.heading3),
          const SizedBox(height: AppSpacing.lg),

          // D-pad
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

  void _changeMode(String mode) {
    final isConnected =
        ref.read(connectionStatusProvider) == ConnectionStatus.connected;

    setState(() {
      _currentMode = mode;
    });

    if (isConnected) {
      _sendCommand('MODE:$mode');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$mode mode sent to robot'),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$mode mode selected locally. Connect to send it.'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _sendCommand(String commandType) {
    final command = ControlCommand(
      commandId: _commandId,
      commandType: commandType,
      parameters: {
        'speed': _speedValue,
        'robotId': 'robot_001',
        'mode': _currentMode,
      },
      timestamp: DateTime.now(),
    );

    ref.read(connectionStatusProvider.notifier).sendCommand(command);

    setState(() {
      _isMoving = commandType != 'stop' && !commandType.startsWith('MODE:');
    });

    if (!commandType.startsWith('MODE:')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Command sent: $commandType'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}

class _ModeButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final VoidCallback? onPressed;

  const _ModeButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(AppBorderRadius.md),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          border: Border.all(
            color: isSelected ? color : Colors.white.withValues(alpha: 0.25),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 30,
              color: isSelected ? Colors.white : color,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.9)
                    : Colors.white.withValues(alpha: 0.65),
                fontSize: 11,
              ),
            ),
          ],
        ),
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
