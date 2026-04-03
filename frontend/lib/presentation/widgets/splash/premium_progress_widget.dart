import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../../src/theme/app_theme.dart';
import '../../../../src/utils/responsive_breakpoints.dart';

class PremiumProgressWidget extends StatelessWidget {
  final AnimationController progressController;
  final AnimationController shimmerController;
  final Animation<double> shimmerAnimation;

  const PremiumProgressWidget({
    super.key,
    required this.progressController,
    required this.shimmerController,
    required this.shimmerAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        progressController,
        shimmerController,
      ]),
      builder: (context, child) {
        return Column(
          children: [
            Container(
              width: ResponsiveBreakpoints.responsive(
                context,
                tablet: 40.w,
                small: 40.w,
                medium: 22.w,
                large: 30.w,
                ultrawide: 22.w,
              ),
              height: ResponsiveBreakpoints.responsive(
                context,
                tablet: 1.2.h,
                small: 1.0.h,
                medium: 1.0.h,
                large: 0.8.h,
                ultrawide: 0.8.h,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(context.borderRadius('xl')),
                gradient: LinearGradient(
                  colors: [
                    AppTheme.pureWhite.withOpacity(0.1),
                    AppTheme.pureWhite.withOpacity(0.2),
                    AppTheme.pureWhite.withOpacity(0.1),
                  ],
                ),
                border: Border.all(
                  color: AppTheme.accentGold.withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                  BoxShadow(
                    color: AppTheme.accentGold.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Animated background glow
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(context.borderRadius('xl')),
                      gradient: LinearGradient(
                        begin: Alignment(-1.0 + shimmerAnimation.value * 0.5, 0),
                        end: Alignment(1.0 + shimmerAnimation.value * 0.5, 0),
                        colors: [
                          Colors.transparent,
                          AppTheme.accentGold.withOpacity(0.1),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),

                  // Progress fill with advanced gradient
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progressController.value,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(context.borderRadius('xl')),
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.accentGold.withOpacity(0.8),
                            AppTheme.accentGold,
                            const Color(0xFFFFD700),
                            AppTheme.accentGold,
                            AppTheme.accentGold.withOpacity(0.8),
                          ],
                          stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.accentGold.withOpacity(0.6),
                            blurRadius: 20,
                            offset: const Offset(0, 0),
                          ),
                          BoxShadow(
                            color: AppTheme.accentGold.withOpacity(0.8),
                            blurRadius: 5,
                            offset: const Offset(0, 0),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Animated progress shimmer
                  if (progressController.value > 0.1)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(context.borderRadius('xl')),
                          gradient: LinearGradient(
                            begin: Alignment(-1.5, 0),
                            end: Alignment(1.5, 0),
                            colors: [
                              Colors.transparent,
                              AppTheme.pureWhite.withOpacity(0.6),
                              AppTheme.pureWhite.withOpacity(0.8),
                              AppTheme.pureWhite.withOpacity(0.6),
                              Colors.transparent,
                            ],
                            stops: [
                              (progressController.value - 0.4).clamp(0.0, 1.0),
                              (progressController.value - 0.2).clamp(0.0, 1.0),
                              progressController.value.clamp(0.0, 1.0),
                              (progressController.value + 0.2).clamp(0.0, 1.0),
                              (progressController.value + 0.4).clamp(0.0, 1.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            SizedBox(height: context.smallPadding * 2.5),

            // Luxury loading text with glow
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [
                  AppTheme.pureWhite.withOpacity(0.8),
                  AppTheme.accentGold.withOpacity(0.9),
                  AppTheme.pureWhite.withOpacity(0.8),
                ],
              ).createShader(bounds),
              child: Text(
                'Crafting your exclusive fashion experience...',
                style: TextStyle(
                  fontSize: context.captionFontSize * 1.1,
                  fontWeight: FontWeight.w300,
                  color: Colors.white,
                  letterSpacing: 1.5,
                  shadows: [
                    Shadow(
                      color: AppTheme.accentGold.withOpacity(0.4),
                      offset: const Offset(0, 0),
                      blurRadius: 12,
                    ),
                    Shadow(
                      color: Colors.black.withOpacity(0.4),
                      offset: const Offset(0, 1),
                      blurRadius: 3,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}