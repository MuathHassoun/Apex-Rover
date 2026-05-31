import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/theme.dart';
import '../models/robot_model.dart';
import '../providers/connection_provider.dart';
import '../providers/sensor_status_provider.dart';

class SensorsScreen extends ConsumerWidget {
  const SensorsScreen({Key? key}) : super(key: key);

  static const Color _bgColor = Color(0xFF020712);
  static const Color _panelColor = Color(0xFF07111F);
  static const Color _panelColor2 = Color(0xFF0D1B2E);
  static const Color _borderColor = Color(0xFF1E3858);
  static const Color _cyanColor = Color(0xFF00B4FF);
  static const Color _textColor = Colors.white;
  static const Color _mutedColor = Color(0xFF9AA8BA);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sensors = ref.watch(sensorStatusProvider);
    final connectionStatus = ref.watch(connectionStatusProvider);

    final isConnected = connectionStatus == ConnectionStatus.connected;

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
            _heroStatusCard(sensors, isConnected),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: _sensorValueCard(
                    title: 'Pitch',
                    value: sensors.pitch == null ? '--' : '${sensors.pitch!.toStringAsFixed(1)}°',
                    subtitle: 'Forward / backward tilt',
                    icon: Icons.swap_vert_rounded,
                    color: _angleColor(sensors.pitch, warning: 15, danger: 30),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _sensorValueCard(
                    title: 'Roll',
                    value: sensors.roll == null ? '--' : '${sensors.roll!.toStringAsFixed(1)}°',
                    subtitle: 'Left / right tilt',
                    icon: Icons.screen_rotation_alt_rounded,
                    color: _angleColor(sensors.roll, warning: 12, danger: 25),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: _sensorValueCard(
                    title: 'Front US',
                    value: sensors.frontDistance == null
                        ? '--'
                        : '${sensors.frontDistance!.toStringAsFixed(1)} cm',
                    subtitle: 'Front ultrasonic',
                    icon: Icons.vertical_align_top_rounded,
                    color: _distanceColor(sensors.frontDistance),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _sensorValueCard(
                    title: 'Rear US',
                    value: sensors.rearDistance == null
                        ? '--'
                        : '${sensors.rearDistance!.toStringAsFixed(1)} cm',
                    subtitle: 'Rear ultrasonic',
                    icon: Icons.vertical_align_bottom_rounded,
                    color: _distanceColor(sensors.rearDistance),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _balanceDetailsPanel(sensors),
            const SizedBox(height: AppSpacing.lg),
            _dataFlowPanel(),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _heroStatusCard(SensorStatus sensors, bool isConnected) {
    final status = sensors.balanceStatus.toUpperCase();

    Color color;
    IconData icon;
    String title;
    String subtitle;

    if (!isConnected) {
      color = Colors.redAccent;
      icon = Icons.wifi_off_rounded;
      title = 'Not Connected';
      subtitle = 'Connect to ESP32 WebSocket to receive live sensor data.';
    } else if (sensors.isDanger) {
      color = Colors.redAccent;
      icon = Icons.dangerous_rounded;
      title = 'Danger Detected';
      subtitle = 'Robot may fall or has reached a critical balance state.';
    } else if (sensors.isWarning) {
      color = Colors.orangeAccent;
      icon = Icons.warning_rounded;
      title = 'Warning';
      subtitle = 'Robot is unstable or an obstacle is close.';
    } else if (sensors.isStable) {
      color = Colors.greenAccent;
      icon = Icons.check_circle_rounded;
      title = 'Stable';
      subtitle = 'Robot balance and sensor readings are within safe limits.';
    } else {
      color = _cyanColor;
      icon = Icons.sensors_rounded;
      title = 'Waiting for Data';
      subtitle = 'Sensor values will appear when Raspberry forwards data from Mega.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.18),
            _panelColor,
            _panelColor2,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: color.withValues(alpha: 0.65),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.13),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.13),
              border: Border.all(
                color: color.withValues(alpha: 0.55),
              ),
            ),
            child: Icon(icon, color: color, size: 38),
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
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    _chip(status),
                    _chip(isConnected ? 'ONLINE' : 'OFFLINE'),
                    _chip(_lastUpdateText(sensors.lastUpdate)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sensorValueCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_panelColor, _panelColor2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: color.withValues(alpha: 0.38),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.09),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: color.withValues(alpha: 0.25),
                  ),
                ),
                child: Icon(icon, color: color, size: 25),
              ),
              const Spacer(),
              Icon(Icons.circle, color: color, size: 12),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _textColor,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTextStyles.bodyMedium.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: AppTextStyles.bodySmall.copyWith(
              color: _mutedColor,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }

  Widget _balanceDetailsPanel(SensorStatus sensors) {
    return _panel(
      title: 'Balance Analysis',
      subtitle: 'MPU6500 safety interpretation',
      icon: Icons.analytics_rounded,
      child: Column(
        children: [
          _analysisRow(
            label: 'Balance Status',
            value: sensors.balanceStatus.toUpperCase(),
            color: _balanceColor(sensors),
          ),
          _divider,
          _analysisRow(
            label: 'Pitch Warning',
            value: '±15°',
            color: Colors.orangeAccent,
          ),
          _divider,
          _analysisRow(
            label: 'Pitch Danger',
            value: '±30°',
            color: Colors.redAccent,
          ),
          _divider,
          _analysisRow(
            label: 'Roll Warning',
            value: '±12°',
            color: Colors.orangeAccent,
          ),
          _divider,
          _analysisRow(
            label: 'Roll Danger',
            value: '±25°',
            color: Colors.redAccent,
          ),
        ],
      ),
    );
  }

  Widget _dataFlowPanel() {
    return _panel(
      title: 'Sensor Data Flow',
      subtitle: 'How sensor values reach the mobile app',
      icon: Icons.account_tree_rounded,
      child: Column(
        children: [
          _flowStep(
            number: '1',
            title: 'Arduino Mega',
            subtitle: 'Reads MPU6500 and ultrasonic sensors',
            color: Colors.orangeAccent,
          ),
          _flowConnector(),
          _flowStep(
            number: '2',
            title: 'Raspberry Pi',
            subtitle: 'Receives SENSOR lines and forwards them',
            color: Colors.purpleAccent,
          ),
          _flowConnector(),
          _flowStep(
            number: '3',
            title: 'ESP32',
            subtitle: 'Broadcasts SENSOR message over WebSocket',
            color: Colors.greenAccent,
          ),
          _flowConnector(),
          _flowStep(
            number: '4',
            title: 'Mobile App',
            subtitle: 'Displays live values and warning alerts',
            color: _cyanColor,
          ),
        ],
      ),
    );
  }

  Widget _analysisRow({
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
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
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _flowStep({
    required String number,
    required String title,
    required String subtitle,
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

  Widget _flowConnector() {
    return Container(
      width: 2,
      height: 18,
      color: _borderColor.withValues(alpha: 0.9),
      margin: const EdgeInsets.symmetric(vertical: 4),
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

  Widget _chip(String text) {
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

  Widget get _divider => Divider(
        height: 18,
        color: Colors.white.withValues(alpha: 0.08),
      );

  Color _angleColor(double? value, {required double warning, required double danger}) {
    if (value == null) return _cyanColor;

    final absValue = value.abs();

    if (absValue >= danger) return Colors.redAccent;
    if (absValue >= warning) return Colors.orangeAccent;

    return Colors.greenAccent;
  }

  Color _distanceColor(double? value) {
    if (value == null || value < 0) return _cyanColor;

    if (value < 5) return Colors.redAccent;
    if (value < 12) return Colors.orangeAccent;

    return Colors.greenAccent;
  }

  Color _balanceColor(SensorStatus sensors) {
    if (sensors.isDanger) return Colors.redAccent;
    if (sensors.isWarning) return Colors.orangeAccent;
    if (sensors.isStable) return Colors.greenAccent;
    return _cyanColor;
  }

  String _lastUpdateText(DateTime? lastUpdate) {
    if (lastUpdate == null) return 'NO DATA';

    final diff = DateTime.now().difference(lastUpdate);

    if (diff.inSeconds < 5) return 'LIVE';
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';

    return '${diff.inHours}h ago';
  }
}
