# Change History

## 2026-05-30 17:57 (UTC+3:30) — Rename package name to `ca.karavi.audiowmark.app`

Changed the application package id from `ir.ntk.audiowmark.app` to `ca.karavi.audiowmark.app`.

Files changed:
- `src/audio_stegano_app/android/app/build.gradle.kts` — `namespace` and `applicationId`.
- `src/audio_stegano_app/android/app/src/main/kotlin/ca/karavi/audiowmark/app/MainActivity.kt` — package declaration + method/event channel names; file moved from old `ir/ntk/audiowmark/app` directory (old directory removed).
- `src/audio_stegano_app/windows/runner/windows_open_file_channel.cpp` — event channel name.
- `src/audio_stegano_app/lib/core/platform/windows_open_file_intent_io.dart` — event channel name.
- `src/audio_stegano_app/lib/core/platform/android_open_file_intent_io.dart` — method/event channel names.
- `README.md` — Android ID label.

Verification: repo-wide search shows no remaining `ir.ntk.audiowmark` references in source.

## 2026-05-30 18:15 (UTC+3:30) — Android home-screen quick-actions widget

Added a home-screen widget «دسترسی سریع» with two shortcuts: **ضبط** (record) and **نهان‌نگاری** (embed).

Native:
- `QuickActionsWidgetProvider.kt` — AppWidget with PendingIntent actions.
- Widget layout/resources under `android/app/src/main/res/` (layout, drawables, strings, light/dark colors).
- `MainActivity.kt` — widget MethodChannel/EventChannel bridge.
- `AndroidManifest.xml` — receiver registration; ProGuard keep rule.

Flutter:
- `android_widget_intent_*` platform bridge + `pendingWidgetActionProvider`.
- `home_shell.dart` routes widget taps to embed tab.
- `embed_screen.dart` handles record (auto-start if message exists) or file picker for embed.
- `app_strings.dart` — `widgetRecordHint` / `widgetEmbedHint` (fa/en/ar/fr).

Verification: `flutter analyze` clean; `flutter build apk --debug` succeeded.
