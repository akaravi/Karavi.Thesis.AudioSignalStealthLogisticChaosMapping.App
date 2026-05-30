# Cursor Plan — Audio Stealth Logistic Chaos Mapping App

## Part 1 — Rename Android/native package id

```json
{
  "promptSpecVersion": "1.1.0",
  "kind": "json-prompt",
  "part": 1,
  "title": "Rename package name to ca.karavi.audiowmark.app",
  "request": "Change package name to ca.karavi.audiowmark.app",
  "from": "ir.ntk.audiowmark.app",
  "to": "ca.karavi.audiowmark.app",
  "touchedFiles": [
    "src/audio_stegano_app/android/app/build.gradle.kts",
    "src/audio_stegano_app/android/app/src/main/kotlin/ca/karavi/audiowmark/app/MainActivity.kt",
    "src/audio_stegano_app/windows/runner/windows_open_file_channel.cpp",
    "src/audio_stegano_app/lib/core/platform/windows_open_file_intent_io.dart",
    "src/audio_stegano_app/lib/core/platform/android_open_file_intent_io.dart",
    "README.md"
  ],
  "notes": [
    "Android namespace and applicationId updated.",
    "MainActivity.kt moved from kotlin/ir/ntk/audiowmark/app to kotlin/ca/karavi/audiowmark/app.",
    "Native <-> Dart MethodChannel/EventChannel names kept in sync across Android and Windows.",
    "No iOS/macOS folders present in this project."
  ]
}
```

## Result 1

```json
{
  "part": 1,
  "status": "done",
  "verification": "Grep across repo confirms zero remaining ir.ntk.audiowmark references in source; old kotlin/ir directory removed; new MainActivity.kt read-back is clean UTF-8.",
  "remaining": "Build verification (flutter build) optional next step."
}
```

## Part 2 — Android home-screen quick-actions widget

```json
{
  "promptSpecVersion": "1.1.0",
  "kind": "json-prompt",
  "part": 2,
  "title": "Android widget for quick record and embed access",
  "request": "Design Android home-screen widget for fast record and steganography (embed) shortcuts",
  "features": [
    "AppWidgetProvider with two action buttons: ضبط (record) and نهان‌نگاری (embed)",
    "RTL-friendly layout with light/dark widget color tokens (values + values-night)",
    "MainActivity widget intent bridge via MethodChannel/EventChannel",
    "Flutter pendingWidgetActionProvider consumed by EmbedScreen",
    "Auto-start record or file picker when message text already exists"
  ],
  "touchedFiles": [
    "src/audio_stegano_app/android/app/src/main/kotlin/ca/karavi/audiowmark/app/QuickActionsWidgetProvider.kt",
    "src/audio_stegano_app/android/app/src/main/kotlin/ca/karavi/audiowmark/app/MainActivity.kt",
    "src/audio_stegano_app/android/app/src/main/AndroidManifest.xml",
    "src/audio_stegano_app/android/app/src/main/res/layout/widget_quick_actions.xml",
    "src/audio_stegano_app/android/app/src/main/res/xml/widget_quick_actions_info.xml",
    "src/audio_stegano_app/android/app/src/main/res/values/strings.xml",
    "src/audio_stegano_app/android/app/src/main/res/values/colors.xml",
    "src/audio_stegano_app/android/app/src/main/res/values-night/colors.xml",
    "src/audio_stegano_app/lib/core/platform/android_widget_action.dart",
    "src/audio_stegano_app/lib/core/platform/android_widget_intent.dart",
    "src/audio_stegano_app/lib/core/platform/android_widget_intent_io.dart",
    "src/audio_stegano_app/lib/core/platform/android_widget_intent_stub.dart",
    "src/audio_stegano_app/lib/app/pending_widget_action_provider.dart",
    "src/audio_stegano_app/lib/app/home_shell.dart",
    "src/audio_stegano_app/lib/features/embed/embed_screen.dart",
    "src/audio_stegano_app/lib/app/app_strings.dart",
    "src/audio_stegano_app/android/app/proguard-rules.pro"
  ]
}
```

## Result 2

```json
{
  "part": 2,
  "status": "done",
  "verification": "flutter analyze on changed Dart files: no issues; flutter build apk --debug exit 0.",
  "usage": "Long-press home screen → Widgets → صوت‌نهان → دسترسی سریع; tap ضبط or نهان‌نگاری."
}
```
