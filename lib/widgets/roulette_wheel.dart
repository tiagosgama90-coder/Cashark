import 'dart:math';

import 'package:flutter/material.dart';

import '../models/economy.dart';
import '../theme/app_theme.dart';

class RouletteWheel extends StatefulWidget {
  final bool spinning;
  final RouletteSymbol? result;
  final VoidCallback? onSpinEnd;

  const RouletteWheel({
    super.key,
    required this.spinning,
    this.result,
    this.onSpinEnd,
  });

  @override
  State<RouletteWheel> createState() => _RouletteWheelState();
}

class _RouletteWheelState extends State<RouletteWheel> with TickerProviderStateMixin {
  late final AnimationController _spinCtrl;
  late final AnimationController _idleCtrl;
  double _turns = 0;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _spinCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3400));
    _idleCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 12))
      ..addListener(() {
        if (!_busy && !widget.spinning) {
          setState(() => _turns = _idleCtrl.value);
        }
      })
      ..repeat();
  }

  @override
  void didUpdateWidget(covariant RouletteWheel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.spinning && !oldWidget.spinning) {
      _startSpin();
    }
  }

  Future<void> _startSpin() async {
    _busy = true;
    _idleCtrl.stop();
    final target = widget.result == RouletteSymbol.coin ? 0.12 : 0.62;
    final extra = 5 + Random().nextInt(4);
    final begin = _turns;
    final end = begin.floorToDouble() + extra + target;
    final anim = Tween<double>(begin: begin, end: end).animate(
      CurvedAnimation(parent: _spinCtrl, curve: Curves.easeOutCubic),
    );
    void listener() => setState(() => _turns = anim.value);
    anim.addListener(listener);
    _spinCtrl
      ..reset()
      ..forward();
    await Future<void>.delayed(_spinCtrl.duration!);
    anim.removeListener(listener);
    _busy = false;
    // Resume idle from current angle
    _idleCtrl.value = _turns % 1.0;
    _idleCtrl.repeat();
    widget.onSpinEnd?.call();
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    _idleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Soft glow under wheel
          Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.orange.withValues(alpha: 0.45),
                  blurRadius: 28,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          Transform.rotate(
            angle: _turns * 2 * pi,
            child: CustomPaint(
              size: const Size(280, 280),
              painter: _WheelPainter(),
            ),
          ),
          const Icon(Icons.arrow_drop_down, size: 56, color: Colors.white),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [AppColors.gold, AppColors.goldDeep]),
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 10),
              ],
            ),
            child: const Center(child: Text('🦈', style: TextStyle(fontSize: 28))),
          ),
        ],
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    const segments = 10;
    for (var i = 0; i < segments; i++) {
      final start = -pi / 2 + (i * 2 * pi / segments);
      final isCoin = i.isEven;
      final paint = Paint()
        ..color = isCoin ? const Color(0xFFFFB300) : const Color(0xFF1E88E5);
      canvas.drawArc(Rect.fromCircle(center: c, radius: r), start, 2 * pi / segments, true, paint);

      // Highlight wedge
      final mid = start + pi / segments;
      final tx = c.dx + cos(mid) * r * 0.62;
      final ty = c.dy + sin(mid) * r * 0.62;
      final tp = TextPainter(
        text: TextSpan(text: isCoin ? '🪙' : '🦈', style: const TextStyle(fontSize: 26)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(tx - tp.width / 2, ty - tp.height / 2));
    }

    canvas.drawCircle(
      c,
      r - 5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..color = Colors.white,
    );
    canvas.drawCircle(
      c,
      r - 5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = AppColors.orangeDeep,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
