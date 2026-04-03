import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../src/theme/app_theme.dart';

class PremiumButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double height;

  const PremiumButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height = 50,
  });

  @override
  State<PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<PremiumButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(1.5.w),
              boxShadow: widget.isOutlined
                  ? null
                  : [
                BoxShadow(
                  color: (widget.backgroundColor ?? AppTheme.primaryMaroon)
                      .withOpacity(0.3),
                  blurRadius: 1.w,
                  offset: Offset(0, 0.5.w),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.isLoading ? null : widget.onPressed,
                onTapDown: (_) => _animationController.forward(),
                onTapUp: (_) => _animationController.reverse(),
                onTapCancel: () => _animationController.reverse(),
                borderRadius: BorderRadius.circular(1.5.w),
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.isOutlined
                        ? Colors.transparent
                        : (widget.backgroundColor ?? AppTheme.primaryMaroon),
                    border: widget.isOutlined
                        ? Border.all(
                      color: widget.backgroundColor ?? AppTheme.primaryMaroon,
                      width: 0.2.w,
                    )
                        : null,
                    borderRadius: BorderRadius.circular(1.5.w),
                  ),
                  child: Center(
                    child: widget.isLoading
                        ? SizedBox(
                      width: 3.sp,
                      height: 3.sp,
                      child: CircularProgressIndicator(
                        strokeWidth: 0.3.sp,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          widget.isOutlined
                              ? (widget.backgroundColor ?? AppTheme.primaryMaroon)
                              : AppTheme.pureWhite,
                        ),
                      ),
                    )
                        : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(
                            widget.icon,
                            size: 12.sp,
                            color: widget.isOutlined
                                ? (widget.textColor ?? 
                                   widget.backgroundColor ?? 
                                   AppTheme.primaryMaroon)
                                : (widget.textColor ?? AppTheme.pureWhite),
                          ),
                          SizedBox(width: 1.w),
                        ],
                        Text(
                          widget.text,
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                            color: widget.isOutlined
                                ? (widget.textColor ?? 
                                   widget.backgroundColor ?? 
                                   AppTheme.primaryMaroon)
                                : (widget.textColor ?? AppTheme.pureWhite),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
