import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import '../../../src/theme/app_theme.dart';
import '../../../src/utils/responsive_breakpoints.dart';

class DropdownItem<T> {
  final T value;
  final String label;

  DropdownItem({required this.value, required this.label});
}

class PremiumDropdownField<T> extends StatefulWidget {
  final String? label;
  final String? hint;
  final List<DropdownItem<T>> items;
  final T? value;
  final ValueChanged<T?>? onChanged;
  final FormFieldValidator<T?>? validator;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool enabled;
  final double? fontSize;
  final double? labelFontSize;
  final Color? focusColor;
  final BoxDecoration? containerDecoration;
  final FocusNode? focusNode;

  const PremiumDropdownField({
    super.key,
    this.label,
    this.hint,
    required this.items,
    this.value,
    this.onChanged,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
    this.fontSize,
    this.labelFontSize,
    this.focusColor,
    this.containerDecoration,
    this.focusNode,
  });

  @override
  State<PremiumDropdownField<T>> createState() => _PremiumDropdownFieldState<T>();
}

class _PremiumDropdownFieldState<T> extends State<PremiumDropdownField<T>>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Color?> _borderColorAnimation;
  late FocusNode _focusNode;
  bool _isFocused = false;
  bool _isMenuOpen = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _animationController = AnimationController(duration: const Duration(milliseconds: 200), vsync: this);
    _borderColorAnimation = ColorTween(
      begin: const Color(0xFFE0E0E0),
      end: widget.focusColor ?? AppTheme.primaryMaroon,
    ).animate(_animationController);

    _focusNode.addListener(() {
      if (mounted) {
        setState(() {
          _isFocused = _focusNode.hasFocus;
        });
        if (_isFocused) {
          _animationController.forward();
          // Auto-open menu on focus gain for smoother keyboard navigation
          if (widget.enabled && !_isMenuOpen) {
            _showMenu();
          }
        } else {
          _animationController.reverse();
        }
      }
    });

    _focusNode.onKeyEvent = (node, event) {
      if (event is KeyDownEvent && 
          (event.logicalKey == LogicalKeyboardKey.enter || 
           event.logicalKey == LogicalKeyboardKey.space)) {
        if (!_isMenuOpen) {
          _showMenu();
        }
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    };
  }

  Future<void> _showMenu() async {
    if (!widget.enabled || _isMenuOpen) return;
    
    setState(() => _isMenuOpen = true);
    
    try {
      if (!_focusNode.hasFocus) {
        _focusNode.requestFocus();
      }

      final RenderBox? box = context.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) {
        setState(() => _isMenuOpen = false);
        return;
      }

      final Size size = box.size;
      final RenderBox? overlay = Navigator.of(context).overlay?.context.findRenderObject() as RenderBox?;
      
      if (overlay == null) {
        setState(() => _isMenuOpen = false);
        return;
      }

      final Offset bottomOffset = box.localToGlobal(Offset(0, size.height + 4), ancestor: overlay);
      final Offset topOffset = box.localToGlobal(Offset(0, -4), ancestor: overlay);

      double calculatedMenuHeight = (widget.items.length * 48.0) + 16.0;
      if (calculatedMenuHeight > 300) calculatedMenuHeight = 300;

      final double spaceBelow = overlay.size.height - bottomOffset.dy;
      final double spaceAbove = topOffset.dy;

      bool popUpwards = false;
      if (spaceBelow < calculatedMenuHeight && spaceAbove > spaceBelow) {
        popUpwards = true;
      }

      Offset menuPos;
      if (popUpwards) {
        menuPos = box.localToGlobal(Offset(0, -calculatedMenuHeight - 4), ancestor: overlay);
      } else {
        menuPos = bottomOffset;
      }

      final RelativeRect positionRect = RelativeRect.fromRect(
        Rect.fromPoints(
          menuPos,
          Offset(menuPos.dx + size.width, menuPos.dy),
        ),
        Offset.zero & overlay.size,
      );

      final T? selected = await showMenu<T>(
        context: context,
        position: positionRect,
        constraints: BoxConstraints(maxHeight: 300, minWidth: size.width),
        items: widget.items.map((item) {
          return PopupMenuItem<T>(
            value: item.value,
            child: Text(
              item.label,
              style: TextStyle(
                fontSize: widget.fontSize ?? 14,
                fontWeight: FontWeight.w400,
                color: Colors.black87,
              ),
            ),
          );
        }).toList(),
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        color: AppTheme.pureWhite,
      );

      if (selected != null) {
        widget.onChanged?.call(selected);
      }
    } catch (e) {
      debugPrint('Error showing dropdown menu: $e');
    } finally {
      if (mounted) {
        setState(() => _isMenuOpen = false);
        // Release focus so the field returns to its un-highlighted state
        // and can be tapped/focused again properly later.
        _focusNode.unfocus();
      }
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
        return Container(
          decoration: widget.containerDecoration,
          child: TextFormField(
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
            onTap: widget.enabled ? _showMenu : null,
            validator: widget.validator != null ? (String? value) => widget.validator!(widget.value) : null,
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
                      size: 20,
                      color: _isFocused ? (widget.focusColor ?? AppTheme.primaryMaroon) : const Color(0xFF9E9E9E),
                    )
                  : null,
              suffixIcon: widget.suffixIcon ??
                  Icon(
                    Icons.arrow_drop_down_rounded,
                    size: 24,
                    color: _isFocused ? (widget.focusColor ?? AppTheme.primaryMaroon) : const Color(0xFF9E9E9E),
                  ),
              filled: true,
              fillColor: widget.enabled ? AppTheme.pureWhite : Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: _isFocused ? (widget.focusColor ?? AppTheme.primaryMaroon) : const Color(0xFFE0E0E0),
                  width: 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: const Color(0xFFE0E0E0), width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: widget.focusColor ?? AppTheme.primaryMaroon, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.red, width: 1),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.red, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              labelStyle: TextStyle(
                color: _isFocused ? (widget.focusColor ?? AppTheme.primaryMaroon) : AppTheme.charcoalGray,
                fontSize: widget.labelFontSize ?? 14,
                fontWeight: FontWeight.w500,
              ),
              floatingLabelStyle: TextStyle(
                color: _isFocused ? (widget.focusColor ?? AppTheme.primaryMaroon) : AppTheme.charcoalGray,
                fontSize: widget.labelFontSize ?? 14,
                fontWeight: FontWeight.w600,
              ),
              hintStyle: TextStyle(
                color: AppTheme.charcoalGray.withOpacity(0.6),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        );
      },
    );
  }
}
