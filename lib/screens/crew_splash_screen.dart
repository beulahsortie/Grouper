import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';

class CrewSplashScreen extends StatefulWidget {
  final VoidCallback? onComplete;
  const CrewSplashScreen({super.key, this.onComplete});

  @override
  State<CrewSplashScreen> createState() => _CrewSplashScreenState();
}

class _CrewSplashScreenState extends State<CrewSplashScreen>
    with TickerProviderStateMixin {

  // Dots orbit continuously
  late final AnimationController _dotsCtrl;

  // Logo fades + scales in
  late final AnimationController _logoInCtrl;
  late final Animation<double>   _logoOpacity;
  late final Animation<double>   _logoScale;

  // Logo slow rotation (starts with fade-in, keeps going)
  late final AnimationController _rotateCtrl;

  // Letters fade in left to right
  late final AnimationController _textCtrl;
  final List<Animation<double>>  _letterOpacity = [];
  final List<Animation<double>>  _letterSlide   = [];

  // Dots shrink + scatter as logo appears
  late final AnimationController _dotsExitCtrl;
  late final Animation<double>   _dotsExitScale;

  // Full exit
  late final AnimationController _exitCtrl;
  late final Animation<double>   _exitOpacity;

  static const _letters = ['C', 'R', 'E', 'W'];
  static const _gold    = Color(0xFFF5A31A);
  static const _bgDark  = Color(0xFF354169);
  static const _bgLight = Color(0xFF3D4578);

  @override
  void initState() {
    super.initState();

    // Dots orbit — one full revolution every 1.4s
    _dotsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    // Logo fade in over 800ms
    _logoInCtrl  = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _logoOpacity = CurvedAnimation(
        parent: _logoInCtrl, curve: Curves.easeIn);
    _logoScale   = Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: _logoInCtrl, curve: Curves.easeOutBack));

    // Slow continuous logo rotation — one turn every 6s
    _rotateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    // Dots scale to 0 as logo appears
    _dotsExitCtrl  = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _dotsExitScale = Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(parent: _dotsExitCtrl, curve: Curves.easeIn));

    // Text
    _textCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    for (int i = 0; i < _letters.length; i++) {
      final s = i * 0.22;
      final e = (s + 0.35).clamp(0.0, 1.0);
      _letterOpacity.add(Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: _textCtrl,
              curve: Interval(s, e, curve: Curves.easeOut))));
      _letterSlide.add(Tween<double>(begin: -28.0, end: 0.0).animate(
          CurvedAnimation(parent: _textCtrl,
              curve: Interval(s, e, curve: Curves.easeOutCubic))));
    }

    // Exit
    _exitCtrl    = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _exitOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(parent: _exitCtrl, curve: Curves.easeIn));

    _runSequence();
  }

  Future<void> _runSequence() async {
    // Dots fly in from far and converge — no hold
    await Future.delayed(const Duration(milliseconds: 1400));

    // Dots converge to center (fade in center) while logo fades in
    _dotsExitCtrl.forward();
    await _logoInCtrl.forward();

    // Short pause then letters
    await Future.delayed(const Duration(milliseconds: 150));
    await _textCtrl.forward();

    // Hold
    await Future.delayed(const Duration(milliseconds: 1200));

    // Exit
    await _exitCtrl.forward();
    if (mounted) widget.onComplete?.call();
  }

  @override
  void dispose() {
    _dotsCtrl.dispose();
    _logoInCtrl.dispose();
    _rotateCtrl.dispose();
    _dotsExitCtrl.dispose();
    _textCtrl.dispose();
    _exitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _exitOpacity,
      builder: (_, __) => Opacity(
        opacity: _exitOpacity.value,
        child: Scaffold(
          backgroundColor: _bgDark,
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_bgLight, _bgDark],
              ),
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [

                  // ── Logo + orbiting dots ─────────────────────
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [

                        // Orbiting dots (behind logo)
                        AnimatedBuilder(
                          animation: Listenable.merge(
                              [_dotsCtrl, _dotsExitCtrl]),
                          builder: (_, __) => CustomPaint(
                            size: const Size(120, 120),
                            painter: _OrbitDotsPainter(
                              progress:  _dotsCtrl.value,
                              exitScale: _dotsExitScale.value,
                              gold:      _gold,
                            ),
                          ),
                        ),

                        // Logo image fades in on top
                        AnimatedBuilder(
                          animation: Listenable.merge(
                              [_logoInCtrl, _rotateCtrl]),
                          builder: (_, __) => FadeTransition(
                            opacity: _logoOpacity,
                            child: ScaleTransition(
                              scale: _logoScale,
                              child: RotationTransition(
                                turns: _rotateCtrl,
                                child: Image.asset(
                                  'assets/images/crew_logo_standalone.png',
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                 // const SizedBox(width: 8),

                  // ── CREW letters ──────────────────────────────
                  AnimatedBuilder(
                    animation: _textCtrl,
                    builder: (_, __) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(_letters.length, (i) =>
                        Transform.translate(
                          offset: Offset(_letterSlide[i].value, 0),
                          child: Opacity(
                            opacity: _letterOpacity[i].value,
                            child: Text(
                              _letters[i],
                              style: const TextStyle(
                                color: _gold,
                                fontSize: 68,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 4,
                                height: 1.0,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Orbiting dots painter ─────────────────────────────────────────────────────
//
// Phase A (exitScale=1): dots start far outside (2.8x orbit radius),
//   spiral inward over the first 0.6 of progress, then orbit normally.
// Phase B (exitScale 1→0): orbit radius shrinks to 0 (converge to center),
//   dots fade out as they reach the center — like being absorbed by the logo.

class _OrbitDotsPainter extends CustomPainter {
  final double progress;   // 0→1 repeating
  final double exitScale;  // 1→0 when logo appears
  final Color gold;

  const _OrbitDotsPainter({
    required this.progress,
    required this.exitScale,
    required this.gold,
  });

  static const int _n = 6;

  @override
  void paint(Canvas canvas, Size size) {
    if (exitScale <= 0.01) return;

    final cx = size.width  / 2;
    final cy = size.height / 2;

    // Final orbit radius (tight ring around logo)
    final finalOrbitR = size.width / 2 * 0.90;

    // Fly-in: for the first ~0.55 of progress (first orbit), dots come from far
    // After that they orbit at finalOrbitR
    // Dots always coming from outside — no steady orbit phase
    // They spiral inward over the full first revolution then keep tight
    final flyIn = (1.0 - (progress / 0.6).clamp(0.0, 1.0));
    final currentOrbitR = finalOrbitR + flyIn * finalOrbitR * 2.6;

    // Exit: converge to center
    final orbitR = currentOrbitR * exitScale;

    final baseAngle = progress * 2 * pi;

    for (int i = 0; i < _n; i++) {
      final dotAngle = baseAngle + (i * 2 * pi / _n);
      final dotX = cx + cos(dotAngle) * orbitR;
      final dotY = cy + sin(dotAngle) * orbitR;

      // Dot size shrinks as it reaches center
      final dotR = (3.8 + (i % 3) * 0.7) * exitScale.clamp(0.0, 1.0);

      // Alpha: full while orbiting, fades out as converging to center
      final alpha = exitScale.clamp(0.0, 1.0);

      // Trail — 5 ghost dots following in arc
      for (int t = 1; t <= 5; t++) {
        final trailAngle = dotAngle - t * (pi / 18);
        final trailOrbitR = finalOrbitR * exitScale + flyIn * finalOrbitR * 2.2 * exitScale;
        final trailX = cx + cos(trailAngle) * trailOrbitR;
        final trailY = cy + sin(trailAngle) * trailOrbitR;
        canvas.drawCircle(
          Offset(trailX, trailY),
          dotR * (1.0 - t * 0.14).clamp(0.0, 1.0),
          Paint()
            ..color = gold.withOpacity(alpha * (1.0 - t / 6.0) * 0.5)
            ..style = PaintingStyle.fill,
        );
      }

      // Main dot
      canvas.drawCircle(
        Offset(dotX, dotY),
        dotR,
        Paint()
          ..color = gold.withOpacity(alpha)
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(_OrbitDotsPainter old) =>
      old.progress != progress || old.exitScale != exitScale;
}