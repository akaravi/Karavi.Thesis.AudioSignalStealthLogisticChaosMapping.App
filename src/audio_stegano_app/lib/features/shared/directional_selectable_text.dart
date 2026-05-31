import 'package:flutter/material.dart';

import '../../core/ui/content_text_direction.dart';

/// [SelectableText] with content-aware direction (Latin-only → LTR in RTL locales).
class DirectionalSelectableText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final bool forceLatinLtr;

  const DirectionalSelectableText(
    this.text, {
    super.key,
    this.style,
    this.forceLatinLtr = false,
  });

  @override
  Widget build(BuildContext context) {
    final direction = ContentTextDirection.resolve(
      text,
      localeDirection: Directionality.of(context),
      forceLatinLtr: forceLatinLtr,
    );
    return Directionality(
      textDirection: direction,
      child: SelectableText(text, style: style),
    );
  }
}
