#include "windows_open_file_channel.h"

#include <flutter/event_channel.h>
#include <flutter/event_sink.h>
#include <flutter/event_stream_handler.h>
#include <flutter/flutter_engine.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <mutex>
#include <string>
#include <utility>

namespace {

class WindowsOpenFileStreamHandler;

WindowsOpenFileStreamHandler* g_stream_handler = nullptr;

class WindowsOpenFileStreamHandler
    : public flutter::StreamHandler<flutter::EncodableValue> {
 public:
  void EmitPath(const std::string& path) {
    std::lock_guard<std::mutex> lock(mutex_);
    if (sink_) {
      sink_->Success(flutter::EncodableValue(path));
    }
  }

 protected:
  std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>>
  OnListenInternal(
      const flutter::EncodableValue* arguments,
      std::unique_ptr<flutter::EventSink<flutter::EncodableValue>>&& events)
      override {
    std::lock_guard<std::mutex> lock(mutex_);
    sink_ = std::move(events);
    return nullptr;
  }

  std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>>
  OnCancelInternal(const flutter::EncodableValue* arguments) override {
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
  static auto channel =
      std::make_unique<flutter::EventChannel<flutter::EncodableValue>>(
          messenger, "ca.karavi.audiowmark.app/windows_open_file_events",
          &flutter::StandardMethodCodec::GetInstance());

  static bool registered = false;
  if (!registered) {
    auto handler = std::make_unique<WindowsOpenFileStreamHandler>();
    g_stream_handler = handler.get();
    channel->SetStreamHandler(
        std::unique_ptr<flutter::StreamHandler<flutter::EncodableValue>>(
            handler.release()));
    registered = true;
  }
}

void EmitWindowsOpenFilePath(const std::string& path) {
  if (g_stream_handler != nullptr) {
    g_stream_handler->EmitPath(path);
  }
}
