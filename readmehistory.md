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

## 2026-05-30 18:50 (UTC+3:30) — Fix Android widget «Can't load widget»

Root cause: `RemoteViews` cannot inflate plain `<View>`, ripple backgrounds, nested `layout_weight` with `0dp` height, or vector icons on some launchers.

Fixes:
- Replaced divider `<View>` with 1dp `TextView`.
- Replaced ripple button backgrounds with simple `shape` drawables.
- Fixed action row height to `72dp` (no `0dp` + weight chain on root).
- Replaced vector icons with shape drawables.
- Removed `previewLayout` / `targetCell*` from widget provider XML.
- Added `widget_quick_actions_fallback.xml` + try/catch in `QuickActionsWidgetProvider`.

Verification: `flutter build apk --debug` succeeded.

## 2026-05-30 — Widget direct text + record capture (`WidgetCaptureActivity`)

Widget taps now open a dedicated capture sheet (not the main app tabs):
- `WidgetCaptureActivity` + `WidgetCaptureScreen` — text field, record/stop, auto-embed on stop; embed mode picks file.
- Skips splash/onboarding when launched from widget.
- Widget provider targets `WidgetCaptureActivity` instead of `MainActivity`.

Verification: `flutter analyze` + `flutter build apk --debug` OK.


## 2026-05-30 — Version bump `1.2.4` → `1.2.5`

Ran `.\_update-ver.ps1` (patch +1). Synced:
- `src/audio_stegano_app/pubspec.yaml` → `1.2.5`
- `src/audio_stegano_desktop/src/AudioStegano.Desktop/AudioStegano.Desktop.csproj` → `Version`, `AssemblyVersion`, `FileVersion`, `InformationalVersion`

