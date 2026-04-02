import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../providers/robot_provider.dart';
import '../providers/connection_provider.dart';
import '../models/robot_model.dart'; // needed for ConnectionStatus enum

import '../widgets/battery_card.dart';
import '../widgets/status_card.dart';
import '../widgets/alert_widget.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final robot = ref.watch(robotProvider);
    final isBatteryLow = ref.watch(isBatteryLowProvider);
    final isBatteryCritical = ref.watch(isBatteryCriticalProvider);
    final connectionStatus = ref.watch(connectionStatusProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Connection Status Alert
          if (connectionStatus != ConnectionStatus.connected)
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                border: Border.all(color: AppColors.warning),
                borderRadius: BorderRadius.circular(AppBorderRadius.lg),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: AppColors.warning),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Robot not connected',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.lg),

          // Battery Status Card
          if (robot != null) ...[
            BatteryCard(battery: robot.batteryStatus),
            const SizedBox(height: AppSpacing.lg),
          ],

          // Critical Alerts
          if (isBatteryCritical)
            AlertWidget(
              title: 'Critical Battery Level',
              message: 'Battery is critically low. Robot may shut down soon.',
              type: AlertType.critical,
            ),
          if (isBatteryLow && !isBatteryCritical)
            AlertWidget(
              title: 'Low Battery',
              message: 'Battery is running low. Consider charging.',
              type: AlertType.warning,
            ),

          if (isBatteryCritical || isBatteryLow) const SizedBox(height: AppSpacing.lg),

          // Robot State
          if (robot != null) ...[
            Text(
              'Robot State',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: AppSpacing.md),
            Grid(
              children: [
                StatusCard(
                  label: 'Power',
                  value: robot.robotState.isPoweredOn ? 'ON' : 'OFF',
                  status: robot.robotState.isPoweredOn,
                ),
                StatusCard(
                  label: 'Charging',
                  value: robot.robotState.isCharging ? 'Yes' : 'No',
                  status: robot.robotState.isCharging,
                ),
                StatusCard(
                  label: 'Mode',
                  value: robot.robotState.robotMode.toUpperCase(),
                  status: robot.robotState.robotMode != 'error',
                ),
                StatusCard(
                  label: 'Type',
                  // the robot type lives under its state
                  value: robot.robotState.robotType,
                  status: true,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Last Update
            Center(
              child: Text(
                'Last Update: ${_formatTime(robot.lastSync)}',
                style: AppTextStyles.caption.copyWith(
                  color: Colors.grey,
                ),
              ),
            ),
          ] else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_off,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'No Robot Connected',
                      style: AppTextStyles.heading3.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Connect to a robot from the Connection page',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
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
