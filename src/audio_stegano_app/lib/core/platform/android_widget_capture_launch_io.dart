import 'dart:io';

import 'package:flutter/services.dart';

import 'android_widget_action.dart';
import 'widget_capture_launch.dart';

const _channel = MethodChannel('ca.karavi.audiowmark.app/widget_capture');

abstract final class AndroidWidgetCaptureLaunchBridge {
  static bool get isSupported => Platform.isAndroid;

  static Future<WidgetCaptureLaunch?> consumeInitial() async {
    if (!isSupported) return null;
    final raw = await _channel.invokeMethod<Map<dynamic, dynamic>?>(
      'getWidgetCaptureLaunch',
    );
    if (raw == null || raw['active'] != true) return null;
    final action = _parseAction(raw['action']?.toString());
    if (action == null) return null;
    return WidgetCaptureLaunch(action: action);
  }

  static AndroidWidgetQuickAction? _parseAction(String? raw) {
    return switch (raw) {
      'record' => AndroidWidgetQuickAction.record,
      'embed' => AndroidWidgetQuickAction.embed,
      _ => null,
    };
  }
}
