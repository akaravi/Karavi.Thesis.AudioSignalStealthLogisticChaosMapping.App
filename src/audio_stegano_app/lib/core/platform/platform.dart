import 'package:flutter/foundation.dart';

/// True on Windows desktop (not web).
bool get isNativeWindows =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

/// True on Android or iOS (not web).
bool get isMobilePlatform =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);
