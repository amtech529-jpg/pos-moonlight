import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../src/theme/app_theme.dart';
import '../../../src/utils/responsive_breakpoints.dart';

class DropdownItem<T> {
  final T value;
  final String label;

  DropdownItem({required this.value, required this.label});
}

class PremiumDropdownField<T> extends StatefulWidget {
  final String label;
  final String? hint;
  final List<DropdownItem<T>> items;
  final T? value;
  final ValueChanged<T?>? onChanged;
  final FormFieldValidator<T?>? validator;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool enabled;

  const PremiumDropdownField({
    super.key,
    required this.label,
    this.hint,
    required this.items,
    this.value,
    this.onChanged,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
  });

  @override
  State<PremiumDropdownField<T>> createState() => _PremiumDropdownFieldState<T>();
}

class _PremiumDropdownFieldState<T> extends State<PremiumDropdownField<T>>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Color?> _borderColorAnimation;
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: const Duration(milliseconds: 200), vsync: this);
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
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _borderColorAnimation,
      builder: (context, child) {
        return TextFormField(
          readOnly: true,
          focusNode: _focusNode,
          controller: TextEditingController(
            text: widget.value != null
                ? widget.items
                .firstWhere(
                  (item) => item.value == widget.value,
              orElse: () => DropdownItem<T>(value: widget.value as T, label: ''),
            )
                .label
                : '',
          ),
          onTap: widget.enabled
              ? () async {
            final RenderBox box = context.findRenderObject() as RenderBox;
            final Offset position = box.localToGlobal(Offset.zero);
            final Size size = box.size;

            if (widget.items.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No options available')),
              );
              return;
            }
            final T? selected = await showMenu<T>(
              context: context,
              position: RelativeRect.fromLTRB(
                position.dx,
                position.dy + size.height,
                position.dx + size.width,
                position.dy,
              ),
              items: widget.items.map((item) {
                return PopupMenuItem<T>(
                  value: item.value,
                  child: Text(
                    item.label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.black87,
                    ),
                  ),
                );
              }).toList(),
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(1.5.w)),
              color: AppTheme.pureWhite,
            );

            if (selected != null) {
              widget.onChanged?.call(selected);
            }
          }
              : null,
          validator: widget.validator != null ? (String? value) => widget.validator!(widget.value) : null,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Colors.black87,
          ),
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint,
            prefixIcon: widget.prefixIcon != null
                ? Icon(
              widget.prefixIcon,
              size: 12.sp,
              color: _isFocused ? AppTheme.primaryMaroon : const Color(0xFF9E9E9E),
            )
                : null,
            suffixIcon:
            widget.suffixIcon ??
                Icon(
                  Icons.arrow_drop_down_rounded,
                  size: 12.sp,
                  color: _isFocused ? AppTheme.primaryMaroon : const Color(0xFF9E9E9E),
                ),
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
              borderSide: BorderSide(color: const Color(0xFFE0E0E0), width: 0.1.w),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(1.5.w),
              borderSide: BorderSide(color: AppTheme.primaryMaroon, width: 0.2.w),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(1.5.w),
              borderSide: BorderSide(color: Colors.red, width: 0.1.w),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(1.5.w),
              borderSide: BorderSide(color: Colors.red, width: 0.2.w),
            ),
            contentPadding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 2.w),
            labelStyle: TextStyle(
              color: _isFocused ? AppTheme.primaryMaroon : AppTheme.charcoalGray,
              fontSize: 10.sp,
              fontWeight: FontWeight.w500,
            ),
            hintStyle: TextStyle(
              color: AppTheme.charcoalGray.withOpacity(0.6),
              fontSize: 10.sp,
              fontWeight: FontWeight.w400,
            ),
          ),
        );
      },
    );
  }
}
