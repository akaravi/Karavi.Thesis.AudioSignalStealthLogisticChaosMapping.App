import 'dart:io';

import 'package:path/path.dart' as p;

/// Reads [appsettings.json] next to the executable, bundle, or working directory.
Future<String?> tryLoadDeployAppSettingsJson() async {
  final exeDir = p.dirname(Platform.resolvedExecutable);
  final cwd = Directory.current.path;

  final candidates = <String>[
    p.join(exeDir, 'appsettings.json'),
    p.join(cwd, 'appsettings.json'),
    p.join(exeDir, 'data', 'flutter_assets', 'assets', 'appsettings.json'),
    // Windows release/debug
    p.join(exeDir, '..', 'appsettings.json'),
    // Linux desktop bundle (appsettings copied beside binary)
    p.join(exeDir, '..', '..', 'appsettings.json'),
  ];

  final seen = <String>{};
  for (final path in candidates) {
    final normalized = p.normalize(path);
    if (!seen.add(normalized)) continue;
    final file = File(normalized);
    if (await file.exists()) {
      return file.readAsString();
    }
  }
  return null;
}
