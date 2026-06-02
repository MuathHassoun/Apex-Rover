import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

import '../config/constants.dart';

class RaspberryModeStatus {
  final bool ok;
  final String mode;
  final bool manualDualCameraRunning;
  final bool sensorBridgeRunning;
  final bool autoFrontCameraRunning;
  final bool autoBrainRunning;
  final String message;

  const RaspberryModeStatus({
    required this.ok,
    required this.mode,
    required this.manualDualCameraRunning,
    required this.sensorBridgeRunning,
    required this.autoFrontCameraRunning,
    required this.autoBrainRunning,
    required this.message,
  });

  factory RaspberryModeStatus.fromJson(Map<String, dynamic> json) {
    return RaspberryModeStatus(
      ok: json['ok'] == true,
      mode: (json['mode'] ?? 'UNKNOWN').toString(),
      manualDualCameraRunning:
          json['manual_dual_camera_running'] == true || json['manual_camera_running'] == true,
      sensorBridgeRunning:
          json['sensor_bridge_running'] == true || json['manual_sensor_running'] == true,
      autoFrontCameraRunning: json['auto_front_camera_running'] == true,
      autoBrainRunning: json['auto_brain_running'] == true || json['auto_running'] == true,
      message: (json['message'] ?? '').toString(),
    );
  }

  static RaspberryModeStatus offline([String message = 'Raspberry offline']) {
    return RaspberryModeStatus(
      ok: false,
      mode: 'OFFLINE',
      manualDualCameraRunning: false,
      sensorBridgeRunning: false,
      autoFrontCameraRunning: false,
      autoBrainRunning: false,
      message: message,
    );
  }
}

class RaspberryModeService {
  final Logger _logger = Logger();
  String? _resolvedBaseUrl;

  Future<RaspberryModeStatus> getStatus() async {
    return _request('/status');
  }

  Future<RaspberryModeStatus> setManualMode() async {
    return _request('/mode/manual');
  }

  Future<RaspberryModeStatus> setAutoMode() async {
    return _request('/mode/auto');
  }

  Future<RaspberryModeStatus> stopAutoAndReturnManual() async {
    return _request('/mode/stop');
  }

  Future<RaspberryModeStatus> emergencyStop() async {
    return _request('/robot/stop');
  }

  Future<RaspberryModeStatus> _request(String path) async {
    try {
      final baseUrl = await _resolveBaseUrl();
      final url = '$baseUrl$path';
      final response = await http.get(Uri.parse(url)).timeout(AppConstants.raspberryRequestTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return RaspberryModeStatus.offline(
          'Raspberry HTTP ${response.statusCode}',
        );
      }

      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        return RaspberryModeStatus.fromJson(decoded);
      }

      return RaspberryModeStatus.offline('Invalid Raspberry response');
    } catch (e) {
      _logger.e('Raspberry mode request failed: $e');
      return RaspberryModeStatus.offline(e.toString());
    }
  }

  Future<String> _resolveBaseUrl() async {
    if (_resolvedBaseUrl != null) {
      return _resolvedBaseUrl!;
    }

    final triedIps = <String>{};
    final allIps = <String>[...AppConstants.raspberryCandidateIps];

    for (var i = 1; i <= 254; i++) {
      final ip = '192.168.4.$i';
      if (allIps.contains(ip)) continue;
      allIps.add(ip);
    }

    for (final ip in allIps) {
      if (triedIps.contains(ip)) continue;
      triedIps.add(ip);
      final baseUrl = AppConstants.raspberryBaseUrl(ip);

      try {
        final response = await http
            .get(Uri.parse('$baseUrl/status'))
            .timeout(AppConstants.raspberryProbeTimeout);

        if (response.statusCode >= 200 && response.statusCode < 300) {
          _resolvedBaseUrl = baseUrl;
          _logger.i('Raspberry found at $baseUrl');
          return _resolvedBaseUrl!;
        }
      } catch (e) {
        _logger.w('Raspberry probe failed for $baseUrl: $e');
      }
    }

    throw Exception('No reachable Raspberry host found');
  }
}
