import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/economy.dart';
import '../services/ads_service.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';

enum _Phase { ready, playing, over }

enum _EnemyKind { shark, jelly, drone }

/// Ocean Stardust — free-roam 3D sea arena with sci-fi shark ship.
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

  // Player on XZ plane; yaw faces move direction. Camera orbits behind ship.
  double px = 0, pz = 0;
  double yaw = 0; // radians
  double pitchBob = 0;
  double bank = 0;
  double speed = 0;

  final bullets = <_Bullet>[];
  final enemies = <_Enemy>[];
  final bubbles = <_Bubble>[];
  final sparks = <_Spark>[];
  final schools = <_SchoolFish>[];

  double _fireAcc = 0;
  double _spawnAcc = 0;
  double _time = 0;
  int sessionKills = 0;
  int wave = 1;
  final _rng = math.Random();

  // Virtual joystick
  Offset? _stickCenter;
  Offset _stickDelta = Offset.zero;

  static const arena = 22.0;
  static const camDist = 6.2;
  static const camHeight = 3.4;
  static const fov = 1.05;

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

  double get difficulty {
    final mul = 1 + (wave - 1) * EconomyConfig.difficultySpeedPerWave;
    return mul.clamp(1.0, EconomyConfig.maxDifficultyMul);
  }

  void _seed() {
    bullets.clear();
    enemies.clear();
    sparks.clear();
    bubbles
      ..clear()
      ..addAll(List.generate(55, (_) => _Bubble(
            x: (_rng.nextDouble() - 0.5) * arena * 2,
            y: _rng.nextDouble() * 4,
            z: (_rng.nextDouble() - 0.5) * arena * 2,
            r: 0.05 + _rng.nextDouble() * 0.12,
            speed: 0.4 + _rng.nextDouble() * 1.2,
          )));
    schools
      ..clear()
      ..addAll(List.generate(12, (i) => _SchoolFish(
            angle: i / 12 * math.pi * 2,
            radius: 6 + _rng.nextDouble() * 10,
            y: 0.2 + _rng.nextDouble() * 1.5,
            speed: 0.4 + _rng.nextDouble() * 0.6,
            hue: 180 + _rng.nextDouble() * 80,
          )));
    px = 0;
    pz = 0;
    yaw = 0;
    bank = 0;
    speed = 0;
    sessionKills = 0;
    wave = 1;
    _fireAcc = 0;
    _spawnAcc = 0;
    _stickDelta = Offset.zero;
  }

  void _start() {
    final lives = context.read<AppState>().user?.lives ?? 0;
    if (lives <= 0) {
      _showBuyLives();
      return;
    }
    setState(() {
      phase = _Phase.playing;
      _seed();
    });
  }

  /// World → screen with camera behind the shark, looking along yaw.
  Offset _project(double x, double y, double z) {
    final camX = px - math.sin(yaw) * camDist;
    final camZ = pz - math.cos(yaw) * camDist;
    final camY = camHeight;

    final dx = x - camX;
    final dy = y - camY;
    final dz = z - camZ;

    // Rotate into camera space (yaw).
    final cos = math.cos(-yaw);
    final sin = math.sin(-yaw);
    final rx = dx * cos - dz * sin;
    final rz = dx * sin + dz * cos;
    final ry = dy;

    final depth = rz.clamp(0.55, 80.0);
    final s = (view.height * 0.62) / (fov * depth);
    return Offset(view.width * 0.5 + rx * s, view.height * 0.48 - ry * s);
  }

  double _depthOf(double x, double z) {
    final camX = px - math.sin(yaw) * camDist;
    final camZ = pz - math.cos(yaw) * camDist;
    final dx = x - camX;
    final dz = z - camZ;
    final cos = math.cos(-yaw);
    final sin = math.sin(-yaw);
    return (dx * sin + dz * cos).clamp(0.55, 80.0);
  }

  void _tick(Duration _) {
    if (view == Size.zero) return;
    const dt = 1 / 60;
    _time += dt;
    pitchBob = math.sin(_time * 3.2) * 0.08;
    final playing = phase == _Phase.playing;

    // Ambient bubbles always
    for (final b in bubbles) {
      b.y += b.speed * dt;
      if (b.y > 5.5) {
        b.y = -0.5;
        b.x = px + (_rng.nextDouble() - 0.5) * 18;
        b.z = pz + (_rng.nextDouble() - 0.5) * 18;
      }
    }
    for (final f in schools) {
      f.angle += f.speed * dt * 0.35;
    }
    for (var i = sparks.length - 1; i >= 0; i--) {
      final s = sparks[i];
      s.life -= dt;
      s.x += s.vx * dt;
      s.y += s.vy * dt;
      s.z += s.vz * dt;
      if (s.life <= 0) sparks.removeAt(i);
    }

    if (!playing) {
      // Idle orbit for menu showcase
      yaw += dt * 0.35;
      px = math.sin(_time * 0.25) * 2;
      pz = math.cos(_time * 0.25) * 2;
      setState(() {});
      return;
    }

    // Steering from virtual stick / pan
    if (_stickDelta.distance > 4) {
      final turn = (_stickDelta.dx / 80).clamp(-1.0, 1.0);
      final throttle = (-_stickDelta.dy / 80).clamp(-0.35, 1.0);
      yaw += turn * 2.6 * dt;
      bank = (bank + turn * 0.08).clamp(-0.7, 0.7);
      speed = (speed + (throttle * 9.5 - speed) * 3 * dt);
    } else {
      speed *= 0.96;
      bank *= 0.9;
    }

    px += math.sin(yaw) * speed * dt;
    pz += math.cos(yaw) * speed * dt;
    // Soft arena bounds (swim in a circle around the sea)
    final dist = math.sqrt(px * px + pz * pz);
    if (dist > arena) {
      final k = arena / dist;
      px *= k;
      pz *= k;
    }

    // Auto fire forward
    _fireAcc += dt;
    if (_fireAcc > (0.20 / (0.85 + difficulty * 0.1))) {
      _fireAcc = 0;
      final fx = math.sin(yaw);
      final fz = math.cos(yaw);
      bullets.add(_Bullet(
        x: px + fx * 0.8,
        y: 0.35 + pitchBob,
        z: pz + fz * 0.8,
        vx: fx * 16,
        vz: fz * 16,
      ));
    }

    for (var i = bullets.length - 1; i >= 0; i--) {
      final b = bullets[i];
      b.x += b.vx * dt;
      b.z += b.vz * dt;
      b.life -= dt;
      if (b.life <= 0) bullets.removeAt(i);
    }

    // Spawn enemies — denser / faster with wave
    _spawnAcc += dt;
    final spawnEvery = (1.15 / difficulty).clamp(0.35, 1.2);
    if (_spawnAcc > spawnEvery) {
      _spawnAcc = 0;
      _spawnEnemy();
    }

    final state = context.read<AppState>();
    for (var i = enemies.length - 1; i >= 0; i--) {
      final e = enemies[i];
      // Chase / circle player
      final dx = px - e.x;
      final dz = pz - e.z;
      final len = math.sqrt(dx * dx + dz * dz) + 0.001;
      final chase = e.speed * difficulty;
      if (e.kind == _EnemyKind.jelly) {
        e.y = 0.6 + math.sin(_time * 2 + e.phase) * 0.5;
        e.x += math.sin(e.phase + _time) * 0.8 * dt;
        e.z += math.cos(e.phase + _time) * 0.8 * dt;
      } else if (e.kind == _EnemyKind.drone) {
        e.x += (dx / len) * chase * 0.7 * dt;
        e.z += (dz / len) * chase * 0.7 * dt;
        e.y = 0.9 + math.sin(_time * 4 + e.phase) * 0.25;
      } else {
        // Shark AI — circle then strike
        e.phase += dt;
        final orbit = 3.2;
        if (len > orbit) {
          e.x += (dx / len) * chase * dt;
          e.z += (dz / len) * chase * dt;
        } else {
          e.x += -dz / len * chase * 0.9 * dt;
          e.z += dx / len * chase * 0.9 * dt;
        }
        e.facing = math.atan2(dx, dz);
        e.y = 0.25 + math.sin(_time * 3 + e.phase) * 0.12;
      }

      // Bullets
      for (var bi = bullets.length - 1; bi >= 0; bi--) {
        final b = bullets[bi];
        final ddx = b.x - e.x;
        final ddz = b.z - e.z;
        final ddy = b.y - e.y;
        if (ddx * ddx + ddz * ddz + ddy * ddy < 1.1) {
          bullets.removeAt(bi);
          e.hp -= 1;
          _burst(e.x, e.y, e.z, e.kind == _EnemyKind.shark ? 210.0 : e.hue);
          if (e.hp <= 0) {
            enemies.removeAt(i);
            sessionKills += 1;
            wave = 1 + sessionKills ~/ EconomyConfig.killsPerWave;
            state.registerKill(wave: wave, isShark: e.kind == _EnemyKind.shark);
          }
          break;
        }
      }
      if (i >= enemies.length) continue;

      // Collision with player
      final pdx = e.x - px;
      final pdz = e.z - pz;
      if (pdx * pdx + pdz * pdz < 1.35) {
        _burst(e.x, e.y, e.z, 15);
        enemies.removeAt(i);
        state.loseLife();
        if ((state.user?.lives ?? 0) <= 0) {
          setState(() => phase = _Phase.over);
          return;
        }
      }
    }

    setState(() {});
  }

  void _spawnEnemy() {
    final a = _rng.nextDouble() * math.pi * 2;
    final dist = 10 + _rng.nextDouble() * 8;
    final kindRoll = _rng.nextDouble();
    final kind = kindRoll < 0.5
        ? _EnemyKind.shark
        : (kindRoll < 0.78 ? _EnemyKind.jelly : _EnemyKind.drone);
    enemies.add(_Enemy(
      x: px + math.sin(a) * dist,
      y: kind == _EnemyKind.drone ? 1.0 : 0.3,
      z: pz + math.cos(a) * dist,
      speed: (kind == _EnemyKind.shark ? 2.4 : 1.6) + _rng.nextDouble(),
      hp: kind == _EnemyKind.shark ? 2 + (wave ~/ 3) : 1 + (wave ~/ 5),
      kind: kind,
      hue: kind == _EnemyKind.jelly ? 280 + _rng.nextDouble() * 40 : 190 + _rng.nextDouble() * 30,
      phase: _rng.nextDouble() * math.pi * 2,
      facing: a + math.pi,
    ));
  }

  void _burst(double x, double y, double z, double hue) {
    for (var i = 0; i < 12; i++) {
      sparks.add(_Spark(
        x: x,
        y: y,
        z: z,
        vx: (_rng.nextDouble() - 0.5) * 5,
        vy: (_rng.nextDouble() - 0.5) * 4,
        vz: (_rng.nextDouble() - 0.5) * 5,
        life: 0.3 + _rng.nextDouble() * 0.4,
        hue: hue,
      ));
    }
  }

  void _onPanStart(DragStartDetails d) {
    _stickCenter = d.localPosition;
    _stickDelta = Offset.zero;
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (phase != _Phase.playing) return;
    final c = _stickCenter ?? d.localPosition;
    _stickDelta = d.localPosition - c;
    if (_stickDelta.distance > 90) {
      _stickDelta = Offset.fromDirection(_stickDelta.direction, 90);
    }
  }

  void _onPanEnd(DragEndDetails _) {
    _stickDelta = Offset.zero;
    _stickCenter = null;
  }

  Future<void> _showBuyLives() async {
    final state = context.read<AppState>();
    final ads = context.read<AdsService>();
    final l = state.l10n;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF062A3A),
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
                subtitle: Text('€${EconomyConfig.lifePriceCash.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white70)),
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
                subtitle: Text('${EconomyConfig.lifePriceSharks} Sharkcoins',
                    style: const TextStyle(color: Colors.white70)),
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
            colors: [Color(0xFF021526), Color(0xFF034F6E), Color(0xFF067A7A)],
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
                    Expanded(
                      child: Text(l.t('play_win'),
                          style: GoogleFonts.fredoka(
                              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                    ),
                    Text('W$wave', style: GoogleFonts.fredoka(color: AppColors.gold, fontSize: 14)),
                    const SizedBox(width: 10),
                    Text('❤️ x$lives', style: GoogleFonts.fredoka(color: Colors.white, fontSize: 15)),
                    const SizedBox(width: 10),
                    Text('🦈 $sessionKills', style: GoogleFonts.fredoka(color: Colors.white, fontSize: 15)),
                  ],
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, c) {
                    view = Size(c.maxWidth, c.maxHeight);
                    if (bubbles.isEmpty && view != Size.zero) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted && bubbles.isEmpty) setState(_seed);
                      });
                    }
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        Positioned.fill(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onPanStart: phase == _Phase.playing ? _onPanStart : null,
                            onPanUpdate: phase == _Phase.playing ? _onPanUpdate : null,
                            onPanEnd: phase == _Phase.playing ? _onPanEnd : null,
                            child: CustomPaint(
                              painter: _OceanPainter(
                                project: _project,
                                depthOf: _depthOf,
                                px: px,
                                pz: pz,
                                yaw: yaw,
                                bank: bank,
                                pitchBob: pitchBob,
                                bullets: bullets,
                                enemies: enemies,
                                bubbles: bubbles,
                                sparks: sparks,
                                schools: schools,
                                time: _time,
                                stick: phase == _Phase.playing ? _stickDelta : null,
                                stickCenter: _stickCenter,
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
                                          color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800)),
                                  Text('${l.t('kills')}: $sessionKills · Wave $wave',
                                      style: GoogleFonts.fredoka(color: Colors.white70, fontSize: 16)),
                                  const SizedBox(height: 12),
                                ] else ...[
                                  Text('OCEAN STARDUST',
                                      style: GoogleFonts.fredoka(
                                          color: const Color(0xFF7DF9FF),
                                          fontSize: 28,
                                          fontWeight: FontWeight.w800)),
                                  Text(l.t('ocean_tagline'),
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.fredoka(color: Colors.white70, fontSize: 13)),
                                  const SizedBox(height: 16),
                                ],
                                ElevatedButton(
                                  onPressed: _start,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFF6B1A),
                                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                                  ),
                                  child: Text(l.t('start'),
                                      style: GoogleFonts.fredoka(
                                          fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white)),
                                ),
                                if (lives <= 0) ...[
                                  const SizedBox(height: 10),
                                  TextButton(
                                    onPressed: _showBuyLives,
                                    child: Text(l.t('buy_lives'),
                                        style: GoogleFonts.fredoka(color: AppColors.gold)),
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

// ── entities ───────────────────────────────────────────────────────────────

class _Bullet {
  double x, y, z, vx, vz, life;
  _Bullet({required this.x, required this.y, required this.z, required this.vx, required this.vz})
      : life = 1.4;
}

class _Enemy {
  double x, y, z, speed, hue, phase, facing;
  int hp;
  _EnemyKind kind;
  _Enemy({
    required this.x,
    required this.y,
    required this.z,
    required this.speed,
    required this.hp,
    required this.kind,
    required this.hue,
    required this.phase,
    required this.facing,
  });
}

class _Bubble {
  double x, y, z, r, speed;
  _Bubble({required this.x, required this.y, required this.z, required this.r, required this.speed});
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

class _SchoolFish {
  double angle, radius, y, speed, hue;
  _SchoolFish({
    required this.angle,
    required this.radius,
    required this.y,
    required this.speed,
    required this.hue,
  });
}

// ── painter ────────────────────────────────────────────────────────────────

class _OceanPainter extends CustomPainter {
  final Offset Function(double, double, double) project;
  final double Function(double, double) depthOf;
  final double px, pz, yaw, bank, pitchBob, time;
  final List<_Bullet> bullets;
  final List<_Enemy> enemies;
  final List<_Bubble> bubbles;
  final List<_Spark> sparks;
  final List<_SchoolFish> schools;
  final Offset? stick;
  final Offset? stickCenter;

  _OceanPainter({
    required this.project,
    required this.depthOf,
    required this.px,
    required this.pz,
    required this.yaw,
    required this.bank,
    required this.pitchBob,
    required this.bullets,
    required this.enemies,
    required this.bubbles,
    required this.sparks,
    required this.schools,
    required this.time,
    required this.stick,
    required this.stickCenter,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    // Water gradient + caustic pulses
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF021E30));
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.35),
      size.shortestSide * 0.55,
      Paint()..color = const Color(0x5522B0C0),
    );
    for (var i = 0; i < 6; i++) {
      final a = time * 0.7 + i;
      canvas.drawCircle(
        Offset(size.width * (0.3 + 0.4 * math.sin(a)), size.height * (0.4 + 0.2 * math.cos(a * 1.3))),
        40 + 20 * math.sin(a * 2),
        Paint()..color = const Color(0x2240E0D0),
      );
    }

    // Sea floor grid rings (circular arena feel)
    for (var r = 4.0; r <= 22; r += 4) {
      final path = Path();
      const segs = 40;
      for (var i = 0; i <= segs; i++) {
        final ang = i / segs * math.pi * 2;
        final p = project(math.sin(ang) * r, -0.6, math.cos(ang) * r);
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
          ..strokeWidth = 1.2
          ..color = const Color(0x3340E0D0),
      );
    }

    // Depth-sort sprites
    final drawList = <_DrawItem>[];

    for (final b in bubbles) {
      drawList.add(_DrawItem(depthOf(b.x, b.z), () {
        final p = project(b.x, b.y, b.z);
        final sc = (18 / depthOf(b.x, b.z)).clamp(0.4, 3.0);
        canvas.drawCircle(p, b.r * 40 * sc, Paint()..color = Colors.white.withValues(alpha: 0.25));
      }));
    }

    for (final f in schools) {
      final x = math.sin(f.angle) * f.radius;
      final z = math.cos(f.angle) * f.radius;
      drawList.add(_DrawItem(depthOf(x, z), () {
        final p = project(x, f.y, z);
        canvas.drawCircle(
          p,
          3,
          Paint()..color = HSVColor.fromAHSV(0.7, f.hue, 0.5, 1).toColor(),
        );
      }));
    }

    for (final e in enemies) {
      drawList.add(_DrawItem(depthOf(e.x, e.z), () => _drawEnemy(canvas, e)));
    }

    for (final b in bullets) {
      drawList.add(_DrawItem(depthOf(b.x, b.z), () {
        final p = project(b.x, b.y, b.z);
        canvas.drawCircle(p, 4, Paint()..color = const Color(0xFFFFF59D));
        canvas.drawCircle(p, 7, Paint()..color = const Color(0x66FF6B1A));
      }));
    }

    for (final s in sparks) {
      drawList.add(_DrawItem(depthOf(s.x, s.z), () {
        final p = project(s.x, s.y, s.z);
        canvas.drawCircle(
          p,
          2.5,
          Paint()..color = HSVColor.fromAHSV(s.life.clamp(0, 1), s.hue % 360, 0.85, 1).toColor(),
        );
      }));
    }

    // Player ship last among near objects — still depth sorted
    drawList.add(_DrawItem(depthOf(px, pz), () {
      _drawSciFiShark(canvas, px, 0.35 + pitchBob, pz, yaw, bank);
    }));

    drawList.sort((a, b) => b.depth.compareTo(a.depth));
    for (final d in drawList) {
      d.paint();
    }

    // Virtual stick
    if (stickCenter != null) {
      canvas.drawCircle(stickCenter!, 42, Paint()..color = Colors.white24);
      canvas.drawCircle(stickCenter! + (stick ?? Offset.zero), 18, Paint()..color = Colors.white54);
    }
  }

  void _drawEnemy(Canvas canvas, _Enemy e) {
    final p = project(e.x, e.y, e.z);
    final d = depthOf(e.x, e.z);
    final s = (26 / d).clamp(4.0, 28.0);

    if (e.kind == _EnemyKind.shark) {
      // Hostile shark silhouette facing its direction (approx)
      final path = Path()
        ..moveTo(p.dx + s * 0.9, p.dy)
        ..lineTo(p.dx - s * 0.2, p.dy - s * 0.45)
        ..lineTo(p.dx - s * 0.9, p.dy - s * 0.15)
        ..lineTo(p.dx - s * 0.55, p.dy)
        ..lineTo(p.dx - s * 0.9, p.dy + s * 0.2)
        ..lineTo(p.dx - s * 0.15, p.dy + s * 0.35)
        ..close();
      canvas.drawPath(path, Paint()..color = const Color(0xFF1565C0));
      canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2
            ..color = const Color(0xFF80D8FF));
      // dorsal
      canvas.drawPath(
        Path()
          ..moveTo(p.dx, p.dy - s * 0.1)
          ..lineTo(p.dx - s * 0.15, p.dy - s * 0.75)
          ..lineTo(p.dx + s * 0.25, p.dy - s * 0.15)
          ..close(),
        Paint()..color = const Color(0xFF0D47A1),
      );
    } else if (e.kind == _EnemyKind.jelly) {
      final c = HSVColor.fromAHSV(0.85, e.hue % 360, 0.7, 1).toColor();
      canvas.drawOval(Rect.fromCenter(center: p, width: s * 1.4, height: s), Paint()..color = c.withValues(alpha: 0.7));
      for (var i = -2; i <= 2; i++) {
        canvas.drawLine(
          p.translate(i * s * 0.18, s * 0.3),
          p.translate(i * s * 0.18, s * 0.9),
          Paint()
            ..color = c
            ..strokeWidth = 1.5,
        );
      }
    } else {
      // Sci-fi drone
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: p, width: s * 1.5, height: s * 0.7), const Radius.circular(4)),
        Paint()..color = const Color(0xFFFF6B1A),
      );
      canvas.drawCircle(p, s * 0.25, Paint()..color = const Color(0xFFFFF176));
    }
  }

  /// Sci-fi Cashark icon ship — chrome blue shark with engine fins & glow.
  void _drawSciFiShark(Canvas canvas, double x, double y, double z, double yaw, double bank) {
    _V local(_V p) {
      final cy = math.cos(yaw);
      final sy = math.sin(yaw);
      final cb = math.cos(bank);
      final sb = math.sin(bank);
      // bank then yaw
      final by = p.y * cb - p.x * sb;
      final bx = p.y * sb + p.x * cb;
      final rx = bx * cy + p.z * sy;
      final rz = -bx * sy + p.z * cy;
      return _V(x + rx, y + by, z + rz);
    }

    const s = 1.0;
    final nose = local(_V(0, 0.05, 1.2 * s));
    final body = local(_V(0, 0.05, 0.1 * s));
    final tail = local(_V(0, 0.05, -1.0 * s));
    final dorsal = local(_V(0, 0.85 * s, 0.15 * s));
    final lw = local(_V(-0.95 * s, -0.05, 0.0));
    final rw = local(_V(0.95 * s, -0.05, 0.0));
    final belly = local(_V(0, -0.35 * s, 0.1));
    final tl = local(_V(-0.45 * s, 0.1, -1.15 * s));
    final tr = local(_V(0.45 * s, 0.1, -1.15 * s));
    final tt = local(_V(0, 0.65 * s, -1.1 * s));
    final engL = local(_V(-0.35 * s, -0.1, -0.7 * s));
    final engR = local(_V(0.35 * s, -0.1, -0.7 * s));

    Offset pr(_V v) => project(v.x, v.y, v.z);

    void face(List<_V> pts, Color c) {
      final path = Path();
      for (var i = 0; i < pts.length; i++) {
        final p = pr(pts[i]);
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      path.close();
      canvas.drawPath(path, Paint()..color = c);
      canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.1
            ..color = const Color(0xAAE0F7FA));
    }

    face([tail, tl, tt], const Color(0xFF01579B));
    face([tail, tr, tt], const Color(0xFF0277BD));
    face([nose, lw, dorsal], const Color(0xFF0288D1));
    face([nose, rw, dorsal], const Color(0xFF039BE5));
    face([nose, lw, belly], const Color(0xFF4FC3F7));
    face([nose, rw, belly], const Color(0xFF81D4FA));
    face([nose, belly, body], const Color(0xFFE1F5FE));
    face([dorsal, lw, tail], const Color(0xFF01579B));
    face([dorsal, rw, tail], const Color(0xFF0277BD));
    face([belly, lw, tail], const Color(0xFFB3E5FC));
    face([belly, rw, tail], const Color(0xFF81D4FA));

    // Sci-fi engine pods
    final el = pr(engL);
    final er = pr(engR);
    canvas.drawCircle(el, 7, Paint()..color = const Color(0x88FF6B1A));
    canvas.drawCircle(er, 7, Paint()..color = const Color(0x88FF6B1A));
    canvas.drawCircle(el, 3.5, Paint()..color = const Color(0xFFFFF59D));
    canvas.drawCircle(er, 3.5, Paint()..color = const Color(0xFFFFF59D));

    // Cockpit / eye + coin crest (app icon nod)
    final eye = pr(local(_V(0.14, 0.18, 0.65)));
    canvas.drawCircle(eye, 3.5, Paint()..color = const Color(0xFFE0F7FA));
    canvas.drawCircle(eye.translate(1, 0), 1.6, Paint()..color = const Color(0xFF004D40));
    final coin = pr(dorsal);
    canvas.drawCircle(coin, 5, Paint()..color = const Color(0xFFFFC107));
    canvas.drawCircle(coin, 2.8, Paint()..color = const Color(0xFFFFE082));
  }

  @override
  bool shouldRepaint(covariant _OceanPainter oldDelegate) => true;
}

class _DrawItem {
  final double depth;
  final void Function() paint;
  _DrawItem(this.depth, this.paint);
}

class _V {
  final double x, y, z;
  const _V(this.x, this.y, this.z);
}
