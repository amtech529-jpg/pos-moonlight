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
  final BoxDecoration? containerDecoration;
  final bool readOnly;

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
    this.containerDecoration,
    this.readOnly = false,
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
      if (mounted) {
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label.isNotEmpty) ...[
          Text(
            widget.label,
            style: TextStyle(
              fontSize: widget.labelFontSize ?? 11.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.charcoalGray,
            ),
          ),
          SizedBox(height: 0.8.h),
        ],
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: widget.containerDecoration ?? BoxDecoration(
            borderRadius: BorderRadius.circular(1.5.w),
            boxShadow: [
              if (_isFocused)
                BoxShadow(
                  color: AppTheme.primaryMaroon.withOpacity(0.15),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            enabled: widget.enabled,
            readOnly: widget.readOnly,
            initialValue: widget.controller != null ? null : widget.initialValue,
            onChanged: widget.onChanged,
            onFieldSubmitted: widget.onSubmitted,
            maxLines: widget.maxLines,
            style: TextStyle(
              fontSize: widget.fontSize ?? 12.sp,
              color: AppTheme.charcoalGray,
              fontWeight: FontWeight.w400,
            ),
            validator: widget.validator,
            decoration: InputDecoration(
              hintText: widget.hint,
              prefixIcon: widget.prefixIcon != null
                  ? Icon(widget.prefixIcon,
                      color: _isFocused ? AppTheme.primaryMaroon : Colors.grey,
                      size: 16.sp)
                  : null,
              suffixIcon: widget.suffixIcon,
              filled: true,
              fillColor: widget.enabled ? AppTheme.pureWhite : Colors.grey.shade50,
              contentPadding:
                  EdgeInsets.symmetric(vertical: 2.h, horizontal: 2.w),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(1.5.w),
                borderSide: BorderSide(
                    color: const Color(0xFFE0E0E0), width: 0.1.w),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(1.5.w),
                borderSide:
                    BorderSide(color: AppTheme.primaryMaroon, width: 0.15.w),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(1.5.w),
                borderSide: BorderSide(
                    color: const Color(0xFFEEEEEE), width: 0.1.w),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(1.5.w),
                borderSide: BorderSide(color: Colors.red, width: 0.1.w),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(1.5.w),
                borderSide: BorderSide(color: Colors.red, width: 0.15.w),
              ),
            ),
          ),
        ),
      ],
    );
  }
}