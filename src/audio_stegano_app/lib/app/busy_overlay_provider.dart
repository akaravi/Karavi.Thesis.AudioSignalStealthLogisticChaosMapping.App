import 'package:flutter_riverpod/legacy.dart';

class AppBusyMessageController extends StateNotifier<String?> {
  AppBusyMessageController() : super(null);

  void show(String message) => state = message;

  void clear() => state = null;
}

/// Non-null message = full-app blocking busy overlay is visible.
final appBusyMessageProvider =
    StateNotifierProvider<AppBusyMessageController, String?>((ref) {
  return AppBusyMessageController();
});
