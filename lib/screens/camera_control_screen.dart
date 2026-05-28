import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CameraControlScreen extends StatefulWidget {
  const CameraControlScreen({Key? key}) : super(key: key);

  @override
  State<CameraControlScreen> createState() => _CameraControlScreenState();
}

class _CameraControlScreenState extends State<CameraControlScreen> {
  // غيّر هذا IP حسب IP الرازبيري عندكم
  final String raspberryBaseUrl = 'http://192.168.4.2:5000';

  String _lastCommand = 'CAM:STOP';
  bool _isSending = false;

  String get videoUrl => '$raspberryBaseUrl/video_feed';

  Future<void> _sendCameraCommand(String command) async {
    setState(() {
      _isSending = true;
      _lastCommand = command;
    });

    try {
      final response = await http.post(
        Uri.parse('$raspberryBaseUrl/camera_command'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'command': command}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Camera command sent: $command'),
            duration: const Duration(milliseconds: 800),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send command: $command'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Raspberry Pi not reachable: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Widget _cameraButton({
    required String label,
    required IconData icon,
    required String command,
    Color color = Colors.blueAccent,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: _isSending ? null : () => _sendCameraCommand(command),
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            color: color.withOpacity(0.16),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color, width: 1.4),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
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
    _sendCameraCommand('CAM:STOP');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                height: 260,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.cyanAccent.withOpacity(0.7),
                    width: 1.4,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.network(
                  videoUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Text(
                        'Camera stream not available\nCheck Raspberry Pi IP',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B1726),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.videocam, color: Colors.cyanAccent),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Last Command: $_lastCommand',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (_isSending)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Camera Direction',
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

              const SizedBox(height: 12),

              Row(
                children: [
                  _cameraButton(
                    label: 'LEFT',
                    icon: Icons.keyboard_arrow_left,
                    command: 'CAM:LEFT',
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
