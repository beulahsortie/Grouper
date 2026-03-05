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
      title: "Crew",
      theme: AppTheme.theme,
      home: const _AppEntry(),
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
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    List<Widget> pages = [
      HomeScreen(
        isLoggedIn: _loggedIn,
        currentUser: _currentUser,
        onGoToLogin: () => setState(() => _currentIndex = 4),
      ),
      ExploreScreen(currentUser: _currentUser),
      ActivitiesScreen(currentUser: _currentUser),
      ChatScreen(currentUser: _currentUser),
      _loggedIn
          ? ProfileScreen(
              currentUser: _currentUser,
              onLogout: () => setState(() {
                _loggedIn = false;
                _currentUser = null;
              }),
            )
          : AuthScreen(
              onLogin: (user) => setState(() {
                _loggedIn = true;
                _currentUser = user;
              }),
            ),
    ];

    return Scaffold(
      // Must be false — true causes the scaffold to resize when keyboard
      // appears, which combined with the Stack makes all screens jump
      resizeToAvoidBottomInset: false,
      extendBody: true,
      body: Stack(
        children: [
          // Pages fill full screen — each screen manages its own
          // keyboard handling via its own Scaffold or scroll padding
          Positioned.fill(
            child: IndexedStack(index: _currentIndex, children: pages),
          ),

          // Bottom nav floats above content
          Positioned(
            left: 10,
            right: 10,
            bottom: bottomPadding + 7,
            child: _BottomNav(
              currentIndex: _currentIndex,
              onTap: (i) => setState(() => _currentIndex = i),
            ),
          ),
        ],
      ),
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
      _NavItem(icon: Icons.home_rounded,         label: "Home"),
      _NavItem(icon: Icons.explore_rounded,       label: "Explore"),
      _NavItem(icon: Icons.receipt_long_rounded,  label: "Activities"),
      _NavItem(icon: Icons.chat_bubble_rounded,   label: "Chats"),
      _NavItem(icon: Icons.person_rounded,        label: "Profile"),
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
            boxShadow: [
              BoxShadow(
                color: const Color.fromARGB(255, 185, 215, 248).withOpacity(0.12),
                blurRadius: 30,
                offset: const Offset(0, 8),
              ),
            ],
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.navy : Colors.transparent,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(items[i].icon,
                          size: 21,
                          color: selected ? Colors.white : AppColors.textMuted),
                      const SizedBox(height: 3),
                      Text(
                        items[i].label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color:
                              selected ? Colors.white : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
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