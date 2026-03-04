import 'dart:ui';
import 'package:flutter/material.dart';

class BgScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final bool extendBody;
  final bool extendBehindAppBar;

  const BgScaffold({
    Key? key,
    required this.body,
    this.appBar,
    this.extendBody = false,
    this.extendBehindAppBar = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: extendBody,
      extendBodyBehindAppBar: extendBehindAppBar,
      backgroundColor: Colors.transparent,
      appBar: appBar,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Image.asset(
            'assets/images/background.jpg',
            fit: BoxFit.cover,
          ),

          // Subtle white overlay to keep text readable
          Container(
            color: Colors.white.withOpacity(0.55),
          ),

          // Screen content
          body,
        ],
      ),
    );
  }
}