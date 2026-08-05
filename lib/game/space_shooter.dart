import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../services/ads_service.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';

enum _GamePhase { ready, playing, over }

class SpaceShooterGame extends StatefulWidget {
  const SpaceShooterGame({super.key});

  @override
  State<SpaceShooterGame> createState() => _SpaceShooterGameState();
}

class _SpaceShooterGameState extends State<SpaceShooterGame>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  _GamePhase phase = _GamePhase.ready;
  Size world = Size.zero;
  Offset ship = Offset.zero;
  final bullets = <Offset>[];
  final enemies = <_Enemy>[];
  final stars = <_Star>[];
  double _acc = 0;
  double _spawn = 0;
  int sessionKills = 0;
  final _rng = Random();

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

  void _resetField() {
    bullets.clear();
    enemies.clear();
    sessionKills = 0;
    ship = Offset(world.width / 2, world.height - 80);
  }

  void _start() {
    final lives = context.read<AppState>().user?.lives ?? 0;
    if (lives <= 0) {
      _showBuyLives();
      return;
    }
    setState(() {
      phase = _GamePhase.playing;
      _resetField();
    });
  }

  void _tick(Duration elapsed) {
    if (phase != _GamePhase.playing || world == Size.zero) return;
    const dt = 1 / 60;
    _acc += dt;
    _spawn += dt;

    // Move bullets
    for (var i = bullets.length - 1; i >= 0; i--) {
      bullets[i] = bullets[i].translate(0, -9);
      if (bullets[i].dy < -20) bullets.removeAt(i);
    }

    // Auto-fire
    if (_acc > 0.22) {
      _acc = 0;
      bullets.add(ship.translate(0, -24));
    }

    // Spawn enemies — medium difficulty
    if (_spawn > 0.85) {
      _spawn = 0;
      enemies.add(_Enemy(
        pos: Offset(40 + _rng.nextDouble() * (world.width - 80), -30),
        speed: 2.2 + _rng.nextDouble() * 2.4,
        hue: _rng.nextDouble(),
        hp: 1 + _rng.nextInt(2),
      ));
    }

    final state = context.read<AppState>();
    for (var i = enemies.length - 1; i >= 0; i--) {
      final e = enemies[i];
      e.pos = e.pos.translate(sin(e.pos.dy / 30) * 1.2, e.speed);

      // Collide bullets
      for (var b = bullets.length - 1; b >= 0; b--) {
        if ((bullets[b] - e.pos).distance < 28) {
          bullets.removeAt(b);
          e.hp -= 1;
          if (e.hp <= 0) {
            enemies.removeAt(i);
            sessionKills += 1;
            state.registerKill();
          }
          break;
        }
      }

      if (i >= enemies.length) continue;

      // Hit ship
      if ((e.pos - ship).distance < 34) {
        enemies.removeAt(i);
        state.loseLife();
        if ((state.user?.lives ?? 0) <= 0) {
          setState(() => phase = _GamePhase.over);
          return;
        }
      } else if (e.pos.dy > world.height + 40) {
        enemies.removeAt(i);
      }
    }

    // Stars drift
    for (final s in stars) {
      s.y += s.speed;
      if (s.y > world.height) s.y = 0;
    }

    setState(() {});
  }

  void _onPan(DragUpdateDetails d) {
    if (phase != _GamePhase.playing) return;
    ship = Offset(
      (ship.dx + d.delta.dx).clamp(24, world.width - 24),
      (ship.dy + d.delta.dy).clamp(world.height * 0.45, world.height - 40),
    );
  }

  Future<void> _showBuyLives() async {
    final state = context.read<AppState>();
    final ads = context.read<AdsService>();
    final l = state.l10n;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l.t('buy_lives'), style: GoogleFonts.fredoka(fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              ListTile(
                leading: const Text('🪙', style: TextStyle(fontSize: 28)),
                title: Text(l.t('buy_with_cash')),
                subtitle: const Text('€0.25'),
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
                title: Text(l.t('buy_with_sharks')),
                subtitle: const Text('40 Sharks'),
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
                title: Text(l.t('watch_ad_life')),
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
            colors: [Color(0xFF1A0A3D), Color(0xFF4A148C), Color(0xFFFF6B1A)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    Text(l.t('play_win'), style: GoogleFonts.fredoka(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    Text('❤️ x$lives', style: GoogleFonts.fredoka(color: Colors.white, fontSize: 16)),
                    const SizedBox(width: 12),
                    Text('🦈 $sessionKills', style: GoogleFonts.fredoka(color: Colors.white, fontSize: 16)),
                  ],
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    world = Size(constraints.maxWidth, constraints.maxHeight);
                    if (stars.isEmpty) {
                      for (var i = 0; i < 40; i++) {
                        stars.add(_Star(
                          x: _rng.nextDouble() * world.width,
                          y: _rng.nextDouble() * world.height,
                          speed: 1 + _rng.nextDouble() * 3,
                          size: 1 + _rng.nextDouble() * 2,
                        ));
                      }
                    }
                    if (ship == Offset.zero) {
                      ship = Offset(world.width / 2, world.height - 80);
                    }
                    return GestureDetector(
                      onPanUpdate: _onPan,
                      child: Stack(
                        children: [
                          CustomPaint(
                            size: world,
                            painter: _GamePainter(
                              ship: ship,
                              bullets: bullets,
                              enemies: enemies,
                              stars: stars,
                            ),
                          ),
                          if (phase == _GamePhase.ready || phase == _GamePhase.over)
                            Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (phase == _GamePhase.over) ...[
                                    Text(l.t('game_over'),
                                        style: GoogleFonts.fredoka(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w700)),
                                    Text('${l.t('kills')}: $sessionKills',
                                        style: GoogleFonts.fredoka(color: Colors.white70, fontSize: 18)),
                                    const SizedBox(height: 16),
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
                      ),
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
          gradient: const LinearGradient(colors: [AppColors.gold, AppColors.orange]),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(color: AppColors.orange.withValues(alpha: 0.5), blurRadius: 18, offset: const Offset(0, 6)),
          ],
        ),
        child: Text(label, style: GoogleFonts.fredoka(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
      ),
    );
  }
}

class _Enemy {
  Offset pos;
  double speed;
  double hue;
  int hp;
  _Enemy({required this.pos, required this.speed, required this.hue, required this.hp});
}

class _Star {
  double x;
  double y;
  double speed;
  double size;
  _Star({required this.x, required this.y, required this.speed, required this.size});
}

class _GamePainter extends CustomPainter {
  final Offset ship;
  final List<Offset> bullets;
  final List<_Enemy> enemies;
  final List<_Star> stars;

  _GamePainter({
    required this.ship,
    required this.bullets,
    required this.enemies,
    required this.stars,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in stars) {
      canvas.drawCircle(Offset(s.x, s.y), s.size, Paint()..color = Colors.white.withValues(alpha: 0.7));
    }

    for (final b in bullets) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: b, width: 6, height: 16), const Radius.circular(4)),
        Paint()..color = const Color(0xFFFFF59D),
      );
    }

    for (final e in enemies) {
      final color = HSVColor.fromAHSV(1, e.hue * 360, 0.85, 1).toColor();
      final path = Path()
        ..moveTo(e.pos.dx, e.pos.dy + 18)
        ..lineTo(e.pos.dx - 18, e.pos.dy - 14)
        ..lineTo(e.pos.dx + 18, e.pos.dy - 14)
        ..close();
      canvas.drawPath(path, Paint()..color = color);
      canvas.drawCircle(e.pos.translate(0, -2), 5, Paint()..color = Colors.white);
    }

    // Player ship
    final shipPath = Path()
      ..moveTo(ship.dx, ship.dy - 26)
      ..lineTo(ship.dx - 22, ship.dy + 18)
      ..lineTo(ship.dx, ship.dy + 8)
      ..lineTo(ship.dx + 22, ship.dy + 18)
      ..close();
    canvas.drawPath(
      shipPath,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF40C4FF), Color(0xFF2979FF)],
        ).createShader(Rect.fromCircle(center: ship, radius: 30)),
    );
    canvas.drawCircle(ship.translate(0, -4), 5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _GamePainter oldDelegate) => true;
}
