import 'package:flutter/material.dart';

/// Scrollable tab content tuned for narrow / mobile layouts.
///
/// - Bounded height via parent [LayoutBuilder] (works inside [Stack] tab hosts).
/// - Keyboard inset padding and drag-to-dismiss keyboard.
/// - Bouncing, always-scrollable physics (short pages still scroll on iOS).
class TabScrollBody extends StatelessWidget {
  const TabScrollBody({super.key, required this.children, this.padding});

  final List<Widget> children;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final viewInsets = mq.viewInsets;
    final base = padding ?? const EdgeInsets.all(16);
    final resolved = base.resolve(Directionality.of(context));
    final effectivePadding = EdgeInsets.fromLTRB(
      resolved.left,
      resolved.top,
      resolved.right,
      resolved.bottom + viewInsets.bottom,
    );

    return SafeArea(
      bottom: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final minHeight = (constraints.maxHeight - effectivePadding.vertical)
              .clamp(0.0, double.infinity);
          return SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: effectivePadding,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: minHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          );
        },
      ),
    );
  }
}
