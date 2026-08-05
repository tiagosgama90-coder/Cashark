import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../services/ads_service.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';

enum _Phase { ready, playing, over }

/// Stardust-style 3D rail shooter with a shark-shaped ship.
class SpaceShooterGame extends StatefulWidget {
  const SpaceShooterGame({super.key});

  @override
  State<SpaceShooterGame> createState() => _SpaceShooterGameState();
}

class _SpaceShooterGameState extends State<SpaceShooterGame>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  _Phase phase = _Phase.ready;
  Size view = Size.zero;

  // Ship position in a near plane (world units).
  double shipX = 0;
  double shipY = -0.6;
  double shipBank = 0;
  double thrust = 0;

  final bullets = <_Bullet>[];
  final enemies = <_Enemy3D>[];
  final rings = <_TunnelRing>[];
  final stars = <_Star3D>[];
  final sparks = <_Spark>[];

  double _fireAcc = 0;
  double _spawnAcc = 0;
  double _time = 0;
  int sessionKills = 0;
  final _rng = math.Random();

  static const nearZ = 1.2;
  static const farZ = 42.0;
  static const shipZ = 2.4;
  static const fov = 1.15;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _seedWorld() {
    rings
      ..clear()
      ..addAll(List.generate(14, (i) {
        final z = 3.0 + i * 3.0;
        return _TunnelRing(
          z: z,
          radius: 3.2 + math.sin(i * 0.7) * 0.35,
          hue: (i * 28) % 360,
          rot: i * 0.2,
        );
      }));
    stars
      ..clear()
      ..addAll(List.generate(90, (_) {
        return _Star3D(
          x: (_rng.nextDouble() - 0.5) * 16,
          y: (_rng.nextDouble() - 0.5) * 12,
          z: nearZ + _rng.nextDouble() * (farZ - nearZ),
          speed: 8 + _rng.nextDouble() * 14,
          size: 0.8 + _rng.nextDouble() * 1.8,
        );
      }));
    bullets.clear();
    enemies.clear();
    sparks.clear();
    shipX = 0;
    shipY = -0.55;
    shipBank = 0;
    sessionKills = 0;
    _fireAcc = 0;
    _spawnAcc = 0;
  }

  void _start() {
    final lives = context.read<AppState>().user?.lives ?? 0;
    if (lives <= 0) {
      _showBuyLives();
      return;
    }
    setState(() {
      phase = _Phase.playing;
      _seedWorld();
    });
  }

  Offset _project(double x, double y, double z) {
    final zz = z.clamp(0.35, 80.0);
    final s = (view.height * 0.55) / (fov * zz);
    return Offset(view.width * 0.5 + x * s, view.height * 0.52 - y * s);
  }

  double _scale(double z) => (view.height * 0.55) / (fov * z.clamp(0.35, 80.0));

  void _tick(Duration _) {
    if (view == Size.zero) return;
    const dt = 1 / 60;
    _time += dt;
    thrust += dt;

    // Always animate background a bit on menus.
    final playing = phase == _Phase.playing;
    final speedMul = playing ? 1.0 : 0.35;

    for (final s in stars) {
      s.z -= s.speed * dt * speedMul;
      if (s.z < nearZ) {
        s.z = farZ;
        s.x = (_rng.nextDouble() - 0.5) * 16;
        s.y = (_rng.nextDouble() - 0.5) * 12;
      }
    }

    for (final r in rings) {
      r.z -= 10.5 * dt * speedMul;
      r.rot += dt * 0.55;
      if (r.z < nearZ) {
        r.z = farZ;
        r.hue = (r.hue + 40) % 360;
        r.radius = 3.0 + _rng.nextDouble() * 0.7;
      }
    }

    for (var i = sparks.length - 1; i >= 0; i--) {
      final sp = sparks[i];
      sp.life -= dt;
      sp.x += sp.vx * dt;
      sp.y += sp.vy * dt;
      sp.z += sp.vz * dt;
      if (sp.life <= 0) sparks.removeAt(i);
    }

    if (!playing) {
      setState(() {});
      return;
    }

    // Ease bank back.
    shipBank *= 0.90;

    // Bullets fly forward (+depth decrease? toward far = increasing z visually into screen)
    // We shoot INTO the tunnel: bullets increase Z (away from camera) from ship.
    for (var i = bullets.length - 1; i >= 0; i--) {
      final b = bullets[i];
      b.z += 28 * dt;
      b.x += b.vx * dt;
      if (b.z > farZ) bullets.removeAt(i);
    }

    _fireAcc += dt;
    if (_fireAcc > 0.16) {
      _fireAcc = 0;
      bullets.add(_Bullet(x: shipX - 0.18, y: shipY + 0.05, z: shipZ + 0.2, vx: -0.15));
      bullets.add(_Bullet(x: shipX + 0.18, y: shipY + 0.05, z: shipZ + 0.2, vx: 0.15));
    }

    _spawnAcc += dt;
    if (_spawnAcc > 0.78) {
      _spawnAcc = 0;
      enemies.add(_Enemy3D(
        x: (_rng.nextDouble() - 0.5) * 3.4,
        y: (_rng.nextDouble() - 0.5) * 2.2,
        z: farZ - 2,
        speed: 7.5 + _rng.nextDouble() * 5.5,
        hue: _rng.nextDouble() * 360,
        hp: 1 + _rng.nextInt(2),
        wobble: _rng.nextDouble() * math.pi * 2,
        kind: _rng.nextInt(3),
      ));
    }

    final state = context.read<AppState>();
    for (var i = enemies.length - 1; i >= 0; i--) {
      final e = enemies[i];
      e.z -= e.speed * dt;
      e.wobble += dt * 2.5;
      e.x += math.sin(e.wobble) * 0.55 * dt;
      e.y += math.cos(e.wobble * 0.8) * 0.35 * dt;

      // Bullet hits
      for (var bi = bullets.length - 1; bi >= 0; bi--) {
        final b = bullets[bi];
        final dx = b.x - e.x;
        final dy = b.y - e.y;
        final dz = b.z - e.z;
        if (dx * dx + dy * dy + dz * dz < 0.85) {
          bullets.removeAt(bi);
          e.hp -= 1;
          _burst(e.x, e.y, e.z, e.hue);
          if (e.hp <= 0) {
            enemies.removeAt(i);
            sessionKills += 1;
            state.registerKill();
          }
          break;
        }
      }
      if (i >= enemies.length) continue;

      // Reach ship depth → damage
      if (e.z <= shipZ + 0.35) {
        final dx = e.x - shipX;
        final dy = e.y - shipY;
        if (dx * dx + dy * dy < 1.1 || e.z < shipZ - 0.1) {
          _burst(e.x, e.y, e.z, 10);
          enemies.removeAt(i);
          state.loseLife();
          if ((state.user?.lives ?? 0) <= 0) {
            setState(() => phase = _Phase.over);
            return;
          }
        } else if (e.z < nearZ) {
          enemies.removeAt(i);
        }
      }
    }

    setState(() {});
  }

  void _burst(double x, double y, double z, double hue) {
    for (var i = 0; i < 10; i++) {
      sparks.add(_Spark(
        x: x,
        y: y,
        z: z,
        vx: (_rng.nextDouble() - 0.5) * 3,
        vy: (_rng.nextDouble() - 0.5) * 3,
        vz: (_rng.nextDouble() - 0.5) * 4,
        life: 0.35 + _rng.nextDouble() * 0.35,
        hue: hue,
      ));
    }
  }

  void _onPan(DragUpdateDetails d) {
    if (phase != _Phase.playing || view == Size.zero) return;
    // Map finger to ship plane.
    shipX = (shipX + d.delta.dx / view.width * 5.2).clamp(-2.1, 2.1);
    shipY = (shipY - d.delta.dy / view.height * 4.2).clamp(-1.6, 1.5);
    shipBank = (shipBank + d.delta.dx * 0.04).clamp(-0.7, 0.7);
  }

  Future<void> _showBuyLives() async {
    final state = context.read<AppState>();
    final ads = context.read<AdsService>();
    final l = state.l10n;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1A1030),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l.t('buy_lives'),
                  style: GoogleFonts.fredoka(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
              ListTile(
                leading: const Text('🪙', style: TextStyle(fontSize: 28)),
                title: Text(l.t('buy_with_cash'), style: const TextStyle(color: Colors.white)),
                subtitle: const Text('€0.25', style: TextStyle(color: Colors.white70)),
                onTap: () async {
                  final err = await state.buyLifeWithCash();
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (err != null && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                  }
                },
              ),
              ListTile(
                leading: const Text('🦈', style: TextStyle(fontSize: 28)),
                title: Text(l.t('buy_with_sharks'), style: const TextStyle(color: Colors.white)),
                subtitle: const Text('40 Sharks', style: TextStyle(color: Colors.white70)),
                onTap: () async {
                  final err = await state.buyLifeWithSharks();
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (err != null && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                  }
                },
              ),
              ListTile(
                leading: const Text('📺', style: TextStyle(fontSize: 28)),
                title: Text(l.t('watch_ad_life'), style: const TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await ads.showRewarded(onReward: () => state.addLifeFromAd());
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final l = state.l10n;
    final lives = state.user?.lives ?? 0;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF050018), Color(0xFF1A0A40), Color(0xFF3B0A2A)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    Text(l.t('play_win'),
                        style: GoogleFonts.fredoka(
                            color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    Text('❤️ x$lives', style: GoogleFonts.fredoka(color: Colors.white, fontSize: 16)),
                    const SizedBox(width: 12),
                    Text('🦈 $sessionKills', style: GoogleFonts.fredoka(color: Colors.white, fontSize: 16)),
                  ],
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, c) {
                    view = Size(c.maxWidth, c.maxHeight);
                    if (stars.isEmpty && view != Size.zero) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted && stars.isEmpty) {
                          setState(_seedWorld);
                        }
                      });
                    }
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        // 3D world — pan only while playing so START stays tappable
                        Positioned.fill(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onPanUpdate: phase == _Phase.playing ? _onPan : null,
                            child: CustomPaint(
                              painter: _StardustPainter(
                                project: _project,
                                scaleOf: _scale,
                                rings: rings,
                                stars: stars,
                                enemies: enemies,
                                bullets: bullets,
                                sparks: sparks,
                                shipX: shipX,
                                shipY: shipY,
                                shipZ: shipZ,
                                shipBank: shipBank,
                                time: _time,
                              ),
                            ),
                          ),
                        ),
                        if (phase == _Phase.ready || phase == _Phase.over)
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (phase == _Phase.over) ...[
                                  Text(l.t('game_over'),
                                      style: GoogleFonts.fredoka(
                                          color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800)),
                                  Text('${l.t('kills')}: $sessionKills',
                                      style: GoogleFonts.fredoka(color: Colors.white70, fontSize: 18)),
                                  const SizedBox(height: 14),
                                ] else ...[
                                  Text('STARDUST SHARK',
                                      style: GoogleFonts.fredoka(
                                          color: const Color(0xFFFF6B1A),
                                          fontSize: 28,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.2)),
                                  Text('3D rail · arrasta para pilotar a nave-tubarão',
                                      style: GoogleFonts.fredoka(color: Colors.white70, fontSize: 14)),
                                  const SizedBox(height: 18),
                                ],
                                _StartButton(label: l.t('start'), onTap: _start),
                                if (lives <= 0) ...[
                                  const SizedBox(height: 12),
                                  TextButton(
                                    onPressed: _showBuyLives,
                                    child: Text(l.t('buy_lives'),
                                        style: GoogleFonts.fredoka(color: AppColors.gold, fontSize: 16)),
                                  ),
                                ],
                              ],
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StartButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _StartButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFFFC107), Color(0xFFFF6B1A)]),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(color: const Color(0xFFFF6B1A).withValues(alpha: 0.55), blurRadius: 22, offset: const Offset(0, 8)),
          ],
        ),
        child: Text(label,
            style: GoogleFonts.fredoka(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
      ),
    );
  }
}

// ─── entities ───────────────────────────────────────────────────────────────

class _Bullet {
  double x, y, z, vx;
  _Bullet({required this.x, required this.y, required this.z, this.vx = 0});
}

class _Enemy3D {
  double x, y, z, speed, hue, wobble;
  int hp;
  int kind;
  _Enemy3D({
    required this.x,
    required this.y,
    required this.z,
    required this.speed,
    required this.hue,
    required this.hp,
    required this.wobble,
    required this.kind,
  });
}

class _TunnelRing {
  double z, radius, hue, rot;
  _TunnelRing({required this.z, required this.radius, required this.hue, required this.rot});
}

class _Star3D {
  double x, y, z, speed, size;
  _Star3D({required this.x, required this.y, required this.z, required this.speed, required this.size});
}

class _Spark {
  double x, y, z, vx, vy, vz, life, hue;
  _Spark({
    required this.x,
    required this.y,
    required this.z,
    required this.vx,
    required this.vy,
    required this.vz,
    required this.life,
    required this.hue,
  });
}

// ─── painter ────────────────────────────────────────────────────────────────

class _StardustPainter extends CustomPainter {
  final Offset Function(double, double, double) project;
  final double Function(double) scaleOf;
  final List<_TunnelRing> rings;
  final List<_Star3D> stars;
  final List<_Enemy3D> enemies;
  final List<_Bullet> bullets;
  final List<_Spark> sparks;
  final double shipX, shipY, shipZ, shipBank, time;

  _StardustPainter({
    required this.project,
    required this.scaleOf,
    required this.rings,
    required this.stars,
    required this.enemies,
    required this.bullets,
    required this.sparks,
    required this.shipX,
    required this.shipY,
    required this.shipZ,
    required this.shipBank,
    required this.time,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Nebula glow
    final nebula = Paint()
      ..shader = ui.Gradient.radial(
        Offset(size.width * 0.5, size.height * 0.45),
        size.shortestSide * 0.7,
        [
          const Color(0x66FF6B1A),
          const Color(0x33297BFF),
          const Color(0x00000000),
        ],
      );
    canvas.drawRect(Offset.zero & size, nebula);

    // Stars (far → near for painter's algorithm-ish)
    final sortedStars = [...stars]..sort((a, b) => b.z.compareTo(a.z));
    for (final s in sortedStars) {
      final p = project(s.x, s.y, s.z);
      final sc = scaleOf(s.z);
      canvas.drawCircle(
        p,
        (s.size * sc * 0.04).clamp(0.6, 3.5),
        Paint()..color = Colors.white.withValues(alpha: 0.35 + (1 - s.z / 42) * 0.55),
      );
    }

    // Tunnel rings
    final sortedRings = [...rings]..sort((a, b) => b.z.compareTo(a.z));
    for (final r in sortedRings) {
      _drawRing(canvas, r);
    }

    // Enemies far → near
    final sortedEnemies = [...enemies]..sort((a, b) => b.z.compareTo(a.z));
    for (final e in sortedEnemies) {
      _drawEnemy(canvas, e);
    }

    // Bullets
    for (final b in bullets) {
      final p = project(b.x, b.y, b.z);
      final sc = scaleOf(b.z);
      final paint = Paint()
        ..shader = ui.Gradient.linear(
          p.translate(0, 10 * sc * 0.05),
          p.translate(0, -18 * sc * 0.05),
          const [Color(0x00FFF59D), Color(0xFFFFF176), Color(0xFFFF6B1A)],
        );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: p, width: 5 * sc * 0.08, height: 22 * sc * 0.08),
          const Radius.circular(4),
        ),
        paint,
      );
    }

    // Sparks
    for (final sp in sparks) {
      final p = project(sp.x, sp.y, sp.z);
      canvas.drawCircle(
        p,
        2.5,
        Paint()..color = HSVColor.fromAHSV(sp.life.clamp(0, 1), sp.hue % 360, 0.9, 1).toColor(),
      );
    }

    // Shark ship (nearest)
    _drawSharkShip(canvas, shipX, shipY, shipZ, shipBank, time);
  }

  void _drawRing(Canvas canvas, _TunnelRing r) {
    const segs = 28;
    final color = HSVColor.fromAHSV(1, r.hue % 360, 0.85, 1).toColor();
    final path = Path();
    for (var i = 0; i <= segs; i++) {
      final a = r.rot + (i / segs) * math.pi * 2;
      final x = math.cos(a) * r.radius;
      final y = math.sin(a) * r.radius * 0.72;
      final p = project(x, y, r.z);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = (6 * scaleOf(r.z) * 0.06).clamp(1.5, 5)
        ..color = color.withValues(alpha: 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 0.5),
    );
    // Inner accent
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.white.withValues(alpha: 0.25),
    );
  }

  void _drawEnemy(Canvas canvas, _Enemy3D e) {
    final sc = scaleOf(e.z);
    final c = project(e.x, e.y, e.z);
    final color = HSVColor.fromAHSV(1, e.hue % 360, 0.9, 1).toColor();
    final s = 18 * sc * 0.1;

    final path = Path();
    if (e.kind == 0) {
      // Spinner diamond
      path.moveTo(c.dx, c.dy - s);
      path.lineTo(c.dx + s * 0.9, c.dy);
      path.lineTo(c.dx, c.dy + s * 0.8);
      path.lineTo(c.dx - s * 0.9, c.dy);
      path.close();
    } else if (e.kind == 1) {
      // Saucer
      path.addOval(Rect.fromCenter(center: c, width: s * 2.1, height: s * 0.9));
    } else {
      // Spike
      path.moveTo(c.dx, c.dy + s);
      path.lineTo(c.dx - s * 0.7, c.dy - s * 0.6);
      path.lineTo(c.dx, c.dy - s * 0.2);
      path.lineTo(c.dx + s * 0.7, c.dy - s * 0.6);
      path.close();
    }

    canvas.drawPath(
      path,
      Paint()
        ..shader = ui.Gradient.linear(
          c.translate(-s, -s),
          c.translate(s, s),
          [color, Color.lerp(color, Colors.white, 0.35)!],
        ),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.white.withValues(alpha: 0.65),
    );
  }

  /// Low-poly 3D shark ship facing into the tunnel (+Z).
  void _drawSharkShip(Canvas canvas, double x, double y, double z, double bank, double t) {
    // Local shark mesh points (nose forward +Z, belly -Y).
    final nose = _V(0, 0.05, 0.95);
    final tail = _V(0, 0.0, -0.85);
    final leftWing = _V(-0.75, 0.05, -0.1);
    final rightWing = _V(0.75, 0.05, -0.1);
    final dorsal = _V(0, 0.55, 0.05);
    final belly = _V(0, -0.32, 0.05);
    final jawL = _V(-0.22, -0.18, 0.55);
    final jawR = _V(0.22, -0.18, 0.55);
    final tailL = _V(-0.35, 0.05, -0.95);
    final tailR = _V(0.35, 0.05, -0.95);
    final tailTop = _V(0, 0.45, -0.9);

    _V xf(_V p) {
      // Bank (roll) + slight idle bob.
      final bob = math.sin(t * 6) * 0.03;
      final cy = math.cos(bank);
      final sy = math.sin(bank);
      final rx = p.x * cy - p.y * sy;
      final ry = p.x * sy + p.y * cy + bob;
      return _V(x + rx, y + ry, z + p.z);
    }

    final pts = {
      'nose': xf(nose),
      'tail': xf(tail),
      'lw': xf(leftWing),
      'rw': xf(rightWing),
      'dorsal': xf(dorsal),
      'belly': xf(belly),
      'jl': xf(jawL),
      'jr': xf(jawR),
      'tl': xf(tailL),
      'tr': xf(tailR),
      'tt': xf(tailTop),
    };

    Offset pr(_V v) => project(v.x, v.y, v.z);

    void face(List<String> keys, Color color, {bool stroke = true}) {
      final path = Path();
      for (var i = 0; i < keys.length; i++) {
        final p = pr(pts[keys[i]]!);
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      path.close();
      canvas.drawPath(path, Paint()..color = color);
      if (stroke) {
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.3
            ..color = Colors.white.withValues(alpha: 0.55),
        );
      }
    }

    // Draw back faces first (simple painter order).
    face(['tail', 'tl', 'tt'], const Color(0xFF1565C0));
    face(['tail', 'tr', 'tt'], const Color(0xFF1976D2));
    face(['nose', 'lw', 'dorsal'], const Color(0xFF1E88E5));
    face(['nose', 'rw', 'dorsal'], const Color(0xFF42A5F5));
    face(['nose', 'jl', 'belly'], const Color(0xFFE3F2FD));
    face(['nose', 'jr', 'belly'], const Color(0xFFBBDEFB));
    face(['nose', 'lw', 'belly'], const Color(0xFF2196F3));
    face(['nose', 'rw', 'belly'], const Color(0xFF64B5F6));
    face(['dorsal', 'lw', 'tail'], const Color(0xFF0D47A1));
    face(['dorsal', 'rw', 'tail'], const Color(0xFF1565C0));
    face(['belly', 'lw', 'tail'], const Color(0xFF90CAF9));
    face(['belly', 'rw', 'tail'], const Color(0xFF64B5F6));

    // Engine glow under belly
    final glow = pr(pts['belly']!);
    canvas.drawCircle(
      glow.translate(0, 8),
      14,
      Paint()
        ..color = const Color(0xAAFF6B1A)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    canvas.drawCircle(glow.translate(0, 6), 5, Paint()..color = const Color(0xFFFFF59D));

    // Eye
    final eye = pr(xf(_V(0.12, 0.12, 0.55)));
    canvas.drawCircle(eye, 3.2, Paint()..color = Colors.white);
    canvas.drawCircle(eye.translate(0.8, 0), 1.5, Paint()..color = Colors.black87);

    // Coin accent on fin (Cashark brand)
    final coin = pr(pts['dorsal']!);
    canvas.drawCircle(coin, 4.5, Paint()..color = const Color(0xFFFFC107));
    canvas.drawCircle(coin, 2.5, Paint()..color = const Color(0xFFFFE082));
  }

  @override
  bool shouldRepaint(covariant _StardustPainter oldDelegate) => true;
}

class _V {
  final double x, y, z;
  const _V(this.x, this.y, this.z);
}
