import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

import 'android_widget_action.dart';

const _methodChannel = MethodChannel('ir.ntk.audiowmark.app/widget');
const _eventChannel = EventChannel('ir.ntk.audiowmark.app/widget_events');

/// Android home-screen widget quick actions (record / embed).
abstract final class AndroidWidgetIntent {
  static bool get isSupported => Platform.isAndroid;

  static Future<AndroidWidgetQuickAction?> consumeInitial() async {
    if (!isSupported) return null;
    final raw = await _methodChannel.invokeMethod<String?>(
      'getInitialWidgetAction',
    );
    return _parseAction(raw);
  }

  static Stream<AndroidWidgetQuickAction> watchActions() {
    if (!isSupported) return const Stream.empty();
    return _eventChannel
        .receiveBroadcastStream()
        .map((event) => _parseAction(event?.toString()))
        .where((action) => action != null)
        .cast<AndroidWidgetQuickAction>();
  }

  static AndroidWidgetQuickAction? _parseAction(String? raw) {
    return switch (raw) {
      'record' => AndroidWidgetQuickAction.record,
      'embed' => AndroidWidgetQuickAction.embed,
      _ => null,
    };
  }
}
