import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../config/theme.dart';
import '../models/robot_model.dart';
import '../providers/connection_provider.dart';

import 'auto_status_screen.dart';
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
  double _speedValue = 60.0;
  double _stepperStepsValue = 100.0;
  double _servoAngleStepValue = 5.0;

  bool _isMoving = false;
  String _lastCommand = 'READY';

  final String _commandId = const Uuid().v4();

  static const Color _bgColor = Color(0xFF020712);
  static const Color _panelColor = Color(0xFF07111F);
  static const Color _panelColor2 = Color(0xFF0D1B2E);
  static const Color _borderColor = Color(0xFF1E3858);
  static const Color _cyanColor = Color(0xFF00B4FF);
  static const Color _textColor = Colors.white;
  static const Color _mutedColor = Color(0xFF9AA8BA);

  @override
  Widget build(BuildContext context) {
    final isConnected =
        ref.watch(connectionStatusProvider) == ConnectionStatus.connected;

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
            _connectionHeader(isConnected),
            const SizedBox(height: AppSpacing.lg),
            _heroRemoteCard(),
            const SizedBox(height: AppSpacing.lg),
            _quickActions(),
            const SizedBox(height: AppSpacing.lg),
            _autoStatusCard(),
            const SizedBox(height: AppSpacing.lg),
            _movementPanel(isConnected),
            const SizedBox(height: AppSpacing.lg),
            _speedPanel(isConnected),
            const SizedBox(height: AppSpacing.lg),
            _unoSettingsPanel(isConnected),
            const SizedBox(height: AppSpacing.lg),
            _statusFooter(),
          ],
        ),
      ),
    );
  }

  Widget _connectionHeader(bool isConnected) {
    final color = isConnected ? Colors.greenAccent : Colors.redAccent;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.18),
            _panelColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: color.withValues(alpha: 0.75),
          width: 1.4,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.12),
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
              color: color.withValues(alpha: 0.14),
              border: Border.all(
                color: color.withValues(alpha: 0.55),
              ),
            ),
            child: Icon(
              isConnected ? Icons.check_circle : Icons.error,
              color: color,
              size: 29,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isConnected ? 'Connected & Ready' : 'Robot Not Connected',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: _textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isConnected
                      ? 'Manual control is active through ESP32'
                      : 'Go to Connect page and connect using WebSocket',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: _mutedColor,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: color.withValues(alpha: 0.4),
              ),
            ),
            child: Text(
              isConnected ? 'ONLINE' : 'OFFLINE',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroRemoteCard() {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => const RemoteControlScreen(),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF06111F), Color(0xFF12395A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _cyanColor.withValues(alpha: 0.7),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _cyanColor.withValues(alpha: 0.20),
              blurRadius: 22,
              offset: const Offset(0, 9),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 66,
              height: 66,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _cyanColor.withValues(alpha: 0.14),
                border: Border.all(
                  color: _cyanColor.withValues(alpha: 0.75),
                  width: 1.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _cyanColor.withValues(alpha: 0.18),
                    blurRadius: 18,
                  ),
                ],
              ),
              child: const Icon(
                Icons.screen_rotation,
                color: _cyanColor,
                size: 35,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Remote Control',
                    style: AppTextStyles.heading3.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Landscape view · Camera feed · Sensors · Robot controls',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.75),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 11),
                  Row(
                    children: [
                      _smallChip('Camera'),
                      const SizedBox(width: 6),
                      _smallChip('Sensors'),
                      const SizedBox(width: 6),
                      _smallChip('Manual'),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withValues(alpha: 0.70),
              size: 18,
            ),
          ],
        ),
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

  Widget _quickActions() {
    return Row(
      children: [
        Expanded(
          child: _navigationCard(
            title: 'Drive Mode',
            subtitle: 'Wheel control',
            icon: Icons.sports_esports,
            color: _cyanColor,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (_) => const DriveModeScreen(),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _navigationCard(
            title: 'Camera',
            subtitle: 'Stand control',
            icon: Icons.videocam,
            color: Colors.cyanAccent,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (_) => const CameraControlScreen(),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _navigationCard(
            title: 'Arm',
            subtitle: 'Arm control',
            icon: Icons.pan_tool,
            color: Colors.purpleAccent,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (_) => const ArmControlScreen(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _navigationCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(
          minHeight: 118,
        ),
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_panelColor, _panelColor2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: color.withValues(alpha: 0.38),
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.10),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 43,
              height: 43,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: color.withValues(alpha: 0.30),
                ),
              ),
              child: Icon(icon, color: color, size: 25),
            ),
            const SizedBox(height: 9),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: _textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _mutedColor,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _autoStatusCard() {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => const AutoStatusScreen(),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF07111F), Color(0xFF12395A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.orangeAccent.withValues(alpha: 0.45),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.orangeAccent.withValues(alpha: 0.10),
              blurRadius: 16,
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
                color: Colors.orangeAccent.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: Colors.orangeAccent.withValues(alpha: 0.30),
                ),
              ),
              child: const Icon(
                Icons.timeline,
                color: Colors.orangeAccent,
                size: 27,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Auto Status Track',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: _textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'View auto stage, decisions, errors, and robot cameras',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: _mutedColor,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withValues(alpha: 0.55),
              size: 17,
            ),
          ],
        ),
      ),
    );
  }

  Widget _movementPanel(bool isConnected) {
    return _panel(
      title: 'Movement Control',
      subtitle: 'Quick manual movement commands',
      icon: Icons.open_with,
      child: Column(
        children: [
          _directionButton(
            label: 'Forward',
            icon: Icons.keyboard_arrow_up,
            command: 'move_forward',
            enabled: isConnected,
            color: Colors.greenAccent,
            wide: true,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _directionButton(
                  label: 'Left',
                  icon: Icons.keyboard_arrow_left,
                  command: 'turn_left',
                  enabled: isConnected,
                  color: _cyanColor,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _directionButton(
                  label: 'Stop',
                  icon: Icons.stop_circle,
                  command: 'stop',
                  enabled: isConnected,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _directionButton(
                  label: 'Right',
                  icon: Icons.keyboard_arrow_right,
                  command: 'turn_right',
                  enabled: isConnected,
                  color: _cyanColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _directionButton(
            label: 'Backward',
            icon: Icons.keyboard_arrow_down,
            command: 'move_backward',
            enabled: isConnected,
            color: Colors.greenAccent,
            wide: true,
          ),
        ],
      ),
    );
  }

  Widget _directionButton({
    required String label,
    required IconData icon,
    required String command,
    required bool enabled,
    required Color color,
    bool wide = false,
  }) {
    return GestureDetector(
      onTap: enabled ? () => _sendCommand(command) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        height: 58,
        width: wide ? double.infinity : null,
        decoration: BoxDecoration(
          color: enabled
              ? color.withValues(alpha: 0.13)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: enabled
                ? color.withValues(alpha: 0.70)
                : Colors.white.withValues(alpha: 0.10),
            width: 1.3,
          ),
          boxShadow: [
            if (enabled)
              BoxShadow(
                color: color.withValues(alpha: 0.08),
                blurRadius: 12,
              ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: enabled ? color : Colors.white24,
              size: 29,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: enabled ? color : Colors.white24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _speedPanel(bool isConnected) {
    return _panel(
      title: 'Speed Control',
      subtitle: 'Current speed: ${_speedValue.toStringAsFixed(0)}%',
      icon: Icons.speed,
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.speed, size: 22, color: _cyanColor),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: _cyanColor,
                    inactiveTrackColor: Colors.white.withValues(alpha: 0.12),
                    thumbColor: _cyanColor,
                    overlayColor: _cyanColor.withValues(alpha: 0.18),
                    valueIndicatorColor: _cyanColor,
                  ),
                  child: Slider(
                    value: _speedValue,
                    min: 0,
                    max: 100,
                    divisions: 20,
                    label: '${_speedValue.toStringAsFixed(0)}%',
                    onChanged: isConnected
                        ? (value) => setState(() => _speedValue = value)
                        : null,
                  ),
                ),
              ),
              _valueBox('${_speedValue.toStringAsFixed(0)}%', _cyanColor),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _speedPreset(30, isConnected),
              const SizedBox(width: AppSpacing.sm),
              _speedPreset(60, isConnected),
              const SizedBox(width: AppSpacing.sm),
              _speedPreset(90, isConnected),
            ],
          ),
        ],
      ),
    );
  }

  Widget _speedPreset(double value, bool isConnected) {
    final selected = _speedValue.round() == value.round();

    return Expanded(
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: selected ? Colors.black : _cyanColor,
          backgroundColor:
              selected ? _cyanColor : _cyanColor.withValues(alpha: 0.07),
          side: BorderSide(
            color: _cyanColor.withValues(alpha: selected ? 0.95 : 0.35),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: isConnected
            ? () {
                setState(() => _speedValue = value);
                _sendCommand('speed_only');
              }
            : null,
        child: Text('${value.toStringAsFixed(0)}%'),
      ),
    );
  }

  Widget _unoSettingsPanel(bool isConnected) {
    return _panel(
      title: 'UNO Motion Settings',
      subtitle:
          'Stepper steps: ${_stepperStepsValue.toStringAsFixed(0)} · Servo angle: ${_servoAngleStepValue.toStringAsFixed(0)}°',
      icon: Icons.tune,
      child: Column(
        children: [
          _settingsSlider(
            title: 'Stepper Steps',
            subtitle: 'Applied to camera stepper and arm base stepper',
            icon: Icons.settings_input_component,
            color: Colors.orangeAccent,
            value: _stepperStepsValue,
            min: 10,
            max: 1000,
            divisions: 99,
            label: '${_stepperStepsValue.toStringAsFixed(0)} steps',
            valueText: _stepperStepsValue.toStringAsFixed(0),
            enabled: true,
            onChanged: (value) {
              setState(() {
                _stepperStepsValue = (value / 10).round() * 10;
              });
            },
          ),
          const SizedBox(height: AppSpacing.md),
          _settingsSlider(
            title: 'Servo Angle Step',
            subtitle: 'Applied to shoulder, elbow, wrist, gripper and AUX',
            icon: Icons.rotate_90_degrees_ccw,
            color: Colors.purpleAccent,
            value: _servoAngleStepValue,
            min: 1,
            max: 20,
            divisions: 19,
            label: '${_servoAngleStepValue.toStringAsFixed(0)}°',
            valueText: '${_servoAngleStepValue.toStringAsFixed(0)}°',
            enabled: true,
            onChanged: (value) {
              setState(() {
                _servoAngleStepValue = value.roundToDouble();
              });
            },
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: isConnected
                    ? _cyanColor
                    : Colors.white.withValues(alpha: 0.08),
                foregroundColor: isConnected ? Colors.black : Colors.white30,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onPressed: isConnected ? _sendUnoSettings : null,
              icon: const Icon(Icons.send_rounded),
              label: const Text(
                'Apply UNO Settings',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'UNO must support ARM:CONFIG commands to apply these values.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: _mutedColor,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingsSlider({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String label,
    required String valueText,
    required bool enabled,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.24),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: color.withValues(alpha: 0.28),
                  ),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: AppSpacing.sm),
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
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              _valueBox(valueText, color),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: color,
              inactiveTrackColor: Colors.white.withValues(alpha: 0.12),
              thumbColor: color,
              overlayColor: color.withValues(alpha: 0.18),
              valueIndicatorColor: color,
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              label: label,
              onChanged: enabled ? onChanged : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _valueBox(String value, Color color) {
    return Container(
      width: 66,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.30),
        ),
      ),
      child: Text(
        value,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
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

  Widget _statusFooter() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: _isMoving
              ? Colors.greenAccent.withValues(alpha: 0.10)
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: _isMoving
                ? Colors.greenAccent.withValues(alpha: 0.35)
                : Colors.white.withValues(alpha: 0.10),
          ),
        ),
        child: Text(
          _isMoving
              ? 'Robot is moving · $_lastCommand'
              : 'Ready · $_lastCommand',
          style: AppTextStyles.bodyMedium.copyWith(
            color: _isMoving ? Colors.greenAccent : _mutedColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _sendCommand(String commandType) {
    final actualCommand = commandType == 'speed_only' ? 'stop' : commandType;

    final command = ControlCommand(
      commandId: _commandId,
      commandType: actualCommand,
      parameters: {
        'speed': _speedValue,
        'robotId': 'robot_001',
      },
      timestamp: DateTime.now(),
    );

    ref.read(connectionStatusProvider.notifier).sendCommand(command);

    setState(() {
      _lastCommand = commandType;
      _isMoving = actualCommand != 'stop';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _panelColor2,
        content: Text(
          'Command sent: $commandType',
          style: const TextStyle(color: Colors.white),
        ),
        duration: const Duration(milliseconds: 800),
      ),
    );
  }

  void _sendRawCommand(String commandType) {
    final command = ControlCommand(
      commandId: '${_commandId}_${DateTime.now().millisecondsSinceEpoch}',
      commandType: commandType,
      parameters: {
        'robotId': 'robot_001',
      },
      timestamp: DateTime.now(),
    );

    ref.read(connectionStatusProvider.notifier).sendCommand(command);

    setState(() {
      _lastCommand = commandType;
      _isMoving = false;
    });
  }

  void _sendUnoSettings() {
    final stepperSteps = _stepperStepsValue.round();
    final servoStep = _servoAngleStepValue.round();

    _sendRawCommand('ARM:CONFIG:STEPPER_STEPS:$stepperSteps');
    _sendRawCommand('ARM:CONFIG:SERVO_STEP:$servoStep');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _panelColor2,
        content: Text(
          'UNO settings sent: $stepperSteps steps, $servoStep° servo step',
          style: const TextStyle(color: Colors.white),
        ),
        duration: const Duration(milliseconds: 1000),
      ),
    );
  }
}