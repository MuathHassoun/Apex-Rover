
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/robot_model.dart';
import '../providers/connection_provider.dart';

class CameraControlScreen extends ConsumerStatefulWidget {
  const CameraControlScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CameraControlScreen> createState() =>
      _CameraControlScreenState();
}

class _CameraControlScreenState extends ConsumerState<CameraControlScreen> {
  final TextEditingController _stepsController = TextEditingController(text: '200');
  String _lastCommand = 'CAM:STOP';

  int get _stepCount {
    final value = int.tryParse(_stepsController.text.trim()) ?? 200;
    return value.clamp(1, 5000);
  }

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
          height: 78,
          decoration: BoxDecoration(
            color: isConnected
                ? color.withOpacity(0.16)
                : Colors.grey.withOpacity(0.10),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isConnected ? color.withOpacity(0.9) : Colors.grey,
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
    _stepsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isConnected =
        ref.watch(connectionStatusProvider) == ConnectionStatus.connected;

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
                    color: Colors.cyanAccent.withOpacity(0.55),
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
                      'Control NEMA 17 stepper and camera servo through ESP32',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.62),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isConnected ? Icons.check_circle : Icons.error_outline,
                            color: isConnected ? Colors.greenAccent : Colors.redAccent,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              isConnected
                                  ? 'Connected | Last Command: $_lastCommand'
                                  : 'Not Connected',
                              style: TextStyle(
                                color: isConnected ? Colors.white : Colors.redAccent,
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
                  'Stepper Step Count',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _stepsController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Example: 200',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.45)),
                  prefixIcon: const Icon(Icons.pin, color: Colors.cyanAccent),
                  suffixText: 'steps',
                  suffixStyle: const TextStyle(color: Colors.cyanAccent),
                  filled: true,
                  fillColor: const Color(0xFF0B1726),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.cyanAccent.withOpacity(0.4)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.cyanAccent.withOpacity(0.35)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Colors.cyanAccent),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              Row(
                children: [
                  _cameraButton(
                    label: 'STEP LEFT\n$_stepCount',
                    icon: Icons.rotate_left,
                    command: 'CAM:STEP_LEFT:$_stepCount',
                    color: Colors.purpleAccent,
                  ),
                  const SizedBox(width: 12),
                  _cameraButton(
                    label: 'STEP RIGHT\n$_stepCount',
                    icon: Icons.rotate_right,
                    command: 'CAM:STEP_RIGHT:$_stepCount',
                    color: Colors.purpleAccent,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Tilt Control',
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
                    label: 'UP',
                    icon: Icons.keyboard_arrow_up,
                    command: 'CAM:UP',
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
                    label: 'DOWN',
                    icon: Icons.keyboard_arrow_down,
                    command: 'CAM:DOWN',
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
                'Step buttons move a fixed number of steps. LEFT/RIGHT rotate continuously until STOP.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.45),
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
