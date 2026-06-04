import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../config/constants.dart';
import '../models/robot_model.dart';
import '../providers/connection_provider.dart';
import '../providers/sensor_status_provider.dart';

enum RemoteControlMode {
  basic,
  rearJack,
  frontJack,
  arm,
}

class _T {
  static const bg = Color(0xFF020A14);

  static const cyan = Color(0xFF00E5FF);
  static const green = Color(0xFF00E676);
  static const red = Color(0xFFFF1744);
  static const orange = Color(0xFFFF9100);
  static const purple = Color(0xFFD500F9);
  static const amber = Color(0xFFFFD740);
  static const blue = Color(0xFF448AFF);

  static const textPrimary = Color(0xFFE8F4FF);
  static const textSecondary = Color(0xFF9AB7D0);
  static const textMuted = Color(0xFF5F7D99);
}

class RemoteControlScreen extends ConsumerStatefulWidget {
  const RemoteControlScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RemoteControlScreen> createState() =>
      _RemoteControlScreenState();
}

class _RemoteControlScreenState extends ConsumerState<RemoteControlScreen>
    with TickerProviderStateMixin {
  RemoteControlMode _mode = RemoteControlMode.basic;
  String _lastCommand = 'READY';
  String _lastAlertStatus = '';

  static const int _cameraServerPort = 5000;
  static const Duration _cameraProbeTimeout = Duration(seconds: 2);

  String? _resolvedCameraBaseUrl;
  bool _isResolvingCameraBaseUrl = false;

  Timer? _cameraRefreshTimer;
  int _cameraFrameTick = 0;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  String get _cameraSnapshotUrl {
    final endpoint =
        _mode == RemoteControlMode.arm ? 'arm_snapshot' : 'front_snapshot';

    final baseUrl = _resolvedCameraBaseUrl ??
        'http://${AppConstants.raspberryCandidateIps.first}:$_cameraServerPort';

    return '$baseUrl/$endpoint?t=$_cameraFrameTick';
  }

  @override
  void initState() {
    super.initState();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.45, end: 1.0).animate(
      _pulseController,
    );

    _cameraRefreshTimer = Timer.periodic(
      const Duration(milliseconds: 250),
      (_) {
        if (!mounted) return;

        setState(() {
          _cameraFrameTick++;
        });
      },
    );

    _resolveCameraHost();
  }

  @override
  void dispose() {
    _cameraRefreshTimer?.cancel();
    _pulseController.dispose();

    _sendCommand('STOP', showMessage: false);
    _sendCommand('JACK:ALL:STOP', showMessage: false);

    _sendCommand('CAM:STOP', showMessage: false);
    _sendCommand('CAM:SERVO:STOP', showMessage: false);

    _sendCommand('ARM:BASE:STOP', showMessage: false);
    _sendCommand('ARM:SHOULDER:STOP', showMessage: false);
    _sendCommand('ARM:ELBOW:STOP', showMessage: false);
    _sendCommand('ARM:WRIST:STOP', showMessage: false);
    _sendCommand('ARM:AUX:STOP', showMessage: false);
    _sendCommand('ARM:GRIPPER:STOP', showMessage: false);
    _sendCommand('ARM:STOP', showMessage: false);

    _restorePortraitMode();

    super.dispose();
  }

  Future<void> _restorePortraitMode() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  void _sendCommand(String commandType, {bool showMessage = true}) {
    final isConnected =
        ref.read(connectionStatusProvider) == ConnectionStatus.connected;

    if (!isConnected) {
      if (showMessage && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.link_off, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text('Robot not connected'),
              ],
            ),
            backgroundColor: _T.red.withOpacity(0.9),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(milliseconds: 900),
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

    if (!mounted) return;

    setState(() {
      _lastCommand = commandType;
    });
  }

  void _showSensorAlertIfNeeded(SensorStatus previous, SensorStatus next) {
    final nextStatus = next.balanceStatus.toUpperCase();

    if (nextStatus == _lastAlertStatus) return;

    if (nextStatus == 'WARNING' || nextStatus == 'DANGER') {
      _lastAlertStatus = nextStatus;

      SystemSound.play(SystemSoundType.alert);

      if (!mounted) return;

      final isDanger = nextStatus == 'DANGER';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isDanger ? Icons.dangerous : Icons.warning_amber,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                isDanger
                    ? 'DANGER — Robot may fall'
                    : 'WARNING — Robot is unstable',
              ),
            ],
          ),
          backgroundColor:
              isDanger ? _T.red.withOpacity(0.9) : _T.orange.withOpacity(0.9),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }

    if (nextStatus == 'STABLE') {
      _lastAlertStatus = 'STABLE';
    }
  }

  Future<void> _resolveCameraHost() async {
    if (_resolvedCameraBaseUrl != null || _isResolvingCameraBaseUrl) {
      return;
    }

    _isResolvingCameraBaseUrl = true;

    final allIps = <String>[...AppConstants.raspberryCandidateIps];

    for (var i = 1; i <= 254; i++) {
      final ip = '192.168.4.$i';
      if (allIps.contains(ip)) continue;
      allIps.add(ip);
    }

    for (final ip in allIps) {
      final baseUrl = 'http://$ip:$_cameraServerPort';
      final probeUrl = '$baseUrl/front_snapshot?t=probe';

      try {
        final response =
            await http.get(Uri.parse(probeUrl)).timeout(_cameraProbeTimeout);

        if (response.statusCode >= 200 && response.statusCode < 300) {
          if (!mounted) break;

          setState(() {
            _resolvedCameraBaseUrl = baseUrl;
          });

          break;
        }
      } catch (_) {
        // Ignore probe failures and try next address.
      }
    }

    _isResolvingCameraBaseUrl = false;
  }

  String get _modeTitle {
    switch (_mode) {
      case RemoteControlMode.basic:
        return 'Basic';
      case RemoteControlMode.rearJack:
        return 'Rear Jack';
      case RemoteControlMode.frontJack:
        return 'Front Jack';
      case RemoteControlMode.arm:
        return 'Arm';
    }
  }

  IconData get _modeIcon {
    switch (_mode) {
      case RemoteControlMode.basic:
        return Icons.sports_esports_rounded;
      case RemoteControlMode.rearJack:
        return Icons.vertical_align_bottom_rounded;
      case RemoteControlMode.frontJack:
        return Icons.vertical_align_top_rounded;
      case RemoteControlMode.arm:
        return Icons.precision_manufacturing_rounded;
    }
  }

  bool get _showFrontCamera => _mode != RemoteControlMode.arm;

  void _openModeMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF06111F),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.82,
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Select Control Mode',
                  style: TextStyle(
                    color: _T.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),
                _modeTile(
                  title: 'Basic',
                  subtitle: 'Movement controls + camera controls',
                  icon: Icons.sports_esports_rounded,
                  mode: RemoteControlMode.basic,
                ),
                _modeTile(
                  title: 'Rear Jack',
                  subtitle: 'Rear jack controls + camera controls',
                  icon: Icons.vertical_align_bottom_rounded,
                  mode: RemoteControlMode.rearJack,
                ),
                _modeTile(
                  title: 'Front Jack',
                  subtitle: 'Front jack controls + camera controls',
                  icon: Icons.vertical_align_top_rounded,
                  mode: RemoteControlMode.frontJack,
                ),
                _modeTile(
                  title: 'Arm',
                  subtitle: 'Arm continuous controls + arm camera',
                  icon: Icons.precision_manufacturing_rounded,
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

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color:
            selected ? _T.cyan.withOpacity(0.14) : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? _T.cyan.withOpacity(0.55) : Colors.white12,
        ),
      ),
      child: ListTile(
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
          color: selected ? _T.cyan : _T.textSecondary,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: selected ? _T.cyan : _T.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: _T.textSecondary),
        ),
        trailing:
            selected ? const Icon(Icons.check_circle, color: _T.cyan) : null,
      ),
    );
  }

  Widget _cameraView() {
    final title = _showFrontCamera ? 'Front Camera' : 'Arm Camera';

    return Positioned.fill(
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.network(
              _cameraSnapshotUrl,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (context, error, stackTrace) {
                return _cameraOffline(title);
              },
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.25,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.18),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            left: 12,
            child: _tinyText('Last: $_lastCommand'),
          ),
          Positioned(
            bottom: 8,
            right: 12,
            child: AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, __) {
                return Opacity(
                  opacity: _pulseAnim.value,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _T.red.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _cameraOffline(String title) {
    return Container(
      color: _T.bg,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.videocam_off_rounded,
              color: _T.red.withOpacity(0.9),
              size: 56,
            ),
            const SizedBox(height: 10),
            Text(
              '$title Not Available',
              style: const TextStyle(
                color: _T.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _cameraSnapshotUrl,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _T.textMuted,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tinyText(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.22),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: _T.textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _glassButton({
    required IconData icon,
    required String label,
    required String command,
    required Color color,
    double size = 58,
    bool sendOnTapDown = true,
    String? releaseCommand,
  }) {
    final isConnected =
        ref.watch(connectionStatusProvider) == ConnectionStatus.connected;

    void sendReleaseCommand() {
      if (!isConnected || releaseCommand == null) return;
      _sendCommand(releaseCommand, showMessage: false);
    }

    return GestureDetector(
      onTapDown:
          isConnected && sendOnTapDown ? (_) => _sendCommand(command) : null,
      onTapUp:
          isConnected && releaseCommand != null ? (_) => sendReleaseCommand() : null,
      onTapCancel:
          isConnected && releaseCommand != null ? sendReleaseCommand : null,
      onTap: isConnected && !sendOnTapDown && releaseCommand == null
          ? () => _sendCommand(command)
          : null,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.16),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isConnected
                ? color.withOpacity(0.50)
                : Colors.white.withOpacity(0.14),
            width: 1.1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isConnected ? color : _T.textMuted,
              size: size * 0.38,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isConnected ? color : _T.textMuted,
                fontSize: 8.5,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roundStopButton({
    required String command,
    double size = 62,
  }) {
    final isConnected =
        ref.watch(connectionStatusProvider) == ConnectionStatus.connected;

    return GestureDetector(
      onTapDown: isConnected ? (_) => _sendCommand(command) : null,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withOpacity(0.20),
          border: Border.all(
            color: isConnected ? _T.red.withOpacity(0.60) : Colors.white12,
            width: 1.3,
          ),
        ),
        child: Icon(
          Icons.stop_rounded,
          color: isConnected ? _T.red : _T.textMuted,
          size: size * 0.48,
        ),
      ),
    );
  }

  Widget _cameraControlsLeft() {
    if (_mode == RemoteControlMode.arm) {
      return _sideZone(
        alignment: CrossAxisAlignment.start,
        child: _armLeftControlsOverlay(),
      );
    }

    return _sideZone(
      alignment: CrossAxisAlignment.start,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _glassButton(
            icon: Icons.keyboard_arrow_up_rounded,
            label: 'CAM UP',
            command: 'CAM:SERVO:MOVE_UP',
            releaseCommand: 'CAM:SERVO:STOP',
            color: _T.cyan,
            size: 54,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _glassButton(
                icon: Icons.keyboard_arrow_left_rounded,
                label: 'LEFT',
                command: 'CAM:LEFT',
                releaseCommand: 'CAM:STOP',
                color: _T.cyan,
                size: 54,
              ),
              const SizedBox(width: 8),
              _roundStopButton(command: 'CAM:STOP', size: 56),
              const SizedBox(width: 8),
              _glassButton(
                icon: Icons.keyboard_arrow_right_rounded,
                label: 'RIGHT',
                command: 'CAM:RIGHT',
                releaseCommand: 'CAM:STOP',
                color: _T.cyan,
                size: 54,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _glassButton(
                icon: Icons.keyboard_arrow_down_rounded,
                label: 'CAM DOWN',
                command: 'CAM:SERVO:MOVE_DOWN',
                releaseCommand: 'CAM:SERVO:STOP',
                color: _T.cyan,
                size: 54,
              ),
              const SizedBox(width: 8),
              _glassButton(
                icon: Icons.center_focus_strong_rounded,
                label: 'CENTER',
                command: 'CAM:CENTER',
                color: _T.orange,
                size: 54,
                sendOnTapDown: false,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mainControlsRight() {
    return _sideZone(
      alignment: CrossAxisAlignment.end,
      child: _mainControlsForMode(),
    );
  }

  Widget _mainControlsForMode() {
    switch (_mode) {
      case RemoteControlMode.basic:
        return _movementControlsOverlay;

      case RemoteControlMode.rearJack:
        return _jackControlsOverlay(
          title: 'REAR',
          extend: 'JACK:REAR:EXTEND',
          stop: 'JACK:REAR:STOP',
          retract: 'JACK:REAR:RETRACT',
        );

      case RemoteControlMode.frontJack:
        return _jackControlsOverlay(
          title: 'FRONT',
          extend: 'JACK:FRONT:EXTEND',
          stop: 'JACK:FRONT:STOP',
          retract: 'JACK:FRONT:RETRACT',
        );

      case RemoteControlMode.arm:
        return _armRightControlsOverlay();
    }
  }

  Widget get _movementControlsOverlay {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _glassButton(
          icon: Icons.keyboard_arrow_up_rounded,
          label: 'FORWARD',
          command: 'move_forward',
          releaseCommand: 'STOP',
          color: _T.green,
          size: 62,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _glassButton(
              icon: Icons.keyboard_arrow_left_rounded,
              label: 'LEFT',
              command: 'turn_left',
              releaseCommand: 'STOP',
              color: _T.cyan,
              size: 62,
            ),
            const SizedBox(width: 8),
            _roundStopButton(command: 'STOP', size: 64),
            const SizedBox(width: 8),
            _glassButton(
              icon: Icons.keyboard_arrow_right_rounded,
              label: 'RIGHT',
              command: 'turn_right',
              releaseCommand: 'STOP',
              color: _T.cyan,
              size: 62,
            ),
          ],
        ),
        const SizedBox(height: 8),
        _glassButton(
          icon: Icons.keyboard_arrow_down_rounded,
          label: 'BACK',
          command: 'move_backward',
          releaseCommand: 'STOP',
          color: _T.green,
          size: 62,
        ),
      ],
    );
  }

  Widget _jackControlsOverlay({
    required String title,
    required String extend,
    required String stop,
    required String retract,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _overlayLabel('$title JACK'),
        const SizedBox(height: 7),
        _glassButton(
          icon: Icons.expand_less_rounded,
          label: 'EXTEND',
          command: extend,
          color: _T.orange,
          size: 64,
        ),
        const SizedBox(height: 8),
        _roundStopButton(command: stop, size: 64),
        const SizedBox(height: 8),
        _glassButton(
          icon: Icons.expand_more_rounded,
          label: 'RETRACT',
          command: retract,
          color: _T.orange,
          size: 64,
        ),
      ],
    );
  }

  Widget _armLeftControlsOverlay() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _overlayLabel('BASE'),
        const SizedBox(height: 7),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _glassButton(
              icon: Icons.rotate_left_rounded,
              label: 'BASE L',
              command: 'ARM:BASE:LEFT',
              releaseCommand: 'ARM:BASE:STOP',
              color: _T.purple,
              size: 58,
            ),
            const SizedBox(width: 8),
            _glassButton(
              icon: Icons.rotate_right_rounded,
              label: 'BASE R',
              command: 'ARM:BASE:RIGHT',
              releaseCommand: 'ARM:BASE:STOP',
              color: _T.purple,
              size: 58,
            ),
          ],
        ),
        const SizedBox(height: 8),
        _roundStopButton(command: 'ARM:BASE:STOP', size: 60),
        const SizedBox(height: 14),
        _overlayLabel('SHOULDER'),
        const SizedBox(height: 7),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _glassButton(
              icon: Icons.arrow_downward_rounded,
              label: 'SH DN',
              command: 'ARM:SHOULDER:MOVE_DOWN',
              releaseCommand: 'ARM:SHOULDER:STOP',
              color: _T.amber,
              size: 58,
            ),
            const SizedBox(width: 8),
            _glassButton(
              icon: Icons.arrow_upward_rounded,
              label: 'SH UP',
              command: 'ARM:SHOULDER:MOVE_UP',
              releaseCommand: 'ARM:SHOULDER:STOP',
              color: _T.amber,
              size: 58,
            ),
          ],
        ),
      ],
    );
  }

  Widget _armRightControlsOverlay() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _overlayLabel('ELBOW'),
        const SizedBox(height: 7),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _glassButton(
              icon: Icons.south_rounded,
              label: 'ELB DN',
              command: 'ARM:ELBOW:MOVE_DOWN',
              releaseCommand: 'ARM:ELBOW:STOP',
              color: _T.amber,
              size: 58,
            ),
            const SizedBox(width: 8),
            _glassButton(
              icon: Icons.north_rounded,
              label: 'ELB UP',
              command: 'ARM:ELBOW:MOVE_UP',
              releaseCommand: 'ARM:ELBOW:STOP',
              color: _T.amber,
              size: 58,
            ),
          ],
        ),
        const SizedBox(height: 14),
        _overlayLabel('WRIST'),
        const SizedBox(height: 7),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _glassButton(
              icon: Icons.keyboard_arrow_down_rounded,
              label: 'WR DN',
              command: 'ARM:WRIST:MOVE_DOWN',
              releaseCommand: 'ARM:WRIST:STOP',
              color: _T.blue,
              size: 56,
            ),
            const SizedBox(width: 8),
            _glassButton(
              icon: Icons.keyboard_arrow_up_rounded,
              label: 'WR UP',
              command: 'ARM:WRIST:MOVE_UP',
              releaseCommand: 'ARM:WRIST:STOP',
              color: _T.blue,
              size: 56,
            ),
          ],
        ),
        const SizedBox(height: 14),
        _overlayLabel('GRIPPER'),
        const SizedBox(height: 7),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _glassButton(
              icon: Icons.pan_tool_alt_rounded,
              label: 'OPEN',
              command: 'ARM:GRIPPER:MOVE_OPEN',
              releaseCommand: 'ARM:GRIPPER:STOP',
              color: _T.green,
              size: 56,
            ),
            const SizedBox(width: 8),
            _glassButton(
              icon: Icons.back_hand_rounded,
              label: 'CLOSE',
              command: 'ARM:GRIPPER:MOVE_CLOSE',
              releaseCommand: 'ARM:GRIPPER:STOP',
              color: _T.green,
              size: 56,
            ),
          ],
        ),
        const SizedBox(height: 14),
        _overlayLabel('AUX'),
        const SizedBox(height: 7),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _glassButton(
              icon: Icons.rotate_left_rounded,
              label: 'AUX L',
              command: 'ARM:AUX:MOVE_DOWN',
              releaseCommand: 'ARM:AUX:STOP',
              color: _T.purple,
              size: 56,
            ),
            const SizedBox(width: 8),
            _glassButton(
              icon: Icons.rotate_right_rounded,
              label: 'AUX R',
              command: 'ARM:AUX:MOVE_UP',
              releaseCommand: 'ARM:AUX:STOP',
              color: _T.purple,
              size: 56,
            ),
          ],
        ),
        const SizedBox(height: 14),
        _overlayLabel('STATES'),
        const SizedBox(height: 7),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _glassButton(
              icon: Icons.check_rounded,
              label: 'READY',
              command: 'ARM:READY',
              color: _T.green,
              size: 54,
              sendOnTapDown: false,
            ),
            const SizedBox(width: 8),
            _glassButton(
              icon: Icons.outbox_rounded,
              label: 'TAKE',
              command: 'ARM:TAKE_OUT',
              color: _T.amber,
              size: 54,
              sendOnTapDown: false,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _glassButton(
              icon: Icons.move_to_inbox_rounded,
              label: 'DROP IN',
              command: 'ARM:DROP_IN',
              color: _T.red,
              size: 54,
              sendOnTapDown: false,
            ),
            const SizedBox(width: 8),
            _glassButton(
              icon: Icons.output_rounded,
              label: 'DROP OUT',
              command: 'ARM:DROP_OUT',
              color: _T.orange,
              size: 54,
              sendOnTapDown: false,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _glassButton(
              icon: Icons.home_rounded,
              label: 'HOME',
              command: 'ARM:HOME',
              color: _T.textSecondary,
              size: 54,
              sendOnTapDown: false,
            ),
            const SizedBox(width: 8),
            _glassButton(
              icon: Icons.stop_circle_rounded,
              label: 'STOP',
              command: 'ARM:STOP',
              color: _T.red,
              size: 54,
              sendOnTapDown: false,
            ),
          ],
        ),
      ],
    );
  }

  Widget _overlayLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: _T.textSecondary,
        fontSize: 9,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.1,
      ),
    );
  }

  Widget _sideZone({
    required CrossAxisAlignment alignment,
    required Widget child,
  }) {
    final align =
        alignment == CrossAxisAlignment.start ? Alignment.centerLeft : Alignment.centerRight;

    return SizedBox(
      width: 260,
      height: double.infinity,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: 260,
          ),
          child: Align(
            alignment: align,
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _sensorStatusOverlay() {
    final sensors = ref.watch(sensorStatusProvider);

    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (sensors.isDanger) {
      statusColor = _T.red;
      statusIcon = Icons.dangerous_rounded;
      statusText = 'DANGER';
    } else if (sensors.isWarning) {
      statusColor = _T.orange;
      statusIcon = Icons.warning_amber_rounded;
      statusText = 'WARNING';
    } else if (sensors.isStable) {
      statusColor = _T.green;
      statusIcon = Icons.check_circle_rounded;
      statusText = 'STABLE';
    } else {
      statusColor = _T.textMuted;
      statusIcon = Icons.sensors_rounded;
      statusText = 'NO DATA';
    }

    return IgnorePointer(
      ignoring: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _sensorPlainItem(
            icon: statusIcon,
            label: statusText,
            color: statusColor,
          ),
          _sensorPlainItem(
            icon: Icons.swap_vert_rounded,
            label: sensors.pitch == null
                ? 'Pitch --'
                : 'Pitch ${sensors.pitch!.toStringAsFixed(1)}°',
            color: _T.cyan,
          ),
          _sensorPlainItem(
            icon: Icons.screen_rotation_alt_rounded,
            label: sensors.roll == null
                ? 'Roll --'
                : 'Roll ${sensors.roll!.toStringAsFixed(1)}°',
            color: _T.cyan,
          ),
          _sensorPlainItem(
            icon: Icons.vertical_align_top_rounded,
            label: sensors.frontDistance == null
                ? 'Front --'
                : 'Front ${sensors.frontDistance!.toStringAsFixed(1)}cm',
            color: _T.blue,
          ),
          _sensorPlainItem(
            icon: Icons.vertical_align_bottom_rounded,
            label: sensors.rearDistance == null
                ? 'Rear --'
                : 'Rear ${sensors.rearDistance!.toStringAsFixed(1)}cm',
            color: _T.blue,
          ),
        ],
      ),
    );
  }

  Widget _sensorPlainItem({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              shadows: const [
                Shadow(
                  color: Colors.black,
                  blurRadius: 5,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _flatTopButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = _T.textPrimary,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 17,
            shadows: const [
              Shadow(
                color: Colors.black,
                blurRadius: 6,
              ),
            ],
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              shadows: const [
                Shadow(
                  color: Colors.black,
                  blurRadius: 6,
                ),
              ],
            ),
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

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) async {
        await _restorePortraitMode();
      },
      child: Scaffold(
        backgroundColor: _T.bg,
        body: SafeArea(
          child: Stack(
            children: [
              _cameraView(),
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: true,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.black.withOpacity(0.22),
                          Colors.transparent,
                          Colors.black.withOpacity(0.22),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 6,
                left: 8,
                child: _flatTopButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  label: 'Back',
                  onTap: () async {
                    await _restorePortraitMode();

                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ),
              Positioned(
                top: 6,
                right: 8,
                child: _flatTopButton(
                  icon: Icons.tune_rounded,
                  label: _modeTitle,
                  color: _T.cyan,
                  onTap: _openModeMenu,
                ),
              ),
              Positioned(
                top: 7,
                left: 84,
                right: 84,
                child: Center(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: _sensorStatusOverlay(),
                  ),
                ),
              ),
              Positioned(
                left: 8,
                top: 58,
                bottom: 38,
                child: _cameraControlsLeft(),
              ),
              Positioned(
                right: 8,
                top: 58,
                bottom: 38,
                child: _mainControlsRight(),
              ),
              Positioned(
                bottom: 6,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  ignoring: true,
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _modeIcon,
                          color: _T.cyan,
                          size: 13,
                          shadows: const [
                            Shadow(color: Colors.black, blurRadius: 5),
                          ],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isConnected
                              ? 'Connected · $_modeTitle'
                              : 'Disconnected · $_modeTitle',
                          style: TextStyle(
                            color: isConnected ? _T.green : _T.red,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            shadows: const [
                              Shadow(color: Colors.black, blurRadius: 5),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}