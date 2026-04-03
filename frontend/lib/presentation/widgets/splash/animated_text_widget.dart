import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../../src/theme/app_theme.dart';
import '../../../../src/utils/responsive_breakpoints.dart';

class AnimatedTextWidget extends StatelessWidget {
  final Animation<Offset> textSlideAnimation;
  final Animation<double> textOpacityAnimation;
  final Animation<double> textGlowAnimation;
  final Animation<double> shimmerAnimation;
  final AnimationController textController;
  final AnimationController shimmerController;

  const AnimatedTextWidget({
    super.key,
    required this.textSlideAnimation,
    required this.textOpacityAnimation,
    required this.textGlowAnimation,
    required this.shimmerAnimation,
    required this.textController,
    required this.shimmerController,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        textController,
        shimmerController,
      ]),
      builder: (context, child) {
        return SlideTransition(
          position: textSlideAnimation,
          child: FadeTransition(
            opacity: textOpacityAnimation,
            child: Column(
              children: [
                // Company name with complex shader effects
                Stack(
                  children: [
                    // Glow background
                    Text(
                      'Moonlight',
                      style: TextStyle(
                        fontSize: context.headingFontSize * 1.2,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.accentGold.withOpacity(0.3),
                        letterSpacing: 3.0,
                      ),
                    ),
                    // Main text with animated shader
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        begin: Alignment(-1.0 + textGlowAnimation.value, -0.5),
                        end: Alignment(1.0 + textGlowAnimation.value, 0.5),
                        colors: [
                          AppTheme.pureWhite.withOpacity(0.8),
                          AppTheme.accentGold,
                          AppTheme.pureWhite,
                          AppTheme.accentGold.withOpacity(0.9),
                          AppTheme.pureWhite.withOpacity(0.8),
                        ],
                        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                      ).createShader(bounds),
                      child: Text(
                        'Moonlight',
                        style: TextStyle(
                          fontSize: context.headingFontSize * 1.2,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 3.0,
                          shadows: [
                            Shadow(
                              color: AppTheme.accentGold.withOpacity(0.5),
                              offset: const Offset(0, 0),
                              blurRadius: 20,
                            ),
                            Shadow(
                              color: Colors.black.withOpacity(0.5),
                              offset: const Offset(0, 3),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: context.smallPadding * 1.5),

                // Animated decorative elements
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildDecorativeDiamond(context),
                    Container(
                      width: ResponsiveBreakpoints.responsive(
                        context,
                        tablet: 20.w,
                        small: 20.w,
                        medium: 12.w,
                        large: 15.w,
                        ultrawide: 12.w,
                      ),
                      height: 3,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            AppTheme.accentGold.withOpacity(0.3),
                            AppTheme.accentGold,
                            AppTheme.accentGold.withOpacity(0.3),
                            Colors.transparent,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.accentGold.withOpacity(0.5),
                            blurRadius: 10,
                            offset: const Offset(0, 0),
                          ),
                        ],
                      ),
                    ),
                    _buildDecorativeDiamond(context),
                  ],
                ),

                SizedBox(height: context.smallPadding * 2),

                // Enhanced subtitle
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      AppTheme.pureWhite.withOpacity(0.9),
                      AppTheme.accentGold.withOpacity(0.7),
                      AppTheme.pureWhite.withOpacity(0.9),
                    ],
                  ).createShader(bounds),
                  child: Text(
                    'Elite Event Management Solution',
                    style: TextStyle(
                      fontSize: context.headerFontSize,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                      letterSpacing: 2.5,
                      shadows: [
                        Shadow(
                          color: AppTheme.accentGold.withOpacity(0.3),
                          offset: const Offset(0, 0),
                          blurRadius: 15,
                        ),
                        Shadow(
                          color: Colors.black.withOpacity(0.3),
                          offset: const Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDecorativeDiamond(BuildContext context) {
    return AnimatedBuilder(
      animation: shimmerController,
      builder: (context, child) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: context.smallPadding),
          child: Transform.rotate(
            angle: shimmerAnimation.value * 0.1,
            child: Icon(
              Icons.star_rounded,
              size: context.iconSize('small') * 0.8,
              color: AppTheme.accentGold.withOpacity(0.8),
            ),
          ),
        );
      },
    );
  }
}