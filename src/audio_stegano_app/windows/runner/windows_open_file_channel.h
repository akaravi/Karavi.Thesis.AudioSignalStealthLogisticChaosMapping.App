#ifndef RUNNER_WINDOWS_OPEN_FILE_CHANNEL_H_
#define RUNNER_WINDOWS_OPEN_FILE_CHANNEL_H_

#include <string>

namespace flutter {
class FlutterEngine;
}

void RegisterWindowsOpenFileChannel(flutter::FlutterEngine* engine);

void EmitWindowsOpenFilePath(const std::string& path);

#endif  // RUNNER_WINDOWS_OPEN_FILE_CHANNEL_H_
