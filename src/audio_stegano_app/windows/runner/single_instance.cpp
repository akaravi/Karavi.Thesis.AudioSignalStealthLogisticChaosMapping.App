#include "single_instance.h"

#include <algorithm>
#include <atomic>
#include <cctype>
#include <mutex>
#include <thread>
#include <vector>

namespace {

constexpr const char* kPipeName =
    "\\\\.\\pipe\\Karavi.AudioStegano.Flutter.OpenFile.v1";

HWND g_main_window = nullptr;
std::function<void(const std::string& path)> g_on_path;
std::thread g_server_thread;
std::atomic<bool> g_stop_server{false};
std::mutex g_pending_mutex;
std::vector<std::string> g_pending_paths;

void DispatchPath(const std::string& path) {
  if (g_main_window != nullptr) {
    auto* copy = new std::string(path);
    if (::PostMessage(g_main_window, single_instance::kOpenAudioFileMessage, 0,
                      reinterpret_cast<LPARAM>(copy))) {
      return;
    }
    delete copy;
  }

  std::function<void(const std::string& path)> handler;
  {
    std::lock_guard<std::mutex> lock(g_pending_mutex);
    if (g_on_path) {
      handler = g_on_path;
    } else {
      g_pending_paths.push_back(path);
      return;
    }
  }
  if (handler) {
    handler(path);
  }
}

std::string TrimQuotes(std::string value) {
  while (!value.empty() && value.front() == '"') {
    value.erase(value.begin());
  }
  while (!value.empty() && value.back() == '"') {
    value.pop_back();
  }
  return value;
}

std::string ToLower(std::string value) {
  std::transform(value.begin(), value.end(), value.begin(),
                 [](unsigned char c) { return static_cast<char>(std::tolower(c)); });
  return value;
}

bool EndsWithIgnoreCase(const std::string& value, const std::string& suffix) {
  if (value.size() < suffix.size()) {
    return false;
  }
  return ToLower(value.substr(value.size() - suffix.size())) == ToLower(suffix);
}

bool IsSupportedAudioPath(const std::string& path) {
  return EndsWithIgnoreCase(path, ".wav") ||
         EndsWithIgnoreCase(path, ".mp3") ||
         EndsWithIgnoreCase(path, ".mp4");
}

void ServerLoop() {
  while (!g_stop_server.load()) {
    HANDLE pipe = ::CreateNamedPipeA(
        kPipeName, PIPE_ACCESS_INBOUND,
        PIPE_TYPE_BYTE | PIPE_READMODE_BYTE | PIPE_WAIT, 1, 4096, 4096, 0,
        nullptr);
    if (pipe == INVALID_HANDLE_VALUE) {
      ::Sleep(200);
      continue;
    }

    const BOOL connected = ::ConnectNamedPipe(pipe, nullptr)
                               ? TRUE
                               : (::GetLastError() == ERROR_PIPE_CONNECTED);
    if (connected) {
      char buffer[4096];
      DWORD bytes_read = 0;
      if (::ReadFile(pipe, buffer, sizeof(buffer) - 1, &bytes_read, nullptr) &&
          bytes_read > 0) {
        buffer[bytes_read] = '\0';
        std::string path(buffer);
        while (!path.empty() &&
               (path.back() == '\n' || path.back() == '\r')) {
          path.pop_back();
        }
        if (!path.empty()) {
          DispatchPath(path);
        }
      }
    }

    ::DisconnectNamedPipe(pipe);
    ::CloseHandle(pipe);
  }
}

void WakeServerThread() {
  HANDLE client =
      ::CreateFileA(kPipeName, GENERIC_WRITE, 0, nullptr, OPEN_EXISTING, 0,
                    nullptr);
  if (client != INVALID_HANDLE_VALUE) {
  ::CloseHandle(client);
  }
}

}  // namespace

namespace single_instance {

bool TryBecomePrimary() {
  HANDLE client =
      ::CreateFileA(kPipeName, GENERIC_WRITE, 0, nullptr, OPEN_EXISTING, 0,
                    nullptr);
  if (client != INVALID_HANDLE_VALUE) {
    ::CloseHandle(client);
    return false;
  }
  return true;
}

void SendPathToPrimary(const std::string& path) {
  if (path.empty()) {
    return;
  }
  HANDLE client =
      ::CreateFileA(kPipeName, GENERIC_WRITE, 0, nullptr, OPEN_EXISTING, 0,
                    nullptr);
  if (client == INVALID_HANDLE_VALUE) {
    return;
  }
  std::string payload = path;
  payload.push_back('\n');
  DWORD written = 0;
  ::WriteFile(client, payload.data(), static_cast<DWORD>(payload.size()),
              &written, nullptr);
  ::CloseHandle(client);
}

std::optional<std::string> FindAudioPathInArgs(
    const std::vector<std::string>& args) {
  for (const auto& raw : args) {
    if (raw.empty() || raw.front() == '-') {
      continue;
    }
    const std::string path = TrimQuotes(raw);
    if (!IsSupportedAudioPath(path)) {
      continue;
    }
    if (::GetFileAttributesA(path.c_str()) != INVALID_FILE_ATTRIBUTES) {
      return path;
    }
  }
  return std::nullopt;
}

void SetMainWindow(HWND hwnd) { g_main_window = hwnd; }

void ActivateMainWindow() {
  if (g_main_window == nullptr) {
    return;
  }
  if (::IsIconic(g_main_window)) {
    ::ShowWindow(g_main_window, SW_RESTORE);
  }
  ::SetForegroundWindow(g_main_window);
}

void EnsurePipeServerRunning() {
  if (g_server_thread.joinable()) {
    return;
  }
  g_stop_server.store(false);
  g_server_thread = std::thread(ServerLoop);
}

void AttachPathHandler(std::function<void(const std::string& path)> on_path) {
  std::vector<std::string> pending;
  {
    std::lock_guard<std::mutex> lock(g_pending_mutex);
    g_on_path = std::move(on_path);
    pending.swap(g_pending_paths);
  }
  for (const auto& path : pending) {
    if (g_on_path) {
      g_on_path(path);
    }
  }
}

void StopServer() {
  g_stop_server.store(true);
  WakeServerThread();
  if (g_server_thread.joinable()) {
    g_server_thread.join();
  }
  {
    std::lock_guard<std::mutex> lock(g_pending_mutex);
    g_on_path = nullptr;
    g_pending_paths.clear();
  }
}

}  // namespace single_instance
