import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../../src/theme/app_theme.dart';
import '../../../../src/utils/responsive_breakpoints.dart';

class AnimatedLogoWidget extends StatelessWidget {
  final Animation<double> logoScaleAnimation;
  final Animation<double> logoRotationAnimation;
  final Animation<double> logoOpacityAnimation;
  final Animation<double> logoFloatAnimation;
  final Animation<double> shimmerAnimation;
  final Animation<double> pulseAnimation;
  final Animation<double> lightRayAnimation;
  final AnimationController logoController;
  final AnimationController shimmerController;
  final AnimationController pulseController;
  final AnimationController lightRayController;

  const AnimatedLogoWidget({
    super.key,
    required this.logoScaleAnimation,
    required this.logoRotationAnimation,
    required this.logoOpacityAnimation,
    required this.logoFloatAnimation,
    required this.shimmerAnimation,
    required this.pulseAnimation,
    required this.lightRayAnimation,
    required this.logoController,
    required this.shimmerController,
    required this.pulseController,
    required this.lightRayController,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        logoController,
        shimmerController,
        pulseController,
        lightRayController,
      ]),
      builder: (context, child) {
        return Transform.scale(
          scale: logoScaleAnimation.value * pulseAnimation.value,
          child: Transform.rotate(
            angle: logoRotationAnimation.value,
            child: Transform.translate(
              offset: Offset(0, -5 * logoFloatAnimation.value),
              child: Opacity(
                opacity: logoOpacityAnimation.value,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer glow ring
                    Container(
                      width: ResponsiveBreakpoints.responsive(
                        context,
                        tablet: 18.w,
                        small: 18.w,
                        medium: 18.w,
                        large: 18.w,
                        ultrawide: 18.w,
                      ),
                      height: ResponsiveBreakpoints.responsive(
                        context,
                        tablet: 18.w,
                        small: 18.w,
                        medium: 18.w,
                        large: 18.w,
                        ultrawide: 18.w,
                      ),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.transparent,
                            AppTheme.accentGold.withOpacity(0.1 * lightRayAnimation.value),
                            AppTheme.accentGold.withOpacity(0.3 * lightRayAnimation.value),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.7, 0.85, 1.0],
                        ),
                      ),
                    ),

                    // Main logo container with advanced effects
                    Container(
                      width: ResponsiveBreakpoints.responsive(
                        context,
                        tablet: 14.w,
                        small: 14.w,
                        medium: 14.w,
                        large: 14.w,
                        ultrawide: 14.w,
                      ),
                      height: ResponsiveBreakpoints.responsive(
                        context,
                        tablet: 14.w,
                        small: 14.w,
                        medium: 14.w,
                        large: 14.w,
                        ultrawide: 14.w,
                      ),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppTheme.pureWhite,
                            AppTheme.pureWhite.withOpacity(0.98),
                            AppTheme.pureWhite.withOpacity(0.95),
                            AppTheme.pureWhite.withOpacity(0.9),
                          ],
                          stops: const [0.0, 0.5, 0.8, 1.0],
                        ),
                        boxShadow: [
                          // Primary golden glow
                          BoxShadow(
                            color: AppTheme.accentGold.withOpacity(0.6 * lightRayAnimation.value),
                            blurRadius: context.shadowBlur('heavy') * 2,
                            spreadRadius: 4,
                            offset: const Offset(0, 0),
                          ),
                          // Secondary glow
                          BoxShadow(
                            color: AppTheme.accentGold.withOpacity(0.3 * lightRayAnimation.value),
                            blurRadius: context.shadowBlur('heavy') * 3,
                            spreadRadius: 8,
                            offset: const Offset(0, 0),
                          ),
                          // Depth shadow
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: context.shadowBlur('heavy'),
                            offset: Offset(0, context.smallPadding * 2),
                          ),
                          // Inner highlight
                          BoxShadow(
                            color: AppTheme.pureWhite.withOpacity(0.8),
                            blurRadius: context.shadowBlur(),
                            spreadRadius: -2,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Animated shimmer overlay
                          ClipOval(
                            child: Container(
                              width: double.infinity,
                              height: double.infinity,
                              decoration: BoxDecoration(
                                gradient: SweepGradient(
                                  center: Alignment.center,
                                  startAngle: shimmerAnimation.value * 3.14159,
                                  endAngle: (shimmerAnimation.value + 1) * 3.14159,
                                  colors: [
                                    Colors.transparent,
                                    AppTheme.accentGold.withOpacity(0.1),
                                    AppTheme.accentGold.withOpacity(0.3),
                                    AppTheme.accentGold.withOpacity(0.1),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Moon logo with premium effects
                          ShaderMask(
                            shaderCallback: (bounds) => RadialGradient(
                              colors: [
                                AppTheme.primaryMaroon,
                                AppTheme.secondaryMaroon,
                                AppTheme.accentGold,
                                AppTheme.primaryMaroon,
                              ],
                              stops: const [0.0, 0.3, 0.7, 1.0],
                            ).createShader(bounds),
                            child: Image.asset('assets/images/moon.png')
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}