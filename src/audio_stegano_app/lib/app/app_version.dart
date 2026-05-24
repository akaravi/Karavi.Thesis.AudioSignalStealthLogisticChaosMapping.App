import 'package:package_info_plus/package_info_plus.dart';

/// Runtime app version from [pubspec.yaml] (`version: MAJOR.MINOR.PATCH`).
abstract final class AppVersion {
  static PackageInfo? _info;

  static bool get isLoaded => _info != null;

  static Future<void> load() async {
    _info = await PackageInfo.fromPlatform();
  }

  static String get display {
    final info = _info;
    if (info == null) return '—';
    return info.version;
  }
}
