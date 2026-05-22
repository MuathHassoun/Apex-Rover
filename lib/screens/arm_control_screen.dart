

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/theme.dart';
import '../models/robot_model.dart';
import '../providers/connection_provider.dart';

class ArmControlScreen extends ConsumerStatefulWidget {
  const ArmControlScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ArmControlScreen> createState() => _ArmControlScreenState();
}

class _ArmControlScreenState extends ConsumerState<ArmControlScreen> {
  String _lastAction = 'Ready';

  bool get _isConnected =>
      ref.read(connectionStatusProvider) == ConnectionStatus.connected;

  void _sendArmCommand(String command) {
    final isConnected =
        ref.read(connectionStatusProvider) == ConnectionStatus.connected;

    setState(() {
      _lastAction = command.replaceAll('ARM:', '').replaceAll(':', ' ');
    });

    if (!isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not connected to robot'),
          duration: Duration(seconds: 2),
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
        duration: const Duration(milliseconds: 900),
      ),
    );
  }

  void _sendBase(String direction) {
    _sendArmCommand('ARM:BASE:$direction');
  }

  void _sendAction(String action) {
    _sendArmCommand('ARM:$action');
  }

  @override
  Widget build(BuildContext context) {
    final connectionStatus = ref.watch(connectionStatusProvider);
    final isConnected = connectionStatus == ConnectionStatus.connected;

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
              ),

              const SizedBox(height: AppSpacing.lg),

              _SectionTitle(
                title: 'Base Rotation',
                subtitle: 'Control the stepper motor at the arm base',
              ),
              const SizedBox(height: AppSpacing.md),

              Row(
                children: [
                  Expanded(
                    child: _ArmHoldButton(
                      label: 'LEFT',
                      icon: Icons.rotate_left,
                      color: Colors.cyanAccent,
                      enabled: isConnected,
                      onDown: () => _sendBase('LEFT'),
                      onUp: () => _sendBase('STOP'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _ArmStopButton(
                      enabled: isConnected,
                      onTap: () => _sendBase('STOP'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _ArmHoldButton(
                      label: 'RIGHT',
                      icon: Icons.rotate_right,
                      color: Colors.cyanAccent,
                      enabled: isConnected,
                      onDown: () => _sendBase('RIGHT'),
                      onUp: () => _sendBase('STOP'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xl),

              _SectionTitle(
                title: 'Arm Movement',
                subtitle: 'Move the arm to reach objects',
              ),
              const SizedBox(height: AppSpacing.md),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B1726),
                  borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Column(
                  children: [
                    _ArmCommandButton(
                      label: 'ARM UP',
                      icon: Icons.keyboard_arrow_up,
                      color: Colors.greenAccent,
                      enabled: isConnected,
                      onTap: () => _sendAction('UP'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: _ArmCommandButton(
                            label: 'BACK',
                            icon: Icons.keyboard_arrow_left,
                            color: Colors.blueAccent,
                            enabled: isConnected,
                            onTap: () => _sendAction('BACK'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _ArmCommandButton(
                            label: 'FORWARD',
                            icon: Icons.keyboard_arrow_right,
                            color: Colors.blueAccent,
                            enabled: isConnected,
                            onTap: () => _sendAction('FORWARD'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _ArmCommandButton(
                      label: 'ARM DOWN',
                      icon: Icons.keyboard_arrow_down,
                      color: Colors.orangeAccent,
                      enabled: isConnected,
                      onTap: () => _sendAction('DOWN'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              _SectionTitle(
                title: 'Wrist & Gripper',
                subtitle: 'Adjust the wrist and control object grabbing',
              ),
              const SizedBox(height: AppSpacing.md),

              Row(
                children: [
                  Expanded(
                    child: _ArmCommandButton(
                      label: 'WRIST UP',
                      icon: Icons.expand_less,
                      color: Colors.purpleAccent,
                      enabled: isConnected,
                      onTap: () => _sendArmCommand('ARM:WRIST:UP'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _ArmCommandButton(
                      label: 'WRIST DOWN',
                      icon: Icons.expand_more,
                      color: Colors.purpleAccent,
                      enabled: isConnected,
                      onTap: () => _sendArmCommand('ARM:WRIST:DOWN'),
                    ),
                  ),
                ],
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
                title: 'Quick Actions',
                subtitle: 'Useful positions for picking and placing objects',
              ),
              const SizedBox(height: AppSpacing.md),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                childAspectRatio: 1.6,
                children: [
                  _QuickActionButton(
                    label: 'HOME',
                    icon: Icons.home,
                    color: Colors.white,
                    enabled: isConnected,
                    onTap: () => _sendAction('HOME'),
                  ),
                  _QuickActionButton(
                    label: 'PICK',
                    icon: Icons.touch_app,
                    color: Colors.greenAccent,
                    enabled: isConnected,
                    onTap: () => _sendAction('PICK'),
                  ),
                  _QuickActionButton(
                    label: 'CARRY',
                    icon: Icons.inventory_2,
                    color: Colors.amberAccent,
                    enabled: isConnected,
                    onTap: () => _sendAction('CARRY'),
                  ),
                  _QuickActionButton(
                    label: 'DROP BOX',
                    icon: Icons.move_to_inbox,
                    color: Colors.orangeAccent,
                    enabled: isConnected,
                    onTap: () => _sendAction('DROP'),
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

  const _StatusCard({
    required this.isConnected,
    required this.lastAction,
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
                  'Last action: $lastAction',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.65),
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

class _ArmHoldButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool enabled;
  final VoidCallback onDown;
  final VoidCallback onUp;

  const _ArmHoldButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.enabled,
    required this.onDown,
    required this.onUp,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: enabled ? (_) => onDown() : null,
      onTapUp: enabled ? (_) => onUp() : null,
      onTapCancel: enabled ? onUp : null,
      child: Container(
        height: 82,
        decoration: BoxDecoration(
          color: enabled ? color.withOpacity(0.16) : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          border: Border.all(
            color: enabled ? color : Colors.grey,
            width: 1.4,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: enabled ? color : Colors.grey, size: 30),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: enabled ? color : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArmStopButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;

  const _ArmStopButton({
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
          color: enabled
              ? Colors.redAccent.withOpacity(0.18)
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          border: Border.all(
            color: enabled ? Colors.redAccent : Colors.grey,
            width: 1.4,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.stop_circle,
              color: enabled ? Colors.redAccent : Colors.grey,
              size: 30,
            ),
            const SizedBox(height: 6),
            Text(
              'STOP',
              style: TextStyle(
                color: enabled ? Colors.redAccent : Colors.grey,
                fontWeight: FontWeight.bold,
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
        height: 76,
        decoration: BoxDecoration(
          color: enabled ? color.withOpacity(0.14) : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          border: Border.all(
            color: enabled ? color.withOpacity(0.85) : Colors.grey,
            width: 1.3,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: enabled ? color : Colors.grey, size: 28),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: enabled ? color : Colors.grey,
                fontWeight: FontWeight.bold,
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
              style: TextStyle(
                color: enabled ? color : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
