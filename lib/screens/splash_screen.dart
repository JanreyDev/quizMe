import 'package:flutter/material.dart';
import 'dart:async';
import 'role_selection_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _bulbAnimation;
  late Animation<Offset> _circle1Animation;
  late Animation<Offset> _circle2Animation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    // Fade in animation
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    // Logo scale with bounce
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.7, curve: Curves.elasticOut),
      ),
    );

    // Lightbulb moving around the circle
    _bulbAnimation =
        TweenSequence<Offset>([
          TweenSequenceItem(
            tween: Tween<Offset>(
              begin: const Offset(-3, -3),
              end: const Offset(1.5, -1.5),
            ),
            weight: 25,
          ),
          TweenSequenceItem(
            tween: Tween<Offset>(
              begin: const Offset(1.5, -1.5),
              end: const Offset(-1.2, 1.2),
            ),
            weight: 30,
          ),
          TweenSequenceItem(
            tween: Tween<Offset>(
              begin: const Offset(-1.2, 1.2),
              end: const Offset(0, 0),
            ),
            weight: 45,
          ),
        ]).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.3, 1.0, curve: Curves.easeInOut),
          ),
        );

    // Circle 1 movement (top left)
    _circle1Animation = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: const Offset(-2, -1),
          end: const Offset(1, 0.5),
        ),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: const Offset(1, 0.5),
          end: const Offset(0, 0),
        ),
        weight: 50,
      ),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Circle 2 movement (bottom right)
    _circle2Animation = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: const Offset(2, 1),
          end: const Offset(-0.8, -0.3),
        ),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: const Offset(-0.8, -0.3),
          end: const Offset(0, 0),
        ),
        weight: 50,
      ),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Lightbulb rotation
    _rotationAnimation = Tween<double>(begin: -0.5, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
      ),
    );

    // Start animation
    _controller.forward();

    // Navigate after delay
    Timer(const Duration(milliseconds: 3200), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const RoleSelectionScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Animated background circle 1 (top left area)
          AnimatedBuilder(
            animation: _circle1Animation,
            builder: (context, child) {
              return Positioned(
                top: 80 + (_circle1Animation.value.dy * 50),
                left: -50 + (_circle1Animation.value.dx * 100),
                child: Opacity(
                  opacity: _fadeAnimation.value * 0.8,
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF5DADE2).withOpacity(0.3),
                    ),
                  ),
                ),
              );
            },
          ),
          // Animated background circle 2 (bottom right area)
          AnimatedBuilder(
            animation: _circle2Animation,
            builder: (context, child) {
              return Positioned(
                bottom: 120 + (_circle2Animation.value.dy * 60),
                right: -80 + (_circle2Animation.value.dx * 80),
                child: Opacity(
                  opacity: _fadeAnimation.value * 0.6,
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF5DADE2).withOpacity(0.25),
                    ),
                  ),
                ),
              );
            },
          ),
          // Main centered content
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: SizedBox(
                  width: 250,
                  height: 250,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Main blue circle with logo
                      Container(
                        width: 200,
                        height: 200,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF5DADE2),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x305DADE2),
                              blurRadius: 20,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'QuizMe',
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A3A5C),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ),
                      // Animated lightbulb
                      AnimatedBuilder(
                        animation: _bulbAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(
                              _bulbAnimation.value.dx * 60,
                              _bulbAnimation.value.dy * 60,
                            ),
                            child: Transform.rotate(
                              angle: _rotationAnimation.value,
                              child: Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.lightbulb,
                                  size: 36,
                                  color: Color(0xFFFFC107),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Bottom text
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: const Center(
                child: Text(
                  'Empowering Education',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF5DADE2),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
