import 'package:flutter/material.dart';
import '../config/constants.dart';
import '../config/theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

  String _todayDate() {
    final now = DateTime.now();

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[now.month - 1]} ${now.day}, ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // App Logo & Name
          Center(
            child: Column(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppBorderRadius.xl),
                  ),
                  child: const Icon(
                    Icons.smart_toy,
                    size: 64,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  AppConstants.appName,
                  style: AppTextStyles.heading2,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Version ${AppConstants.appVersion} (${AppConstants.appBuildNumber})',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Description
          Text(
            'About',
            style: AppTextStyles.heading3,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Robot Master Control is a professional mobile application for controlling robots in real-time. It provides intuitive controls and flexible robot connectivity.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.grey[700],
              height: 1.6,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Team
          Text(
            'Development Team',
            style: AppTextStyles.heading3,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Our team is made up of experienced developers and engineers who are passionate about robotics and dedicated to delivering the best robot-control experience.\nAlways striving for improvement, the team includes:\n  • Muath Hassoun\n  • Abedulhafiz Elwan',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.grey[700],
              height: 1.6,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Features
          Text(
            'Key Features',
            style: AppTextStyles.heading3,
          ),
          const SizedBox(height: AppSpacing.md),
          const _FeatureItem(
            icon: Icons.dashboard,
            title: 'Real-time Dashboard',
            description: 'Monitor robot state at a glance',
          ),
          const SizedBox(height: AppSpacing.md),
          const _FeatureItem(
            icon: Icons.gamepad,
            title: 'Intuitive Control',
            description: 'Easy-to-use controls for robot movement and operations',
          ),
          const SizedBox(height: AppSpacing.md),
          const _FeatureItem(
            icon: Icons.wifi,
            title: 'Flexible Connectivity',
            description: 'Support for MQTT and WebSocket connections',
          ),
          const SizedBox(height: AppSpacing.xl),

          // Robot Info
          Text(
            'Robot Information',
            style: AppTextStyles.heading3,
          ),
          const SizedBox(height: AppSpacing.md),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  const _InfoRow(
                    label: 'Robot Model',
                    value: 'ApexRover Pro',
                  ),
                  _divider,
                  const _InfoRow(
                    label: 'Firmware Version',
                    value: '2.1.0',
                  ),
                  _divider,
                  const _InfoRow(
                    label: 'API Version',
                    value: '1.0',
                  ),
                  _divider,
                  _InfoRow(
                    label: 'Last Updated',
                    value: _todayDate(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // License
          Center(
            child: Column(
              children: [
                Text(
                  'License & Legal',
                  style: AppTextStyles.labelLarge,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'MIT License © 2026 ApexRover\nAll rights reserved',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget get _divider => const Divider(height: 16);
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.labelLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                description,
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
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
        Text(
          value,
          style: AppTextStyles.labelLarge.copyWith(
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}