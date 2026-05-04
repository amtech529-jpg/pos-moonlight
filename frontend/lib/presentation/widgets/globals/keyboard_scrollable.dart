import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class KeyboardScrollable extends StatefulWidget {
  final Widget child;
  final ScrollController? controller;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry? padding;
  final Axis scrollDirection;
  final bool reverse;
  final bool? primary;
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;
  final String? restorationId;
  final Clip clipBehavior;
  final bool thumbVisibility;
  final bool trackVisibility;

  const KeyboardScrollable({
    super.key,
    required this.child,
    this.controller,
    this.physics,
    this.padding,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.primary,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    this.restorationId,
    this.clipBehavior = Clip.hardEdge,
    this.thumbVisibility = true,
    this.trackVisibility = true,
  });

  @override
  State<KeyboardScrollable> createState() => _KeyboardScrollableState();
}

class _KeyboardScrollableState extends State<KeyboardScrollable> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller ?? ScrollController();
    // Register a global hardware key handler so arrow/page keys work
    // even when a text field inside this widget has focus.
    HardwareKeyboard.instance.addHandler(_onHardwareKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onHardwareKey);
    if (widget.controller == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  void _scroll(double delta) {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      (_scrollController.offset + delta).clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      ),
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
    );
  }

  bool _onHardwareKey(KeyEvent event) {
    // Only act on KeyDownEvent or KeyRepeatEvent (held down)
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return false;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowUp:
        _scroll(-80.0);
        return true; // consumed
      case LogicalKeyboardKey.arrowDown:
        _scroll(80.0);
        return true;
      case LogicalKeyboardKey.pageUp:
        _scroll(-300.0);
        return true;
      case LogicalKeyboardKey.pageDown:
        _scroll(300.0);
        return true;
      default:
        return false; // let other handlers process it
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: widget.thumbVisibility,
      trackVisibility: widget.trackVisibility,
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: widget.physics,
        padding: widget.padding,
        scrollDirection: widget.scrollDirection,
        reverse: widget.reverse,
        primary: widget.primary,
        keyboardDismissBehavior: widget.keyboardDismissBehavior,
        restorationId: widget.restorationId,
        clipBehavior: widget.clipBehavior,
        child: widget.child,
      ),
    );
  }
}
