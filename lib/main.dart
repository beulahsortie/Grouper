import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';
import 'screens/explore_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/chat_screen.dart' show ChatScreen;
import 'screens/profile_screen.dart';
import 'screens/activities_screen.dart';
import 'theme/app_theme.dart';
import 'screens/crew_splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Grouper",
      theme: AppTheme.theme,
      home: const _AppEntry()
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _logoCtrl;
  late final AnimationController _iconCtrl;
  late final AnimationController _textCtrl;
  late final AnimationController _tagCtrl;
  late final AnimationController _dotsCtrl;
  late final AnimationController _exitCtrl;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _iconBounce;
  late final Animation<double> _textOpacity;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _tagOpacity;
  late final Animation<double> _exitOpacity;

  @override
  void initState() {
    super.initState();

    _logoCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _logoScale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.08).chain(CurveTween(curve: Curves.easeOut)), weight: 70),
      TweenSequenceItem(tween: Tween(begin: 1.08, end: 1.0).chain(CurveTween(curve: Curves.easeIn)), weight: 30),
    ]).animate(_logoCtrl);
    _logoOpacity = Tween(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _logoCtrl, curve: const Interval(0.0, 0.5)));

    _iconCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _iconBounce = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.28).chain(CurveTween(curve: Curves.easeOut)), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.28, end: 1.0).chain(CurveTween(curve: Curves.elasticIn)), weight: 50),
    ]).animate(_iconCtrl);

    _textCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _textOpacity = CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut);
    _textSlide = Tween(begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOutCubic));

    _tagCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _tagOpacity = CurvedAnimation(parent: _tagCtrl, curve: Curves.easeIn);

    _dotsCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);

    _exitCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _exitOpacity = Tween(begin: 1.0, end: 0.0)
        .animate(CurvedAnimation(parent: _exitCtrl, curve: Curves.easeIn));

    _run();
  }

  Future<void> _run() async {
    await Future.delayed(const Duration(milliseconds: 180));
    await _logoCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 80));
    await _iconCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 60));
    await _textCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 80));
    await _tagCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 1000));
    await _exitCtrl.forward();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(pageBuilder: (_, __, ___) => const MainScreen(), transitionDuration: Duration.zero),
      );
    }
  }

  @override
  void dispose() {
    _logoCtrl.dispose(); _iconCtrl.dispose(); _textCtrl.dispose();
    _tagCtrl.dispose(); _dotsCtrl.dispose(); _exitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _exitOpacity,
      builder: (_, __) => Opacity(
        opacity: _exitOpacity.value,
        child: Scaffold(
          backgroundColor: AppColors.navy,
          body: Stack(
            children: [
              Center(child: Container(
                width: 360, height: 360,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [AppColors.gold.withOpacity(0.14), Colors.transparent]),
                ),
              )),
              Positioned(top: -70, left: -70, child: Container(
                width: 240, height: 240,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.03)),
              )),
              Positioned(bottom: -90, right: -90, child: Container(
                width: 300, height: 300,
                decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.gold.withOpacity(0.06)),
              )),
              Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  AnimatedBuilder(
                    animation: Listenable.merge([_logoCtrl, _iconCtrl]),
                    builder: (_, __) => Opacity(
                      opacity: _logoOpacity.value,
                      child: Transform.scale(
                        scale: _logoScale.value,
                        child: Container(
                          width: 104, height: 104,
                          decoration: BoxDecoration(
                            color: AppColors.gold,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [BoxShadow(color: AppColors.gold.withOpacity(0.45), blurRadius: 36, offset: const Offset(0, 10))],
                          ),
                          child: Transform.scale(
                            scale: _iconBounce.value,
                            child: const Icon(Icons.location_city_rounded, color: AppColors.navy, size: 54),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  AnimatedBuilder(
                    animation: _textCtrl,
                    builder: (_, __) => FadeTransition(
                      opacity: _textOpacity,
                      child: SlideTransition(
                        position: _textSlide,
                        child: const Text("Grouper", style: TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.w900, letterSpacing: -1.5)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedBuilder(
                    animation: _tagCtrl,
                    builder: (_, __) => FadeTransition(
                      opacity: _tagOpacity,
                      child: Text("Find your crew. Book your game.",
                          style: TextStyle(color: Colors.white.withOpacity(0.52), fontSize: 14, letterSpacing: 0.2)),
                    ),
                  ),
                ]),
              ),
              Positioned(
                bottom: 58, left: 0, right: 0,
                child: AnimatedBuilder(
                  animation: _dotsCtrl,
                  builder: (_, __) => Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) {
                      final t = (_dotsCtrl.value - i * 0.28).clamp(0.0, 1.0);
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 6, height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.25 + 0.65 * t),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _AppEntry extends StatelessWidget {
  const _AppEntry();
  @override
  Widget build(BuildContext context) {
    return CrewSplashScreen(
      onComplete: () {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const MainScreen(),
            transitionDuration: Duration.zero,
          ),
        );
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  bool _loggedIn = false;
  Map<String, dynamic>? _currentUser;

  @override
  Widget build(BuildContext context) {
    List<Widget> pages = [
      HomeScreen(isLoggedIn: _loggedIn, currentUser: _currentUser, onGoToLogin: () => setState(() => _currentIndex = 4)),
      ExploreScreen(currentUser: _currentUser),
      ActivitiesScreen(currentUser: _currentUser),
      ChatScreen(currentUser: _currentUser),
      _loggedIn
          ? ProfileScreen(currentUser: _currentUser, onLogout: () => setState(() { _loggedIn = false; _currentUser = null; }))
          : AuthScreen(onLogin: (user) => setState(() { _loggedIn = true; _currentUser = user; })),
    ];

    return Scaffold(
      extendBody: true,
      body: Stack(children: [
        Positioned.fill(
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              padding: MediaQuery.of(context).padding.copyWith(
                bottom: MediaQuery.of(context).padding.bottom + 80,
              ),
            ),
            child: IndexedStack(index: _currentIndex, children: pages),
          ),
        ),
        Positioned(
          left: 10, right: 10,
          bottom: MediaQuery.of(context).padding.bottom + 7,
          child: _BottomNav(currentIndex: _currentIndex, onTap: (i) => setState(() => _currentIndex = i)),
        ),
      ]),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const items = [
      _NavItem(icon: Icons.home_rounded, label: "Home"),
      _NavItem(icon: Icons.explore_rounded, label: "Explore"),
      _NavItem(icon: Icons.receipt_long_rounded, label: "Activities"),
      _NavItem(icon: Icons.chat_bubble_rounded, label: "Chats"),
      _NavItem(icon: Icons.person_rounded, label: "Profile"),
    ];
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.65),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [BoxShadow(color: const Color.fromARGB(255, 185, 215, 248).withOpacity(0.12), blurRadius: 30, offset: const Offset(0, 8))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final selected = i == currentIndex;
              return GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.navy : Colors.transparent,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(items[i].icon, size: 21, color: selected ? Colors.white : AppColors.textMuted),
                    const SizedBox(height: 3),
                    Text(items[i].label, style: TextStyle(fontSize: 10, fontWeight: selected ? FontWeight.w700 : FontWeight.w400, color: selected ? Colors.white : AppColors.textMuted)),
                  ]),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}