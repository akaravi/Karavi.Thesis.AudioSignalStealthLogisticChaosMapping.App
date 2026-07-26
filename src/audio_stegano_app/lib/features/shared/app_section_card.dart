import 'package:flutter/material.dart';

import '../../app/app_ui_tokens.dart';

/// Standard elevated section card used on every main tab.
class AppSectionCard extends StatelessWidget {
  const AppSectionCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.outlined = false,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool outlined;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: color ?? scheme.surfaceContainerLow,
      margin: margin ?? EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: AppUiTokens.cardBorderRadius,
        side: outlined
            ? AppUiTokens.resultOutline(scheme)
            : BorderSide.none,
      ),
      child: Padding(
        padding: padding ?? AppUiTokens.cardPadding,
        child: child,
      ),
    );
  }
}
