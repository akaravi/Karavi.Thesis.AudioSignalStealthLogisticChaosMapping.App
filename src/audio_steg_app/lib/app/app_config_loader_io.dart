import 'dart:io';

import 'package:path/path.dart' as p;

/// Reads [appsettings.json] next to the executable or current working directory.
Future<String?> tryLoadDeployAppSettingsJson() async {
  final candidates = <String>[
    p.join(p.dirname(Platform.resolvedExecutable), 'appsettings.json'),
    p.join(Directory.current.path, 'appsettings.json'),
  ];

  for (final path in candidates) {
    final file = File(path);
    if (await file.exists()) {
      return file.readAsString();
    }
  }
  return null;
}
