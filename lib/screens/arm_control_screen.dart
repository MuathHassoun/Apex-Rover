import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/theme.dart';
import '../models/robot_model.dart';
import '../providers/connection_provider.dart';
import '../providers/uno_motion_settings_provider.dart';

class ArmControlScreen extends ConsumerStatefulWidget {
  const ArmControlScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ArmControlScreen> createState() => _ArmControlScreenState();
}

class _ArmControlScreenState extends ConsumerState<ArmControlScreen> {
  String _lastAction = 'Ready';
  bool _isAssistRunning = false;

  bool get _isConnected => ref.read(connectionStatusProvider) == ConnectionStatus.connected;

  Future<void> _sendArmCommand(
    String command, {
    bool showSnack = true,
  }) async {
    final isConnected = ref.read(connectionStatusProvider) == ConnectionStatus.connected;

    if (!mounted) return;

    setState(() {
      _lastAction = command.replaceAll('ARM:', '').replaceAll(':', ' ');
    });

    if (!isConnected) {
      if (showSnack) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Not connected to robot'),
            backgroundColor: Colors.redAccent,
            duration: Duration(seconds: 1),
          ),
        );
      }
      return;
    }

    final armCommand = ControlCommand(
      commandId: 'arm_${DateTime.now().millisecondsSinceEpoch}',
      commandType: command,
      parameters: const {
        'robotId': 'robot_001',
      },
      timestamp: DateTime.now(),
    );

    await ref.read(connectionStatusProvider.notifier).sendCommand(armCommand);

    if (!mounted || !showSnack) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Arm command sent: $command'),
        duration: const Duration(milliseconds: 500),
      ),
    );
  }

  Future<void> _runLiftAssist() async {
    if (_isAssistRunning) return;

    final isConnected = ref.read(connectionStatusProvider) == ConnectionStatus.connected;

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

    final settings = ref.read(unoMotionSettingsProvider);

    final int normalStep = settings.servoAngleStep;
    final int safeStep = normalStep <= 2 ? normalStep : 2;

    setState(() {
      _isAssistRunning = true;
      _lastAction = 'LIFT ASSIST START';
    });

    final sequence = <String>[
      'ARM:WRIST:UP:$safeStep',
      'ARM:ELBOW:UP:$safeStep',
      'ARM:SHOULDER:UP:$safeStep',
      'ARM:ELBOW:UP:$safeStep',
      'ARM:SHOULDER:UP:$safeStep',
      'ARM:WRIST:UP:$safeStep',
      'ARM:ELBOW:UP:$safeStep',
      'ARM:SHOULDER:UP:$safeStep',
    ];

    for (final command in sequence) {
      if (!mounted) return;
      await _sendArmCommand(command, showSnack: false);
      await Future.delayed(const Duration(milliseconds: 170));
    }

    if (!mounted) return;

    setState(() {
      _isAssistRunning = false;
      _lastAction = 'LIFT ASSIST DONE';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Lift Assist done with safe step: $safeStep°'),
        backgroundColor: Colors.green.shade700,
        duration: const Duration(milliseconds: 900),
      ),
    );
  }

  Future<void> _runLowerAssist() async {
    if (_isAssistRunning) return;

    final isConnected = ref.read(connectionStatusProvider) == ConnectionStatus.connected;

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

    final settings = ref.read(unoMotionSettingsProvider);

    final int normalStep = settings.servoAngleStep;
    final int safeStep = normalStep <= 2 ? normalStep : 2;

    setState(() {
      _isAssistRunning = true;
      _lastAction = 'LOWER ASSIST START';
    });

    final sequence = <String>[
      'ARM:SHOULDER:DOWN:$safeStep',
      'ARM:ELBOW:DOWN:$safeStep',
      'ARM:WRIST:DOWN:$safeStep',
      'ARM:SHOULDER:DOWN:$safeStep',
      'ARM:ELBOW:DOWN:$safeStep',
      'ARM:WRIST:DOWN:$safeStep',
    ];

    for (final command in sequence) {
      if (!mounted) return;
      await _sendArmCommand(command, showSnack: false);
      await Future.delayed(const Duration(milliseconds: 170));
    }

    if (!mounted) return;

    setState(() {
      _isAssistRunning = false;
      _lastAction = 'LOWER ASSIST DONE';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Lower Assist done with safe step: $safeStep°'),
        backgroundColor: Colors.orange.shade700,
        duration: const Duration(milliseconds: 900),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = ref.watch(connectionStatusProvider) == ConnectionStatus.connected;

    final settings = ref.watch(unoMotionSettingsProvider);
    final stepperSteps = settings.stepperSteps;
    final servoStep = settings.servoAngleStep;

    final int safeServoStep = servoStep <= 2 ? servoStep : 2;

    return Scaffold(
      backgroundColor: const Color(0xFF050B12),
      appBar: AppBar(
        title: const Text('Arm Control'),
        backgroundColor: const Color(0xFF07111F),
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            tooltip: 'Stop Arm',
            onPressed: isConnected ? () => _sendArmCommand('ARM:STOP') : null,
            icon: const Icon(Icons.stop_circle),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StatusCard(
                isConnected: isConnected,
                lastAction: _lastAction,
                stepperSteps: stepperSteps,
                servoStep: servoStep,
                isAssistRunning: _isAssistRunning,
              ),
              const SizedBox(height: AppSpacing.lg),
              _SectionTitle(
                title: 'Lift Assist Test',
                subtitle:
                    'Use small staged movements to reduce shoulder and elbow shaking under load',
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _LargeActionButton(
                      label: _isAssistRunning ? 'RUNNING...' : 'LIFT ASSIST',
                      subtitle: 'Safe step $safeServoStep°',
                      icon: Icons.upload_rounded,
                      color: Colors.greenAccent,
                      enabled: isConnected && !_isAssistRunning,
                      onTap: _runLiftAssist,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _LargeActionButton(
                      label: _isAssistRunning ? 'RUNNING...' : 'LOWER ASSIST',
                      subtitle: 'Safe step $safeServoStep°',
                      icon: Icons.download_rounded,
                      color: Colors.orangeAccent,
                      enabled: isConnected && !_isAssistRunning,
                      onTap: _runLowerAssist,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _InfoBox(
                text:
                    'Lift Assist sends small commands in sequence: wrist, elbow, shoulder. This may reduce shaking, but if the servo torque or power is weak, the mechanical issue will still remain.',
              ),
              const SizedBox(height: AppSpacing.xl),
              _SectionTitle(
                title: 'Base Stepper',
                subtitle: 'Arm base moves $stepperSteps steps per click',
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _ArmCommandButton(
                      label: 'BASE LEFT\n$stepperSteps',
                      icon: Icons.rotate_left,
                      color: Colors.cyanAccent,
                      enabled: isConnected && !_isAssistRunning,
                      onTap: () => _sendArmCommand(
                        'ARM:BASE:STEP_LEFT:$stepperSteps',
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _ArmCommandButton(
                      label: 'STOP',
                      icon: Icons.stop_circle,
                      color: Colors.redAccent,
                      enabled: isConnected,
                      onTap: () => _sendArmCommand('ARM:STOP'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _ArmCommandButton(
                      label: 'BASE RIGHT\n$stepperSteps',
                      icon: Icons.rotate_right,
                      color: Colors.cyanAccent,
                      enabled: isConnected && !_isAssistRunning,
                      onTap: () => _sendArmCommand(
                        'ARM:BASE:STEP_RIGHT:$stepperSteps',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              _JointControlSection(
                title: 'Shoulder',
                subtitle: 'Main load servo. Use small steps when the arm carries weight.',
                upLabel: 'SH UP\n$servoStep°',
                downLabel: 'SH DOWN\n$servoStep°',
                upCommand: 'ARM:SHOULDER:UP:$servoStep',
                downCommand: 'ARM:SHOULDER:DOWN:$servoStep',
                color: Colors.greenAccent,
                enabled: isConnected && !_isAssistRunning,
                onCommand: _sendArmCommand,
              ),
              const SizedBox(height: AppSpacing.xl),
              _JointControlSection(
                title: 'Elbow',
                subtitle: 'Second main load servo. If shaking appears, use Lift Assist.',
                upLabel: 'ELB UP\n$servoStep°',
                downLabel: 'ELB DOWN\n$servoStep°',
                upCommand: 'ARM:ELBOW:UP:$servoStep',
                downCommand: 'ARM:ELBOW:DOWN:$servoStep',
                color: Colors.amberAccent,
                enabled: isConnected && !_isAssistRunning,
                onCommand: _sendArmCommand,
              ),
              const SizedBox(height: AppSpacing.xl),
              _JointControlSection(
                title: 'Wrist',
                subtitle: 'Adjust object angle before lifting.',
                upLabel: 'WR UP\n$servoStep°',
                downLabel: 'WR DOWN\n$servoStep°',
                upCommand: 'ARM:WRIST:UP:$servoStep',
                downCommand: 'ARM:WRIST:DOWN:$servoStep',
                color: Colors.purpleAccent,
                enabled: isConnected && !_isAssistRunning,
                onCommand: _sendArmCommand,
              ),
              const SizedBox(height: AppSpacing.xl),
              _JointControlSection(
                title: 'AUX',
                subtitle: 'Auxiliary servo axis.',
                upLabel: 'AUX UP\n$servoStep°',
                downLabel: 'AUX DOWN\n$servoStep°',
                upCommand: 'ARM:AUX:UP:$servoStep',
                downCommand: 'ARM:AUX:DOWN:$servoStep',
                color: Colors.blueAccent,
                enabled: isConnected && !_isAssistRunning,
                onCommand: _sendArmCommand,
              ),
              const SizedBox(height: AppSpacing.xl),
              _SectionTitle(
                title: 'Gripper',
                subtitle: 'Open and close object gripper',
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _ArmCommandButton(
                      label: 'OPEN',
                      icon: Icons.back_hand,
                      color: Colors.lightGreenAccent,
                      enabled: isConnected && !_isAssistRunning,
                      onTap: () => _sendArmCommand('ARM:GRIPPER:OPEN'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _ArmCommandButton(
                      label: 'CLOSE',
                      icon: Icons.pan_tool,
                      color: Colors.redAccent,
                      enabled: isConnected && !_isAssistRunning,
                      onTap: () => _sendArmCommand('ARM:GRIPPER:CLOSE'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              _SectionTitle(
                title: 'Safe Positions',
                subtitle: 'Use READY before testing, HOME when done.',
              ),
              const SizedBox(height: AppSpacing.md),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                childAspectRatio: 1.65,
                children: [
                  _QuickActionButton(
                    label: 'READY',
                    icon: Icons.play_circle,
                    color: Colors.greenAccent,
                    enabled: isConnected && !_isAssistRunning,
                    onTap: () => _sendArmCommand('ARM:READY'),
                  ),
                  _QuickActionButton(
                    label: 'HOME',
                    icon: Icons.home,
                    color: Colors.white,
                    enabled: isConnected && !_isAssistRunning,
                    onTap: () => _sendArmCommand('ARM:HOME'),
                  ),
                  _QuickActionButton(
                    label: 'DROP',
                    icon: Icons.home,
                    color: Colors.orangeAccent,
                    enabled: isConnected,
                    onTap: () => _sendArmCommand('ARM:DROP'),
                  ),
                  _QuickActionButton(
                    label: 'ARM STOP',
                    icon: Icons.stop_circle,
                    color: Colors.redAccent,
                    enabled: isConnected,
                    onTap: () => _sendArmCommand('ARM:STOP'),
                  ),
                  _QuickActionButton(
                    label: 'CONFIG STATUS',
                    icon: Icons.info,
                    color: Colors.cyanAccent,
                    enabled: isConnected && !_isAssistRunning,
                    onTap: () => _sendArmCommand('ARM:CONFIG:STATUS'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final bool isConnected;
  final String lastAction;
  final int stepperSteps;
  final int servoStep;
  final bool isAssistRunning;

  const _StatusCard({
    required this.isConnected,
    required this.lastAction,
    required this.stepperSteps,
    required this.servoStep,
    required this.isAssistRunning,
  });

  @override
  Widget build(BuildContext context) {
    final color = isConnected ? Colors.greenAccent : Colors.redAccent;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D1421), Color(0xFF1A2540)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Icon(
            isConnected ? Icons.check_circle : Icons.error,
            color: color,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAssistRunning
                      ? 'Assist Running'
                      : isConnected
                          ? 'Arm Ready'
                          : 'Not Connected',
                  style: TextStyle(
                    color: isAssistRunning ? Colors.orangeAccent : color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Last: $lastAction',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Stepper: $stepperSteps steps · Servo: $servoStep°',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.precision_manufacturing,
            color: Colors.cyanAccent,
            size: 30,
          ),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String text;

  const _InfoBox({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.orangeAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(
          color: Colors.orangeAccent.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            color: Colors.orangeAccent,
            size: 22,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
                height: 1.35,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.heading3.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: AppTextStyles.bodySmall.copyWith(
            color: Colors.white.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }
}

class _JointControlSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final String upLabel;
  final String downLabel;
  final String upCommand;
  final String downCommand;
  final Color color;
  final bool enabled;
  final Future<void> Function(String command) onCommand;

  const _JointControlSection({
    required this.title,
    required this.subtitle,
    required this.upLabel,
    required this.downLabel,
    required this.upCommand,
    required this.downCommand,
    required this.color,
    required this.enabled,
    required this.onCommand,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SectionTitle(
          title: title,
          subtitle: subtitle,
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _ArmCommandButton(
                label: upLabel,
                icon: Icons.keyboard_arrow_up,
                color: color,
                enabled: enabled,
                onTap: () => onCommand(upCommand),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _ArmCommandButton(
                label: downLabel,
                icon: Icons.keyboard_arrow_down,
                color: color,
                enabled: enabled,
                onTap: () => onCommand(downCommand),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LargeActionButton extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  const _LargeActionButton({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        height: 96,
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: enabled ? color.withValues(alpha: 0.14) : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          border: Border.all(
            color: enabled ? color.withValues(alpha: 0.85) : Colors.grey,
            width: 1.3,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: enabled ? color : Colors.grey, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: enabled ? color : Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: enabled ? Colors.white.withValues(alpha: 0.65) : Colors.grey,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArmCommandButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  const _ArmCommandButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        height: 82,
        decoration: BoxDecoration(
          color: enabled ? color.withValues(alpha: 0.14) : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          border: Border.all(
            color: enabled ? color.withValues(alpha: 0.85) : Colors.grey,
            width: 1.3,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: enabled ? color : Colors.grey, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: enabled ? color : Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        decoration: BoxDecoration(
          color: enabled ? color.withValues(alpha: 0.12) : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          border: Border.all(
            color: enabled ? color.withValues(alpha: 0.8) : Colors.grey,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: enabled ? color : Colors.grey, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: enabled ? color : Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
