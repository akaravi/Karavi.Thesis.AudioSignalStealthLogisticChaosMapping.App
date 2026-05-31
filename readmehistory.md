# Change History

## 2026-05-31 (UTC+3:30) — Version bump 1.2.5 → 1.2.6

Ran `.\_update-ver.ps1` (patch +1). Synced:
- `src/audio_stegano_app/pubspec.yaml` — `version: 1.2.6`
- `src/audio_stegano_desktop/src/AudioStegano.Desktop/AudioStegano.Desktop.csproj` — `Version`, `AssemblyVersion`, `FileVersion`, `InformationalVersion` → 1.2.6

## 2026-05-31 09:53 (UTC+3:30) — Fix Android app stuck on bootstrap loading spinner

Root cause: on a normal launcher start the app runs `MainActivity`, which only registers the `ir.ntk.audiowmark.app/open_file` channel. The widget-capture channel `ir.ntk.audiowmark.app/widget_capture` is registered only in `WidgetCaptureActivity`. App bootstrap always calls `AndroidWidgetCaptureLaunchBridge.consumeInitial()`, which invoked `getWidgetCaptureLaunch` on that channel without error handling. On launcher start this throws `MissingPluginException`, so `_hydrate()` aborted before setting `_hydrated = true` and the app hung forever on the `CircularProgressIndicator`. Not a CDN/internet issue (Android manifest has no `INTERNET` permission).

Also verified no CDN/network runtime assets exist: no `google_fonts`/CDN deps in `pubspec.yaml`, no `Image.network`/`NetworkImage`/`GoogleFonts`/CDN hosts in `lib`, `web/index.html` loads only local `flutter_bootstrap.js`.

Files changed:
- `src/audio_stegano_app/lib/core/platform/android_widget_capture_launch_io.dart` — wrap `invokeMethod('getWidgetCaptureLaunch')` in try/catch for `MissingPluginException` and `PlatformException`, returning null (treated as "no widget launch").
- `src/audio_stegano_app/lib/app/app_bootstrap.dart` — `_hydrate()` now try/catch around channel + settings hydration, logs via `SessionLog`, and always sets `_hydrated = true` in `finally`-style so the spinner never blocks startup; added `session_log.dart` import.

Verification: `flutter analyze` on both files → No issues found.

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

## 2026-05-30 — Revert package name to `ir.ntk.audiowmark.app`

Changed application package id from `ca.karavi.audiowmark.app` back to `ir.ntk.audiowmark.app`.

Updated: `build.gradle.kts`, Kotlin sources moved to `kotlin/ir/ntk/audiowmark/app/` (MainActivity, QuickActionsWidgetProvider, WidgetCaptureActivity), Dart/Windows MethodChannel names, ProGuard rules, README.

Verification: grep confirms zero remaining `ca.karavi.audiowmark` in source.

## 2026-05-30 — Flutter web: bundle CanvasKit locally (`--no-web-resources-cdn`)

Fixed web startup failures when `www.gstatic.com` is blocked (`ERR_CONNECTION_CLOSED` on canvaskit.js/wasm). Build/run scripts now pass `--no-web-resources-cdn`; `web/index.html` comment updated.

## 2026-05-30 — Enforce no-CDN law for Flutter web (`_flutter-web-no-cdn.ps1`)

Central module `_flutter-web-no-cdn.ps1`: build/run args always include `--no-web-resources-cdn`; post-build repair strips CDN literals from deploy output; strict scan fails if any CDN host remains. Wired into `_build-flutter-web.ps1`, `_build-all-projects.ps1`, `_run-all-local.ps1`. Updated `.cursor/rules/no-external-cdn-assets.mdc` and README.

## 2026-05-30 — Zero CDN: patch Flutter web deploy output

`Repair-KaraviFlutterWebOutputRemoveExternalCdnLiterals` removes gstatic CanvasKit/font URLs from `flutter.js`, `flutter_bootstrap.js`, `main.dart.js`; `Assert-KaraviFlutterWebOutputNoExternalCdn` now fails on any CDN host in deploy files. `web/index.html` comment no longer mentions gstatic.



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

