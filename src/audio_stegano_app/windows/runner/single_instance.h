#ifndef RUNNER_SINGLE_INSTANCE_H_
#define RUNNER_SINGLE_INSTANCE_H_

#include <functional>
#include <optional>
#include <string>
#include <vector>

#include <windows.h>

namespace single_instance {

// Posted to the main HWND when a secondary instance forwards a file path.
inline constexpr UINT kOpenAudioFileMessage = WM_APP + 100;

// Returns false when another instance is already running.
bool TryBecomePrimary();

void SendPathToPrimary(const std::string& path);

std::optional<std::string> FindAudioPathInArgs(
    const std::vector<std::string>& args);

void SetMainWindow(HWND hwnd);
void ActivateMainWindow();

void EnsurePipeServerRunning();
void AttachPathHandler(std::function<void(const std::string& path)> on_path);
void StopServer();

}  // namespace single_instance

#endif  // RUNNER_SINGLE_INSTANCE_H_
