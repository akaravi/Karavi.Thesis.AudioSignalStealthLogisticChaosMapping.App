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

## Part 3 — Fix widget «Can't load widget»

```json
{
  "promptSpecVersion": "1.1.0",
  "kind": "json-prompt",
  "part": 3,
  "title": "Fix RemoteViews-incompatible widget layout",
  "issue": "Android home screen showed Cannot load widget",
  "rootCause": "RemoteViews does not support plain View, ripple backgrounds, 0dp+weight sizing, or some vector drawables",
  "fixes": [
    "Divider View replaced with TextView",
    "Ripple backgrounds replaced with shape drawables",
    "Fixed action row height; removed nested 0dp weight",
    "Icons changed to shape drawables",
    "Removed previewLayout from appwidget-provider",
    "Added fallback layout and provider try/catch"
  ],
  "status": "done"
}
```

## Result 3

```json
{
  "part": 3,
  "status": "done",
  "verification": "flutter build apk --debug exit 0 after widget layout fixes."
}
```

## Part 4 — update ver

```json
{
  "promptSpecVersion": "1.1.0",
  "kind": "json-prompt",
  "part": 4,
  "title": "update ver",
  "command": ".\\_update-ver.ps1",
  "from": "1.2.4",
  "to": "1.2.5",
  "bump": "patch +1",
  "files": [
    "src/audio_stegano_app/pubspec.yaml",
    "src/audio_stegano_desktop/src/AudioStegano.Desktop/AudioStegano.Desktop.csproj"
  ]
}
```

## Result 4

```json
{
  "part": 4,
  "status": "done",
  "verification": "pubspec.yaml and AudioStegano.Desktop.csproj both at 1.2.5; script exit 0."
}
```

## Part 5 — Widget direct text + record capture

```json
{
  "promptSpecVersion": "1.1.0",
  "kind": "json-prompt",
  "part": 5,
  "title": "Widget must capture text and record audio directly",
  "solution": "WidgetCaptureActivity opens WidgetCaptureScreen immediately (skip splash); user enters text and records in compact UI; auto-embed on stop",
  "status": "done"
}
```

## Result 5

```json
{
  "part": 5,
  "status": "done",
  "verification": "flutter build apk --debug exit 0; WidgetCaptureActivity registered in manifest."
}
```
