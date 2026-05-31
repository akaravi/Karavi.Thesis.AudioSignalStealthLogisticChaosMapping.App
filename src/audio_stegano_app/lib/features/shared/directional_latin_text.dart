import 'package:flutter/material.dart';

import '../../core/ui/content_text_direction.dart';

/// [Text] with content-aware direction (Latin-only → LTR in RTL locales).
class DirectionalLatinText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool forceLatinLtr;

  const DirectionalLatinText(
    this.text, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
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
      child: Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: overflow,
      ),
    );
  }
}
