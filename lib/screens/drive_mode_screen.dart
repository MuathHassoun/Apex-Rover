import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/robot_model.dart';
import '../providers/connection_provider.dart';

class DriveModeScreen extends ConsumerStatefulWidget {
  const DriveModeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DriveModeScreen> createState() => _DriveModeScreenState();
}

class _DriveModeScreenState extends ConsumerState<DriveModeScreen> {
  double _speed = 50;
  double _steer = 0;
  String _lastCommand = 'STOP';
  DateTime _lastSendTime = DateTime.fromMillisecondsSinceEpoch(0);

  bool get _isConnected =>
      ref.read(connectionStatusProvider) == ConnectionStatus.connected;

  void _sendCommand(String commandType, {bool force = false}) {
    final now = DateTime.now();

    if (!force &&
        commandType == _lastCommand &&
        now.difference(_lastSendTime).inMilliseconds < 250) {
      return;
    }

    _lastCommand = commandType;
    _lastSendTime = now;

    final command = ControlCommand(
      commandId: 'drive_${now.millisecondsSinceEpoch}',
      commandType: commandType,
      parameters: {
        'speed': _speed,
        'robotId': 'robot_001',
      },
      timestamp: now,
    );

    ref.read(connectionStatusProvider.notifier).sendCommand(command);
  }

  void _sendStop() {
    _sendCommand('stop', force: true);
  }

  void _onSteerChanged(double value) {
    setState(() => _steer = value);

    if (!_isConnected) return;

    if (value > 0.35) {
      _sendCommand('turn_right');
    } else if (value < -0.35) {
      _sendCommand('turn_left');
    }
  }

  void _onSteerEnd() {
    setState(() => _steer = 0);
    _sendStop();
  }

  @override
  Widget build(BuildContext context) {
    final connectionStatus = ref.watch(connectionStatusProvider);
    final isConnected = connectionStatus == ConnectionStatus.connected;

    return Scaffold(
      backgroundColor: const Color(0xFF050B12),
      appBar: AppBar(
        title: const Text('Drive Mode'),
        backgroundColor: const Color(0xFF07111F),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _StatusPanel(
                isConnected: isConnected,
                lastCommand: _lastCommand,
                speed: _speed,
              ),
              const SizedBox(height: 20),

              Expanded(
                child: Center(
                  child: _SteeringWheel(
                    value: _steer,
                    enabled: isConnected,
                    onChanged: _onSteerChanged,
                    onEnd: _onSteerEnd,
                  ),
                ),
              ),

              _SpeedSlider(
                speed: _speed,
                enabled: isConnected,
                onChanged: (value) {
                  setState(() => _speed = value);

                  final command = ControlCommand(
                    commandId: 'speed_${DateTime.now().millisecondsSinceEpoch}',
                    commandType: 'stop',
                    parameters: {
                      'speed': _speed,
                      'robotId': 'robot_001',
                    },
                    timestamp: DateTime.now(),
                  );

                  ref.read(connectionStatusProvider.notifier).sendCommand(command);
                },
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _PedalButton(
                      label: 'REVERSE',
                      icon: Icons.keyboard_arrow_down,
                      color: Colors.orange,
                      enabled: isConnected,
                      onDown: () => _sendCommand('move_backward', force: true),
                      onUp: _sendStop,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _BrakeButton(
                      enabled: isConnected,
                      onTap: _sendStop,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PedalButton(
                      label: 'GAS',
                      icon: Icons.keyboard_arrow_up,
                      color: Colors.green,
                      enabled: isConnected,
                      onDown: () => _sendCommand('move_forward', force: true),
                      onUp: _sendStop,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPanel extends StatelessWidget {
  final bool isConnected;
  final String lastCommand;
  final double speed;

  const _StatusPanel({
    required this.isConnected,
    required this.lastCommand,
    required this.speed,
  });

  @override
  Widget build(BuildContext context) {
    final color = isConnected ? Colors.greenAccent : Colors.redAccent;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1726),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(
            isConnected ? Icons.wifi : Icons.wifi_off,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isConnected ? 'Connected to Robot' : 'Not Connected',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            '$lastCommand | ${speed.round()}%',
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpeedSlider extends StatelessWidget {
  final double speed;
  final bool enabled;
  final ValueChanged<double> onChanged;

  const _SpeedSlider({
    required this.speed,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1726),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.speed, color: Colors.cyanAccent),
              const SizedBox(width: 8),
              Text(
                'Speed: ${speed.round()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Slider(
            value: speed,
            min: 0,
            max: 100,
            divisions: 10,
            label: '${speed.round()}%',
            onChanged: enabled ? onChanged : null,
          ),
        ],
      ),
    );
  }
}

class _SteeringWheel extends StatelessWidget {
  final double value;
  final bool enabled;
  final ValueChanged<double> onChanged;
  final VoidCallback onEnd;

  const _SteeringWheel({
    required this.value,
    required this.enabled,
    required this.onChanged,
    required this.onEnd,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: enabled
          ? (details) {
              final box = context.findRenderObject() as RenderBox;
              final local = box.globalToLocal(details.globalPosition);
              final centerX = box.size.width / 2;
              final dx = local.dx - centerX;
              final normalized = (dx / 90).clamp(-1.0, 1.0);
              onChanged(normalized);
            }
          : null,
      onPanEnd: enabled ? (_) => onEnd() : null,
      onPanCancel: enabled ? onEnd : null,
      child: CustomPaint(
        size: const Size(220, 220),
        painter: _SteeringPainter(value: value, enabled: enabled),
      ),
    );
  }
}

class _SteeringPainter extends CustomPainter {
  final double value;
  final bool enabled;

  _SteeringPainter({
    required this.value,
    required this.enabled,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    canvas.drawCircle(center + const Offset(4, 6), radius - 8, shadowPaint);

    final wheelPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          enabled ? const Color(0xFF4A5B70) : const Color(0xFF333333),
          const Color(0xFF101820),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius - 10, wheelPaint);

    final innerPaint = Paint()
      ..color = const Color(0xFF050B12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18;

    canvas.drawCircle(center, radius - 36, innerPaint);

    final angle = value * 0.8;

    final spokePaint = Paint()
      ..color = enabled ? Colors.cyanAccent.withOpacity(0.8) : Colors.grey
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 3; i++) {
      final a = angle + i * 2 * math.pi / 3;
      final start = center + Offset(math.cos(a), math.sin(a)) * 22;
      final end = center + Offset(math.cos(a), math.sin(a)) * (radius - 28);
      canvas.drawLine(start, end, spokePaint);
    }

    final centerPaint = Paint()
      ..color = enabled ? Colors.cyanAccent : Colors.grey;

    canvas.drawCircle(center, 20, centerPaint);

    final indicatorPaint = Paint()
      ..color = value.abs() > 0.35 ? Colors.greenAccent : Colors.white54
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 5),
      -math.pi / 2,
      value * math.pi,
      false,
      indicatorPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _SteeringPainter oldDelegate) {
    return oldDelegate.value != value || oldDelegate.enabled != enabled;
  }
}

class _PedalButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool enabled;
  final VoidCallback onDown;
  final VoidCallback onUp;

  const _PedalButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.enabled,
    required this.onDown,
    required this.onUp,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: enabled ? (_) => onDown() : null,
      onTapUp: enabled ? (_) => onUp() : null,
      onTapCancel: enabled ? onUp : null,
      child: Container(
        height: 90,
        decoration: BoxDecoration(
          color: enabled ? color.withOpacity(0.18) : Colors.grey.withOpacity(0.12),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: enabled ? color : Colors.grey,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: enabled ? color : Colors.grey, size: 34),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: enabled ? color : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrakeButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;

  const _BrakeButton({
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        height: 90,
        decoration: BoxDecoration(
          color: enabled
              ? Colors.redAccent.withOpacity(0.2)
              : Colors.grey.withOpacity(0.12),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: enabled ? Colors.redAccent : Colors.grey,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.stop_circle,
              color: enabled ? Colors.redAccent : Colors.grey,
              size: 34,
            ),
            const SizedBox(height: 4),
            Text(
              'BRAKE',
              style: TextStyle(
                color: enabled ? Colors.redAccent : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}