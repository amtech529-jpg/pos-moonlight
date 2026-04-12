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
  final FocusNode? focusNode;

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
    this.focusNode,
  });

  @override
  State<PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<PremiumButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late FocusNode _focusNode;
  bool _isFocused = false;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(() {
      if (mounted) {
        setState(() {
          _isFocused = _focusNode.hasFocus;
        });
      }
    });

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
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
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isHighlighted = _isFocused || _isHovered;
    final borderRadius = BorderRadius.circular(25); 

    return AnimatedScale(
      scale: isHighlighted ? 1.05 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                borderRadius: borderRadius,
                boxShadow: [
                  if (!widget.isOutlined)
                    BoxShadow(
                      color: (widget.backgroundColor ?? AppTheme.primaryMaroon)
                          .withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  if (isHighlighted)
                    BoxShadow(
                      color: AppTheme.accentGold.withOpacity(0.4),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  focusNode: _focusNode,
                  onTap: widget.isLoading ? null : (widget.onPressed ?? () {}),
                  onTapDown: (_) => _animationController.forward(),
                  onTapUp: (_) => _animationController.reverse(),
                  onTapCancel: () => _animationController.reverse(),
                  onHover: (hovering) {
                    setState(() => _isHovered = hovering);
                  },
                  borderRadius: borderRadius,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: widget.isOutlined
                          ? (isHighlighted ? (widget.backgroundColor ?? AppTheme.primaryMaroon).withOpacity(0.1) : Colors.transparent)
                          : (isHighlighted ? (widget.backgroundColor ?? AppTheme.primaryMaroon).withLightness(0.05) : (widget.backgroundColor ?? AppTheme.primaryMaroon)),
                      border: Border.all(
                        color: isHighlighted 
                          ? AppTheme.accentGold 
                          : (widget.isOutlined ? (widget.backgroundColor ?? AppTheme.primaryMaroon) : Colors.transparent),
                        width: isHighlighted ? 2.5 : (widget.isOutlined ? 1.5 : 0),
                      ),
                      borderRadius: borderRadius,
                    ),
                    child: Center(
                      child: widget.isLoading
                          ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
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
                              size: 14.sp,
                              color: (widget.isOutlined
                                  ? (widget.textColor ?? 
                                     widget.backgroundColor ?? 
                                     AppTheme.primaryMaroon)
                                  : (widget.textColor ?? AppTheme.pureWhite)),
                            ),
                            SizedBox(width: 8),
                          ],
                          Text(
                            widget.text,
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: (widget.isOutlined
                                  ? (widget.textColor ?? 
                                     widget.backgroundColor ?? 
                                     AppTheme.primaryMaroon)
                                  : (widget.textColor ?? AppTheme.pureWhite)),
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
      ),
    );
  }
}

extension ColorExtension on Color {
  Color withLightness(double amount) {
    final hsl = HSLColor.fromColor(this);
    return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
  }
}

