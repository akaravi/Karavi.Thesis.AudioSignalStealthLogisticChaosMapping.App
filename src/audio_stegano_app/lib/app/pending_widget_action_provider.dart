import 'package:flutter_riverpod/legacy.dart';

import '../core/platform/android_widget_action.dart';

class PendingWidgetActionController extends StateNotifier<AndroidWidgetQuickAction?> {
  PendingWidgetActionController() : super(null);

  void setPending(AndroidWidgetQuickAction? action) => state = action;

  void clear() => state = null;
}

/// Set when the user taps the Android home-screen widget; consumed by [EmbedScreen].
final pendingWidgetActionProvider =
    StateNotifierProvider<PendingWidgetActionController, AndroidWidgetQuickAction?>(
      (ref) => PendingWidgetActionController(),
    );
