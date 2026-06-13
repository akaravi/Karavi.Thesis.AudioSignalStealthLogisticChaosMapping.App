# Change History

## 2026-06-02 — Run all (local dev)

- Build/test: dotnet build OK, dotnet test 14, flutter test 49, flutter analyze clean.
- `flutter pub get` online 403 → used `dart pub get --offline`.
- Fixed `lsb_codec_test.dart` for mandatory autoencoder.
- Services: WPF pid 38076, Flutter Web HTTP 200 at 5320, Flutter Windows exe on 5323.
- Added `_launch-dev-services.ps1`, `_health-check-dev.ps1`, `_restart-wpf.ps1`, `_restart-flutter-windows.ps1`.
- `LastRunInfo.html` updated at repo root.

## 2026-06-02 — Autoencoder-only stego (removed xor_only path)

Per user requirement: every embed/extract **must** pass through `trained_autoencoder.mat`.

- Removed `StegoEmbedMode` / `xor_only` branch (Flutter + WPF); deleted `stego_embed_mode.dart` and `StegoEmbedMode.cs`.
- `StegoMessageContext` always requires `MessageBlockAutoencoder`; pipeline: bits → `round(net(mapminmax))` → XOR → chaotic LSB.
- `StegoRunner` always loads bundled autoencoder JSON; removed `DefaultStegoEmbedMode` from all `appsettings.json`.
- Removed settings UI toggle for embed mode; `settings.stegoEmbedMode` dropped from Flutter settings.
- Tests updated: Flutter 8 + WPF 14 passed.

## 2026-06-02 — Stego audit: mapminmax + settings UI for ae_xor

Verified full pipeline against `train/embed_message.m` / `extract_message.m`:

- **Default runtime mode is `xor_only`** (`appsettings.json` → `DefaultStegoEmbedMode`) — autoencoder is **not** invoked unless mode is `ae_xor` (same default as MATLAB script).
- **`MessageBlockAutoencoder`**: added input/output `mapminmax` (bits [0,1] ↔ [-1,1]) so `round(net(...))` matches MATLAB `net()` preprocessing; `decodeBits` uses the same forward path as `encodeRounded`.
- **Flutter settings**: new segmented control **XOR only / Autoencoder + XOR** (`settings.stegoEmbedMode`); embed/extract screens already pass this to `StegoRunner`.
- Tests: Flutter `ae_xor` round-trip asserts exact text; WPF `AeXor_LoadsEmbeddedWeights_And_Embeds` asserts `"Test"`.

## 2026-06-01 — Rename stego files to embed_message / extract_message (MATLAB parity)

Flutter (`lib/core/stego/`): `embed_message.dart` (`EmbedMessage`), `extract_message.dart` (`ExtractMessage`), plus `stego_common.dart`, `logistic_map_keygen.dart`, `logistic_positions.dart`, `evaluate_stego.dart`. WPF: `EmbedMessage.cs`, `ExtractMessage.cs`, `StegoMessageContext.cs`. `AudioWatermarking` remains a thin compatibility wrapper.

## 2026-06-01 — Trained autoencoder assets + ae_xor embed mode

Bundled thesis `train/trained_autoencoder.mat` (~146 KB) and exported runtime weights `trained_autoencoder.json` (8-10-8 `tansig`, IW/LW/b from MATLAB `net` cells). Flutter assets: `assets/stego/`; WPF: embedded JSON + optional `.mat` copy beside Core.

- `MessageBlockAutoencoder` / `StegoEmbedMode` (`xor_only` | `ae_xor`) in Flutter + `AudioStegano.Core`.
- `DefaultStegoEmbedMode` in `appsettings.json` (default `xor_only`, same as MATLAB `embed_message.m`).
- `scripts/export_trained_autoencoder.py` regenerates JSON after retraining.
- Embed/extract/`StegoRunner` pass `settings.stegoEmbedMode`.

Note: `ae_xor` uses the trained net before LSB; bit-exact text recovery may differ from MATLAB until input/output `mapminmax` from `configure(net,X,X)` is ported — use `xor_only` for production round-trip.

## 2026-06-01 — Stego: chaotic LSB positions (train/embed_message.m)

Aligned Flutter (`audio_watermarking.dart`) and WPF (`AudioWatermarking.cs`) with thesis `train/embed_message.m` / `train/extract_message.m` / `train/logistic_positions.m`:

- Message bits → XOR with `logistic_map_keygen` key → LSB at **chaotic sample indices** (not sequential `0..n-1`).
- New `LogisticPositions` / `LogisticPositions.compute` (port of `logistic_positions.m`: unique + fill + sort).
- Unit tests: round-trip Persian/English, metrics, wrong-key; new test that positions differ from sequential prefix.

**Compatibility:** stego WAV files produced by the **previous sequential LSB** build cannot be extracted with this version; re-embed with the same `r`, `x0`, and `msg_bit_length`.

## 2026-06-01 16:49 (UTC+3:30) — Android release build 1.2.6 (Cafe Bazaar, official key)

`.\_build-cafebazaar-release.ps1` exit 0. Signed with `E:\BANK Android Key publish\key.jks`. Output: `publish\cafebazaar_20260601_164348\` — `AudioStegano_1.2.6.bin` (upload), `AudioStegano_1.2.6.aab`, `AudioStegano_1.2.6_arm64-v8a.apk`, `mapping_1.2.6.txt`.

## 2026-05-31 (UTC+3:30) — Android release signing project law (E:\BANK publish key)

Added mandatory rule `.cursor/rules/android-release-signing.mdc`: all release APK/AAB/Cafe Bazaar builds must sign with `E:\BANK Android Key publish\key.jks`; passwords from `key_password.txt` (line 1 = store, line 2 = key). Implemented `_android-release-signing.ps1` (`Sync-KaraviAndroidKeyProperties`, `Assert-KaraviAndroidReleaseSigningConfigured`). Wired into `_build-flutter-android.ps1` and `_build-cafebazaar-release.ps1`. Updated `key.properties.example` and README.

## 2026-05-31 (UTC+3:30) — Flutter web: fix invisible text (offline CanvasKit fonts)

Root cause: `_flutter-web-no-cdn.ps1` rewrites `fonts.gstatic.com/s/` → `assets/fonts/` for zero-CDN deploy, but no font files were placed there. CanvasKit could not load Roboto/Noto fallbacks, so **all UI text rendered blank** (icons/layout still visible).

Fix:
- Bundled `Roboto` (Regular/Medium/Bold) + `Noto Sans Arabic` TTF under `src/audio_stegano_app/assets/fonts/` and registered in `pubspec.yaml`.
- `AppTheme`: `fontFamily: Roboto`, `fontFamilyFallback: ['Noto Sans Arabic']`.
- Offline CanvasKit woff2 fallbacks committed under `src/audio_stegano_app/web/fonts/` (roboto, notosansarabic, notosansoldpersian).
- `_flutter-web-no-cdn.ps1`: new `Copy-KaraviFlutterWebBundledNotoFonts` copies `web/fonts/**` → `build/web/assets/fonts/**` after CDN literal repair.

Verification: `flutter build web --release --no-web-resources-cdn` + post-process exit 0; HTTP 200 for bundled font URLs on local server.

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

## 2026-06-13 — WordPress post folder (Part 73)

- Created `wordpress/` with SEO post for **صوت‌نهان** (xwave.ir / Myket).
- `post-content.html` — headings, short sentences, internal/external links, image alt/title.
- `seo-meta.json` — focus keyword, meta description, OG, 10 suggested tags.
- `schema-software-application.jsonld` — Schema.org SoftwareApplication.
- `images/*.webp` — WebP from Cafe Bazaar 16:9 screenshots + Myket/XWave banners + app icon.
- `scripts/convert-screenshots-to-webp.py` — regenerate WebP assets.

## 2026-06-13 — WordPress post expanded (Part 73b)

- `post-content.html` — 1800+ words; tutorial section `#tutorial` at end (7 steps + practice).
- New WebP: `guide-quick-start.webp`, `language-selection.webp`, `embed-message-length-dialog.webp`.
- `seo-meta.json` — reading time 12 min, meta description updated.

## 2026-06-13 — WordPress banners English-only (Part 73c)

- Regenerated `banner-myket-download.webp` and `banner-xwave-site.webp` with **English-only** raster text (no Persian in PIL-generated images).
- Added `wordpress/scripts/build-link-banners.py`; documented rule in `wordpress/README.md`.

## 2026-06-13 — WordPress fa/en locale folders (Part 74)

- Moved Persian content to `wordpress/fa/` (post, seo-meta, schema, images, README).
- Created `wordpress/en/` with full English post (1500+ words), SEO, schema, images, README.
- Root `wordpress/README.md` indexes both locales; scripts output to `fa/images` and `en/images`.
- Cross-links between fa and en posts in seo-meta and post footers.

## 2026-06-13 — Gemini Create Video JSON prompt (Part 75)

- `wordpress/gemini-create-video-promo.json` — 9-scene Veo 3.1 promo (~54s), image-to-video from fa/images, Persian voiceover with full diacritics.
- `wordpress/GEMINI-VIDEO-README.md` — usage guide for Gemini Create Video.

## 2026-06-13 — Move wordpress to SocialMediaContent (Part 76)

- `wordpress/` → `SocialMediaContent/wordpress/` (fa, en, scripts, images, Gemini JSON).
- Added `SocialMediaContent/README.md`; updated all path references and Python scripts (`WP_ROOT`, `REPO_ROOT`).

## 2026-06-13 — Move Gemini to SocialMediaContent/gemini (Part 77)

- `gemini-create-video-promo.json` + guide → `SocialMediaContent/gemini/` (`README.md`).
- Removed Gemini section from `SocialMediaContent/wordpress/README.md`; cross-link to `../gemini/`.

## 2026-06-13 — Gemini fa/en split (Part 78)

- `SocialMediaContent/gemini/fa/` — Persian prompt (`voiceoverDiacritics`, full tashkil), images from `wordpress/fa/images/`.
- `SocialMediaContent/gemini/en/` — fully English prompt (`voiceover`, `onScreenText`), images from `wordpress/en/images/`.
- Per-locale `README.md`; root `gemini/README.md` indexes both; deleted root `gemini-create-video-promo.json`.

