
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AutoStatusScreen extends StatefulWidget {
  const AutoStatusScreen({Key? key}) : super(key: key);

  @override
  State<AutoStatusScreen> createState() => _AutoStatusScreenState();
}

class _AutoStatusScreenState extends State<AutoStatusScreen> {
  static const String raspberryModeBaseUrl = 'http://192.168.4.2:5050';
  static const String raspberryCameraBaseUrl = 'http://192.168.4.2:5000';

  static const Color _bgColor = Color(0xFF020712);
  static const Color _panelColor = Color(0xFF07111F);
  static const Color _panelColor2 = Color(0xFF0D1B2E);
  static const Color _borderColor = Color(0xFF1E3858);
  static const Color _cyanColor = Color(0xFF00B4FF);
  static const Color _mutedColor = Color(0xFF9AA8BA);

  Timer? _timer;

  bool _loading = true;
  bool _online = false;
  String _selectedCamera = 'front';

  String _mode = 'UNKNOWN';
  String _stage = 'Waiting for auto status...';
  String _action = 'No action yet';
  String _decision = 'No decision yet';
  String _error = '';
  String _lastUpdate = '';

  List<AutoTrackItem> _track = [];

  @override
  void initState() {
    super.initState();
    _fetchAutoStatus();

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _fetchAutoStatus(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _cameraUrl {
    final ts = DateTime.now().millisecondsSinceEpoch;

    if (_selectedCamera == 'arm') {
      return '$raspberryCameraBaseUrl/arm_snapshot?ts=$ts';
    }

    return '$raspberryCameraBaseUrl/front_snapshot?ts=$ts';
  }

  Future<void> _fetchAutoStatus() async {
    try {
      final response = await http
          .get(Uri.parse('$raspberryModeBaseUrl/auto_status'))
          .timeout(const Duration(seconds: 3));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        _setOffline('HTTP ${response.statusCode}');
        return;
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        _setOffline('Invalid JSON');
        return;
      }

      final parsedTrack = _parseTrack(decoded);

      setState(() {
        _loading = false;
        _online = decoded['ok'] == true || decoded['mode'] != null;

        _mode = (decoded['mode'] ?? 'AUTO').toString();
        _stage = _readString(
          decoded,
          ['stage', 'current_stage', 'state', 'phase'],
          fallback: 'AUTO',
        );

        _action = _readString(
          decoded,
          ['action', 'current_action', 'doing', 'what_doing'],
          fallback: 'No current action',
        );

        _decision = _readString(
          decoded,
          ['decision', 'current_decision', 'last_decision'],
          fallback: 'No decision yet',
        );

        _error = _readString(
          decoded,
          ['error', 'last_error', 'exception'],
          fallback: '',
        );

        _lastUpdate = _readString(
          decoded,
          ['time', 'timestamp', 'last_update'],
          fallback: DateTime.now().toLocal().toString().split('.').first,
        );

        _track = parsedTrack;
      });
    } catch (e) {
      _setOffline(e.toString());
    }
  }

  void _setOffline(String message) {
    setState(() {
      _loading = false;
      _online = false;
      _error = message;
      _lastUpdate = DateTime.now().toLocal().toString().split('.').first;
    });
  }

  String _readString(
    Map<String, dynamic> json,
    List<String> keys, {
    required String fallback,
  }) {
    for (final key in keys) {
      final value = json[key];

      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }

    return fallback;
  }

  List<AutoTrackItem> _parseTrack(Map<String, dynamic> json) {
    final dynamic raw =
        json['track'] ?? json['events'] ?? json['logs'] ?? json['timeline'];

    if (raw is List) {
      return raw.map((item) {
        if (item is Map<String, dynamic>) {
          return AutoTrackItem.fromJson(item);
        }

        return AutoTrackItem(
          type: 'info',
          message: item.toString(),
          stage: _stage,
          time: '',
          important: false,
        );
      }).toList();
    }

    final fallbackMessages = <AutoTrackItem>[];

    final action = _readString(
      json,
      ['action', 'current_action', 'doing', 'what_doing'],
      fallback: '',
    );

    final decision = _readString(
      json,
      ['decision', 'current_decision', 'last_decision'],
      fallback: '',
    );

    final error = _readString(
      json,
      ['error', 'last_error', 'exception'],
      fallback: '',
    );

    if (action.isNotEmpty) {
      fallbackMessages.add(
        AutoTrackItem(
          type: 'action',
          message: action,
          stage: _stage,
          time: _lastUpdate,
          important: false,
        ),
      );
    }

    if (decision.isNotEmpty) {
      fallbackMessages.add(
        AutoTrackItem(
          type: 'decision',
          message: decision,
          stage: _stage,
          time: _lastUpdate,
          important: true,
        ),
      );
    }

    if (error.isNotEmpty) {
      fallbackMessages.add(
        AutoTrackItem(
          type: 'error',
          message: error,
          stage: _stage,
          time: _lastUpdate,
          important: true,
        ),
      );
    }

    return fallbackMessages;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 0,
        title: const Text(
          'Auto Status Track',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: _fetchAutoStatus,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _fetchAutoStatus,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 92),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _topCameraSwitcher(),
                  const SizedBox(height: 12),
                  _cameraPreview(),
                  const SizedBox(height: 14),
                  _summaryCards(),
                  const SizedBox(height: 14),
                  _decisionPanel(),
                  const SizedBox(height: 14),
                  _trackPanel(),
                ],
              ),
            ),
          ),
          _bottomStageBar(),
        ],
      ),
    );
  }

  Widget _topCameraSwitcher() {
    return Row(
      children: [
        _cameraButton(
          title: 'Robot Camera',
          value: 'front',
          icon: Icons.videocam,
        ),
        const SizedBox(width: 8),
        _cameraButton(
          title: 'Arm Camera',
          value: 'arm',
          icon: Icons.precision_manufacturing,
        ),
        const Spacer(),
        _connectionChip(),
      ],
    );
  }

  Widget _cameraButton({
    required String title,
    required String value,
    required IconData icon,
  }) {
    final selected = _selectedCamera == value;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedCamera = value;
        });
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? _cyanColor.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? _cyanColor.withValues(alpha: 0.75)
                : Colors.white.withValues(alpha: 0.12),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 17,
              color: selected ? _cyanColor : Colors.white70,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                color: selected ? _cyanColor : Colors.white70,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _connectionChip() {
    final color = _online ? Colors.greenAccent : Colors.redAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        _online ? 'ONLINE' : 'OFFLINE',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _cameraPreview() {
    return Container(
      height: 210,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _cyanColor.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: _cyanColor.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.network(
              _cameraUrl,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (_, __, ___) {
                return Container(
                  color: Colors.black,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.videocam_off,
                        color: Colors.white30,
                        size: 44,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedCamera == 'front'
                            ? 'Robot camera not available'
                            : 'Arm camera not available',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Positioned(
            left: 12,
            top: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
              child: Text(
                _selectedCamera == 'front' ? 'Robot View' : 'Arm View',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCards() {
    return Row(
      children: [
        Expanded(
          child: _smallStatusCard(
            title: 'Mode',
            value: _mode,
            icon: Icons.memory,
            color: _cyanColor,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _smallStatusCard(
            title: 'Last Update',
            value: _lastUpdate.isEmpty ? 'Waiting' : _lastUpdate,
            icon: Icons.update,
            color: Colors.orangeAccent,
          ),
        ),
      ],
    );
  }

  Widget _smallStatusCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: _panelColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 23),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _mutedColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _decisionPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _cyanColor.withValues(alpha: 0.16),
            _panelColor2,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _cyanColor.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            icon: Icons.psychology_alt,
            title: 'Current Robot Decision',
            color: _cyanColor,
          ),
          const SizedBox(height: 10),
          Text(
            _decision,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          _infoRow('Current Action', _action),
          if (_error.isNotEmpty) ...[
            const SizedBox(height: 8),
            _infoRow('Error', _error, color: Colors.redAccent),
          ],
        ],
      ),
    );
  }

  Widget _trackPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _panelColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _borderColor.withValues(alpha: 0.95),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            icon: Icons.timeline,
            title: 'Automation Track',
            color: Colors.greenAccent,
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_track.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'No track messages yet',
                  style: TextStyle(
                    color: Colors.white54,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
          else
            Column(
              children: _track
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _trackItem(item),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _trackItem(AutoTrackItem item) {
    final color = item.color;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: item.important
            ? color.withValues(alpha: 0.13)
            : Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.important
              ? color.withValues(alpha: 0.50)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(item.icon, color: color, size: 22),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.header,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  item.message,
                  style: const TextStyle(
                    color: Colors.white,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (item.stage.isNotEmpty || item.time.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    '${item.stage.isEmpty ? '' : 'Stage: ${item.stage}'}'
                    '${item.stage.isNotEmpty && item.time.isNotEmpty ? ' · ' : ''}'
                    '${item.time}',
                    style: const TextStyle(
                      color: _mutedColor,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 23),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String title, String value, {Color color = _mutedColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$title: ',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
              fontSize: 12,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _bottomStageBar() {
    return Positioned(
      left: 14,
      right: 14,
      bottom: 14,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _panelColor2.withValues(alpha: 0.97),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _cyanColor.withValues(alpha: 0.45),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.flag_circle, color: _cyanColor, size: 24),
            const SizedBox(width: 9),
            const Text(
              'Current Stage:',
              style: TextStyle(
                color: _mutedColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _stage,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AutoTrackItem {
  final String type;
  final String message;
  final String stage;
  final String time;
  final bool important;

  const AutoTrackItem({
    required this.type,
    required this.message,
    required this.stage,
    required this.time,
    required this.important,
  });

  factory AutoTrackItem.fromJson(Map<String, dynamic> json) {
    final type = (json['type'] ?? json['level'] ?? json['kind'] ?? 'info')
        .toString()
        .toLowerCase();

    final message = (json['message'] ??
            json['text'] ??
            json['description'] ??
            json['action'] ??
            json['decision'] ??
            '')
        .toString();

    final stage = (json['stage'] ?? json['current_stage'] ?? '').toString();

    final time = (json['time'] ?? json['timestamp'] ?? '').toString();

    final important = json['important'] == true ||
        type.contains('decision') ||
        type.contains('error') ||
        type.contains('warning');

    return AutoTrackItem(
      type: type,
      message: message,
      stage: stage,
      time: time,
      important: important,
    );
  }

  String get header {
    if (type.contains('decision')) return 'Decision';
    if (type.contains('error')) return 'Error';
    if (type.contains('warning')) return 'Warning';
    if (type.contains('action')) return 'Action';
    if (type.contains('camera')) return 'Camera';
    if (type.contains('sensor')) return 'Sensor';
    return 'Info';
  }

  IconData get icon {
    if (type.contains('decision')) return Icons.psychology_alt;
    if (type.contains('error')) return Icons.error;
    if (type.contains('warning')) return Icons.warning_amber;
    if (type.contains('action')) return Icons.play_circle;
    if (type.contains('camera')) return Icons.videocam;
    if (type.contains('sensor')) return Icons.sensors;
    return Icons.info;
  }

  Color get color {
    if (type.contains('decision')) return Colors.cyanAccent;
    if (type.contains('error')) return Colors.redAccent;
    if (type.contains('warning')) return Colors.orangeAccent;
    if (type.contains('action')) return Colors.greenAccent;
    if (type.contains('camera')) return Colors.purpleAccent;
    if (type.contains('sensor')) return Colors.blueAccent;
    return Colors.white70;
  }
}
