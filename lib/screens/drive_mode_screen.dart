import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class _GroundItem {
  Offset pos;
  final int type;
  bool collected = false;
  _GroundItem({required this.pos, required this.type});
}

class DriveModeScreen extends StatefulWidget {
  const DriveModeScreen({Key? key}) : super(key: key);
  @override
  State<DriveModeScreen> createState() => _DriveModeScreenState();
}

class _DriveModeScreenState extends State<DriveModeScreen>
    with TickerProviderStateMixin {
  double _wx = 0, _wy = 0, _heading = 0;
  double _steer = 0;
  bool _gas = false;
  bool _reverse = false;
  bool _armActive = false;
  int _itemsCollected = 0;
  Offset _stickPos = Offset.zero;
  final List<Offset> _trail = [];
  final List<_GroundItem> _items = [];

  late AnimationController _trkCtrl;
  late AnimationController _plsCtrl;
  late AnimationController _armCtrl;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _trkCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..addListener(_onTick);
    _plsCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 850))
      ..repeat(reverse: true);
    _armCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));

    final rng = math.Random(42);
    for (int i = 0; i < 20; i++) {
      _items.add(_GroundItem(
        pos: Offset(
            (rng.nextDouble() - 0.5) * 1400,
            (rng.nextDouble() - 0.5) * 1400),
        type: i % 3,
      ));
    }
  }

  void _onTick() {
    if ((!_gas && !_reverse) || !mounted) return;
    setState(() {
      _heading = (_heading + _steer * 0.03) % (2 * math.pi);
      final spd = _reverse ? -2.0 : 2.5;
      _wx += math.sin(_heading) * spd;
      _wy -= math.cos(_heading) * spd;
      if (_trail.isEmpty ||
          (_trail.last - Offset(_wx, _wy)).distance > 12) {
        _trail.add(Offset(_wx, _wy));
        if (_trail.length > 200) _trail.removeAt(0);
      }
    });
  }

  void _setGas(bool v) {
    setState(() { _gas = v; _reverse = false; });
    if (v) _trkCtrl.repeat();
    else if (!_reverse) _trkCtrl.stop();
  }

  void _setReverse(bool v) {
    setState(() { _reverse = v; _gas = false; });
    if (v) _trkCtrl.repeat();
    else if (!_gas) _trkCtrl.stop();
  }

  void _brake() {
    setState(() {
      _gas = false;
      _reverse = false;
      _steer = 0;
      _stickPos = Offset.zero;
    });
    _trkCtrl.stop();
  }

  void _onStickChanged(Offset norm) =>
      setState(() { _stickPos = norm; _steer = norm.dx; });

  void _onStickEnd() =>
      setState(() { _stickPos = Offset.zero; _steer = 0; });

  void _toggleArm() {
    if (_armActive) {
      setState(() => _armActive = false);
      _armCtrl.reverse();
      return;
    }
    setState(() => _armActive = true);
    _armCtrl.forward();

    _GroundItem? nearest;
    double minDist = 180;
    for (final item in _items) {
      if (item.collected) continue;
      final d = (item.pos - Offset(_wx, _wy)).distance;
      if (d < minDist) { minDist = d; nearest = item; }
    }
    if (nearest != null) {
      Future.delayed(const Duration(milliseconds: 850), () {
        if (!mounted) return;
        setState(() {
          nearest!.collected = true;
          _itemsCollected++;
          _armActive = false;
        });
        _armCtrl.reverse();
      });
    } else {
      Future.delayed(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        setState(() => _armActive = false);
        _armCtrl.reverse();
      });
    }
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _trkCtrl.dispose();
    _plsCtrl.dispose();
    _armCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        // Environment
        Positioned.fill(
          child: AnimatedBuilder(
            animation: Listenable.merge([_trkCtrl, _plsCtrl]),
            builder: (_, __) => CustomPaint(
              painter: _EnvPainter(
                wx: _wx, wy: _wy, heading: _heading,
                trail: _trail, pulse: _plsCtrl.value,
                gas: _gas, items: _items,
              ),
            ),
          ),
        ),
        // Robot
        Center(
          child: AnimatedBuilder(
            animation: Listenable.merge([_trkCtrl, _plsCtrl, _armCtrl]),
            builder: (_, __) => FittedBox(
              child: SizedBox(
                width: 300, height: 300,
                child: CustomPaint(
                  painter: _RobotPainter(
                    track: _trkCtrl.value,
                    pulse: _plsCtrl.value,
                    armAnim: _armCtrl.value,
                    gas: _gas,
                    reverse: _reverse,
                    armActive: _armActive,
                    itemsCollected: _itemsCollected,
                  ),
                ),
              ),
            ),
          ),
        ),
        // HUD
        Positioned(
          top: 44, left: 16,
          child: _HudWidget(
            heading: _heading,
            gas: _gas,
            reverse: _reverse,
            items: _itemsCollected,
          ),
        ),
        // Controls
        Positioned(
          left: 0, right: 0, bottom: 0,
          child: _ControlsBar(
            stickPos: _stickPos,
            gas: _gas,
            reverse: _reverse,
            armActive: _armActive,
            onStickChanged: _onStickChanged,
            onStickEnd: _onStickEnd,
            onGas: _setGas,
            onReverse: _setReverse,
            onBrake: _brake,
            onArm: _toggleArm,
            onBack: () => Navigator.of(context).pop(),
          ),
        ),
      ]),
    );
  }
}

// ─── HUD ──────────────────────────────────────────────────────────────────────
class _HudWidget extends StatelessWidget {
  final double heading;
  final bool gas, reverse;
  final int items;
  const _HudWidget({
    required this.heading,
    required this.gas,
    required this.reverse,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final deg = (heading * 180 / math.pi).toStringAsFixed(0);
    const dirs = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final dir = dirs[((heading / (2 * math.pi)) * 8).round() % 8];
    final moving = gas || reverse;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: const Color(0xFF00B4FF).withValues(alpha: 0.4)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.navigation, color: Color(0xFF00B4FF), size: 13),
          const SizedBox(width: 4),
          Text('$dir  $deg°',
              style: const TextStyle(
                  color: Color(0xFF00B4FF), fontSize: 12)),
        ]),
        const SizedBox(height: 3),
        Row(children: [
          Icon(
            moving ? Icons.speed : Icons.pause,
            color: gas
                ? Colors.greenAccent
                : reverse
                    ? Colors.orangeAccent
                    : Colors.grey,
            size: 13,
          ),
          const SizedBox(width: 4),
          Text(
            gas ? 'FORWARD' : reverse ? 'REVERSE' : 'IDLE',
            style: TextStyle(
              color: gas
                  ? Colors.greenAccent
                  : reverse
                      ? Colors.orangeAccent
                      : Colors.grey,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ]),
        if (items > 0) ...[
          const SizedBox(height: 3),
          Row(children: [
            const Icon(Icons.inventory_2,
                color: Colors.orangeAccent, size: 13),
            const SizedBox(width: 4),
            Text('$items items',
                style: const TextStyle(
                    color: Colors.orangeAccent, fontSize: 11)),
          ]),
        ],
      ]),
    );
  }
}

// ─── Controls Bar ─────────────────────────────────────────────────────────────
class _ControlsBar extends StatelessWidget {
  final Offset stickPos;
  final bool gas, reverse, armActive;
  final ValueChanged<Offset> onStickChanged;
  final VoidCallback onStickEnd;
  final ValueChanged<bool> onGas;
  final ValueChanged<bool> onReverse;
  final VoidCallback onBrake, onArm, onBack;

  const _ControlsBar({
    required this.stickPos,
    required this.gas,
    required this.reverse,
    required this.armActive,
    required this.onStickChanged,
    required this.onStickEnd,
    required this.onGas,
    required this.onReverse,
    required this.onBrake,
    required this.onArm,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withValues(alpha: 0.96),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Steering wheel
          _SteeringWheelWidget(
            stickPos: stickPos,
            onStickChanged: onStickChanged,
            onStickEnd: onStickEnd,
          ),
          const Spacer(),
          // Middle buttons
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _IconBtn(
                icon: Icons.arrow_back,
                label: 'BACK',
                color: Colors.grey,
                onTap: onBack,
              ),
              const SizedBox(height: 8),
              _IconBtn(
                icon: Icons.precision_manufacturing,
                label: armActive ? 'ARM ON' : 'ARM',
                color: armActive
                    ? Colors.orangeAccent
                    : const Color(0xFF4A8090),
                onTap: onArm,
              ),
            ]),
          ),
          const Spacer(),
          // Pedals
          _PedalsWidget(
            gas: gas,
            reverse: reverse,
            onGas: onGas,
            onReverse: onReverse,
            onBrake: onBrake,
          ),
        ],
      ),
    );
  }
}

// ─── Steering Wheel ───────────────────────────────────────────────────────────
class _SteeringWheelWidget extends StatelessWidget {
  final Offset stickPos;
  final ValueChanged<Offset> onStickChanged;
  final VoidCallback onStickEnd;

  const _SteeringWheelWidget({
    required this.stickPos,
    required this.onStickChanged,
    required this.onStickEnd,
  });

  static const _size = 150.0;
  static const _wheelR = 68.0;
  static const _deadR = 20.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (d) {
        final center = const Offset(_size / 2, _size / 2);
        final offset = d.localPosition - center;
        final maxR = _wheelR - _deadR - 8;
        var nx = offset.dx / maxR;
        var ny = offset.dy / maxR;
        final len = math.sqrt(nx * nx + ny * ny);
        if (len > 1) { nx /= len; ny /= len; }
        onStickChanged(Offset(nx.clamp(-1, 1), ny.clamp(-1, 1)));
      },
      onPanEnd: (_) => onStickEnd(),
      onPanCancel: onStickEnd,
      child: SizedBox(
        width: _size,
        height: _size,
        child: CustomPaint(
          painter: _SteeringWheelPainter(
            stickPos: stickPos,
            wheelR: _wheelR,
            deadR: _deadR,
          ),
        ),
      ),
    );
  }
}

class _SteeringWheelPainter extends CustomPainter {
  final Offset stickPos;
  final double wheelR, deadR;
  const _SteeringWheelPainter({
    required this.stickPos,
    required this.wheelR,
    required this.deadR,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final center = Offset(cx, cy);
    final stickR = deadR - 4;

    canvas.drawCircle(center + const Offset(3, 4), wheelR,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));

    canvas.drawCircle(center, wheelR,
        Paint()
          ..shader = RadialGradient(
            colors: [const Color(0xFF606060), const Color(0xFF282828)],
            stops: const [0.72, 1.0],
          ).createShader(Rect.fromCircle(center: center, radius: wheelR)));

    canvas.drawArc(
        Rect.fromCircle(center: center, radius: wheelR - 5),
        -math.pi * 0.75, math.pi * 0.55, false,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.18)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round);

    canvas.drawCircle(center, wheelR - 13,
        Paint()..color = const Color(0xFF0E0E0E));

    final spokeAngle = stickPos.dx * 0.45;
    final spokePaint = Paint()
      ..color = const Color(0xFF484848)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 3; i++) {
      final a = spokeAngle + i * 2 * math.pi / 3 - math.pi / 2;
      canvas.drawLine(
        center + Offset(math.cos(a) * (deadR + 2), math.sin(a) * (deadR + 2)),
        center + Offset(math.cos(a) * (wheelR - 14), math.sin(a) * (wheelR - 14)),
        spokePaint,
      );
    }

    canvas.drawCircle(center, deadR + 2,
        Paint()
          ..shader = RadialGradient(
            colors: [const Color(0xFF555555), const Color(0xFF1A1A1A)],
          ).createShader(Rect.fromCircle(center: center, radius: deadR + 2)));
    canvas.drawCircle(center, deadR + 2,
        Paint()
          ..color = const Color(0xFF606060)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    canvas.drawCircle(center, 5,
        Paint()..color = const Color(0xFF00B4FF).withValues(alpha: 0.8));

    final maxR = wheelR - deadR - 8;
    final ballCenter = center + Offset(stickPos.dx * maxR, stickPos.dy * maxR);
    canvas.drawCircle(ballCenter + const Offset(2, 3), stickR,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.6)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
    canvas.drawCircle(ballCenter, stickR,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.35, -0.35),
            colors: [const Color(0xFF00DFFF), const Color(0xFF005A80)],
          ).createShader(Rect.fromCircle(center: ballCenter, radius: stickR)));
    canvas.drawCircle(ballCenter, stickR,
        Paint()
          ..color = const Color(0xFF00B4FF).withValues(alpha: 0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    canvas.drawCircle(
        ballCenter + Offset(-stickR * 0.3, -stickR * 0.32),
        stickR * 0.38,
        Paint()..color = Colors.white.withValues(alpha: 0.45));
  }

  @override
  bool shouldRepaint(_SteeringWheelPainter old) => old.stickPos != stickPos;
}

// ─── Pedals ───────────────────────────────────────────────────────────────────
class _PedalsWidget extends StatelessWidget {
  final bool gas, reverse;
  final ValueChanged<bool> onGas;
  final ValueChanged<bool> onReverse;
  final VoidCallback onBrake;

  const _PedalsWidget({
    required this.gas,
    required this.reverse,
    required this.onGas,
    required this.onReverse,
    required this.onBrake,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Reverse
          GestureDetector(
            onTapDown: (_) => onReverse(true),
            onTapUp: (_) => onReverse(false),
            onTapCancel: () => onReverse(false),
            child: _PedalWidget(
              label: 'REV',
              isActive: reverse,
              color: Colors.orangeAccent,
            ),
          ),
          const SizedBox(height: 6),
          // Brake
          GestureDetector(
            onTap: onBrake,
            child: const _PedalWidget(
              label: 'BRAKE',
              isActive: false,
              color: Colors.redAccent,
            ),
          ),
          const SizedBox(height: 6),
          // Gas
          GestureDetector(
            onTapDown: (_) => onGas(true),
            onTapUp: (_) => onGas(false),
            onTapCancel: () => onGas(false),
            child: _PedalWidget(
              label: 'GAS',
              isActive: gas,
              color: Colors.greenAccent,
            ),
          ),
        ],
      ),
    );
  }
}

class _PedalWidget extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color color;

  const _PedalWidget({
    required this.label,
    required this.isActive,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      height: 46,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: isActive
            ? color.withValues(alpha: 0.35)
            : const Color(0xFF1A1A1A),
        border: Border.all(
          color: isActive ? color : Colors.white24,
          width: isActive ? 2 : 1,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 10,
                  spreadRadius: 2,
                )
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            label == 'GAS'
                ? Icons.arrow_upward
                : label == 'REV'
                    ? Icons.arrow_downward
                    : Icons.stop,
            color: isActive ? color : Colors.white54,
            size: 16,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: isActive ? color : Colors.white54,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Icon Button ──────────────────────────────────────────────────────────────
class _IconBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _IconBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.15),
          border: Border.all(color: color, width: 1.8),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 20),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 8,
                  fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }
}

// ─── Environment Painter ──────────────────────────────────────────────────────
class _EnvPainter extends CustomPainter {
  final double wx, wy, heading, pulse;
  final List<Offset> trail;
  final bool gas;
  final List<_GroundItem> items;

  _EnvPainter({
    required this.wx,
    required this.wy,
    required this.heading,
    required this.trail,
    required this.pulse,
    required this.gas,
    required this.items,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Dark tech background
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()
          ..shader = RadialGradient(
            colors: [const Color(0xFF0A1628), const Color(0xFF030810)],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)));

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(-heading);
    canvas.translate(-wx, -wy);

    _drawGrid(canvas);
    _drawCircuits(canvas);
    _drawTrail(canvas);
    _drawItems(canvas);

    canvas.restore();

    _drawVignette(canvas, size, cx, cy);
    if (gas) _drawSpeedLines(canvas, size, cx, cy);
  }

  void _drawGrid(Canvas canvas) {
    const step = 60.0;
    final gp = Paint()
      ..color = const Color(0xFF00B4FF).withValues(alpha: 0.08)
      ..strokeWidth = 0.8;
    final x0 = (wx / step).floor() * step - 800;
    final y0 = (wy / step).floor() * step - 600;
    for (double x = x0; x < wx + 800; x += step) {
      canvas.drawLine(Offset(x, wy - 600), Offset(x, wy + 600), gp);
    }
    for (double y = y0; y < wy + 600; y += step) {
      canvas.drawLine(Offset(wx - 800, y), Offset(wx + 800, y), gp);
    }
    // Hex dots at intersections
    for (double x = x0; x < wx + 800; x += step) {
      for (double y = y0; y < wy + 600; y += step) {
        canvas.drawCircle(Offset(x, y), 1.5,
            Paint()
              ..color = const Color(0xFF00B4FF).withValues(alpha: 0.2));
      }
    }
  }

  void _drawCircuits(Canvas canvas) {
    final cp = Paint()
      ..color = const Color(0xFF00B4FF).withValues(alpha: 0.06)
      ..strokeWidth = 1.5;
    final rng = math.Random(77);
    for (int i = 0; i < 30; i++) {
      final x = ((wx / 200).floor() + rng.nextInt(10) - 5) * 200.0 +
          rng.nextDouble() * 180;
      final y = ((wy / 200).floor() + rng.nextInt(10) - 5) * 200.0 +
          rng.nextDouble() * 180;
      canvas.drawLine(Offset(x, y), Offset(x + 40, y), cp);
      canvas.drawLine(Offset(x + 40, y), Offset(x + 40, y + 30), cp);
      canvas.drawCircle(Offset(x + 40, y + 30), 3,
          Paint()
            ..color = const Color(0xFF00B4FF).withValues(alpha: 0.15));
    }
  }

  void _drawTrail(Canvas canvas) {
    if (trail.length < 2) return;
    for (int i = 1; i < trail.length; i++) {
      canvas.drawLine(
          trail[i - 1], trail[i],
          Paint()
            ..color = const Color(0xFF00B4FF)
                .withValues(alpha: i / trail.length * 0.35)
            ..strokeWidth = 2.5
            ..strokeCap = StrokeCap.round);
    }
  }

  void _drawItems(Canvas canvas) {
    for (final item in items) {
      if (item.collected) continue;
      _drawItem(canvas, item);
    }
  }

  void _drawItem(Canvas canvas, _GroundItem item) {
    final x = item.pos.dx;
    final y = item.pos.dy;

    // Glow
    canvas.drawCircle(Offset(x, y), 22 + pulse * 5,
        Paint()
          ..color = (item.type == 0
                  ? Colors.orangeAccent
                  : item.type == 1
                      ? Colors.cyanAccent
                      : Colors.purpleAccent)
              .withValues(alpha: 0.12 + pulse * 0.08)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));

    if (item.type == 0) {
      // Crate
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset(x, y), width: 26, height: 26),
              const Radius.circular(3)),
          Paint()
            ..shader = const LinearGradient(
              colors: [Color(0xFFC27A1A), Color(0xFF6B3D00)],
            ).createShader(Rect.fromCenter(
                center: Offset(x, y), width: 26, height: 26)));
      final gp = Paint()
        ..color = Colors.black.withValues(alpha: 0.3)
        ..strokeWidth = 1;
      canvas.drawLine(Offset(x, y - 12), Offset(x, y + 12), gp);
      canvas.drawLine(Offset(x - 12, y), Offset(x + 12, y), gp);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset(x, y), width: 26, height: 26),
              const Radius.circular(3)),
          Paint()
            ..color = Colors.orangeAccent.withValues(alpha: 0.4)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5);
    } else if (item.type == 1) {
      // Sphere
      canvas.drawCircle(Offset(x, y), 11,
          Paint()
            ..shader = RadialGradient(
              center: const Alignment(-0.3, -0.3),
              colors: [Colors.cyanAccent, const Color(0xFF004060)],
            ).createShader(
                Rect.fromCircle(center: Offset(x, y), radius: 11)));
      canvas.drawCircle(Offset(x, y), 11,
          Paint()
            ..color = Colors.cyanAccent.withValues(alpha: 0.5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5);
    } else {
      // Gem
      final gem = Path()
        ..moveTo(x, y - 13)
        ..lineTo(x + 9, y - 3)
        ..lineTo(x + 7, y + 10)
        ..lineTo(x - 7, y + 10)
        ..lineTo(x - 9, y - 3)
        ..close();
      canvas.drawPath(gem,
          Paint()..color = const Color(0xFFAA00FF).withValues(alpha: 0.9));
      canvas.drawPath(gem,
          Paint()
            ..color = Colors.purpleAccent
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5);
    }
  }

  void _drawSpeedLines(Canvas canvas, Size size, double cx, double cy) {
    final rng = math.Random(13);
    for (int i = 0; i < 14; i++) {
      final angle = rng.nextDouble() * 2 * math.pi;
      final dist = 80 + rng.nextDouble() * size.width * 0.35;
      final len = 20 + rng.nextDouble() * 50;
      canvas.drawLine(
          Offset(cx + math.cos(angle) * dist, cy + math.sin(angle) * dist),
          Offset(cx + math.cos(angle) * (dist + len),
              cy + math.sin(angle) * (dist + len)),
          Paint()
            ..color = const Color(0xFF00B4FF)
                .withValues(alpha: 0.08 + pulse * 0.06)
            ..strokeWidth = 1.2
            ..strokeCap = StrokeCap.round);
    }
  }

  void _drawVignette(Canvas canvas, Size size, double cx, double cy) {
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()
          ..shader = RadialGradient(
            colors: [Colors.transparent, Colors.black.withValues(alpha: 0.75)],
            stops: const [0.45, 1.0],
          ).createShader(Rect.fromCircle(
              center: Offset(cx, cy), radius: size.width * 0.65)));
  }

  @override
  bool shouldRepaint(_EnvPainter old) => true;
}

// ─── Robot Painter ────────────────────────────────────────────────────────────
class _RobotPainter extends CustomPainter {
  final double track, pulse, armAnim;
  final bool gas, reverse, armActive;
  final int itemsCollected;

  const _RobotPainter({
    required this.track,
    required this.pulse,
    required this.armAnim,
    required this.gas,
    required this.reverse,
    required this.armActive,
    required this.itemsCollected,
  });

  static const _cx = 150.0;
  static const _cy = 160.0;

  @override
  void paint(Canvas canvas, Size size) {
    _drawTracks(canvas);
    _drawBody(canvas);
    _drawBackBox(canvas);
    _drawArm(canvas);
    _drawFront(canvas);
  }

  void _drawBackBox(Canvas canvas) {
    // Box on robot's back (top of body)
    const boxCx = _cx;
    const boxCy = _cy - 52.0;
    const bw = 44.0, bh = 28.0;

    // Shadow
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: const Offset(boxCx + 2, boxCy + 3),
                width: bw, height: bh),
            const Radius.circular(4)),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));

    // Box body
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: const Offset(boxCx, boxCy),
                width: bw, height: bh),
            const Radius.circular(4)),
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2A4060), Color(0xFF0D1B2A)],
          ).createShader(Rect.fromCenter(
              center: const Offset(boxCx, boxCy), width: bw, height: bh)));

    // Box border
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: const Offset(boxCx, boxCy),
                width: bw, height: bh),
            const Radius.circular(4)),
        Paint()
          ..color = const Color(0xFF00B4FF).withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);

    // Items count or empty indicator
    if (itemsCollected > 0) {
      // Show collected items
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(
                  center: const Offset(boxCx, boxCy),
                  width: bw - 8, height: bh - 8),
              const Radius.circular(3)),
          Paint()
            ..color = Colors.orangeAccent.withValues(alpha: 0.2));

      final tp = TextPainter(
        text: TextSpan(
          text: 'x$itemsCollected',
          style: const TextStyle(
            color: Colors.orangeAccent,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas,
          Offset(boxCx - tp.width / 2, boxCy - tp.height / 2));

      // Glow when items inside
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(
                  center: const Offset(boxCx, boxCy),
                  width: bw + 4, height: bh + 4),
              const Radius.circular(6)),
          Paint()
            ..color = Colors.orangeAccent
                .withValues(alpha: 0.15 + pulse * 0.12)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    } else {
      // Empty box indicator
      canvas.drawLine(
          const Offset(boxCx - 8, boxCy - 6),
          const Offset(boxCx + 8, boxCy + 6),
          Paint()
            ..color = const Color(0xFF00B4FF).withValues(alpha: 0.3)
            ..strokeWidth = 1.5);
      canvas.drawLine(
          const Offset(boxCx + 8, boxCy - 6),
          const Offset(boxCx - 8, boxCy + 6),
          Paint()
            ..color = const Color(0xFF00B4FF).withValues(alpha: 0.3)
            ..strokeWidth = 1.5);
    }

    // Box lid
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: const Offset(boxCx, boxCy - bh / 2 - 2),
                width: bw + 4, height: 5),
            const Radius.circular(2)),
        Paint()..color = const Color(0xFF3A5070));
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: const Offset(boxCx, boxCy - bh / 2 - 2),
                width: bw + 4, height: 5),
            const Radius.circular(2)),
        Paint()
          ..color = const Color(0xFF00B4FF).withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);
  }

  void _drawTracks(Canvas canvas) {
    for (final side in [-1, 1]) {
      final tx = _cx + side * 66.0;
      const trackW = 24.0, trackH = 88.0, trackR = 12.0;
      final beltRect = RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(tx, _cy), width: trackW, height: trackH),
          const Radius.circular(trackR));

      canvas.drawRRect(beltRect.shift(const Offset(2, 3)),
          Paint()
            ..color = Colors.black.withValues(alpha: 0.5)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));

      canvas.drawRRect(beltRect,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                Color(0xFF1A2530),
                Color(0xFF2A3A48),
                Color(0xFF1A2530),
              ],
            ).createShader(Rect.fromCenter(
                center: Offset(tx, _cy), width: trackW, height: trackH)));

      canvas.save();
      canvas.clipRRect(beltRect);
      const linkH = 10.0;
      final tDir = reverse ? -1.0 : 1.0;
      final offset = (track * linkH * tDir) % linkH;
      for (double y = _cy - trackH / 2 - linkH + offset;
          y < _cy + trackH / 2 + linkH;
          y += linkH) {
        canvas.drawRect(
            Rect.fromCenter(
                center: Offset(tx, y), width: trackW - 4, height: linkH - 2),
            Paint()
              ..color = const Color(0xFF3A4A5A)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1);
      }
      canvas.restore();

      for (final sy in [
        _cy - trackH / 2 + trackR,
        _cy + trackH / 2 - trackR,
      ]) {
        canvas.drawCircle(Offset(tx, sy), trackR - 2,
            Paint()..color = const Color(0xFF3A5060));
        canvas.drawCircle(Offset(tx, sy), trackR - 2,
            Paint()
              ..color = const Color(0xFF5A7080)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2);
        for (int t = 0; t < 6; t++) {
          final a = t * math.pi / 3 + track * math.pi * 2;
          canvas.drawCircle(
              Offset(tx + math.cos(a) * (trackR + 1),
                  sy + math.sin(a) * (trackR + 1)),
              2.5,
              Paint()..color = const Color(0xFF6A8090));
        }
      }

      if (gas || reverse) {
        canvas.drawRRect(beltRect,
            Paint()
              ..color = (reverse ? Colors.orangeAccent : const Color(0xFF00B4FF))
                  .withValues(alpha: 0.12 + pulse * 0.08)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.5
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
      }
    }
  }

  void _drawBody(Canvas canvas) {
    final hull = RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: const Offset(_cx, _cy), width: 96, height: 76),
        const Radius.circular(10));

    canvas.drawRRect(hull.shift(const Offset(3, 4)),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));

    canvas.drawRRect(hull,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E3045), Color(0xFF0D1825)],
          ).createShader(Rect.fromCenter(
              center: const Offset(_cx, _cy), width: 96, height: 76)));

    // Inner panel
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: const Offset(_cx, _cy + 5), width: 78, height: 50),
            const Radius.circular(6)),
        Paint()
          ..color = const Color(0xFF0A1520)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);

    // Bolts
    for (final bx in [-34.0, 34.0]) {
      for (final by in [-26.0, 26.0]) {
        canvas.drawCircle(Offset(_cx + bx, _cy + by), 3,
            Paint()..color = const Color(0xFF4A6070));
        canvas.drawCircle(Offset(_cx + bx, _cy + by), 1.5,
            Paint()..color = const Color(0xFF6A8090));
      }
    }

    // PCB lines
    final pcb = Paint()
      ..color = const Color(0xFF00B4FF).withValues(alpha: 0.25)
      ..strokeWidth = 1;
    canvas.drawLine(const Offset(_cx - 20, _cy + 10),
        const Offset(_cx + 15, _cy + 10), pcb);
    canvas.drawLine(const Offset(_cx - 5, _cy), const Offset(_cx - 5, _cy + 20), pcb);

    // LED
    canvas.drawCircle(
        const Offset(_cx + 28, _cy - 20), 4,
        Paint()
          ..color = (gas
                  ? Colors.greenAccent
                  : reverse
                      ? Colors.orangeAccent
                      : Colors.redAccent)
              .withValues(alpha: 0.7 + pulse * 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));

    // Hull glow
    canvas.drawRRect(hull,
        Paint()
          ..color = const Color(0xFF00B4FF)
              .withValues(alpha: 0.15 + pulse * 0.07)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
  }

  void _drawArm(Canvas canvas) {
    const baseX = _cx + 16.0;
    const baseY = _cy - 36.0;

    canvas.drawCircle(const Offset(baseX, baseY), 7,
        Paint()..color = const Color(0xFF3A5060));

    final seg1Angle = -math.pi / 3;
    final seg1Len = 20 + armAnim * 26;
    final seg1End = Offset(
        baseX + math.cos(seg1Angle) * seg1Len,
        baseY + math.sin(seg1Angle) * seg1Len);

    canvas.drawLine(const Offset(baseX, baseY), seg1End,
        Paint()
          ..color = const Color(0xFF5A7080)
          ..strokeWidth = 7
          ..strokeCap = StrokeCap.round);

    final seg2Angle = seg1Angle - math.pi / 5 + armAnim * 0.4;
    final seg2Len = 16 + armAnim * 16;
    final seg2End = Offset(
        seg1End.dx + math.cos(seg2Angle) * seg2Len,
        seg1End.dy + math.sin(seg2Angle) * seg2Len);

    canvas.drawLine(seg1End, seg2End,
        Paint()
          ..color = const Color(0xFF4A6070)
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round);

    final spread = armActive ? 0.4 : 0.12;
    for (final s in [-1.0, 1.0]) {
      canvas.drawLine(
          seg2End,
          Offset(
              seg2End.dx + math.cos(seg2Angle + s * spread) * 12,
              seg2End.dy + math.sin(seg2Angle + s * spread) * 12),
          Paint()
            ..color = const Color(0xFF00B4FF)
            ..strokeWidth = 3
            ..strokeCap = StrokeCap.round);
    }

    if (armActive) {
      canvas.drawCircle(seg2End, 8 + pulse * 5,
          Paint()
            ..color = const Color(0xFF00B4FF)
                .withValues(alpha: 0.3 + pulse * 0.2)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    }
  }

  void _drawFront(Canvas canvas) {
    const fy = _cy - 38.0;

    // Camera eye
    canvas.drawCircle(const Offset(_cx, fy), 8,
        Paint()..color = const Color(0xFF0A1520));
    canvas.drawCircle(const Offset(_cx, fy), 8,
        Paint()
          ..color = const Color(0xFF00B4FF).withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    canvas.drawCircle(const Offset(_cx, fy), 4,
        Paint()
          ..color = const Color(0xFF00B4FF).withValues(alpha: 0.7)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));

    // Side sensors
    for (final sx in [-18.0, 18.0]) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(
                  center: Offset(_cx + sx, fy + 2), width: 7, height: 11),
              const Radius.circular(2)),
          Paint()..color = const Color(0xFF2A4050));
      canvas.drawCircle(Offset(_cx + sx, fy + 2), 3,
          Paint()
            ..color = const Color(0xFF00B4FF)
                .withValues(alpha: 0.4 + pulse * 0.3));
    }

    // LED strip
    for (int i = 0; i < 5; i++) {
      canvas.drawRect(
          Rect.fromCenter(
              center: Offset(_cx - 14 + i * 7.0, fy + 13),
              width: 5, height: 3),
          Paint()
            ..color = (i.isEven ? Colors.cyanAccent : Colors.greenAccent)
                .withValues(alpha: 0.5 + pulse * 0.4));
    }

    // Top ridge
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: const Offset(_cx, _cy - 32),
                width: 68, height: 10),
            const Radius.circular(5)),
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFF2A4050), Color(0xFF3A5065)],
          ).createShader(Rect.fromCenter(
              center: const Offset(_cx, _cy - 32), width: 68, height: 10)));
  }

  @override
  bool shouldRepaint(_RobotPainter old) => true;
}