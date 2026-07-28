import 'package:flutter/material.dart';

import '../../app/app_ui_tokens.dart';

/// Page destination header — title always visible (start / RTL-right) + trailing actions.
///
/// Uses an explicit [Row] instead of Material [AppBar] title slot so web/RTL
/// cannot collapse the title to zero width beside large circular FABs.
class PageAppBar extends StatelessWidget implements PreferredSizeWidget {
  const PageAppBar({
    super.key,
    required this.title,
    this.actions,
  });

  final String title;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final titleStyle =
        (Theme.of(context).appBarTheme.titleTextStyle ??
                Theme.of(context).textTheme.titleLarge)
            ?.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w600,
              fontSize: 20,
            );

    final actionWidgets = <Widget>[];
    if (actions != null && actions!.isNotEmpty) {
      for (var i = 0; i < actions!.length; i++) {
        if (i > 0) {
          actionWidgets.add(const SizedBox(width: AppUiTokens.toolbarFabGap));
        }
        actionWidgets.add(actions![i]);
      }
    }

    return Material(
      color: scheme.surface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: kToolbarHeight,
          child: Padding(
            padding: const EdgeInsetsDirectional.only(start: 16, end: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.start,
                      style: titleStyle,
                    ),
                  ),
                ),
                if (actionWidgets.isNotEmpty) ...actionWidgets,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
