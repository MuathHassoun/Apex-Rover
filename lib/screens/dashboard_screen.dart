
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/theme.dart';
import '../providers/robot_provider.dart';
import '../providers/connection_provider.dart';
import '../providers/app_mode_provider.dart';
import '../models/robot_model.dart';
import '../widgets/status_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  void _changeAppMode(
    BuildContext context,
    WidgetRef ref,
    AppControlMode mode,
  ) {
    ref.read(appControlModeProvider.notifier).state = mode;

    final connectionStatus = ref.read(connectionStatusProvider);
    final isConnected = connectionStatus == ConnectionStatus.connected;

    final commandText = mode == AppControlMode.manual ? 'SYS:MODE:MANUAL' : 'SYS:MODE:AUTO';

    if (isConnected) {
      final command = ControlCommand(
        commandId: 'mode_${DateTime.now().millisecondsSinceEpoch}',
        commandType: commandText,
        parameters: const {
          'robotId': 'robot_001',
        },
        timestamp: DateTime.now(),
      );

      ref.read(connectionStatusProvider.notifier).sendCommand(command);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            mode == AppControlMode.manual ? 'Manual Mode activated' : 'Automatic Mode activated',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            mode == AppControlMode.manual
                ? 'Manual Mode selected locally. Connect to send it.'
                : 'Automatic Mode selected locally. Connect to send it.',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final robot = ref.watch(robotProvider);
    final connectionStatus = ref.watch(connectionStatusProvider);
    final appMode = ref.watch(appControlModeProvider);

    final isConnected = connectionStatus == ConnectionStatus.connected;
    final isManual = appMode == AppControlMode.manual;
    final isAutomatic = appMode == AppControlMode.automatic;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Connection Status Alert
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isConnected
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.warning.withValues(alpha: 0.1),
              border: Border.all(
                color: isConnected ? AppColors.success : AppColors.warning,
              ),
              borderRadius: BorderRadius.circular(AppBorderRadius.lg),
            ),
            child: Row(
              children: [
                Icon(
                  isConnected ? Icons.check_circle : Icons.warning,
                  color: isConnected ? AppColors.success : AppColors.warning,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    isConnected ? 'Robot connected successfully' : 'Robot not connected',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isConnected ? AppColors.success : AppColors.warning,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Control Mode
          Text(
            'Control Mode',
            style: AppTextStyles.heading3,
          ),
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
                color: isManual
                    ? AppColors.success.withValues(alpha: 0.8)
                    : Colors.orange.withValues(alpha: 0.8),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _ModeChoiceButton(
                        title: 'Manual',
                        subtitle: 'Mobile → ESP32',
                        icon: Icons.touch_app,
                        isSelected: isManual,
                        color: AppColors.success,
                        onTap: () => _changeAppMode(
                          context,
                          ref,
                          AppControlMode.manual,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _ModeChoiceButton(
                        title: 'Automatic',
                        subtitle: 'Raspberry Pi → ESP32',
                        icon: Icons.smart_toy,
                        isSelected: isAutomatic,
                        color: Colors.orange,
                        onTap: () => _changeAppMode(
                          context,
                          ref,
                          AppControlMode.automatic,
                        ),
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
                        isManual ? Icons.gamepad : Icons.auto_mode,
                        color: isManual ? AppColors.success : Colors.orange,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          isManual
                              ? 'Manual Mode: the mobile app controls the robot through ESP32. Control page is enabled.'
                              : 'Automatic Mode: Raspberry Pi controls the robot through ESP32. Manual Control page is blocked for safety.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // // Robot State
          // if (robot != null) ...[
          //   Text(
          //     'Robot State',
          //     style: AppTextStyles.heading3,
          //   ),
          //   const SizedBox(height: AppSpacing.md),
          //   Grid(
          //     children: [
          //       StatusCard(
          //         label: 'Power',
          //         value: robot.robotState.isPoweredOn ? 'ON' : 'OFF',
          //         status: robot.robotState.isPoweredOn,
          //       ),
          //       StatusCard(
          //         label: 'Charging',
          //         value: robot.robotState.isCharging ? 'Yes' : 'No',
          //         status: robot.robotState.isCharging,
          //       ),
          //       StatusCard(
          //         label: 'Mode',
          //         value: isManual ? 'MANUAL' : 'AUTO',
          //         status: true,
          //       ),
          //       StatusCard(
          //         label: 'Type',
          //         value: robot.robotState.robotType,
          //         status: true,
          //       ),
          //     ],
          //   ),
          //   const SizedBox(height: AppSpacing.lg),
          //   Center(
          //     child: Text(
          //       'Last Update: ${_formatTime(robot.lastSync)}',
          //       style: AppTextStyles.caption.copyWith(
          //         color: Colors.grey,
          //       ),
          //     ),
          //   ),
          // ] else
          //   Center(
          //     child: Padding(
          //       padding: const EdgeInsets.all(AppSpacing.xl),
          //       child: Column(
          //         mainAxisAlignment: MainAxisAlignment.center,
          //         children: [
          //           Icon(
          //             Icons.cloud_off,
          //             size: 64,
          //             color: Colors.grey[400],
          //           ),
          //           const SizedBox(height: AppSpacing.lg),
          //           Text(
          //             'No Robot Connected',
          //             style: AppTextStyles.heading3.copyWith(
          //               color: Colors.grey[600],
          //             ),
          //           ),
          //           const SizedBox(height: AppSpacing.sm),
          //           Text(
          //             'Connect to a robot from the Connection page',
          //             style: AppTextStyles.bodySmall.copyWith(
          //               color: Colors.grey[500],
          //             ),
          //             textAlign: TextAlign.center,
          //           ),
          //         ],
          //       ),
          //     ),
          //   ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}

class _ModeChoiceButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _ModeChoiceButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppBorderRadius.md),
      onTap: onTap,
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
              color: isSelected ? Colors.white : color,
              size: 30,
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

class Grid extends StatelessWidget {
  final List<Widget> children;

  const Grid({
    Key? key,
    required this.children,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      children: children,
    );
  }
}