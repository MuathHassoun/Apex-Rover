

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/robot_model.dart';
import '../providers/connection_provider.dart';
import '../providers/sensor_status_provider.dart';

enum RemoteControlMode {
  basic,
  rearJack,
  frontJack,
  arm,
}

class RemoteControlScreen extends ConsumerStatefulWidget {
  const RemoteControlScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RemoteControlScreen> createState() =>
      _RemoteControlScreenState();
}

class _RemoteControlScreenState extends ConsumerState<RemoteControlScreen> {
  RemoteControlMode _mode = RemoteControlMode.basic;
  String _lastCommand = 'READY';
  String _lastAlertStatus = '';

  // Raspberry Pi camera server
  static const String raspberryBaseUrl = 'http://192.168.4.2:5000';

  Timer? _cameraRefreshTimer;
  int _cameraFrameTick = 0;

  String get _cameraSnapshotUrl {
    final endpoint =
        _mode == RemoteControlMode.arm ? 'arm_snapshot' : 'front_snapshot';

    // Cache-busting query to force refresh
    return '$raspberryBaseUrl/$endpoint?t=$_cameraFrameTick';
  }

  @override
  void initState() {
    super.initState();

    // Force landscape when entering this screen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Refresh camera image about 4 times per second.
    // This avoids using flutter_mjpeg package.
    _cameraRefreshTimer = Timer.periodic(
      const Duration(milliseconds: 250),
      (_) {
        if (mounted) {
          setState(() {
            _cameraFrameTick++;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _cameraRefreshTimer?.cancel();

    // Safety stop when leaving remote screen
    _sendCommand('STOP', showMessage: false);
    _sendCommand('CAM:STOP', showMessage: false);

    // Return app to portrait after leaving
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    super.dispose();
  }

  bool get _isConnected =>
      ref.read(connectionStatusProvider) == ConnectionStatus.connected;

  void _sendCommand(String commandType, {bool showMessage = true}) {
    final isConnected =
        ref.read(connectionStatusProvider) == ConnectionStatus.connected;

    if (!isConnected) {
      if (showMessage && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Robot is not connected'),
            backgroundColor: Colors.redAccent,
            duration: Duration(milliseconds: 900),
          ),
        );
      }
      return;
    }

    final now = DateTime.now();

    final command = ControlCommand(
      commandId: 'remote_${now.millisecondsSinceEpoch}',
      commandType: commandType,
      parameters: const {
        'robotId': 'robot_001',
        'speed': 60,
      },
      timestamp: now,
    );

    ref.read(connectionStatusProvider.notifier).sendCommand(command);

    if (mounted) {
      setState(() {
        _lastCommand = commandType;
      });
    }
  }

  void _showSensorAlertIfNeeded(SensorStatus previous, SensorStatus next) {
    final nextStatus = next.balanceStatus.toUpperCase();

    if (nextStatus == _lastAlertStatus) {
      return;
    }

    if (nextStatus == 'WARNING' || nextStatus == 'DANGER') {
      _lastAlertStatus = nextStatus;

      SystemSound.play(SystemSoundType.alert);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            nextStatus == 'DANGER'
                ? 'Danger: Robot may fall'
                : 'Warning: Robot is unstable',
          ),
          backgroundColor:
              nextStatus == 'DANGER' ? Colors.redAccent : Colors.orangeAccent,
          duration: const Duration(seconds: 2),
        ),
      );
    }

    if (nextStatus == 'STABLE') {
      _lastAlertStatus = 'STABLE';
    }
  }

  String get _modeTitle {
    switch (_mode) {
      case RemoteControlMode.basic:
        return 'Basic Control';
      case RemoteControlMode.rearJack:
        return 'Rear Jack';
      case RemoteControlMode.frontJack:
        return 'Front Jack';
      case RemoteControlMode.arm:
        return 'Arm Control';
    }
  }

  bool get _showCameraStandControls {
    return _mode != RemoteControlMode.arm;
  }

  bool get _showFrontCamera {
    return _mode != RemoteControlMode.arm;
  }

  void _openModeMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF07111F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              runSpacing: 10,
              children: [
                const Text(
                  'Select Control Mode',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _modeTile(
                  title: 'Basic',
                  subtitle: 'Robot movement + camera stand',
                  icon: Icons.sports_esports,
                  mode: RemoteControlMode.basic,
                ),
                _modeTile(
                  title: 'Rear Jack',
                  subtitle: 'Rear actuator control + camera stand',
                  icon: Icons.vertical_align_bottom,
                  mode: RemoteControlMode.rearJack,
                ),
                _modeTile(
                  title: 'Front Jack',
                  subtitle: 'Front actuator control + camera stand',
                  icon: Icons.vertical_align_top,
                  mode: RemoteControlMode.frontJack,
                ),
                _modeTile(
                  title: 'Arm',
                  subtitle: 'Arm control + arm camera',
                  icon: Icons.precision_manufacturing,
                  mode: RemoteControlMode.arm,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _modeTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required RemoteControlMode mode,
  }) {
    final selected = _mode == mode;

    return ListTile(
      onTap: () {
        setState(() {
          _mode = mode;
          _lastCommand = 'MODE: $title';
          _cameraFrameTick++;
        });
        Navigator.pop(context);
      },
      leading: Icon(
        icon,
        color: selected ? Colors.cyanAccent : Colors.white70,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: selected ? Colors.cyanAccent : Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.white54),
      ),
      trailing: selected
          ? const Icon(Icons.check_circle, color: Colors.cyanAccent)
          : null,
    );
  }

  Widget _controlButton({
    required String label,
    required IconData icon,
    required String command,
    Color color = Colors.cyanAccent,
    double width = 82,
    double height = 64,
  }) {
    final isConnected =
        ref.watch(connectionStatusProvider) == ConnectionStatus.connected;

    return GestureDetector(
      onTap: isConnected ? () => _sendCommand(command) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: isConnected
              ? color.withOpacity(0.16)
              : Colors.grey.withOpacity(0.10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isConnected ? color.withOpacity(0.9) : Colors.grey,
            width: 1.4,
          ),
          boxShadow: [
            if (isConnected)
              BoxShadow(
                color: color.withOpacity(0.18),
                blurRadius: 12,
              ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isConnected ? color : Colors.grey,
              size: 27,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isConnected ? color : Colors.grey,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sensorStatusBar() {
    final sensors = ref.watch(sensorStatusProvider);

    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (sensors.isDanger) {
      statusColor = Colors.redAccent;
      statusIcon = Icons.dangerous;
      statusText = 'DANGER';
    } else if (sensors.isWarning) {
      statusColor = Colors.orangeAccent;
      statusIcon = Icons.warning;
      statusText = 'WARNING';
    } else if (sensors.isStable) {
      statusColor = Colors.greenAccent;
      statusIcon = Icons.check_circle;
      statusText = 'STABLE';
    } else {
      statusColor = Colors.white54;
      statusIcon = Icons.sensors;
      statusText = 'NO DATA';
    }

    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.64),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withOpacity(0.75),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          _sensorMiniCard(
            label: 'Balance',
            value: statusText,
            icon: statusIcon,
            color: statusColor,
          ),
          const SizedBox(width: 8),
          _sensorMiniCard(
            label: 'Pitch',
            value: sensors.pitch == null
                ? '--'
                : '${sensors.pitch!.toStringAsFixed(1)}°',
            icon: Icons.swap_vert,
            color: Colors.cyanAccent,
          ),
          const SizedBox(width: 8),
          _sensorMiniCard(
            label: 'Roll',
            value: sensors.roll == null
                ? '--'
                : '${sensors.roll!.toStringAsFixed(1)}°',
            icon: Icons.screen_rotation_alt,
            color: Colors.cyanAccent,
          ),
          const SizedBox(width: 8),
          _sensorMiniCard(
            label: 'Front US',
            value: sensors.frontDistance == null
                ? '--'
                : '${sensors.frontDistance!.toStringAsFixed(1)} cm',
            icon: Icons.vertical_align_top,
            color: Colors.lightBlueAccent,
          ),
          const SizedBox(width: 8),
          _sensorMiniCard(
            label: 'Rear US',
            value: sensors.rearDistance == null
                ? '--'
                : '${sensors.rearDistance!.toStringAsFixed(1)} cm',
            icon: Icons.vertical_align_bottom,
            color: Colors.lightBlueAccent,
          ),
        ],
      ),
    );
  }

  Widget _sensorMiniCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.45),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    value,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
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

  Widget _cameraView() {
    final title = _showFrontCamera ? 'Front Camera' : 'Arm Camera';

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.cyanAccent.withOpacity(0.5),
          width: 1.4,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.network(
                _cameraSnapshotUrl,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.black,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.videocam_off,
                            color: Colors.redAccent,
                            size: 70,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '$title not available',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _cameraSnapshotUrl,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Make sure dual_camera_server.py is running on Raspberry Pi',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            Positioned(
              top: 82,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            Positioned(
              right: 16,
              top: 82,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _modeTitle,
                  style: const TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            Positioned(
              left: 16,
              bottom: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Last: $_lastCommand',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _movementControls() {
    return SizedBox(
      width: 270,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _controlButton(
            label: 'FORWARD',
            icon: Icons.keyboard_arrow_up,
            command: 'FORWARD',
            color: Colors.greenAccent,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _controlButton(
                label: 'LEFT',
                icon: Icons.keyboard_arrow_left,
                command: 'LEFT',
              ),
              const SizedBox(width: 8),
              _controlButton(
                label: 'STOP',
                icon: Icons.stop_circle,
                command: 'STOP',
                color: Colors.redAccent,
              ),
              const SizedBox(width: 8),
              _controlButton(
                label: 'RIGHT',
                icon: Icons.keyboard_arrow_right,
                command: 'RIGHT',
              ),
            ],
          ),
          const SizedBox(height: 8),
          _controlButton(
            label: 'BACK',
            icon: Icons.keyboard_arrow_down,
            command: 'BACKWARD',
            color: Colors.greenAccent,
          ),
        ],
      ),
    );
  }

  Widget _rearJackControls() {
    return SizedBox(
      width: 270,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _controlButton(
            label: 'REAR EXTEND',
            icon: Icons.expand_less,
            command: 'JACK:REAR:EXTEND',
            color: Colors.orangeAccent,
            width: 170,
          ),
          const SizedBox(height: 10),
          _controlButton(
            label: 'REAR STOP',
            icon: Icons.stop_circle,
            command: 'JACK:REAR:STOP',
            color: Colors.redAccent,
            width: 170,
          ),
          const SizedBox(height: 10),
          _controlButton(
            label: 'REAR RETRACT',
            icon: Icons.expand_more,
            command: 'JACK:REAR:RETRACT',
            color: Colors.orangeAccent,
            width: 170,
          ),
        ],
      ),
    );
  }

  Widget _frontJackControls() {
    return SizedBox(
      width: 270,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _controlButton(
            label: 'FRONT EXTEND',
            icon: Icons.expand_less,
            command: 'JACK:FRONT:EXTEND',
            color: Colors.orangeAccent,
            width: 170,
          ),
          const SizedBox(height: 10),
          _controlButton(
            label: 'FRONT STOP',
            icon: Icons.stop_circle,
            command: 'JACK:FRONT:STOP',
            color: Colors.redAccent,
            width: 170,
          ),
          const SizedBox(height: 10),
          _controlButton(
            label: 'FRONT RETRACT',
            icon: Icons.expand_more,
            command: 'JACK:FRONT:RETRACT',
            color: Colors.orangeAccent,
            width: 170,
          ),
        ],
      ),
    );
  }

  Widget _armControls() {
    return SizedBox(
      width: 360,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          _controlButton(
            label: 'BASE L',
            icon: Icons.rotate_left,
            command: 'ARM:BASE:LEFT',
            color: Colors.purpleAccent,
          ),
          _controlButton(
            label: 'BASE R',
            icon: Icons.rotate_right,
            command: 'ARM:BASE:RIGHT',
            color: Colors.purpleAccent,
          ),
          _controlButton(
            label: 'BASE STOP',
            icon: Icons.stop_circle,
            command: 'ARM:BASE:STOP',
            color: Colors.redAccent,
          ),
          _controlButton(
            label: 'SH UP',
            icon: Icons.arrow_upward,
            command: 'ARM:SHOULDER:UP',
            color: Colors.amberAccent,
          ),
          _controlButton(
            label: 'SH DOWN',
            icon: Icons.arrow_downward,
            command: 'ARM:SHOULDER:DOWN',
            color: Colors.amberAccent,
          ),
          _controlButton(
            label: 'ELB UP',
            icon: Icons.north,
            command: 'ARM:ELBOW:UP',
            color: Colors.amberAccent,
          ),
          _controlButton(
            label: 'ELB DOWN',
            icon: Icons.south,
            command: 'ARM:ELBOW:DOWN',
            color: Colors.amberAccent,
          ),
          _controlButton(
            label: 'WR UP',
            icon: Icons.keyboard_arrow_up,
            command: 'ARM:WRIST:UP',
            color: Colors.lightBlueAccent,
          ),
          _controlButton(
            label: 'WR DOWN',
            icon: Icons.keyboard_arrow_down,
            command: 'ARM:WRIST:DOWN',
            color: Colors.lightBlueAccent,
          ),
          _controlButton(
            label: 'OPEN',
            icon: Icons.pan_tool_alt,
            command: 'ARM:GRIPPER:OPEN',
            color: Colors.greenAccent,
          ),
          _controlButton(
            label: 'CLOSE',
            icon: Icons.back_hand,
            command: 'ARM:GRIPPER:CLOSE',
            color: Colors.greenAccent,
          ),
          _controlButton(
            label: 'HOME',
            icon: Icons.home,
            command: 'ARM:HOME',
            color: Colors.white70,
          ),
        ],
      ),
    );
  }

  Widget _mainModeControls() {
    switch (_mode) {
      case RemoteControlMode.basic:
        return _movementControls();
      case RemoteControlMode.rearJack:
        return _rearJackControls();
      case RemoteControlMode.frontJack:
        return _frontJackControls();
      case RemoteControlMode.arm:
        return _armControls();
    }
  }

  Widget _cameraStandControls() {
    return SizedBox(
      width: 190,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _controlButton(
            label: 'CAM UP',
            icon: Icons.keyboard_arrow_up,
            command: 'CAM:UP',
            color: Colors.cyanAccent,
            width: 82,
            height: 55,
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _controlButton(
                label: 'CAM L',
                icon: Icons.keyboard_arrow_left,
                command: 'CAM:LEFT',
                color: Colors.cyanAccent,
                width: 72,
                height: 55,
              ),
              const SizedBox(width: 6),
              _controlButton(
                label: 'STOP',
                icon: Icons.stop_circle,
                command: 'CAM:STOP',
                color: Colors.redAccent,
                width: 72,
                height: 55,
              ),
              const SizedBox(width: 6),
              _controlButton(
                label: 'CAM R',
                icon: Icons.keyboard_arrow_right,
                command: 'CAM:RIGHT',
                color: Colors.cyanAccent,
                width: 72,
                height: 55,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _controlButton(
                label: 'DOWN',
                icon: Icons.keyboard_arrow_down,
                command: 'CAM:DOWN',
                color: Colors.cyanAccent,
                width: 82,
                height: 55,
              ),
              const SizedBox(width: 6),
              _controlButton(
                label: 'CENTER',
                icon: Icons.center_focus_strong,
                command: 'CAM:CENTER',
                color: Colors.orangeAccent,
                width: 82,
                height: 55,
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isConnected =
        ref.watch(connectionStatusProvider) == ConnectionStatus.connected;

    ref.listen<SensorStatus>(
      sensorStatusProvider,
      (previous, next) {
        if (previous == null) return;
        _showSensorAlertIfNeeded(previous, next);
      },
    );

    return Scaffold(
      backgroundColor: const Color(0xFF020712),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: _cameraView(),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: _mode == RemoteControlMode.arm ? 390 : 295,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF07111F),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.12),
                      ),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 44),
                        Text(
                          _modeTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isConnected ? 'Connected' : 'Not Connected',
                          style: TextStyle(
                            color: isConnected
                                ? Colors.greenAccent
                                : Colors.redAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        _mainModeControls(),
                        const Spacer(),
                        if (_showCameraStandControls) _cameraStandControls(),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Positioned(
              top: 14,
              left: 96,
              right: 96,
              child: _sensorStatusBar(),
            ),

            Positioned(
              top: 14,
              left: 14,
              child: _topButton(
                icon: Icons.arrow_back,
                label: 'Back',
                onTap: () => Navigator.of(context).pop(),
              ),
            ),

            Positioned(
              top: 14,
              right: 14,
              child: _topButton(
                icon: Icons.tune,
                label: 'Mode',
                onTap: _openModeMenu,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.55),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.18)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 19),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}