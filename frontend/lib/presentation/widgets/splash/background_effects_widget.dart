import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../src/theme/app_theme.dart';

class BackgroundEffectsWidget extends StatelessWidget {
  final Animation<double> backgroundAnimation;
  final Animation<double> particleAnimation;
  final Animation<double> orbitalAnimation;
  final AnimationController backgroundController;
  final AnimationController particleController;
  final AnimationController orbitalController;

  const BackgroundEffectsWidget({
    super.key,
    required this.backgroundAnimation,
    required this.particleAnimation,
    required this.orbitalAnimation,
    required this.backgroundController,
    required this.particleController,
    required this.orbitalController,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        backgroundController,
        particleController,
        orbitalController,
      ]),
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.5 + (backgroundAnimation.value * 0.5),
              colors: [
                Color.lerp(AppTheme.primaryMaroon, AppTheme.secondaryMaroon,
                    backgroundAnimation.value * 0.3) ?? AppTheme.primaryMaroon,
                AppTheme.primaryMaroon,
                Color.lerp(AppTheme.secondaryMaroon, const Color(0xFF4A0E1A),
                    backgroundAnimation.value * 0.5) ?? AppTheme.secondaryMaroon,
                const Color(0xFF2A0B11),
              ],
              stops: [
                0.0,
                0.4 + (backgroundAnimation.value * 0.2),
                0.8 + (backgroundAnimation.value * 0.1),
                1.0,
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: backgroundController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: LuxuryPatternPainter(backgroundAnimation.value),
                    );
                  },
                ),
              ),

              // Enhanced particle system with multiple layers
              ...List.generate(25, (index) => _buildAdvancedParticle(context, index)),

              // Orbital light rings
              ...List.generate(3, (index) => _buildOrbitalRing(context, index)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAdvancedParticle(BuildContext context, int index) {
    final random = (index * 173) % 100;
    final size = 1.5 + (random % 6);
    final opacity = 0.05 + ((random % 40) / 100);
    final speed = 0.3 + ((random % 70) / 100);
    final delay = (random % 100) / 100;
    final horizontalDrift = ((random % 40) - 20) / 10;

    return AnimatedBuilder(
      animation: particleAnimation,
      builder: (context, child) {
        final progress = (particleAnimation.value + delay) % 1.0;
        final screenHeight = MediaQuery.of(context).size.height;
        final screenWidth = MediaQuery.of(context).size.width;
        final fadeOpacity = opacity * (1 - progress) * (progress > 0.1 ? 1.0 : progress * 10);

        return Positioned(
          left: ((random % 100) / 100 * screenWidth) + (horizontalDrift * progress * screenWidth * 0.1),
          top: screenHeight * (1.2 - progress * 1.4),
          child: Opacity(
            opacity: fadeOpacity,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: index % 3 == 0 ? BoxShape.circle : BoxShape.rectangle,
                borderRadius: index % 3 != 0 ? BorderRadius.circular(size * 0.3) : null,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.accentGold.withOpacity(0.8),
                    AppTheme.accentGold.withOpacity(0.4),
                    Colors.transparent,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentGold.withOpacity(0.6),
                    blurRadius: size * 3,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOrbitalRing(BuildContext context, int ringIndex) {
    final radius = 100.0 + (ringIndex * 50);
    final particleCount = 8 + (ringIndex * 4);

    return AnimatedBuilder(
      animation: orbitalController,
      builder: (context, child) {
        return Stack(
          children: List.generate(particleCount, (particleIndex) {
            final angle = (2 * 3.14159 * particleIndex / particleCount) +
                (orbitalAnimation.value * 3.14159 * (ringIndex % 2 == 0 ? 1 : -1));
            final x = MediaQuery.of(context).size.width / 2 + radius * math.cos(angle);
            final y = MediaQuery.of(context).size.height / 2 + radius * math.sin(angle);

            return Positioned(
              left: x - 2,
              top: y - 2,
              child: Container(
                width: 4.0 - ringIndex,
                height: 4.0 - ringIndex,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.accentGold.withOpacity(0.3 - (ringIndex * 0.1)),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentGold.withOpacity(0.5),
                      blurRadius: 8,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

// Custom painter for luxury background pattern
class LuxuryPatternPainter extends CustomPainter {
  final double animationValue;

  LuxuryPatternPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Create subtle geometric pattern
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    for (int i = 0; i < 6; i++) {
      final radius = 50.0 + (i * 40) + (animationValue * 20);
      paint.color = AppTheme.accentGold.withOpacity(0.1 - (i * 0.015));

      canvas.drawCircle(
        Offset(centerX, centerY),
        radius,
        paint,
      );
    }

    // Add radiating lines
    for (int i = 0; i < 12; i++) {
      final angle = (i * 3.14159 * 2 / 12) + (animationValue * 0.5);
      final startRadius = 80;
      final endRadius = 200;

      paint.color = AppTheme.accentGold.withOpacity(0.05);
      canvas.drawLine(
        Offset(
          centerX + startRadius * math.cos(angle),
          centerY + startRadius * math.sin(angle),
        ),
        Offset(
          centerX + endRadius * math.cos(angle),
          centerY + endRadius * math.sin(angle),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(LuxuryPatternPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}