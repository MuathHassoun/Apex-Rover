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

  void _sendArmCommand(String command) {
    final isConnected = ref.read(connectionStatusProvider) == ConnectionStatus.connected;

    setState(() {
      _lastAction = command.replaceAll('ARM:', '').replaceAll(':', ' ');
    });

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

    final armCommand = ControlCommand(
      commandId: 'arm_${DateTime.now().millisecondsSinceEpoch}',
      commandType: command,
      parameters: const {
        'robotId': 'robot_001',
      },
      timestamp: DateTime.now(),
    );

    ref.read(connectionStatusProvider.notifier).sendCommand(armCommand);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Arm command sent: $command'),
        duration: const Duration(milliseconds: 700),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = ref.watch(connectionStatusProvider) == ConnectionStatus.connected;

    final settings = ref.watch(unoMotionSettingsProvider);
    final stepperSteps = settings.stepperSteps;
    final servoStep = settings.servoAngleStep;

    return Scaffold(
      backgroundColor: const Color(0xFF050B12),
      appBar: AppBar(
        title: const Text('Arm Control'),
        backgroundColor: const Color(0xFF07111F),
        foregroundColor: Colors.white,
        elevation: 2,
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
              ),
              const SizedBox(height: AppSpacing.lg),
              _SectionTitle(
                title: 'Base Stepper',
                subtitle: 'Arm base stepper uses $stepperSteps steps per click',
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _ArmCommandButton(
                      label: 'BASE LEFT\n$stepperSteps',
                      icon: Icons.rotate_left,
                      color: Colors.cyanAccent,
                      enabled: isConnected,
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
                      onTap: () => _sendArmCommand('ARM:BASE:STOP'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _ArmCommandButton(
                      label: 'BASE RIGHT\n$stepperSteps',
                      icon: Icons.rotate_right,
                      color: Colors.cyanAccent,
                      enabled: isConnected,
                      onTap: () => _sendArmCommand(
                        'ARM:BASE:STEP_RIGHT:$stepperSteps',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              _SectionTitle(
                title: 'Shoulder',
                subtitle: 'Servo moves $servoStep° per click',
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _ArmCommandButton(
                      label: 'SHOULDER UP\n$servoStep°',
                      icon: Icons.keyboard_arrow_up,
                      color: Colors.greenAccent,
                      enabled: isConnected,
                      onTap: () => _sendArmCommand(
                        'ARM:SHOULDER:UP:$servoStep',
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _ArmCommandButton(
                      label: 'SHOULDER DOWN\n$servoStep°',
                      icon: Icons.keyboard_arrow_down,
                      color: Colors.orangeAccent,
                      enabled: isConnected,
                      onTap: () => _sendArmCommand(
                        'ARM:SHOULDER:DOWN:$servoStep',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              _SectionTitle(
                title: 'Elbow',
                subtitle: 'Servo moves $servoStep° per click',
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _ArmCommandButton(
                      label: 'ELBOW UP\n$servoStep°',
                      icon: Icons.keyboard_arrow_up,
                      color: Colors.greenAccent,
                      enabled: isConnected,
                      onTap: () => _sendArmCommand(
                        'ARM:ELBOW:UP:$servoStep',
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _ArmCommandButton(
                      label: 'ELBOW DOWN\n$servoStep°',
                      icon: Icons.keyboard_arrow_down,
                      color: Colors.orangeAccent,
                      enabled: isConnected,
                      onTap: () => _sendArmCommand(
                        'ARM:ELBOW:DOWN:$servoStep',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              _SectionTitle(
                title: 'Wrist',
                subtitle: 'Servo moves $servoStep° per click',
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _ArmCommandButton(
                      label: 'WRIST UP\n$servoStep°',
                      icon: Icons.expand_less,
                      color: Colors.purpleAccent,
                      enabled: isConnected,
                      onTap: () => _sendArmCommand(
                        'ARM:WRIST:UP:$servoStep',
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _ArmCommandButton(
                      label: 'WRIST DOWN\n$servoStep°',
                      icon: Icons.expand_more,
                      color: Colors.purpleAccent,
                      enabled: isConnected,
                      onTap: () => _sendArmCommand(
                        'ARM:WRIST:DOWN:$servoStep',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              _SectionTitle(
                title: 'AUX Servo',
                subtitle: 'AUX axis moves $servoStep° per click',
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _ArmCommandButton(
                      label: 'AUX UP\n$servoStep°',
                      icon: Icons.keyboard_arrow_left,
                      color: Colors.blueAccent,
                      enabled: isConnected,
                      onTap: () => _sendArmCommand(
                        'ARM:AUX:UP:$servoStep',
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _ArmCommandButton(
                      label: 'AUX DOWN\n$servoStep°',
                      icon: Icons.keyboard_arrow_right,
                      color: Colors.blueAccent,
                      enabled: isConnected,
                      onTap: () => _sendArmCommand(
                        'ARM:AUX:DOWN:$servoStep',
                      ),
                    ),
                  ),
                ],
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
                      enabled: isConnected,
                      onTap: () => _sendArmCommand('ARM:GRIPPER:OPEN'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _ArmCommandButton(
                      label: 'CLOSE',
                      icon: Icons.pan_tool,
                      color: Colors.redAccent,
                      enabled: isConnected,
                      onTap: () => _sendArmCommand('ARM:GRIPPER:CLOSE'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              _SectionTitle(
                title: 'Safe Positions',
                subtitle: 'UNO staged HOME / READY positions',
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
                    enabled: isConnected,
                    onTap: () => _sendArmCommand('ARM:READY'),
                  ),
                  _QuickActionButton(
                    label: 'HOME',
                    icon: Icons.home,
                    color: Colors.white,
                    enabled: isConnected,
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
                    enabled: isConnected,
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

  const _StatusCard({
    required this.isConnected,
    required this.lastAction,
    required this.stepperSteps,
    required this.servoStep,
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
        border: Border.all(color: color.withOpacity(0.6)),
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
                  isConnected ? 'Arm Ready' : 'Not Connected',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Last: $lastAction',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.65),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Stepper: $stepperSteps steps · Servo: $servoStep°',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.55),
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
            color: Colors.white.withOpacity(0.55),
          ),
        ),
      ],
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
          color: enabled ? color.withOpacity(0.14) : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          border: Border.all(
            color: enabled ? color.withOpacity(0.85) : Colors.grey,
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
          color: enabled ? color.withOpacity(0.12) : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          border: Border.all(
            color: enabled ? color.withOpacity(0.8) : Colors.grey,
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
