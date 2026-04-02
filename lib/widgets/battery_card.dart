import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/robot_model.dart';

class BatteryCard extends StatelessWidget {
  final BatteryStatus battery;

  const BatteryCard({
    Key? key,
    required this.battery,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isCritical = battery.percentage < 10;
    final isLow = battery.percentage < 30 && battery.percentage >= 10;

    Color statusColor = isCritical
        ? AppColors.batteryCritical
        : isLow
            ? AppColors.batteryWarning
            : AppColors.batteryFull;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Battery Status',
                  style: AppTextStyles.heading3,
                ),
                Icon(
                  _getBatteryIcon(battery.percentage),
                  color: statusColor,
                  size: 32,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Battery Percentage
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Charge Level',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.grey,
                  ),
                ),
                Text(
                  '${battery.percentage}%',
                  style: AppTextStyles.heading2.copyWith(
                    color: statusColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
              child: LinearProgressIndicator(
                value: battery.percentage / 100,
                minHeight: 12,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Battery Details Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              childAspectRatio: 1.5,
              children: [
                _BatteryMetric(
                  label: 'Voltage',
                  value: '${battery.voltage.toStringAsFixed(2)}V',
                ),
                _BatteryMetric(
                  label: 'Current',
                  value: '${battery.current.toStringAsFixed(2)}A',
                ),
                _BatteryMetric(
                  label: 'Power',
                  value: '${battery.power.toStringAsFixed(1)}W',
                ),
                _BatteryMetric(
                  label: 'Charging',
                  value: battery.isCharging ? 'Yes' : 'No',
                  valueColor: battery.isCharging
                      ? AppColors.success
                      : Colors.grey,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Status Badge
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                ),
                child: Text(
                  isCritical
                      ? 'CRITICAL'
                      : isLow
                          ? 'LOW'
                          : 'GOOD',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: statusColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getBatteryIcon(int percentage) {
    if (percentage >= 100) {
      return Icons.battery_full;
    } else if (percentage >= 75) {
      return Icons.battery_6_bar;
    } else if (percentage >= 50) {
      return Icons.battery_5_bar;
    } else if (percentage >= 25) {
      return Icons.battery_3_bar;
    } else if (percentage >= 10) {
      return Icons.battery_2_bar;
    } else {
      return Icons.battery_0_bar;
    }
  }
}

class _BatteryMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _BatteryMetric({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: AppTextStyles.labelLarge.copyWith(
              color: valueColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
