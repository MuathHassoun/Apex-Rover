import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/theme.dart';
import '../models/robot_model.dart';
import '../providers/connection_provider.dart';
import '../providers/robot_provider.dart';

import 'control_screen.dart';
import 'remote_control_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  static const Color _bgColor = Color(0xFF020712);
  static const Color _panelColor = Color(0xFF07111F);
  static const Color _panelColor2 = Color(0xFF0D1B2E);
  static const Color _borderColor = Color(0xFF1E3858);
  static const Color _cyanColor = Color(0xFF00B4FF);
  static const Color _textColor = Colors.white;
  static const Color _mutedColor = Color(0xFF9AA8BA);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final robot = ref.watch(robotProvider);
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
            _connectionStatusCard(isConnected, isConnecting),
            const SizedBox(height: AppSpacing.lg),
            _heroDashboardCard(),
            const SizedBox(height: AppSpacing.lg),
            _quickActionCards(context),
            const SizedBox(height: AppSpacing.lg),
            _systemOverviewPanel(robot, isConnected),
            const SizedBox(height: AppSpacing.lg),
            _architecturePanel(),
            const SizedBox(height: 110),
          ],
        ),
      ),
    );
  }

  Widget _connectionStatusCard(bool isConnected, bool isConnecting) {
    final Color statusColor = isConnected
        ? Colors.greenAccent
        : isConnecting
            ? Colors.orangeAccent
            : Colors.redAccent;

    final IconData statusIcon = isConnected
        ? Icons.check_circle
        : isConnecting
            ? Icons.sync
            : Icons.warning_rounded;

    final String title = isConnected
        ? 'Robot connected successfully'
        : isConnecting
            ? 'Connecting to robot...'
            : 'Robot not connected';

    final String subtitle = isConnected
        ? 'ESP32 WebSocket link is active'
        : isConnecting
            ? 'Please wait while the app connects'
            : 'Open Connect page and connect to ESP32';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            statusColor.withValues(alpha: 0.18),
            _panelColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.70),
          width: 1.4,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: statusColor.withValues(alpha: 0.13),
              border: Border.all(
                color: statusColor.withValues(alpha: 0.45),
              ),
            ),
            child: Icon(
              statusIcon,
              color: statusColor,
              size: 28,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: _textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: _mutedColor,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: statusColor.withValues(alpha: 0.38),
              ),
            ),
            child: Text(
              isConnected
                  ? 'ONLINE'
                  : isConnecting
                      ? 'WAIT'
                      : 'OFF',
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroDashboardCard() {
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
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _cyanColor.withValues(alpha: 0.13),
              border: Border.all(
                color: _cyanColor.withValues(alpha: 0.75),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: _cyanColor.withValues(alpha: 0.18),
                  blurRadius: 20,
                ),
              ],
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              color: _cyanColor,
              size: 39,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Apex Rover Dashboard',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.heading3.copyWith(
                    color: _textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Monitor connection state, open manual controls, and access camera-based remote operation.',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.76),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 11),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    _chip('Manual'),
                    _chip('ESP32'),
                    _chip('Camera'),
                    _chip('Sensors'),
                  ],
                ),
              ],
            ),
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
          color: Colors.white.withValues(alpha: 0.15),
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

  Widget _quickActionCards(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool narrow = constraints.maxWidth < 390;

        if (narrow) {
          return Column(
            children: [
              _actionCard(
                title: 'Control',
                subtitle: 'Movement & tools',
                icon: Icons.gamepad_rounded,
                color: _cyanColor,
                onTap: () => _openControlScreen(context),
              ),
              const SizedBox(height: AppSpacing.md),
              _actionCard(
                title: 'Remote',
                subtitle: 'Camera view',
                icon: Icons.screen_rotation_rounded,
                color: Colors.greenAccent,
                onTap: () => _openRemoteScreen(context),
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: _actionCard(
                title: 'Control',
                subtitle: 'Movement & tools',
                icon: Icons.gamepad_rounded,
                color: _cyanColor,
                onTap: () => _openControlScreen(context),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _actionCard(
                title: 'Remote',
                subtitle: 'Camera view',
                icon: Icons.screen_rotation_rounded,
                color: Colors.greenAccent,
                onTap: () => _openRemoteScreen(context),
              ),
            ),
          ],
        );
      },
    );
  }

  void _openControlScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: _bgColor,
          appBar: AppBar(
            backgroundColor: _bgColor,
            foregroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            title: const Text('Control'),
          ),
          body: const ControlScreen(),
        ),
      ),
    );
  }

  void _openRemoteScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const RemoteControlScreen(),
      ),
    );
  }

  Widget _actionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
            color: color.withValues(alpha: 0.35),
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.10),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 43,
              height: 43,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: color.withValues(alpha: 0.25),
                ),
              ),
              child: Icon(
                icon,
                color: color,
                size: 25,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: _textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: _mutedColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _systemOverviewPanel(dynamic robot, bool isConnected) {
    return _panel(
      title: 'System Overview',
      subtitle: 'Current robot control architecture',
      icon: Icons.memory_rounded,
      child: Column(
        children: [
          _overviewTile(
            title: 'Control Mode',
            value: 'Manual',
            icon: Icons.touch_app_rounded,
            color: _cyanColor,
          ),
          const SizedBox(height: AppSpacing.sm),
          _overviewTile(
            title: 'Connection',
            value: isConnected ? 'Online' : 'Offline',
            icon: isConnected ? Icons.link_rounded : Icons.link_off_rounded,
            color: isConnected ? Colors.greenAccent : Colors.redAccent,
          ),
          const SizedBox(height: AppSpacing.sm),
          _overviewTile(
            title: 'Command Path',
            value: 'Mobile → ESP32',
            icon: Icons.route_rounded,
            color: Colors.orangeAccent,
          ),
          const SizedBox(height: AppSpacing.sm),
          _overviewTile(
            title: 'Sensors',
            value: 'Raspberry Bridge',
            icon: Icons.sensors_rounded,
            color: Colors.purpleAccent,
          ),
        ],
      ),
    );
  }

  Widget _overviewTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withValues(alpha: 0.24),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyMedium.copyWith(
                color: _mutedColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelLarge.copyWith(
                color: _textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _architecturePanel() {
    return _panel(
      title: 'Communication Flow',
      subtitle: 'How Apex Rover components communicate',
      icon: Icons.account_tree_rounded,
      child: Column(
        children: [
          _flowStep(
            number: '1',
            title: 'Mobile App',
            subtitle: 'Sends manual commands',
            color: _cyanColor,
          ),
          _flowConnector(),
          _flowStep(
            number: '2',
            title: 'ESP32',
            subtitle: 'WebSocket bridge',
            color: Colors.greenAccent,
          ),
          _flowConnector(),
          _flowStep(
            number: '3',
            title: 'Mega / UNO',
            subtitle: 'Motors and camera stand',
            color: Colors.orangeAccent,
          ),
          const SizedBox(height: AppSpacing.md),
          _infoNote(
            'Raspberry Pi is used for camera streaming and sensor relay only. It does not drive the robot autonomously.',
          ),
        ],
      ),
    );
  }

  Widget _flowStep({
    required String number,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withValues(alpha: 0.24),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.18),
              border: Border.all(
                color: color.withValues(alpha: 0.40),
              ),
            ),
            child: Text(
              number,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: _textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
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

  Widget _flowConnector() {
    return Container(
      width: 2,
      height: 18,
      color: _borderColor.withValues(alpha: 0.9),
      margin: const EdgeInsets.symmetric(vertical: 4),
    );
  }

  Widget _infoNote(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: _cyanColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _cyanColor.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: _cyanColor,
            size: 22,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall.copyWith(
                color: _mutedColor,
                height: 1.35,
              ),
            ),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.heading3.copyWith(
                        color: _textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
}
