import 'android_widget_action.dart';

/// Non-Android / web stub.
abstract final class AndroidWidgetIntent {
  static bool get isSupported => false;

  static Future<AndroidWidgetQuickAction?> consumeInitial() async => null;

  static Stream<AndroidWidgetQuickAction> watchActions() =>
      const Stream.empty();
}
