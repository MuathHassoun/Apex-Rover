import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/robot_model.dart';
import '../providers/connection_provider.dart';

class TestBlocksScreen extends ConsumerStatefulWidget {
  const TestBlocksScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<TestBlocksScreen> createState() => _TestBlocksScreenState();
}

class _TestBlocksScreenState extends ConsumerState<TestBlocksScreen> {
  static const Color _bgColor = Color(0xFF020712);
  static const Color _panelColor = Color(0xFF07111F);
  static const Color _panelColor2 = Color(0xFF0D1B2E);
  static const Color _borderColor = Color(0xFF1E3858);
  static const Color _cyanColor = Color(0xFF00B4FF);
  static const Color _greenColor = Color(0xFF00E676);
  static const Color _blueColor = Color(0xFF448AFF);
  static const Color _orangeColor = Color(0xFFFFB74D);
  static const Color _redColor = Color(0xFFFF5252);
  static const Color _mutedColor = Color(0xFF9AA8BA);

  int _turnDegree = 90;
  int _goAmount = 20;
  int _jackAmount = 4;

  final List<String> _logs = [];
  bool _listenerAttached = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _attachWebSocketListener();
    });
  }

  @override
  void dispose() {
    try {
      if (_listenerAttached) {
        ref
            .read(connectionStatusProvider.notifier)
            .wsService
            .removeListener(_handleIncomingMessage);
      }
    } catch (_) {}

    super.dispose();
  }

  void _attachWebSocketListener() {
    if (_listenerAttached) return;

    try {
      ref.read(connectionStatusProvider.notifier).wsService.addListener(_handleIncomingMessage);

      _listenerAttached = true;
    } catch (_) {}
  }

  void _handleIncomingMessage(dynamic message) {
    final text = message.toString().trim();

    if (text.isEmpty) return;

    if (text.startsWith('SENSOR:')) {
      return;
    }

    if (text.startsWith('ACK:') ||
        text.startsWith('ERR:') ||
        text.startsWith('ERROR:') ||
        text.contains('"event":"bridge_event"') ||
        text.contains('"event":"serial_line"')) {
      _addLog('RX', text);
    }
  }

  void _addLog(String tag, String message) {
    if (!mounted) return;

    final now = TimeOfDay.now();
    final time = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    setState(() {
      _logs.insert(0, '[$time] $tag: $message');

      if (_logs.length > 40) {
        _logs.removeLast();
      }
    });
  }

  Future<void> _sendCommand(String command) async {
    final connectionStatus = ref.read(connectionStatusProvider);

    if (connectionStatus != ConnectionStatus.connected) {
      _addLog('WARN', 'Not connected. Connect WebSocket first.');
      _showSnack('Connect WebSocket first', isError: true);
      return;
    }

    try {
      final controlCommand = ControlCommand(
        commandId: DateTime.now().millisecondsSinceEpoch.toString(),
        commandType: command,
        parameters: const {},
        timestamp: DateTime.now(),
      );

      await ref.read(connectionStatusProvider.notifier).sendCommand(controlCommand);

      _addLog('TX', command);
      _showSnack('Sent: $command');
    } catch (e) {
      _addLog('ERROR', e.toString());
      _showSnack('Failed to send command', isError: true);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? _redColor : _panelColor2,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 900),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final connectionStatus = ref.watch(connectionStatusProvider);
    final connected = connectionStatus == ConnectionStatus.connected;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 110),
        children: [
          _buildHeader(connected),
          const SizedBox(height: 14),
          _buildSection(
            title: 'Auto Scenarios',
            subtitle: 'Test full Mega state machines',
            icon: Icons.auto_mode_rounded,
            child: Column(
              children: [
                Expanded(
                  child: _commandButton(
                    label: 'FULL SCENARIO: UP/DOWN Stairs',
                    command: 'AUTO:FULL_SCENARIO',
                    icon: Icons.stairs_rounded,
                    color: _blueColor,
                    important: true,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _commandButton(
                        label: 'Up Stairs',
                        command: 'AUTO:UP_STAIRS',
                        icon: Icons.stairs_rounded,
                        color: _greenColor,
                        important: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _commandButton(
                        label: 'Down Stairs',
                        command: 'AUTO:DOWN_STAIRS',
                        icon: Icons.south_rounded,
                        color: _orangeColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _commandButton(
                  label: 'Stop Auto / Block',
                  command: 'BLOCK:STOP',
                  icon: Icons.stop_circle_rounded,
                  color: _redColor,
                  fullWidth: true,
                  important: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _buildSection(
            title: 'Turn Block',
            subtitle: 'Mega uses MPU yaw for turning',
            icon: Icons.rotate_90_degrees_ccw_rounded,
            child: Column(
              children: [
                _sliderTile(
                  label: 'Degree',
                  value: _turnDegree,
                  min: 0,
                  max: 360,
                  divisions: 36,
                  suffix: 'deg',
                  onChanged: (v) {
                    setState(() {
                      _turnDegree = v.round();
                    });
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _commandButton(
                        label: 'Turn Left',
                        command: 'BLOCK:TURN:LEFT:$_turnDegree',
                        icon: Icons.turn_left_rounded,
                        color: _cyanColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _commandButton(
                        label: 'Turn Right',
                        command: 'BLOCK:TURN:RIGHT:$_turnDegree',
                        icon: Icons.turn_right_rounded,
                        color: _cyanColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _buildSection(
            title: 'Go Block',
            subtitle: 'Time-based amount for forward/backward movement',
            icon: Icons.open_with_rounded,
            child: Column(
              children: [
                _sliderTile(
                  label: 'Amount',
                  value: _goAmount,
                  min: 1,
                  max: 200,
                  divisions: 199,
                  suffix: 'unit',
                  onChanged: (v) {
                    setState(() {
                      _goAmount = v.round();
                    });
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _commandButton(
                        label: 'Forward',
                        command: 'BLOCK:GO:FORWARD:$_goAmount',
                        icon: Icons.arrow_upward_rounded,
                        color: _greenColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _commandButton(
                        label: 'Backward',
                        command: 'BLOCK:GO:BACKWARD:$_goAmount',
                        icon: Icons.arrow_downward_rounded,
                        color: _orangeColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _buildSection(
            title: 'Jack Blocks',
            subtitle: 'Time-based jack extend/retract test',
            icon: Icons.vertical_align_center_rounded,
            child: Column(
              children: [
                _sliderTile(
                  label: 'Jack Amount',
                  value: _jackAmount,
                  min: 1,
                  max: 20,
                  divisions: 19,
                  suffix: 'unit',
                  onChanged: (v) {
                    setState(() {
                      _jackAmount = v.round();
                    });
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _commandButton(
                        label: 'Rear Extend',
                        command: 'BLOCK:JACK:REAR:EXTEND:$_jackAmount',
                        icon: Icons.keyboard_double_arrow_down_rounded,
                        color: _cyanColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _commandButton(
                        label: 'Rear Retract',
                        command: 'BLOCK:JACK:REAR:RETRACT:$_jackAmount',
                        icon: Icons.keyboard_double_arrow_up_rounded,
                        color: _cyanColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _commandButton(
                        label: 'Front Extend',
                        command: 'BLOCK:JACK:FRONT:EXTEND:$_jackAmount',
                        icon: Icons.keyboard_double_arrow_down_rounded,
                        color: _greenColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _commandButton(
                        label: 'Front Retract',
                        command: 'BLOCK:JACK:FRONT:RETRACT:$_jackAmount',
                        icon: Icons.keyboard_double_arrow_up_rounded,
                        color: _greenColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _buildSection(
            title: 'Emergency',
            subtitle: 'Direct stop commands',
            icon: Icons.emergency_rounded,
            child: Row(
              children: [
                Expanded(
                  child: _commandButton(
                    label: 'STOP',
                    command: 'STOP',
                    icon: Icons.stop_rounded,
                    color: _redColor,
                    important: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _commandButton(
                    label: 'Jack Stop',
                    command: 'JACK:ALL:STOP',
                    icon: Icons.pan_tool_alt_rounded,
                    color: _redColor,
                    important: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _buildLogs(),
        ],
      ),
    );
  }

  Widget _buildHeader(bool connected) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_panelColor, _panelColor2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: connected
              ? _greenColor.withValues(alpha: 0.45)
              : _borderColor.withValues(alpha: 0.95),
        ),
        boxShadow: [
          BoxShadow(
            color: _cyanColor.withValues(alpha: 0.07),
            blurRadius: 18,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _cyanColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _cyanColor.withValues(alpha: 0.35),
              ),
            ),
            child: const Icon(
              Icons.memory_rounded,
              color: _cyanColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LEGO Blocks Test',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Test Mega blocks from mobile',
                  style: TextStyle(
                    color: _mutedColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: connected
                  ? _greenColor.withValues(alpha: 0.13)
                  : _redColor.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: connected
                    ? _greenColor.withValues(alpha: 0.45)
                    : _redColor.withValues(alpha: 0.45),
              ),
            ),
            child: Text(
              connected ? 'Connected' : 'Offline',
              style: TextStyle(
                color: connected ? _greenColor : _redColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_panelColor, _panelColor2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _borderColor.withValues(alpha: 0.90),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: _cyanColor, size: 22),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: _mutedColor,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _sliderTile({
    required String label,
    required int value,
    required int min,
    required int max,
    required int divisions,
    required String suffix,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      decoration: BoxDecoration(
        color: _bgColor.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _borderColor.withValues(alpha: 0.75),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '$value $suffix',
                style: const TextStyle(
                  color: _cyanColor,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Slider(
            value: value.toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: divisions,
            label: '$value',
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _commandButton({
    required String label,
    required String command,
    required IconData icon,
    required Color color,
    bool fullWidth = false,
    bool important = false,
  }) {
    return GestureDetector(
      onTap: () => _sendCommand(command),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: fullWidth ? double.infinity : null,
        constraints: const BoxConstraints(
          minHeight: 62,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: important ? 0.18 : 0.12),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: color.withValues(alpha: important ? 0.60 : 0.38),
          ),
          boxShadow: [
            if (important)
              BoxShadow(
                color: color.withValues(alpha: 0.12),
                blurRadius: 16,
              ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 21),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogs() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _panelColor.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _borderColor.withValues(alpha: 0.85),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.terminal_rounded,
                color: _cyanColor,
                size: 21,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Command / ACK Log',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _logs.clear();
                  });
                },
                child: const Text('Clear'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_logs.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _bgColor.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'No commands yet.',
                style: TextStyle(
                  color: _mutedColor,
                  fontSize: 12,
                ),
              ),
            )
          else
            ..._logs.map(
              (log) => Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 7),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _bgColor.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: log.contains('ERR') || log.contains('ERROR')
                        ? _redColor.withValues(alpha: 0.35)
                        : _borderColor.withValues(alpha: 0.45),
                  ),
                ),
                child: Text(
                  log,
                  style: TextStyle(
                    color: log.contains('ERR') || log.contains('ERROR')
                        ? _redColor
                        : Colors.white.withValues(alpha: 0.88),
                    fontSize: 11,
                    height: 1.25,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
