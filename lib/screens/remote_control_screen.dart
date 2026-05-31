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

// ─── Design Tokens ────────────────────────────────────────────────────────────
class _T {
  static const bg = Color(0xFF020A14);
  static const surface = Color(0xFF071422);
  static const panel = Color(0xFF0B1E30);
  static const card = Color(0xFF0F2438);
  static const border = Color(0x1AFFFFFF);
  static const borderLit = Color(0x3300E5FF);

  static const cyan = Color(0xFF00E5FF);
  static const cyanDim = Color(0x2200E5FF);
  static const cyanMid = Color(0x5500E5FF);
  static const green = Color(0xFF00E676);
  static const greenDim = Color(0x2200E676);
  static const red = Color(0xFFFF1744);
  static const redDim = Color(0x22FF1744);
  static const orange = Color(0xFFFF9100);
  static const orangeDim = Color(0x22FF9100);
  static const purple = Color(0xFFD500F9);
  static const purpleDim = Color(0x22D500F9);
  static const amber = Color(0xFFFFD740);
  static const amberDim = Color(0x22FFD740);
  static const blue = Color(0xFF448AFF);
  static const blueDim = Color(0x22448AFF);

  static const textPrimary = Color(0xFFE8F4FF);
  static const textSecondary = Color(0xFF7AA0BF);
  static const textMuted = Color(0xFF3A5570);
}

class RemoteControlScreen extends ConsumerStatefulWidget {
  const RemoteControlScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RemoteControlScreen> createState() => _RemoteControlScreenState();
}

class _RemoteControlScreenState extends ConsumerState<RemoteControlScreen>
    with TickerProviderStateMixin {
  RemoteControlMode _mode = RemoteControlMode.basic;
  String _lastCommand = 'READY';
  String _lastAlertStatus = '';

  static const String raspberryBaseUrl = 'http://192.168.4.2:5000';

  Timer? _cameraRefreshTimer;
  int _cameraFrameTick = 0;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  String get _cameraSnapshotUrl {
    final endpoint = _mode == RemoteControlMode.arm ? 'arm_snapshot' : 'front_snapshot';
    return '$raspberryBaseUrl/$endpoint?t=$_cameraFrameTick';
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
    _pulseAnim = Tween<double>(begin: 0.4, end: 1.0).animate(_pulseController);

    _cameraRefreshTimer = Timer.periodic(
      const Duration(milliseconds: 250),
      (_) {
        if (mounted) setState(() => _cameraFrameTick++);
      },
    );
  }

  @override
  void dispose() {
    _cameraRefreshTimer?.cancel();
    _pulseController.dispose();
    _sendCommand('STOP', showMessage: false);
    _sendCommand('CAM:STOP', showMessage: false);
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
    final isConnected = ref.read(connectionStatusProvider) == ConnectionStatus.connected;

    if (!isConnected) {
      if (showMessage && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.link_off, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text('Robot not connected'),
              ],
            ),
            backgroundColor: _T.red.withOpacity(0.9),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      parameters: const {'robotId': 'robot_001', 'speed': 60},
      timestamp: now,
    );
    ref.read(connectionStatusProvider.notifier).sendCommand(command);

    if (mounted) setState(() => _lastCommand = commandType);
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
            children: [
              Icon(isDanger ? Icons.dangerous : Icons.warning_amber, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text(isDanger ? 'DANGER — Robot may fall' : 'WARNING — Robot is unstable'),
            ],
          ),
          backgroundColor: isDanger ? _T.red.withOpacity(0.9) : _T.orange.withOpacity(0.9),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
    if (nextStatus == 'STABLE') _lastAlertStatus = 'STABLE';
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

  bool get _showCameraStandControls => _mode != RemoteControlMode.arm;
  bool get _showFrontCamera => _mode != RemoteControlMode.arm;

  // ─── Mode Menu ───────────────────────────────────────────────────────────────
  void _openModeMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _T.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.85,
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: _T.textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _T.cyanDim,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _T.cyan.withOpacity(0.4)),
                      ),
                      child: const Icon(Icons.tune_rounded, color: _T.cyan, size: 18),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Control Mode',
                      style: TextStyle(
                        color: _T.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _modeTile(
                      title: 'Basic',
                      subtitle: 'Robot movement + camera stand',
                      icon: Icons.sports_esports_rounded,
                      mode: RemoteControlMode.basic,
                    ),
                    _modeTile(
                      title: 'Rear Jack',
                      subtitle: 'Rear actuator control',
                      icon: Icons.vertical_align_bottom_rounded,
                      mode: RemoteControlMode.rearJack,
                    ),
                    _modeTile(
                      title: 'Front Jack',
                      subtitle: 'Front actuator control',
                      icon: Icons.vertical_align_top_rounded,
                      mode: RemoteControlMode.frontJack,
                    ),
                    _modeTile(
                      title: 'Arm',
                      subtitle: 'Arm control + arm camera',
                      icon: Icons.precision_manufacturing_rounded,
                      mode: RemoteControlMode.arm,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modeTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required RemoteControlMode mode,
  }) {
    final selected = _mode == mode;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: selected ? _T.cyanDim : _T.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? _T.cyan.withOpacity(0.5) : _T.border,
          width: selected ? 1.5 : 1,
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: selected ? _T.cyan.withOpacity(0.2) : _T.panel,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: selected ? _T.cyan : _T.textSecondary, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: selected ? _T.cyan : _T.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: _T.textSecondary, fontSize: 12),
        ),
        trailing: selected
            ? Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _T.cyan,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.check, color: _T.bg, size: 14),
              )
            : null,
      ),
    );
  }

  // ─── Control Button ───────────────────────────────────────────────────────────
  Widget _controlButton({
    required String label,
    required IconData icon,
    required String command,
    Color color = _T.cyan,
    double width = 80,
    double height = 60,
    bool isStop = false,
  }) {
    final isConnected = ref.watch(connectionStatusProvider) == ConnectionStatus.connected;
    final dimColor = isConnected ? color.withOpacity(0.15) : _T.card;
    final activeColor = isConnected ? color : _T.textMuted;

    return GestureDetector(
      onTapDown: isConnected ? (_) => _sendCommand(command) : null,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: dimColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isConnected ? color.withOpacity(0.55) : _T.border,
            width: 1.2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: activeColor, size: 22),
            const SizedBox(height: 3),
            Text(
              label,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                color: activeColor,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Sensor Bar ───────────────────────────────────────────────────────────────
  Widget _sensorStatusBar() {
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

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: _T.surface.withOpacity(0.92),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withOpacity(0.4), width: 1),
      ),
      child: Row(
        children: [
          _sensorChip(
            label: 'Status',
            value: statusText,
            icon: statusIcon,
            color: statusColor,
            flex: 2,
          ),
          _divider(),
          _sensorChip(
            label: 'Pitch',
            value: sensors.pitch == null ? '—' : '${sensors.pitch!.toStringAsFixed(1)}°',
            icon: Icons.swap_vert_rounded,
            color: _T.cyan,
          ),
          _divider(),
          _sensorChip(
            label: 'Roll',
            value: sensors.roll == null ? '—' : '${sensors.roll!.toStringAsFixed(1)}°',
            icon: Icons.screen_rotation_alt_rounded,
            color: _T.cyan,
          ),
          _divider(),
          _sensorChip(
            label: 'Front US',
            value: sensors.frontDistance == null
                ? '—'
                : '${sensors.frontDistance!.toStringAsFixed(1)}cm',
            icon: Icons.vertical_align_top_rounded,
            color: _T.blue,
          ),
          _divider(),
          _sensorChip(
            label: 'Rear US',
            value: sensors.rearDistance == null
                ? '—'
                : '${sensors.rearDistance!.toStringAsFixed(1)}cm',
            icon: Icons.vertical_align_bottom_rounded,
            color: _T.blue,
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 28,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        color: _T.border,
      );

  Widget _sensorChip({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    int flex = 1,
  }) {
    return Expanded(
      flex: flex,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: _T.textMuted,
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Camera View ─────────────────────────────────────────────────────────────
  Widget _cameraView() {
    final title = _showFrontCamera ? 'Front Camera' : 'Arm Camera';

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _T.borderLit, width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.network(
                _cameraSnapshotUrl,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (context, error, stackTrace) => _cameraOffline(title),
              ),
            ),
            // Top gradient overlay
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 80,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.65),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Bottom gradient overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 60,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Mode badge top-left
            Positioned(
              top: 14,
              left: 14,
              child: _badge(title, _T.cyan, Icons.videocam_rounded),
            ),
            // Mode badge top-right
            Positioned(
              top: 14,
              right: 14,
              child: _badge(_modeTitle, _T.textPrimary, _modeIcon),
            ),
            // Last command bottom-left
            Positioned(
              bottom: 12,
              left: 14,
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _T.green,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _lastCommand,
                    style: const TextStyle(
                      color: _T.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            // Live badge bottom-right
            Positioned(
              bottom: 12,
              right: 14,
              child: AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, __) => Opacity(
                  opacity: _pulseAnim.value,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _T.red.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, color: Colors.white, size: 6),
                        SizedBox(width: 4),
                        Text(
                          'LIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
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
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _T.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _T.red.withOpacity(0.3)),
              ),
              child: const Icon(Icons.videocam_off_rounded, color: _T.red, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              '$title Not Available',
              style: const TextStyle(
                color: _T.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _cameraSnapshotUrl,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _T.textMuted, fontSize: 11),
            ),
            const SizedBox(height: 4),
            const Text(
              'Check dual_camera_server.py on Raspberry Pi',
              textAlign: TextAlign.center,
              style: TextStyle(color: _T.textMuted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Movement Controls ────────────────────────────────────────────────────────
  Widget _movementControls() {
    return _sectionCard(
      title: 'MOVEMENT',
      icon: Icons.sports_esports_rounded,
      color: _T.green,
      child: Column(
        children: [
          _controlButton(
            label: 'FORWARD',
            icon: Icons.keyboard_arrow_up_rounded,
            command: 'FORWARD',
            color: _T.green,
            width: 110,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _controlButton(
                label: 'LEFT',
                icon: Icons.keyboard_arrow_left_rounded,
                command: 'LEFT',
                color: _T.cyan,
              ),
              const SizedBox(width: 8),
              _controlButton(
                label: 'STOP',
                icon: Icons.stop_rounded,
                command: 'STOP',
                color: _T.red,
                isStop: true,
              ),
              const SizedBox(width: 8),
              _controlButton(
                label: 'RIGHT',
                icon: Icons.keyboard_arrow_right_rounded,
                command: 'RIGHT',
                color: _T.cyan,
              ),
            ],
          ),
          const SizedBox(height: 8),
          _controlButton(
            label: 'BACK',
            icon: Icons.keyboard_arrow_down_rounded,
            command: 'BACKWARD',
            color: _T.green,
            width: 110,
          ),
        ],
      ),
    );
  }

  Widget _rearJackControls() {
    return _sectionCard(
      title: 'REAR JACK',
      icon: Icons.vertical_align_bottom_rounded,
      color: _T.orange,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _controlButton(
            label: 'EXTEND',
            icon: Icons.expand_less_rounded,
            command: 'JACK:REAR:EXTEND',
            color: _T.orange,
            width: 96,
          ),
          const SizedBox(width: 10),
          _controlButton(
            label: 'STOP',
            icon: Icons.stop_rounded,
            command: 'JACK:REAR:STOP',
            color: _T.red,
            isStop: true,
            width: 96,
          ),
          const SizedBox(width: 10),
          _controlButton(
            label: 'RETRACT',
            icon: Icons.expand_more_rounded,
            command: 'JACK:REAR:RETRACT',
            color: _T.orange,
            width: 96,
          ),
        ],
      ),
    );
  }

  Widget _frontJackControls() {
    return _sectionCard(
      title: 'FRONT JACK',
      icon: Icons.vertical_align_top_rounded,
      color: _T.orange,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _controlButton(
            label: 'EXTEND',
            icon: Icons.expand_less_rounded,
            command: 'JACK:FRONT:EXTEND',
            color: _T.orange,
            width: 96,
          ),
          const SizedBox(width: 10),
          _controlButton(
            label: 'STOP',
            icon: Icons.stop_rounded,
            command: 'JACK:FRONT:STOP',
            color: _T.red,
            isStop: true,
            width: 96,
          ),
          const SizedBox(width: 10),
          _controlButton(
            label: 'RETRACT',
            icon: Icons.expand_more_rounded,
            command: 'JACK:FRONT:RETRACT',
            color: _T.orange,
            width: 96,
          ),
        ],
      ),
    );
  }

  Widget _armControls() {
    return _sectionCard(
      title: 'ARM CONTROLS',
      icon: Icons.precision_manufacturing_rounded,
      color: _T.purple,
      child: Column(
        children: [
          // Base Row
          _armGroup('BASE', [
            _controlButton(
                label: 'BASE L',
                icon: Icons.rotate_left_rounded,
                command: 'ARM:BASE:LEFT',
                color: _T.purple,
                width: 90),
            const SizedBox(width: 8),
            _controlButton(
                label: 'STOP',
                icon: Icons.stop_rounded,
                command: 'ARM:BASE:STOP',
                color: _T.red,
                isStop: true,
                width: 68),
            const SizedBox(width: 8),
            _controlButton(
                label: 'BASE R',
                icon: Icons.rotate_right_rounded,
                command: 'ARM:BASE:RIGHT',
                color: _T.purple,
                width: 90),
          ]),
          const SizedBox(height: 8),
          // Shoulder & Elbow Row
          _armGroup('JOINTS', [
            _controlButton(
                label: 'SH ↑',
                icon: Icons.arrow_upward_rounded,
                command: 'ARM:SHOULDER:UP',
                color: _T.amber,
                width: 74),
            const SizedBox(width: 6),
            _controlButton(
                label: 'SH ↓',
                icon: Icons.arrow_downward_rounded,
                command: 'ARM:SHOULDER:DOWN',
                color: _T.amber,
                width: 74),
            const SizedBox(width: 6),
            _controlButton(
                label: 'ELB ↑',
                icon: Icons.north_rounded,
                command: 'ARM:ELBOW:UP',
                color: _T.amber,
                width: 74),
            const SizedBox(width: 6),
            _controlButton(
                label: 'ELB ↓',
                icon: Icons.south_rounded,
                command: 'ARM:ELBOW:DOWN',
                color: _T.amber,
                width: 74),
          ]),
          const SizedBox(height: 8),
          // Wrist & Gripper Row
          _armGroup('END EFFECTOR', [
            _controlButton(
                label: 'WR ↑',
                icon: Icons.keyboard_arrow_up_rounded,
                command: 'ARM:WRIST:UP',
                color: _T.blue,
                width: 74),
            const SizedBox(width: 6),
            _controlButton(
                label: 'WR ↓',
                icon: Icons.keyboard_arrow_down_rounded,
                command: 'ARM:WRIST:DOWN',
                color: _T.blue,
                width: 74),
            const SizedBox(width: 6),
            _controlButton(
                label: 'OPEN',
                icon: Icons.pan_tool_alt_rounded,
                command: 'ARM:GRIPPER:OPEN',
                color: _T.green,
                width: 74),
            const SizedBox(width: 6),
            _controlButton(
                label: 'CLOSE',
                icon: Icons.back_hand_rounded,
                command: 'ARM:GRIPPER:CLOSE',
                color: _T.green,
                width: 74),
          ]),
          const SizedBox(height: 8),
          _controlButton(
            label: 'HOME POSITION',
            icon: Icons.home_rounded,
            command: 'ARM:HOME',
            color: _T.textSecondary,
            width: 200,
            height: 48,
          ),
        ],
      ),
    );
  }

  Widget _armGroup(String label, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _T.textMuted,
            fontSize: 8,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 5),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: children,
        ),
      ],
    );
  }

  Widget _cameraStandControls() {
    return _sectionCard(
      title: 'CAMERA STAND',
      icon: Icons.videocam_rounded,
      color: _T.cyan,
      child: Column(
        children: [
          _controlButton(
            label: 'UP',
            icon: Icons.keyboard_arrow_up_rounded,
            command: 'CAM:UP',
            color: _T.cyan,
            width: 100,
            height: 52,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _controlButton(
                label: 'LEFT',
                icon: Icons.keyboard_arrow_left_rounded,
                command: 'CAM:LEFT',
                color: _T.cyan,
                width: 76,
                height: 52,
              ),
              const SizedBox(width: 8),
              _controlButton(
                label: 'STOP',
                icon: Icons.stop_rounded,
                command: 'CAM:STOP',
                color: _T.red,
                isStop: true,
                width: 76,
                height: 52,
              ),
              const SizedBox(width: 8),
              _controlButton(
                label: 'RIGHT',
                icon: Icons.keyboard_arrow_right_rounded,
                command: 'CAM:RIGHT',
                color: _T.cyan,
                width: 76,
                height: 52,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _controlButton(
                label: 'DOWN',
                icon: Icons.keyboard_arrow_down_rounded,
                command: 'CAM:DOWN',
                color: _T.cyan,
                width: 100,
                height: 52,
              ),
              const SizedBox(width: 8),
              _controlButton(
                label: 'CENTER',
                icon: Icons.center_focus_strong_rounded,
                command: 'CAM:CENTER',
                color: _T.orange,
                width: 100,
                height: 52,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _T.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _T.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 12),
              const SizedBox(width: 5),
              Text(
                title,
                style: TextStyle(
                  color: color.withOpacity(0.85),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
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

  // ─── Right Panel ──────────────────────────────────────────────────────────────
  Widget _rightControlPanel(bool isConnected) {
    return Container(
      width: _mode == RemoteControlMode.arm ? 420 : 335,
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _T.border),
      ),
      child: Column(
        children: [
          // Panel header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 52, 16, 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: _T.border)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _T.cyanDim,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _T.cyan.withOpacity(0.4)),
                  ),
                  child: Icon(_modeIcon, color: _T.cyan, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _modeTitle,
                        style: const TextStyle(
                          color: _T.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Row(
                        children: [
                          AnimatedBuilder(
                            animation: _pulseAnim,
                            builder: (_, __) => Opacity(
                              opacity: isConnected ? _pulseAnim.value : 1,
                              child: Container(
                                width: 6,
                                height: 6,
                                margin: const EdgeInsets.only(right: 5),
                                decoration: BoxDecoration(
                                  color: isConnected ? _T.green : _T.red,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),
                          Text(
                            isConnected ? 'Connected' : 'Disconnected',
                            style: TextStyle(
                              color: isConnected ? _T.green : _T.red,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Scrollable controls
          Expanded(
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 16),
                child: Column(
                  children: [
                    _mainModeControls(),
                    if (_showCameraStandControls) _cameraStandControls(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Top Buttons ─────────────────────────────────────────────────────────────
  Widget _topButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = _T.textPrimary,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: _T.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _T.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 17),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isConnected = ref.watch(connectionStatusProvider) == ConnectionStatus.connected;

    ref.listen<SensorStatus>(sensorStatusProvider, (previous, next) {
      if (previous == null) return;
      _showSensorAlertIfNeeded(previous, next);
    });

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) async => await _restorePortraitMode(),
      child: Scaffold(
        backgroundColor: _T.bg,
        body: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    Expanded(child: _cameraView()),
                    const SizedBox(width: 10),
                    _rightControlPanel(isConnected),
                  ],
                ),
              ),
              // Sensor bar (centered top)
              Positioned(
                top: 12,
                left: 110,
                right: 110,
                child: _sensorStatusBar(),
              ),
              // Back button
              Positioned(
                top: 12,
                left: 10,
                child: _topButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  label: 'Back',
                  onTap: () async {
                    await _restorePortraitMode();
                    if (context.mounted) Navigator.of(context).pop();
                  },
                ),
              ),
              // Mode button
              Positioned(
                top: 12,
                right: 10,
                child: _topButton(
                  icon: Icons.tune_rounded,
                  label: 'Mode',
                  color: _T.cyan,
                  onTap: _openModeMenu,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
