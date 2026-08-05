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

class _RouletteWheelState extends State<RouletteWheel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  double _turns = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200));
  }

  @override
  void didUpdateWidget(covariant RouletteWheel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.spinning && !oldWidget.spinning) {
      _startSpin();
    }
  }

  Future<void> _startSpin() async {
    final target = widget.result == RouletteSymbol.coin ? 0.12 : 0.62;
    final extra = 4 + Random().nextInt(3);
    final end = _turns.floorToDouble() + extra + target;
    final anim = Tween<double>(begin: _turns, end: end).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    void listener() => setState(() => _turns = anim.value);
    anim.addListener(listener);
    _ctrl
      ..reset()
      ..forward();
    await Future<void>.delayed(_ctrl.duration!);
    anim.removeListener(listener);
    widget.onSpinEnd?.call();
  }

  @override
  void dispose() {
    _ctrl.dispose();
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
              gradient: const LinearGradient(
                colors: [AppColors.gold, AppColors.goldDeep],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 10,
                ),
              ],
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: const Center(
              child: Text('🦈', style: TextStyle(fontSize: 28)),
            ),
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
    const segments = 8;
    for (var i = 0; i < segments; i++) {
      final start = -pi / 2 + (i * 2 * pi / segments);
      final isCoin = i.isEven;
      final paint = Paint()
        ..shader = SweepGradient(
          startAngle: start,
          endAngle: start + 2 * pi / segments,
          colors: isCoin
              ? [const Color(0xFFFFD54F), const Color(0xFFFF8F00)]
              : [const Color(0xFF42A5F5), const Color(0xFF1565C0)],
        ).createShader(Rect.fromCircle(center: c, radius: r));
      canvas.drawArc(Rect.fromCircle(center: c, radius: r), start, 2 * pi / segments, true, paint);

      final mid = start + pi / segments;
      final tx = c.dx + cos(mid) * r * 0.62;
      final ty = c.dy + sin(mid) * r * 0.62;
      final tp = TextPainter(
        text: TextSpan(
          text: isCoin ? '🪙' : '🦈',
          style: const TextStyle(fontSize: 28),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      canvas.save();
      canvas.translate(tx - tp.width / 2, ty - tp.height / 2);
      tp.paint(canvas, Offset.zero);
      canvas.restore();
    }

    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..color = Colors.white;
    canvas.drawCircle(c, r - 5, rim);
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
