// import 'dart:async';

// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';

// import '../models/robot_model.dart';
// import '../providers/connection_provider.dart';
// import '../providers/sensor_status_provider.dart';

// enum RemoteControlMode { basic, rearJack, frontJack, arm }

// // ─── Design Tokens ─────────────────────────────────────────────────────────────
// class _T {
//   static const bg = Color(0xFF020A14);
//   static const surface = Color(0xFF071422);
//   static const card = Color(0xFF0D1E2E);
//   static const border = Color(0x18FFFFFF);
//   static const borderCyan = Color(0x3300E5FF);

//   static const cyan = Color(0xFF00E5FF);
//   static const cyanDim = Color(0x2200E5FF);
//   static const green = Color(0xFF00E676);
//   static const red = Color(0xFFFF1744);
//   static const orange = Color(0xFFFF9100);
//   static const purple = Color(0xFFD500F9);
//   static const amber = Color(0xFFFFD740);
//   static const blue = Color(0xFF448AFF);

//   static const textPrimary = Color(0xFFE8F4FF);
//   static const textSecondary = Color(0xFF7AA0BF);
//   static const textMuted = Color(0xFF2E4A62);

//   // Overlay panel background — semi-transparent, blurred feel
//   static const panelBg = Color(0xCC07111F);
// }

// class RemoteControlScreen extends ConsumerStatefulWidget {
//   const RemoteControlScreen({Key? key}) : super(key: key);

//   @override
//   ConsumerState<RemoteControlScreen> createState() => _RemoteControlScreenState();
// }

// class _RemoteControlScreenState extends ConsumerState<RemoteControlScreen>
//     with TickerProviderStateMixin {
//   RemoteControlMode _mode = RemoteControlMode.basic;
//   String _lastCommand = 'READY';
//   String _lastAlertStatus = '';

//   static const String _baseUrl = 'http://192.168.4.2:5000';

//   Timer? _cameraTimer;
//   int _frameTick = 0;

//   late AnimationController _pulse;
//   late Animation<double> _pulseAnim;

//   String get _snapshotUrl {
//     final ep = _mode == RemoteControlMode.arm ? 'arm_snapshot' : 'front_snapshot';
//     return '$_baseUrl/$ep?t=$_frameTick';
//   }

//   @override
//   void initState() {
//     super.initState();
//     SystemChrome.setPreferredOrientations(
//         [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
//     SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

//     _pulse = AnimationController(vsync: this, duration: const Duration(seconds: 2))
//       ..repeat(reverse: true);
//     _pulseAnim = Tween<double>(begin: 0.35, end: 1.0).animate(_pulse);

//     _cameraTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
//       if (mounted) setState(() => _frameTick++);
//     });
//   }

//   @override
//   void dispose() {
//     _cameraTimer?.cancel();
//     _pulse.dispose();
//     _send('STOP', silent: true);
//     _send('CAM:STOP', silent: true);
//     _restorePortrait();
//     super.dispose();
//   }

//   Future<void> _restorePortrait() async {
//     await SystemChrome.setPreferredOrientations(
//         [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
//     await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
//   }

//   void _send(String cmd, {bool silent = false}) {
//     final connected = ref.read(connectionStatusProvider) == ConnectionStatus.connected;
//     if (!connected) {
//       if (!silent && mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//           content: const Text('Robot not connected'),
//           backgroundColor: _T.red.withOpacity(0.9),
//           behavior: SnackBarBehavior.floating,
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//           duration: const Duration(milliseconds: 900),
//         ));
//       }
//       return;
//     }
//     final now = DateTime.now();
//     ref.read(connectionStatusProvider.notifier).sendCommand(ControlCommand(
//           commandId: 'rc_${now.millisecondsSinceEpoch}',
//           commandType: cmd,
//           parameters: const {'robotId': 'robot_001', 'speed': 60},
//           timestamp: now,
//         ));
//     if (mounted) setState(() => _lastCommand = cmd);
//   }

//   void _checkAlert(SensorStatus prev, SensorStatus next) {
//     final s = next.balanceStatus.toUpperCase();
//     if (s == _lastAlertStatus) return;
//     if (s == 'WARNING' || s == 'DANGER') {
//       _lastAlertStatus = s;
//       SystemSound.play(SystemSoundType.alert);
//       if (!mounted) return;
//       final danger = s == 'DANGER';
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//         content: Text(danger ? 'DANGER — Robot may fall' : 'WARNING — Unstable'),
//         backgroundColor: (danger ? _T.red : _T.orange).withOpacity(0.9),
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//         duration: const Duration(seconds: 2),
//       ));
//     }
//     if (s == 'STABLE') _lastAlertStatus = 'STABLE';
//   }

//   String get _modeLabel {
//     switch (_mode) {
//       case RemoteControlMode.basic:
//         return 'Basic';
//       case RemoteControlMode.rearJack:
//         return 'Rear Jack';
//       case RemoteControlMode.frontJack:
//         return 'Front Jack';
//       case RemoteControlMode.arm:
//         return 'Arm';
//     }
//   }

//   IconData get _modeIcon {
//     switch (_mode) {
//       case RemoteControlMode.basic:
//         return Icons.sports_esports_rounded;
//       case RemoteControlMode.rearJack:
//         return Icons.vertical_align_bottom_rounded;
//       case RemoteControlMode.frontJack:
//         return Icons.vertical_align_top_rounded;
//       case RemoteControlMode.arm:
//         return Icons.precision_manufacturing_rounded;
//     }
//   }

//   // ─── Mode Bottom Sheet ────────────────────────────────────────────────────────
//   void _openModeMenu() {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: _T.surface,
//       isScrollControlled: true,
//       shape: const RoundedRectangleBorder(
//           borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
//       builder: (_) => FractionallySizedBox(
//         heightFactor: 0.82,
//         child: SafeArea(
//           child: Column(children: [
//             const SizedBox(height: 10),
//             Container(
//                 width: 34,
//                 height: 4,
//                 decoration:
//                     BoxDecoration(color: _T.textMuted, borderRadius: BorderRadius.circular(2))),
//             const SizedBox(height: 18),
//             const Padding(
//               padding: EdgeInsets.symmetric(horizontal: 20),
//               child: Align(
//                 alignment: Alignment.centerLeft,
//                 child: Text('Control Mode',
//                     style: TextStyle(
//                         color: _T.textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
//               ),
//             ),
//             const SizedBox(height: 12),
//             Expanded(
//                 child: ListView(
//               padding: const EdgeInsets.symmetric(horizontal: 14),
//               children: [
//                 _modeTile('Basic', 'Movement + camera stand', Icons.sports_esports_rounded,
//                     RemoteControlMode.basic),
//                 _modeTile('Rear Jack', 'Rear actuator control', Icons.vertical_align_bottom_rounded,
//                     RemoteControlMode.rearJack),
//                 _modeTile('Front Jack', 'Front actuator control', Icons.vertical_align_top_rounded,
//                     RemoteControlMode.frontJack),
//                 _modeTile('Arm', 'Arm control + arm camera', Icons.precision_manufacturing_rounded,
//                     RemoteControlMode.arm),
//               ],
//             )),
//           ]),
//         ),
//       ),
//     );
//   }

//   Widget _modeTile(String title, String sub, IconData icon, RemoteControlMode mode) {
//     final sel = _mode == mode;
//     return AnimatedContainer(
//       duration: const Duration(milliseconds: 180),
//       margin: const EdgeInsets.only(bottom: 9),
//       decoration: BoxDecoration(
//         color: sel ? _T.cyanDim : _T.card,
//         borderRadius: BorderRadius.circular(14),
//         border:
//             Border.all(color: sel ? _T.cyan.withOpacity(0.45) : _T.border, width: sel ? 1.4 : 1),
//       ),
//       child: ListTile(
//         onTap: () {
//           setState(() {
//             _mode = mode;
//             _lastCommand = 'MODE: $title';
//             _frameTick++;
//           });
//           Navigator.pop(context);
//         },
//         leading: Container(
//             width: 38,
//             height: 38,
//             decoration: BoxDecoration(
//                 color: sel ? _T.cyan.withOpacity(0.18) : _T.surface,
//                 borderRadius: BorderRadius.circular(10)),
//             child: Icon(icon, color: sel ? _T.cyan : _T.textSecondary, size: 19)),
//         title: Text(title,
//             style: TextStyle(
//                 color: sel ? _T.cyan : _T.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
//         subtitle: Text(sub, style: const TextStyle(color: _T.textSecondary, fontSize: 11)),
//         trailing: sel
//             ? Container(
//                 width: 22,
//                 height: 22,
//                 decoration: BoxDecoration(color: _T.cyan, borderRadius: BorderRadius.circular(11)),
//                 child: const Icon(Icons.check, color: _T.bg, size: 13))
//             : null,
//       ),
//     );
//   }

//   // ─── Control Button ────────────────────────────────────────────────────────────
//   Widget _btn({
//     required String label,
//     required IconData icon,
//     required String cmd,
//     Color color = _T.cyan,
//     double w = 76,
//     double h = 62,
//   }) {
//     final connected = ref.watch(connectionStatusProvider) == ConnectionStatus.connected;
//     final c = connected ? color : _T.textMuted;

//     return GestureDetector(
//       onTapDown: connected ? (_) => _send(cmd) : null,
//       child: Container(
//         width: w,
//         height: h,
//         decoration: BoxDecoration(
//           color: connected ? color.withOpacity(0.13) : _T.card,
//           borderRadius: BorderRadius.circular(13),
//           border: Border.all(color: connected ? color.withOpacity(0.5) : _T.border, width: 1.2),
//         ),
//         child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
//           Icon(icon, color: c, size: 21),
//           const SizedBox(height: 3),
//           Text(label,
//               textAlign: TextAlign.center,
//               overflow: TextOverflow.ellipsis,
//               style: TextStyle(
//                   color: c, fontSize: 8.5, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
//         ]),
//       ),
//     );
//   }

//   // ─── Section Card (overlay panel) ─────────────────────────────────────────────
//   Widget _panel({
//     required String title,
//     required IconData icon,
//     required Color color,
//     required Widget child,
//   }) {
//     return Container(
//       decoration: BoxDecoration(
//         color: _T.panelBg,
//         borderRadius: BorderRadius.circular(18),
//         border: Border.all(color: _T.border),
//       ),
//       padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
//       child: Column(mainAxisSize: MainAxisSize.min, children: [
//         Row(mainAxisAlignment: MainAxisAlignment.center, children: [
//           Icon(icon, color: color, size: 11),
//           const SizedBox(width: 4),
//           Text(title,
//               style: TextStyle(
//                   color: color.withOpacity(0.9),
//                   fontSize: 9,
//                   fontWeight: FontWeight.w700,
//                   letterSpacing: 1.4)),
//         ]),
//         const SizedBox(height: 8),
//         child,
//       ]),
//     );
//   }

//   // ─── Camera Stand Controls (LEFT) ─────────────────────────────────────────────
//   Widget _camStandPanel() {
//     return _panel(
//       title: 'CAMERA',
//       icon: Icons.videocam_rounded,
//       color: _T.cyan,
//       child: Column(mainAxisSize: MainAxisSize.min, children: [
//         _btn(
//             label: 'UP',
//             icon: Icons.keyboard_arrow_up_rounded,
//             cmd: 'CAM:UP',
//             color: _T.cyan,
//             w: 90,
//             h: 52),
//         const SizedBox(height: 6),
//         Row(mainAxisAlignment: MainAxisAlignment.center, children: [
//           _btn(
//               label: 'LEFT',
//               icon: Icons.keyboard_arrow_left_rounded,
//               cmd: 'CAM:LEFT',
//               color: _T.cyan,
//               w: 68,
//               h: 52),
//           const SizedBox(width: 6),
//           _btn(
//               label: 'STOP',
//               icon: Icons.stop_rounded,
//               cmd: 'CAM:STOP',
//               color: _T.red,
//               w: 68,
//               h: 52),
//           const SizedBox(width: 6),
//           _btn(
//               label: 'RIGHT',
//               icon: Icons.keyboard_arrow_right_rounded,
//               cmd: 'CAM:RIGHT',
//               color: _T.cyan,
//               w: 68,
//               h: 52),
//         ]),
//         const SizedBox(height: 6),
//         Row(mainAxisAlignment: MainAxisAlignment.center, children: [
//           _btn(
//               label: 'DOWN',
//               icon: Icons.keyboard_arrow_down_rounded,
//               cmd: 'CAM:DOWN',
//               color: _T.cyan,
//               w: 86,
//               h: 52),
//           const SizedBox(width: 6),
//           _btn(
//               label: 'CENTER',
//               icon: Icons.center_focus_strong_rounded,
//               cmd: 'CAM:CENTER',
//               color: _T.orange,
//               w: 86,
//               h: 52),
//         ]),
//       ]),
//     );
//   }

//   // ─── Movement Controls (RIGHT) ────────────────────────────────────────────────
//   Widget _movementPanel() {
//     return _panel(
//       title: 'MOVEMENT',
//       icon: Icons.sports_esports_rounded,
//       color: _T.green,
//       child: Column(mainAxisSize: MainAxisSize.min, children: [
//         _btn(
//             label: 'FWD',
//             icon: Icons.keyboard_arrow_up_rounded,
//             cmd: 'FORWARD',
//             color: _T.green,
//             w: 90,
//             h: 52),
//         const SizedBox(height: 6),
//         Row(mainAxisAlignment: MainAxisAlignment.center, children: [
//           _btn(
//               label: 'LEFT',
//               icon: Icons.keyboard_arrow_left_rounded,
//               cmd: 'LEFT',
//               color: _T.cyan,
//               w: 68,
//               h: 52),
//           const SizedBox(width: 6),
//           _btn(label: 'STOP', icon: Icons.stop_rounded, cmd: 'STOP', color: _T.red, w: 68, h: 52),
//           const SizedBox(width: 6),
//           _btn(
//               label: 'RIGHT',
//               icon: Icons.keyboard_arrow_right_rounded,
//               cmd: 'RIGHT',
//               color: _T.cyan,
//               w: 68,
//               h: 52),
//         ]),
//         const SizedBox(height: 6),
//         _btn(
//             label: 'BACK',
//             icon: Icons.keyboard_arrow_down_rounded,
//             cmd: 'BACKWARD',
//             color: _T.green,
//             w: 90,
//             h: 52),
//       ]),
//     );
//   }

//   // ─── Jack Controls ────────────────────────────────────────────────────────────
//   Widget _jackPanel({required bool isRear}) {
//     final prefix = isRear ? 'JACK:REAR' : 'JACK:FRONT';
//     final title = isRear ? 'REAR JACK' : 'FRONT JACK';
//     return _panel(
//       title: title,
//       icon: isRear ? Icons.vertical_align_bottom_rounded : Icons.vertical_align_top_rounded,
//       color: _T.orange,
//       child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
//         _btn(
//             label: 'EXTEND',
//             icon: Icons.expand_less_rounded,
//             cmd: '$prefix:EXTEND',
//             color: _T.orange,
//             w: 88,
//             h: 62),
//         const SizedBox(width: 8),
//         _btn(
//             label: 'STOP',
//             icon: Icons.stop_rounded,
//             cmd: '$prefix:STOP',
//             color: _T.red,
//             w: 68,
//             h: 62),
//         const SizedBox(width: 8),
//         _btn(
//             label: 'RETRACT',
//             icon: Icons.expand_more_rounded,
//             cmd: '$prefix:RETRACT',
//             color: _T.orange,
//             w: 88,
//             h: 62),
//       ]),
//     );
//   }

//   // ─── Arm Controls — split LEFT / RIGHT ────────────────────────────────────────
//   Widget _armLeftPanel() {
//     return _panel(
//       title: 'BASE & SHOULDER',
//       icon: Icons.precision_manufacturing_rounded,
//       color: _T.purple,
//       child: Column(mainAxisSize: MainAxisSize.min, children: [
//         // Base
//         _armSubLabel('BASE'),
//         const SizedBox(height: 5),
//         Row(mainAxisAlignment: MainAxisAlignment.center, children: [
//           _btn(
//               label: 'BASE L',
//               icon: Icons.rotate_left_rounded,
//               cmd: 'ARM:BASE:LEFT',
//               color: _T.purple,
//               w: 82,
//               h: 56),
//           const SizedBox(width: 6),
//           _btn(
//               label: 'STOP',
//               icon: Icons.stop_rounded,
//               cmd: 'ARM:BASE:STOP',
//               color: _T.red,
//               w: 62,
//               h: 56),
//           const SizedBox(width: 6),
//           _btn(
//               label: 'BASE R',
//               icon: Icons.rotate_right_rounded,
//               cmd: 'ARM:BASE:RIGHT',
//               color: _T.purple,
//               w: 82,
//               h: 56),
//         ]),
//         const SizedBox(height: 8),
//         // Shoulder
//         _armSubLabel('SHOULDER'),
//         const SizedBox(height: 5),
//         Row(mainAxisAlignment: MainAxisAlignment.center, children: [
//           _btn(
//               label: 'UP',
//               icon: Icons.arrow_upward_rounded,
//               cmd: 'ARM:SHOULDER:UP',
//               color: _T.amber,
//               w: 100,
//               h: 56),
//           const SizedBox(width: 8),
//           _btn(
//               label: 'DOWN',
//               icon: Icons.arrow_downward_rounded,
//               cmd: 'ARM:SHOULDER:DOWN',
//               color: _T.amber,
//               w: 100,
//               h: 56),
//         ]),
//         const SizedBox(height: 8),
//         // Home
//         _btn(
//             label: 'HOME POSITION',
//             icon: Icons.home_rounded,
//             cmd: 'ARM:HOME',
//             color: _T.textSecondary,
//             w: 210,
//             h: 46),
//       ]),
//     );
//   }

//   Widget _armRightPanel() {
//     return _panel(
//       title: 'ELBOW & END EFFECTOR',
//       icon: Icons.back_hand_rounded,
//       color: _T.blue,
//       child: Column(mainAxisSize: MainAxisSize.min, children: [
//         // Elbow
//         _armSubLabel('ELBOW'),
//         const SizedBox(height: 5),
//         Row(mainAxisAlignment: MainAxisAlignment.center, children: [
//           _btn(
//               label: 'UP',
//               icon: Icons.north_rounded,
//               cmd: 'ARM:ELBOW:UP',
//               color: _T.amber,
//               w: 100,
//               h: 56),
//           const SizedBox(width: 8),
//           _btn(
//               label: 'DOWN',
//               icon: Icons.south_rounded,
//               cmd: 'ARM:ELBOW:DOWN',
//               color: _T.amber,
//               w: 100,
//               h: 56),
//         ]),
//         const SizedBox(height: 8),
//         // Wrist
//         _armSubLabel('WRIST'),
//         const SizedBox(height: 5),
//         Row(mainAxisAlignment: MainAxisAlignment.center, children: [
//           _btn(
//               label: 'UP',
//               icon: Icons.keyboard_arrow_up_rounded,
//               cmd: 'ARM:WRIST:UP',
//               color: _T.blue,
//               w: 100,
//               h: 56),
//           const SizedBox(width: 8),
//           _btn(
//               label: 'DOWN',
//               icon: Icons.keyboard_arrow_down_rounded,
//               cmd: 'ARM:WRIST:DOWN',
//               color: _T.blue,
//               w: 100,
//               h: 56),
//         ]),
//         const SizedBox(height: 8),
//         // Gripper
//         _armSubLabel('GRIPPER'),
//         const SizedBox(height: 5),
//         Row(mainAxisAlignment: MainAxisAlignment.center, children: [
//           _btn(
//               label: 'OPEN',
//               icon: Icons.pan_tool_alt_rounded,
//               cmd: 'ARM:GRIPPER:OPEN',
//               color: _T.green,
//               w: 100,
//               h: 56),
//           const SizedBox(width: 8),
//           _btn(
//               label: 'CLOSE',
//               icon: Icons.back_hand_rounded,
//               cmd: 'ARM:GRIPPER:CLOSE',
//               color: _T.green,
//               w: 100,
//               h: 56),
//         ]),
//       ]),
//     );
//   }

//   Widget _armSubLabel(String t) => Align(
//         alignment: Alignment.centerLeft,
//         child: Text(t,
//             style: const TextStyle(
//                 color: _T.textMuted, fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
//       );

//   // ─── Sensor Bar (transparent, no border) ──────────────────────────────────────
//   Widget _sensorBar() {
//     final s = ref.watch(sensorStatusProvider);

//     Color statusColor;
//     IconData statusIcon;
//     String statusText;

//     if (s.isDanger) {
//       statusColor = _T.red;
//       statusIcon = Icons.dangerous_rounded;
//       statusText = 'DANGER';
//     } else if (s.isWarning) {
//       statusColor = _T.orange;
//       statusIcon = Icons.warning_amber_rounded;
//       statusText = 'WARN';
//     } else if (s.isStable) {
//       statusColor = _T.green;
//       statusIcon = Icons.check_circle_rounded;
//       statusText = 'STABLE';
//     } else {
//       statusColor = _T.textMuted;
//       statusIcon = Icons.sensors_rounded;
//       statusText = 'NO DATA';
//     }

//     return Row(children: [
//       _sChip(statusText, statusIcon, statusColor, wide: true),
//       const SizedBox(width: 10),
//       _sChip(s.pitch == null ? '—' : '${s.pitch!.toStringAsFixed(1)}°', Icons.swap_vert_rounded,
//           _T.cyan,
//           label: 'PITCH'),
//       const SizedBox(width: 10),
//       _sChip(s.roll == null ? '—' : '${s.roll!.toStringAsFixed(1)}°',
//           Icons.screen_rotation_alt_rounded, _T.cyan,
//           label: 'ROLL'),
//       const SizedBox(width: 10),
//       _sChip(s.frontDistance == null ? '—' : '${s.frontDistance!.toStringAsFixed(1)}',
//           Icons.vertical_align_top_rounded, _T.blue,
//           label: 'F·US'),
//       const SizedBox(width: 10),
//       _sChip(s.rearDistance == null ? '—' : '${s.rearDistance!.toStringAsFixed(1)}',
//           Icons.vertical_align_bottom_rounded, _T.blue,
//           label: 'R·US'),
//     ]);
//   }

//   Widget _sChip(String value, IconData icon, Color color, {String? label, bool wide = false}) {
//     return Row(mainAxisSize: MainAxisSize.min, children: [
//       Icon(icon, color: color, size: 13),
//       const SizedBox(width: 4),
//       Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             if (label != null)
//               Text(label,
//                   style: const TextStyle(
//                       color: _T.textMuted,
//                       fontSize: 7.5,
//                       fontWeight: FontWeight.w600,
//                       letterSpacing: 0.8)),
//             Text(value, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
//           ]),
//     ]);
//   }

//   // ─── Top bar: Back · Sensors · Mode ───────────────────────────────────────────
//   Widget _topBar(bool isConnected) {
//     return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
//       // Back — ghost button
//       GestureDetector(
//         onTap: () async {
//           await _restorePortrait();
//           if (context.mounted) Navigator.of(context).pop();
//         },
//         child: Row(mainAxisSize: MainAxisSize.min, children: [
//           const Icon(Icons.arrow_back_ios_new_rounded, color: _T.textPrimary, size: 15),
//           const SizedBox(width: 4),
//           const Text('Back',
//               style: TextStyle(color: _T.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
//         ]),
//       ),

//       const SizedBox(width: 16),

//       // Connection dot
//       AnimatedBuilder(
//         animation: _pulseAnim,
//         builder: (_, __) => Opacity(
//           opacity: isConnected ? _pulseAnim.value : 1,
//           child: Container(
//             width: 7,
//             height: 7,
//             decoration: BoxDecoration(
//                 color: isConnected ? _T.green : _T.red, borderRadius: BorderRadius.circular(4)),
//           ),
//         ),
//       ),
//       const SizedBox(width: 16),

//       // Sensor values — flex middle
//       Expanded(child: _sensorBar()),

//       const SizedBox(width: 16),

//       // Mode — ghost button
//       GestureDetector(
//         onTap: _openModeMenu,
//         child: Row(mainAxisSize: MainAxisSize.min, children: [
//           Icon(_modeIcon, color: _T.cyan, size: 15),
//           const SizedBox(width: 5),
//           Text(_modeLabel,
//               style: const TextStyle(color: _T.cyan, fontWeight: FontWeight.w600, fontSize: 13)),
//           const SizedBox(width: 4),
//           const Icon(Icons.keyboard_arrow_down_rounded, color: _T.cyan, size: 16),
//         ]),
//       ),
//     ]);
//   }

//   // ─── Camera Feed (full screen) ────────────────────────────────────────────────
//   Widget _cameraFeed() {
//     return Image.network(
//       _snapshotUrl,
//       fit: BoxFit.cover,
//       gaplessPlayback: true,
//       errorBuilder: (_, __, ___) => Container(
//         color: _T.bg,
//         child: Center(
//             child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Container(
//                 width: 64,
//                 height: 64,
//                 decoration: BoxDecoration(
//                     color: _T.red.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(18),
//                     border: Border.all(color: _T.red.withOpacity(0.3))),
//                 child: const Icon(Icons.videocam_off_rounded, color: _T.red, size: 32)),
//             const SizedBox(height: 12),
//             const Text('Camera offline',
//                 style: TextStyle(color: _T.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
//             const SizedBox(height: 4),
//             const Text('Check dual_camera_server.py',
//                 style: TextStyle(color: _T.textMuted, fontSize: 11)),
//           ],
//         )),
//       ),
//     );
//   }

//   // ─── Overlay bottom-left: last command + LIVE ─────────────────────────────────
//   Widget _cameraOverlayInfo() {
//     return Row(children: [
//       Container(
//           width: 6,
//           height: 6,
//           decoration: BoxDecoration(color: _T.green, borderRadius: BorderRadius.circular(3))),
//       const SizedBox(width: 6),
//       Text(_lastCommand,
//           style: const TextStyle(color: _T.textPrimary, fontSize: 10, fontWeight: FontWeight.w600)),
//       const SizedBox(width: 14),
//       AnimatedBuilder(
//           animation: _pulseAnim,
//           builder: (_, __) => Opacity(
//                 opacity: _pulseAnim.value,
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
//                   decoration: BoxDecoration(
//                       color: _T.red.withOpacity(0.8), borderRadius: BorderRadius.circular(5)),
//                   child: const Text('● LIVE',
//                       style: TextStyle(
//                           color: Colors.white,
//                           fontSize: 8,
//                           fontWeight: FontWeight.w800,
//                           letterSpacing: 0.8)),
//                 ),
//               )),
//     ]);
//   }

//   // ─── Layout helpers ────────────────────────────────────────────────────────────

//   // Returns LEFT-side overlay widget for each mode
//   Widget _leftOverlay() {
//     switch (_mode) {
//       case RemoteControlMode.basic:
//       case RemoteControlMode.rearJack:
//       case RemoteControlMode.frontJack:
//         return _camStandPanel();
//       case RemoteControlMode.arm:
//         return _armLeftPanel();
//     }
//   }

//   // Returns RIGHT-side overlay widget for each mode
//   Widget _rightOverlay() {
//     switch (_mode) {
//       case RemoteControlMode.basic:
//         return _movementPanel();
//       case RemoteControlMode.rearJack:
//         return _jackPanel(isRear: true);
//       case RemoteControlMode.frontJack:
//         return _jackPanel(isRear: false);
//       case RemoteControlMode.arm:
//         return _armRightPanel();
//     }
//   }

//   // ─── Build ─────────────────────────────────────────────────────────────────────
//   @override
//   Widget build(BuildContext context) {
//     final isConnected = ref.watch(connectionStatusProvider) == ConnectionStatus.connected;

//     ref.listen<SensorStatus>(sensorStatusProvider, (prev, next) {
//       if (prev == null) return;
//       _checkAlert(prev, next);
//     });

//     return PopScope(
//       canPop: true,
//       onPopInvoked: (_) async => await _restorePortrait(),
//       child: Scaffold(
//         backgroundColor: _T.bg,
//         body: Stack(children: [
//           // ── Layer 1: Full-screen camera ──────────────────────────────────────
//           Positioned.fill(child: _cameraFeed()),

//           // ── Layer 2: Top gradient (for top bar legibility) ────────────────────
//           Positioned(
//             top: 0,
//             left: 0,
//             right: 0,
//             height: 70,
//             child: Container(
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   begin: Alignment.topCenter,
//                   end: Alignment.bottomCenter,
//                   colors: [Colors.black.withOpacity(0.72), Colors.transparent],
//                 ),
//               ),
//             ),
//           ),

//           // ── Layer 3: Bottom gradient (for bottom info legibility) ─────────────
//           Positioned(
//             bottom: 0,
//             left: 0,
//             right: 0,
//             height: 50,
//             child: Container(
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   begin: Alignment.bottomCenter,
//                   end: Alignment.topCenter,
//                   colors: [Colors.black.withOpacity(0.65), Colors.transparent],
//                 ),
//               ),
//             ),
//           ),

//           // ── Layer 4: Top bar (Back | Sensors | Mode) ──────────────────────────
//           Positioned(
//             top: 0,
//             left: 0,
//             right: 0,
//             child: SafeArea(
//               bottom: false,
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                 child: _topBar(isConnected),
//               ),
//             ),
//           ),

//           // ── Layer 5: LEFT control panel ────────────────────────────────────────
//           Positioned(
//             left: 10,
//             bottom: 10,
//             child: SafeArea(
//               top: false,
//               child: SingleChildScrollView(
//                 child: ConstrainedBox(
//                   constraints: BoxConstraints(
//                     maxHeight: MediaQuery.of(context).size.height * 0.78,
//                   ),
//                   child: _leftOverlay(),
//                 ),
//               ),
//             ),
//           ),

//           // ── Layer 6: RIGHT control panel ───────────────────────────────────────
//           Positioned(
//             right: 10,
//             bottom: 10,
//             child: SafeArea(
//               top: false,
//               child: SingleChildScrollView(
//                 child: ConstrainedBox(
//                   constraints: BoxConstraints(
//                     maxHeight: MediaQuery.of(context).size.height * 0.78,
//                   ),
//                   child: _rightOverlay(),
//                 ),
//               ),
//             ),
//           ),

//           // ── Layer 7: Bottom-left camera info ───────────────────────────────────
//           Positioned(
//             left: 16,
//             bottom: 14,
//             child: SafeArea(top: false, child: _cameraOverlayInfo()),
//           ),
//         ]),
//       ),
//     );
//   }
// }
