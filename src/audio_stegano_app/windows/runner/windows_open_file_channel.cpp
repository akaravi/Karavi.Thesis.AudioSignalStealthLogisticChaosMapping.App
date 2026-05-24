#include "windows_open_file_channel.h"

#include <flutter/event_channel.h>
#include <flutter/event_sink.h>
#include <flutter/flutter_engine.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <mutex>
#include <string>
#include <utility>

namespace {

class WindowsOpenFileStreamHandler
    : public flutter::StreamHandler<flutter::EncodableValue> {
 public:
  static std::shared_ptr<WindowsOpenFileStreamHandler> GetInstance() {
    static auto instance = std::make_shared<WindowsOpenFileStreamHandler>();
    return instance;
  }

  void EmitPath(const std::string& path) {
    std::lock_guard<std::mutex> lock(mutex_);
    if (sink_) {
      sink_->Success(flutter::EncodableValue(path));
    }
  }

 protected:
  std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>> OnListen(
      const flutter::EncodableValue* arguments,
      std::unique_ptr<flutter::EventSink<flutter::EncodableValue>>&& events)
      override {
    std::lock_guard<std::mutex> lock(mutex_);
    sink_ = std::move(events);
    return nullptr;
  }

  std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>> OnCancel(
      const flutter::EncodableValue* arguments) override {
    std::lock_guard<std::mutex> lock(mutex_);
    sink_.reset();
    return nullptr;
  }

 private:
  std::mutex mutex_;
  std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> sink_;
};

}  // namespace

void RegisterWindowsOpenFileChannel(flutter::FlutterEngine* engine) {
  auto messenger = engine->messenger();
  auto channel =
      std::make_unique<flutter::EventChannel<flutter::EncodableValue>>(
          messenger, "ir.ntk.audiowmark.app/windows_open_file_events",
          &flutter::StandardMethodCodec::GetInstance());

  auto handler = WindowsOpenFileStreamHandler::GetInstance();
  channel->SetStreamHandler(handler);
  // Keep channel alive for app lifetime.
  static auto channel_storage = std::move(channel);
}

void EmitWindowsOpenFilePath(const std::string& path) {
  WindowsOpenFileStreamHandler::GetInstance()->EmitPath(path);
}
