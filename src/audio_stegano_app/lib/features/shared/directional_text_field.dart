import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/ui/content_text_direction.dart';

/// [TextField] that keeps Latin-only content LTR even in RTL UI locales.
class DirectionalTextField extends StatefulWidget {
  final bool forceLatinLtr;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final InputDecoration? decoration;
  final TextInputType? keyboardType;
  final TextAlign textAlign;
  final TextStyle? style;
  final int? maxLines;
  final int? minLines;
  final bool enabled;
  final bool obscureText;
  final bool autocorrect;
  final bool enableSuggestions;
  final ScrollPhysics? scrollPhysics;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onEditingComplete;
  final TapRegionCallback? onTapOutside;
  final VoidCallback? onTap;

  const DirectionalTextField({
    super.key,
    this.forceLatinLtr = false,
    this.controller,
    this.focusNode,
    this.decoration,
    this.keyboardType,
    this.textAlign = TextAlign.start,
    this.style,
    this.maxLines = 1,
    this.minLines,
    this.enabled = true,
    this.obscureText = false,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.scrollPhysics,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.onEditingComplete,
    this.onTapOutside,
    this.onTap,
  });

  @override
  State<DirectionalTextField> createState() => _DirectionalTextFieldState();
}

class _DirectionalTextFieldState extends State<DirectionalTextField> {
  TextEditingController? _ownedController;
  TextDirection _textDirection = TextDirection.ltr;

  TextEditingController get _controller =>
      widget.controller ?? _ownedController!;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _ownedController = TextEditingController();
    }
    _controller.addListener(_syncDirection);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncDirection());
  }

  @override
  void didUpdateWidget(DirectionalTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_syncDirection);
      if (widget.controller == null && _ownedController == null) {
        _ownedController = TextEditingController();
      }
      _controller.addListener(_syncDirection);
      _syncDirection();
    }
    if (oldWidget.forceLatinLtr != widget.forceLatinLtr) {
      _syncDirection();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_syncDirection);
    _ownedController?.dispose();
    super.dispose();
  }

  void _syncDirection() {
    if (!mounted) return;
    final locale = Directionality.of(context);
    final next = ContentTextDirection.resolve(
      _controller.text,
      localeDirection: locale,
      forceLatinLtr: widget.forceLatinLtr,
    );
    if (next != _textDirection) {
      setState(() => _textDirection = next);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: widget.focusNode,
      decoration: widget.decoration,
      keyboardType: widget.keyboardType,
      textAlign: widget.textAlign,
      textDirection: _textDirection,
      style: widget.style,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      enabled: widget.enabled,
      obscureText: widget.obscureText,
      autocorrect: widget.autocorrect,
      enableSuggestions: widget.enableSuggestions,
      scrollPhysics: widget.scrollPhysics,
      inputFormatters: widget.inputFormatters,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      onEditingComplete: widget.onEditingComplete,
      onTapOutside: widget.onTapOutside,
      onTap: widget.onTap,
    );
  }
}
