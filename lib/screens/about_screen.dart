import 'package:flutter/material.dart';

import '../config/constants.dart';
import '../config/theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

  static const Color _bgColor = Color(0xFF020712);
  static const Color _panelColor = Color(0xFF07111F);
  static const Color _panelColor2 = Color(0xFF0D1B2E);
  static const Color _borderColor = Color(0xFF1E3858);
  static const Color _cyanColor = Color(0xFF00B4FF);
  static const Color _textColor = Colors.white;
  static const Color _mutedColor = Color(0xFF9AA8BA);

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
            _heroHeader(),
            const SizedBox(height: AppSpacing.lg),
            _aboutPanel(),
            const SizedBox(height: AppSpacing.lg),
            _teamPanel(),
            const SizedBox(height: AppSpacing.lg),
            _featuresPanel(),
            const SizedBox(height: AppSpacing.lg),
            _robotInfoPanel(),
            const SizedBox(height: AppSpacing.lg),
            _licensePanel(),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _heroHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF06111F), Color(0xFF12395A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: _cyanColor.withValues(alpha: 0.70),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _cyanColor.withValues(alpha: 0.20),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _cyanColor.withValues(alpha: 0.13),
              border: Border.all(
                color: _cyanColor.withValues(alpha: 0.75),
                width: 1.6,
              ),
              boxShadow: [
                BoxShadow(
                  color: _cyanColor.withValues(alpha: 0.20),
                  blurRadius: 24,
                ),
              ],
            ),
            child: const Icon(
              Icons.smart_toy,
              size: 62,
              color: _cyanColor,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            AppConstants.appName,
            style: AppTextStyles.heading2.copyWith(
              color: _textColor,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Version ${AppConstants.appVersion} (${AppConstants.appBuildNumber})',
            style: AppTextStyles.bodyMedium.copyWith(
              color: _mutedColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _chip('Manual Control'),
              _chip('ESP32 WebSocket'),
              _chip('Camera Stream'),
              _chip('Sensors'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.16),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _aboutPanel() {
    return _panel(
      title: 'About',
      subtitle: 'Project overview',
      icon: Icons.info_outline,
      child: Text(
        'Apex Rover Control is a mobile application designed to control and monitor the Apex Rover robot in real time. The app focuses on manual robot control through ESP32, camera viewing through Raspberry Pi, and live sensor-status monitoring.',
        style: AppTextStyles.bodyMedium.copyWith(
          color: _mutedColor,
          height: 1.55,
        ),
      ),
    );
  }

  Widget _teamPanel() {
    return _panel(
      title: 'Development Team',
      subtitle: 'Project contributors',
      icon: Icons.groups_rounded,
      child: Column(
        children: [
          _teamMember(
            name: 'Muath Hassoun',
            role: 'Robotics / Hardware / Control',
            icon: Icons.engineering,
            color: _cyanColor,
          ),
          const SizedBox(height: AppSpacing.sm),
          _teamMember(
            name: 'Abedulhafiz Elwan',
            role: 'Mobile App / Integration / System Design',
            icon: Icons.code,
            color: Colors.purpleAccent,
          ),
        ],
      ),
    );
  }

  Widget _teamMember({
    required String name,
    required String role,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: color.withValues(alpha: 0.22),
              ),
            ),
            child: Icon(icon, color: color, size: 25),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: _textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  role,
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
    );
  }

  Widget _featuresPanel() {
    return _panel(
      title: 'Key Features',
      subtitle: 'Main system capabilities',
      icon: Icons.star_outline_rounded,
      child: Column(
        children: const [
          _FeatureItem(
            icon: Icons.dashboard_rounded,
            title: 'Real-time Dashboard',
            description: 'Monitor robot status and connection state at a glance.',
            color: _cyanColor,
          ),
          SizedBox(height: AppSpacing.md),
          _FeatureItem(
            icon: Icons.gamepad_rounded,
            title: 'Manual Robot Control',
            description: 'Control movement, speed, camera stand, jacks, and arm screens.',
            color: Colors.greenAccent,
          ),
          SizedBox(height: AppSpacing.md),
          _FeatureItem(
            icon: Icons.wifi_rounded,
            title: 'ESP32 WebSocket Link',
            description: 'Fast command delivery from the mobile app to the robot.',
            color: Colors.orangeAccent,
          ),
          SizedBox(height: AppSpacing.md),
          _FeatureItem(
            icon: Icons.videocam_rounded,
            title: 'Camera Streaming',
            description: 'Display front and arm camera streams through Raspberry Pi.',
            color: Colors.cyanAccent,
          ),
          SizedBox(height: AppSpacing.md),
          _FeatureItem(
            icon: Icons.sensors_rounded,
            title: 'Sensor Alerts',
            description: 'Show pitch, roll, ultrasonic values, and balance warnings.',
            color: Colors.redAccent,
          ),
        ],
      ),
    );
  }

  Widget _robotInfoPanel() {
    return _panel(
      title: 'Robot Information',
      subtitle: 'Apex Rover system details',
      icon: Icons.memory_rounded,
      child: Column(
        children: [
          const _InfoRow(
            label: 'Robot Model',
            value: 'Apex Rover',
            icon: Icons.smart_toy,
          ),
          _divider,
          const _InfoRow(
            label: 'Control Mode',
            value: 'Manual',
            icon: Icons.touch_app,
          ),
          _divider,
          const _InfoRow(
            label: 'Bridge',
            value: 'ESP32',
            icon: Icons.router,
          ),
          _divider,
          const _InfoRow(
            label: 'Camera Server',
            value: 'Raspberry Pi',
            icon: Icons.videocam,
          ),
          _divider,
          _InfoRow(
            label: 'Last Updated',
            value: _todayDate(),
            icon: Icons.update,
          ),
        ],
      ),
    );
  }

  Widget _licensePanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.verified_rounded,
            color: _cyanColor.withValues(alpha: 0.85),
            size: 34,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'License & Legal',
            style: AppTextStyles.labelLarge.copyWith(
              color: _textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'MIT License © 2026 Apex Rover\nAll rights reserved',
            style: AppTextStyles.caption.copyWith(
              color: _mutedColor,
              height: 1.45,
            ),
            textAlign: TextAlign.center,
          ),
        ],
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

  Widget get _divider => Divider(
        height: 18,
        color: Colors.white.withValues(alpha: 0.08),
      );
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  static const Color _textColor = Colors.white;
  static const Color _mutedColor = Color(0xFF9AA8BA);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: _textColor,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  description,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: _mutedColor,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  static const Color _cyanColor = Color(0xFF00B4FF);
  static const Color _textColor = Colors.white;
  static const Color _mutedColor = Color(0xFF9AA8BA);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, color: _cyanColor, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: _mutedColor,
              ),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.labelLarge.copyWith(
              color: _textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
