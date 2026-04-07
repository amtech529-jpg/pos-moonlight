import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../src/theme/app_theme.dart';

class PremiumTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final FormFieldValidator<String>? validator;
  final int maxLines;
  final bool enabled;
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final bool selectAllOnFocus;
  final TextInputAction? textInputAction;
  final Function(FocusNode, KeyEvent)? onKeyEvent;
  final double? fontSize;
  final double? labelFontSize;

  const PremiumTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.maxLines = 1,
    this.enabled = true,
    this.initialValue,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.selectAllOnFocus = false,
    this.onKeyEvent,
    this.fontSize,
    this.labelFontSize,
  });

  @override
  State<PremiumTextField> createState() => _PremiumTextFieldState();
}

class _PremiumTextFieldState extends State<PremiumTextField>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Color?> _borderColorAnimation;
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    
    _animationController = AnimationController(
        duration: const Duration(milliseconds: 200),
        vsync: this,
    );
    _borderColorAnimation = ColorTween(
      begin: const Color(0xFFE0E0E0),
      end: AppTheme.primaryMaroon,
    ).animate(_animationController);

    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
      if (_isFocused) {
        _animationController.forward();
        if (widget.selectAllOnFocus && widget.controller != null) {
          widget.controller!.selection = TextSelection(
            baseOffset: 0,
            extentOffset: widget.controller!.text.length,
          );
        }
      } else {
        _animationController.reverse();
      }
    });

    if (widget.onKeyEvent != null) {
      _focusNode.onKeyEvent = (node, event) {
        return widget.onKeyEvent!(node, event);
      };
    }
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
    return AnimatedBuilder(
      animation: _borderColorAnimation,
      builder: (context, child) {
        return TextFormField(
          controller: widget.controller,
          initialValue: widget.controller != null ? null : widget.initialValue,
          focusNode: _focusNode,
          obscureText: widget.obscureText,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          validator: widget.validator,
          maxLines: widget.maxLines,
          enabled: widget.enabled,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          style: TextStyle(
            fontSize: widget.fontSize ?? 14,
            fontWeight: FontWeight.w400,
            color: Colors.black87,
          ),
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint,
            prefixIcon: widget.prefixIcon != null
                ? Icon(
              widget.prefixIcon,
              size: 13.sp,
              color: _isFocused
                  ? AppTheme.primaryMaroon
                  : const Color(0xFF9E9E9E),
            )
                : null,
            suffixIcon: widget.suffixIcon != null
                ? Padding(
                    padding: EdgeInsets.only(right: 1.w),
                    child: widget.suffixIcon,
                  )
                : null,
            filled: true,
            fillColor: widget.enabled ? AppTheme.pureWhite : Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(1.5.w),
              borderSide: BorderSide(
                color: _borderColorAnimation.value ?? const Color(0xFFE0E0E0),
                width: 0.1.w,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(1.5.w),
              borderSide: BorderSide(
                color: const Color(0xFFE0E0E0),
                width: 0.1.w,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(1.5.w),
              borderSide: BorderSide(
                color: AppTheme.primaryMaroon,
                width: 0.2.w,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(1.5.w),
              borderSide: BorderSide(
                color: Colors.red,
                width: 0.1.w,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(1.5.w),
              borderSide: BorderSide(
                color: Colors.red,
                width: 0.2.w,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              vertical: 2.h,
              horizontal: widget.suffixIcon != null ? 3.w : 2.w,
            ),
            labelStyle: TextStyle(
              color: _isFocused ? AppTheme.primaryMaroon : AppTheme.charcoalGray,
              fontSize: widget.labelFontSize ?? 12.sp,
              fontWeight: FontWeight.w500,
            ),
            floatingLabelStyle: TextStyle(
              color: _isFocused ? AppTheme.primaryMaroon : AppTheme.charcoalGray,
              fontSize: widget.labelFontSize ?? 12.sp,
              fontWeight: FontWeight.w600,
            ),
            hintStyle: TextStyle(
              color: AppTheme.charcoalGray.withOpacity(0.6),
              fontSize: 12.sp,
              fontWeight: FontWeight.w400,
            ),
          ),
        );
      },
    );
  }
}