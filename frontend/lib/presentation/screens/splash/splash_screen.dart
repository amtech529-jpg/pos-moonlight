import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../src/providers/app_provider.dart';
import '../../../src/providers/auth_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../../../src/utils/responsive_breakpoints.dart';
import '../../widgets/splash/animated_logo_widget.dart';
import '../../widgets/splash/animated_text_widget.dart';
import '../../widgets/splash/background_effects_widget.dart';
import '../../widgets/splash/premium_progress_widget.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _progressController;
  late AnimationController _backgroundController;
  late AnimationController _particleController;
  late AnimationController _shimmerController;
  late AnimationController _pulseController;
  late AnimationController _orbitalController;
  late AnimationController _lightRayController;

  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoRotationAnimation;
  late Animation<double> _logoOpacityAnimation;
  late Animation<double> _logoFloatAnimation;
  late Animation<Offset> _textSlideAnimation;
  late Animation<double> _textOpacityAnimation;
  late Animation<double> _textGlowAnimation;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _particleAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _orbitalAnimation;
  late Animation<double> _lightRayAnimation;

  bool _hasNavigated = false;
  int _retryCount = 0;
  static const int _maxRetries = 10; // Maximum 5 seconds of waiting (10 * 500ms)

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimation();
  }

  void _initializeAnimations() {
    // Initialize controllers with staggered durations for complexity
    _logoController = AnimationController(duration: const Duration(milliseconds: 2500), vsync: this);
    _textController = AnimationController(duration: const Duration(milliseconds: 1800), vsync: this);
    _progressController = AnimationController(duration: const Duration(milliseconds: 3000), vsync: this);
    _backgroundController = AnimationController(duration: const Duration(milliseconds: 4000), vsync: this);
    _particleController = AnimationController(duration: const Duration(milliseconds: 6000), vsync: this);
    _shimmerController = AnimationController(duration: const Duration(milliseconds: 2000), vsync: this);
    _pulseController = AnimationController(duration: const Duration(milliseconds: 1200), vsync: this);
    _orbitalController = AnimationController(duration: const Duration(milliseconds: 8000), vsync: this);
    _lightRayController = AnimationController(duration: const Duration(milliseconds: 3000), vsync: this);

    // Complex logo animations with multiple phases
    _logoScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.3).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 70,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.3, end: 1.0).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 30,
      ),
    ]).animate(_logoController);

    _logoRotationAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: -1.5, end: 0.2).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 80,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.2, end: 0.0).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 20,
      ),
    ]).animate(_logoController);

    _logoOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeInQuart),
      ),
    );

    _logoFloatAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    // Advanced text animations
    _textSlideAnimation = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: const Offset(0, 2),
          end: const Offset(0, -0.1),
        ).chain(CurveTween(curve: Curves.easeOutExpo)),
        weight: 70,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: const Offset(0, -0.1),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 30,
      ),
    ]).animate(_textController);

    _textOpacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 0.8).chain(CurveTween(curve: Curves.easeIn)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.8, end: 1.0).chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
    ]).animate(_textController);

    _textGlowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut));

    // Complex background animations
    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _backgroundController, curve: Curves.easeInOutSine));

    _particleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _particleController, curve: Curves.linear));

    _shimmerAnimation = Tween<double>(
      begin: -2.0,
      end: 3.0,
    ).animate(CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOutSine));

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    _orbitalAnimation = Tween<double>(
      begin: 0.0,
      end: 2.0,
    ).animate(CurvedAnimation(parent: _orbitalController, curve: Curves.linear));

    _lightRayAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _lightRayController, curve: Curves.easeInOutQuad));
  }

  void _startAnimation() async {
    // Start background effects immediately
    _backgroundController.forward();
    _particleController.repeat();
    _orbitalController.repeat();

    // Staggered entrance with dramatic timing
    await Future.delayed(const Duration(milliseconds: 300));
    _logoController.forward();
    _lightRayController.forward();

    await Future.delayed(const Duration(milliseconds: 800));
    _textController.forward();

    // Start continuous effects
    _shimmerController.repeat(reverse: true);
    _pulseController.repeat(reverse: true);

    await Future.delayed(const Duration(milliseconds: 500));
    _progressController.forward();

    // Initialize services and check authentication
    await _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Initialize app provider (no delay needed)
      await Provider.of<AppProvider>(context, listen: false).initialize();

      // Wait for auth provider to initialize with timeout
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Ensure auth provider is initializing
      if (authProvider.state == AuthState.initial) {
        authProvider.initialize();
      }

      // Wait for auth to complete with timeout (max 5 seconds)
      int waitCount = 0;
      while (authProvider.state == AuthState.initial || 
             authProvider.state == AuthState.loading) {
        await Future.delayed(const Duration(milliseconds: 200));
        waitCount++;
        if (waitCount >= 25) { // 5 seconds max (25 * 200ms)
          debugPrint('Auth initialization timeout, navigating to login');
          break;
        }
        if (!mounted || _hasNavigated) return;
      }

      // Wait for minimum splash duration for better UX (only if not already waited)
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted && !_hasNavigated) {
        _navigateBasedOnAuthState(authProvider);
      }
    } catch (e) {
      debugPrint('Splash initialization error: $e');
      if (mounted && !_hasNavigated) {
        _navigateToLogin();
      }
    }
  }

  void _navigateBasedOnAuthState(AuthProvider authProvider) {
    if (_hasNavigated) return;

    switch (authProvider.state) {
      case AuthState.authenticated:
        _navigateToDashboard();
        break;
      case AuthState.unauthenticated:
      case AuthState.error:
        _navigateToLogin();
        break;
      case AuthState.initial:
      case AuthState.loading:
        // Still loading, wait a bit more
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && !_hasNavigated) {
            _navigateBasedOnAuthState(authProvider);
          }
        });
        break;
    }
  }

  void _navigateToLogin() {
    if (_hasNavigated) return;
    _hasNavigated = true;
    Navigator.of(context).pushReplacementNamed('/login');
  }

  void _navigateToDashboard() {
    if (_hasNavigated) return;
    _hasNavigated = true;
    Navigator.of(context).pushReplacementNamed('/dashboard');
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _progressController.dispose();
    _backgroundController.dispose();
    _particleController.dispose();
    _shimmerController.dispose();
    _pulseController.dispose();
    _orbitalController.dispose();
    _lightRayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return Stack(
            children: [
              // Background Effects
              BackgroundEffectsWidget(
                backgroundAnimation: _backgroundAnimation,
                particleAnimation: _particleAnimation,
                orbitalAnimation: _orbitalAnimation,
                backgroundController: _backgroundController,
                particleController: _particleController,
                orbitalController: _orbitalController,
              ),

              // Light Rays
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _lightRayController,
                  builder: (context, child) {
                    return CustomPaint(painter: LightRaysPainter(_lightRayAnimation.value));
                  },
                ),
              ),

              // Main Content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated Logo
                    AnimatedLogoWidget(
                      logoScaleAnimation: _logoScaleAnimation,
                      logoRotationAnimation: _logoRotationAnimation,
                      logoOpacityAnimation: _logoOpacityAnimation,
                      logoFloatAnimation: _logoFloatAnimation,
                      shimmerAnimation: _shimmerAnimation,
                      pulseAnimation: _pulseAnimation,
                      lightRayAnimation: _lightRayAnimation,
                      logoController: _logoController,
                      shimmerController: _shimmerController,
                      pulseController: _pulseController,
                      lightRayController: _lightRayController,
                    ),

                    SizedBox(height: context.mainPadding * 2.5),

                    // Animated Text
                    AnimatedTextWidget(
                      textSlideAnimation: _textSlideAnimation,
                      textOpacityAnimation: _textOpacityAnimation,
                      textGlowAnimation: _textGlowAnimation,
                      shimmerAnimation: _shimmerAnimation,
                      textController: _textController,
                      shimmerController: _shimmerController,
                    ),

                    SizedBox(height: context.mainPadding * 3),

                    // Premium Progress Indicator
                    PremiumProgressWidget(
                      progressController: _progressController,
                      shimmerController: _shimmerController,
                      shimmerAnimation: _shimmerAnimation,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// Custom painter for light rays effect
class LightRaysPainter extends CustomPainter {
  final double animationValue;

  LightRaysPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Create dramatic light rays
    for (int i = 0; i < 8; i++) {
      final angle = (i * 3.14159 * 2 / 8);
      final gradient = RadialGradient(
        center: Alignment.center,
        radius: 0.8,
        colors: [AppTheme.accentGold.withOpacity(0.1 * animationValue), Colors.transparent],
      );

      paint.shader = gradient.createShader(
        Rect.fromCenter(center: Offset(centerX, centerY), width: size.width, height: size.height),
      );

      final path = Path();
      path.moveTo(centerX, centerY);
      path.lineTo(centerX + size.width * math.cos(angle), centerY + size.height * math.sin(angle));
      path.lineTo(
        centerX + size.width * math.cos(angle + 0.2),
        centerY + size.height * math.sin(angle + 0.2),
      );
      path.close();

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(LightRaysPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
