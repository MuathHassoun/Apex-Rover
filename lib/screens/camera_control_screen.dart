import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/robot_model.dart';
import '../providers/connection_provider.dart';
import '../providers/uno_motion_settings_provider.dart';

class CameraControlScreen extends ConsumerStatefulWidget {
  const CameraControlScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CameraControlScreen> createState() =>
      _CameraControlScreenState();
}

class _CameraControlScreenState extends ConsumerState<CameraControlScreen> {
  String _lastCommand = 'CAM:STOP';

  bool get _isConnected =>
      ref.read(connectionStatusProvider) == ConnectionStatus.connected;

  void _sendCameraCommand(String commandType) {
    final isConnected =
        ref.read(connectionStatusProvider) == ConnectionStatus.connected;

    if (!isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not connected to robot'),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    final now = DateTime.now();
    final command = ControlCommand(
      commandId: 'camera_${now.millisecondsSinceEpoch}',
      commandType: commandType,
      parameters: const {'robotId': 'robot_001'},
      timestamp: now,
    );

    ref.read(connectionStatusProvider.notifier).sendCommand(command);

    setState(() {
      _lastCommand = commandType;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Camera command sent: $commandType'),
        duration: const Duration(milliseconds: 700),
      ),
    );
  }

  Widget _cameraButton({
    required String label,
    required IconData icon,
    required String command,
    required Color color,
  }) {
    final isConnected =
        ref.watch(connectionStatusProvider) == ConnectionStatus.connected;

    return Expanded(
      child: GestureDetector(
        onTap: isConnected ? () => _sendCameraCommand(command) : null,
        child: Container(
          height: 82,
          decoration: BoxDecoration(
            color: isConnected
                ? color.withValues(alpha: 0.16)
                : Colors.grey.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isConnected ? color.withValues(alpha: 0.9) : Colors.grey,
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isConnected ? color : Colors.grey, size: 30),
              const SizedBox(height: 5),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isConnected ? color : Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    if (_isConnected) {
      final now = DateTime.now();
      final command = ControlCommand(
        commandId: 'camera_stop_${now.millisecondsSinceEpoch}',
        commandType: 'CAM:STOP',
        parameters: const {'robotId': 'robot_001'},
        timestamp: now,
      );
      ref.read(connectionStatusProvider.notifier).sendCommand(command);
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isConnected =
        ref.watch(connectionStatusProvider) == ConnectionStatus.connected;

    final settings = ref.watch(unoMotionSettingsProvider);
    final stepperSteps = settings.stepperSteps;
    final servoStep = settings.servoAngleStep;

    return Scaffold(
      backgroundColor: const Color(0xFF050B12),
      appBar: AppBar(
        title: const Text('Camera Control'),
        backgroundColor: const Color(0xFF07111F),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0D1421), Color(0xFF1A2540)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.cyanAccent.withValues(alpha: 0.55),
                    width: 1.4,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.videocam,
                      color: isConnected ? Colors.cyanAccent : Colors.grey,
                      size: 44,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Camera Stand Control',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Stepper: $stepperSteps steps · Servo: $servoStep°',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.62),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isConnected
                                ? Icons.check_circle
                                : Icons.error_outline,
                            color: isConnected
                                ? Colors.greenAccent
                                : Colors.redAccent,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              isConnected
                                  ? 'Connected | Last Command: $_lastCommand'
                                  : 'Not Connected',
                              style: TextStyle(
                                color: isConnected
                                    ? Colors.white
                                    : Colors.redAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Stepper Step Control',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  _cameraButton(
                    label: 'STEP LEFT\n$stepperSteps',
                    icon: Icons.rotate_left,
                    command: 'CAM:STEP_LEFT:$stepperSteps',
                    color: Colors.purpleAccent,
                  ),
                  const SizedBox(width: 12),
                  _cameraButton(
                    label: 'STEP RIGHT\n$stepperSteps',
                    icon: Icons.rotate_right,
                    command: 'CAM:STEP_RIGHT:$stepperSteps',
                    color: Colors.purpleAccent,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Tilt Servo Control',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  _cameraButton(
                    label: 'UP\n$servoStep°',
                    icon: Icons.keyboard_arrow_up,
                    command: 'CAM:UP:$servoStep',
                    color: Colors.greenAccent,
                  ),
                  const SizedBox(width: 12),
                  _cameraButton(
                    label: 'CENTER',
                    icon: Icons.center_focus_strong,
                    command: 'CAM:CENTER',
                    color: Colors.orangeAccent,
                  ),
                  const SizedBox(width: 12),
                  _cameraButton(
                    label: 'DOWN\n$servoStep°',
                    icon: Icons.keyboard_arrow_down,
                    command: 'CAM:DOWN:$servoStep',
                    color: Colors.greenAccent,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Continuous Rotation',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  _cameraButton(
                    label: 'LEFT',
                    icon: Icons.keyboard_arrow_left,
                    command: 'CAM:LEFT',
                    color: Colors.cyanAccent,
                  ),
                  const SizedBox(width: 12),
                  _cameraButton(
                    label: 'STOP',
                    icon: Icons.stop_circle,
                    command: 'CAM:STOP',
                    color: Colors.redAccent,
                  ),
                  const SizedBox(width: 12),
                  _cameraButton(
                    label: 'RIGHT',
                    icon: Icons.keyboard_arrow_right,
                    command: 'CAM:RIGHT',
                    color: Colors.cyanAccent,
                  ),
                ],
              ),

              const SizedBox(height: 18),
              Text(
                'Stepper and servo values come from Control Screen → UNO Motion Settings.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}