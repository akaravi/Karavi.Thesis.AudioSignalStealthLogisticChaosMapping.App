# Change History

## 2026-07-28 — update ver 1.2.6 → 1.2.7 + Flutter web ZIP

- Version bump patch: Flutter `pubspec.yaml` + WPF csproj → `1.2.7`.
- Flutter web release ZIP for server upload: `publish/flutter/web/KaraviThesis_AudioStegano_FlutterWeb_20260728_144929.zip`.

## 2026-07-28 — ui-ux-pro-max: colors + icons Soft UI / security

- Brand seed `#7A68A8` → security blue `#0369A1` (Soft UI Evolution + security utility palette).
- Icon accents role-collapsed (brand / trust / warn / success / info / neutral / danger) — no rainbow nav.
- Extract nav glyph: search → lock_open (Flutter + WPF MDL2 `E785`).
- Softer Soft UI glows/shadows; light/dark surfaces cool slate-blue; web/PWA/widget theme tokens synced.
- Flutter + WPF parity verified (analyze clean, WPF Debug 0 warn/err).

## 2026-07-28 — Page title in header (Material 3 destination AppBar)

- Flutter: each tab owns `PageAppBar` with destination title (نهان‌نگاری / رمزگشایی / تنظیمات / درباره ما); help/new as AppBar actions.
- HomeShell no longer shows app-wide title in chrome; `MaterialApp.title` / window title stay product name.
- WPF: `TitleText` updates on tab switch to the same destination labels; start-aligned header.
- Shared widget: `lib/features/shared/page_app_bar.dart` (Semantics header + M3 start-aligned title).

## 2026-07-28 — Extract audio result: carrier play + no duplicate label

- Duplicate «صوت استخراج‌شده»: title + body both used same string — body replaced with A/B listen (حامل / استخراج‌شده).
- Carrier (loaded stego) play available on result panel after success (input card is hidden).
- Flutter + WPF parity; i18n fa/en/ar/fr: `extractCarrierShort`, `playCarrierAudio`, `extractListenTitle`.

## 2026-07-27 — Embed/Extract: hide input after success (SSOT)

- Flutter: input visibility derived from result (`_stego != null` / extracted payloads) — no separate mutable hide flag that could desync.
- After success: payload tabs + record/load hidden; New clears result and restores input.
- WPF: `AudioSourceCard` collapsed with `EmbedInputPanel` on success; restored on New.

## 2026-07-27 — Fix stuck Loading (chromium CanvasKit 404)

- Root cause: post-process deleted `canvaskit/chromium/`; Chrome loads that path first → 404 → boot spinner forever.
- Keep chromium kit; assert `canvaskit/chromium/canvaskit.js` + `.wasm` after post-process.
- Rebuild release + static serve `http://127.0.0.1:5320/` verified (UI past splash).

## 2026-07-27 — Fix 140MB web Network (debug vs release)

- Root cause: local `flutter run` **debug** (~1400 `*.dart.lib.js`) — not product size.
- Default local web: serve `build/web` release static (~13 MB; MaterialIcons tree-shaken ~16 KB).
- Helpers: `Start-KaraviFlutterWebStaticReleaseServer`; run/launch scripts updated; rule `flutter-web-release-default.mdc`.

## 2026-07-27 — A/B listen: Pause/Stop inside each Play card

- Rule: `.cursor/rules/ab-listen-play-transport.mdc`.
- Pause/Stop per side (A cover / B stego); hidden until play; hide after complete/stop.
- Flutter embed A/B panel; WPF EmbedView cards; auto-clear player on natural complete.

## 2026-07-27 — Equalizer layout + payload capacity bar

- Rule: `.cursor/rules/equalizer-recording-capacity-ui.mdc` — volume left · timer right; capacity bars.
- Equalizer header: physical LTR `[volume%] · label · [timer]` (Flutter + WPF).
- Payload (secret) record + fixed capacity ON → bottom fill bar + auto-stop at budget.
- Cover min bar: fixed budget when checkbox ON; live payload bits when OFF (unchanged logic, rule documented).

## 2026-07-27 — Optimize site/app payload size

- Subset bundled TTFs (Noto ~825→205 KB; Roboto Regular+Bold ~328→141 KB); drop Medium + zip.
- Compress `app_icon` / web icons; remove obsolete `web/fonts` (pubspec fonts only).
- Web build: `--tree-shake-icons`; post-process strips `.map`/`.symbols` and unused `skwasm`/`wimp` (~31→13 MB `build/web`).
- Script: `src/audio_stegano_app/scripts/optimize_flutter_assets.py`; gitignore font/icon backups.

## 2026-07-27 — Embed results Soft UI refine (delicate)

- Soft UI Evolution: quieter type hierarchy, softer surfaces/alpha, tighter gaps (tokens).
- Primary toolbar icon-only (Save/Share/Verify/Copy); A/B cards compact with play icon; Pause/Stop icon-only.
- Verify banner lighter; content-compare plays/copy as icons + tooltips; Extract hero aligned.
- Flutter + WPF; brand purple `#7A68A8` preserved (no CDN pink palette).

## 2026-07-27 — Equalizer badges: intensity left, time right

- Physical order fixed (LTR badge row): volume % left · duration right — independent of UI RTL.
- Flutter `audio_equalizer_view.dart`; WPF `EqualizerControl.xaml.cs`.

## 2026-07-27 — Save extracted: icon-only CTA

- Extract (and Embed recovered) save actions: icon-only with tooltip; removed long label «ذخیره صوت استخراج‌شده».
- Flutter `IconButton.filled` / `filledTonal`; WPF `IconFilledButton` / `IconTonalButton`.

## 2026-07-27 — Full-page busy overlay during process (Flutter + WPF)

- Processing/verifying no longer shows only an in-card spinner; full-viewport blocking overlay until done.
- Flutter: `appBusyMessageProvider` + `AppBusyOverlay` on `HomeShell` (blocks tabs/nav); Embed/Extract publish busy via setState hook.
- WPF: `MainWindow.GlobalBusyOverlay` + `SetGlobalBusy`; Embed/Extract call it; bottom/rail nav hit-test disabled while busy.
- Inline card BusyBar kept collapsed; Soft UI card + brand primary spinner on scrim.

## 2026-07-27 — A/B listen panel: design-auditor beautify (Flutter + WPF)

- Auditory compare: dual A/B side cards (badge + short label + play) instead of flat button row.
- Transport bar groups Pause/Stop with visible labels; playing side gets primary border emphasis.
- Responsive stack under 560px; i18n `abListenOriginalShort` / `abListenStegoShort`.
- Brand purple `#7A68A8` preserved (no CDN, Soft UI Evolution).

## 2026-07-27 — Extract results UI: Hero + Bento parity with Embed

- Extract result panel aligned with Embed redesign: Hero success/error → primary CTAs (Save / Play / Copy) → payload content block.
- i18n: `extractSuccessSubtitle` / `ExtractSuccessSubtitle` (fa/en/ar/fr).
- Flutter `extract_screen.dart` + WPF `ExtractView.xaml` / `.cs`.

## 2026-07-27 — Embed results UI: Hero + Bento blocks (Flutter + WPF)

- Result panel hierarchy: Hero success → Save/Share CTAs (+ icon Verify/Copy) → verify banner → A/B listen (only playback controls) → content compare → analysis (waveform + metrics).
- Removed duplicate Play/Pause/Stop from result header; Pause/Stop live inside A/B listen.
- Narrow content compare stacks vertically (`< 560`); tokens `sectionGapResult`, `resultHeroIconSize`, `resultBlockRadius`, `resultContentBreakpoint`.
- i18n: `operationSuccessSubtitle`, `analysisSectionTitle` (fa/en/ar/fr).

## 2026-07-27 — Embed/Extract: loading, success dialog, scroll, hide inputs

- During embed/extract processing: visible indeterminate loading (Flutter + WPF).
- After successful embed/extract: success dialog (`operationSuccess`), then scroll to results.
- Record/upload (embed) and pick/load (extract) panels stay hidden until «نهان‌نگاری جدید» / «رمزگشایی جدید».
- i18n: `operationSuccess`, `extractCompleteTitle` (fa/en/ar/fr).

## 2026-07-26 — About: remove person icon overlay on profile photo

- Flutter `CircleAvatar` had `Icons.person_outline` as `child`, which paints on top of `backgroundImage` — removed so only the photo shows.

## 2026-07-26 — PlaybackHub: isolated Play/Pause sessions

- Method-based `PlaybackHub` (Flutter + WPF): one engine per surface (cover/stego/payload original/recovered/extract).
- Play pauses other sessions; no shared A/B or payload multiplex onto one player.
- Tab change stops leaving screen’s sessions (`home_shell` / `MainWindow.SelectTab`).

## 2026-07-26 — Web boot: hide top bar, center spinner

- `web/index.html`: hide Flutter `.flutter-loader` top progress bar; purple center spinner above Loading text.

## 2026-07-26 — Dynamic payload bits when fixed budget off

- Settings «حجم پیش‌فرض» off: Embed no longer shows `0 / 262144`; empty payload hides budget line.
- After image/audio/text payload: show required bits + ≈ cover record seconds; cover stop-gate uses those bits.
- Image compress soft when no budget; payload audio not capped at 262144 when fixed off (Flutter + WPF).

## 2026-07-26 — Capacity warning shows needed vs available bits

- When payload (text/image/audio/file) exceeds cover LSB capacity: warn with required bits and available bits (Flutter + WPF).
- Typed `CapacityExceededException` from embed engine; i18n `errorCapacityExceeded`.

## 2026-07-26 — Remove theme color picker; fixed purple light/dark

- Settings: color-seed selection removed (Flutter + WPF); theme control is Light / Dark only.
- Brand locked to soft purple `#7A68A8` on all pages; legacy `seed` prefs dropped; System theme migrates to Light.
- i18n: removed unused `themeSystem` / ColorSeed; help copy no longer mentions color picker.

## 2026-07-26 — Dual waveform: peak-normalize for visibility

- Cover/stego comparison chart auto-scales to joint peak (~92% height) so quiet recordings are readable.
- Thicker strokes + soft fill; WPF chart host no longer fades waveforms at 35% opacity.
- Flutter + WPF; unit tests for normalize helper.

## 2026-07-26 — Cover record gate uses real sample buffer (not wall-clock)

- Root cause: stop was allowed after ~bits/44100 wall-clock while web/capture undersampled (e.g. 12s clock ≈ 144k samples < 262144 bits).
- Gate + progress now use `bufferedMonoSampleCount` / `BufferedMonoSampleCount` vs `requiredBits + safety margin`.
- Flutter + WPF; i18n early-stop copy updated; unit tests sample-based.

## 2026-07-26 — Cover record min duration gate + progress (fixed bits)

- When Settings fixed bit budget is on: cover recording cannot stop until capacity ≥ budget (≈ bits/44100 s).
- Progress bar + remaining time (Flutter + WPF); payload recording unchanged.

## 2026-07-26 — Soft purple theme (light + dark)

- Product chrome is soft purple end-to-end: default seed `#7A68A8`, purple-family surfaces in Flutter (`ColorScheme.fromSeed` tonalSpot) and WPF Light/Dark dictionaries.
- Settings seed swatches = soft purple family only; legacy teal `#00B4B7` auto-migrates on hydrate (Flutter + WPF).
- WPF `ThemeManager` derives PrimaryContainer / Secondary / Nav / Chart from accent so accents stay harmonious.

## 2026-07-26 — UI visual standard across all pages

- Centralized Flutter tokens (`AppUiTokens`) + full component themes (NavigationRail/Bar, Card, SegmentedButton, Chip, Input).
- Shared `AppSectionCard` + `PageToolbarFab`; Embed/Extract/Settings/About use the same card radius, surfaces, and toolbar FAB chrome.
- Nav icons: layers / search / settings / person (aligned with Embed reference screenshot).
- WPF: `SurfaceContainerBrush` elevated cards; ResultCard/Nav/FAB/BottomNav/Rail match Flutter surfaces; Extract icon uses PrimaryBrush.

## 2026-07-26 — Immediate verify: original vs recovered payload side-by-side

- After verify: show **original hidden** and **recovered** together for text, audio payload, and image (Flutter + WPF).
- Audio payload: play original hidden audio + play recovered; images preview both; text selectable both sides.

## 2026-07-26 — Immediate verify A/B listen (cover vs stego)

- Embed verify result: play **original cover** and **watermarked stego** separately (Flutter + WPF) so the user can judge perceptual difference.
- i18n + help steps 5/6 updated (fa-first).

## 2026-07-26 — Immediate verify extracts and shows testable payload

- After embed success (and on Verify): real extract from stego; show recovered text / play-save audio / preview-save image on Embed result panel (Flutter + WPF).
- Separate recovered playback so stego cover and payload do not share one player.

## 2026-07-26 — ASTG Image payload (hide/recover still image)

- ASTG type `Image` (0x02): JPEG/PNG body; Flutter `PayloadImageCodec` + WPF `PayloadImageCodec` compress to fit Settings bit budget (long-edge ≤240, quality ladder).
- Embed: Text | Audio | Image tabs (Flutter SegmentedButton + WPF radios); pick/preview/clear image then cover record/load.
- Extract: preview recovered image + save JPEG/PNG (Flutter + WPF).
- Tests: pack/unpack image + bit-budget helper (Dart/C#).

## 2026-07-26 — Extract dual players (cover vs payload)

- Flutter/WPF Extract: separate players for stego cover vs extracted payload so pause/stop/play no longer share one source.
- Playing one pauses the other; extracted play toggles pause when already playing.

## 2026-07-26 — Fast extracted speech + pre-deploy test gate

- Root cause (WPF): payload recorded at 8 kHz but `StopAndRead()` default-labeled WAV as 44100 → encode downsampled → ~5.5× too fast.
- Fix: `AudioCaptureService` keeps session sample rate; `SampleRateReconcile` (Dart+C#) retags from wall-clock duration on payload stop.
- Pre-deploy: `_test-pre-deploy.ps1` + `audio_payload_duration_test.dart` / `AudioPayloadDurationTests.cs` (duration preserve / mislabel regression). Gate PASSED.

## 2026-07-26 — Extracted audio payload quality fix

- Root cause: linear `(pcm16+32768)>>8` collapsed quiet speech toward silence after extract.
- Audio body meta now includes `peakAbs` (10 B): DC-remove + peak-normalize on encode; restore amplitude on decode; legacy 8 B meta still readable.
- Extract play/save (Flutter + WPF): `PrepareAudioForExport` / `prepareAudioForExport` → 16 kHz for player compatibility.
- Tests: quiet-speech energy + export upsample (Flutter 8 / Core 24 green).

## 2026-07-26 — Embed integrity gate (stego vs original)

- Immediate post-embed check: BER=0, bit-exact payload, cover differs only in LSBs, WAV encode→decode→extract.
- `toMatlabInt16` is identity copy (no float round-trip that could desync cover vs stego).
- Flutter/WPF: reject embed on integrity failure; auto show VerifyMatch; audio verify compares PCM samples not only length.

## 2026-07-26 — ASTG payload envelope + Embed audio tab

- Content-type header `ASTG` (v1) before AE/XOR/LSB: Text / Image / Audio / Other; no magic → legacy UTF-8 text.
- Audio payload body: 8 kHz mono PCM u8; bit budget from Settings `DefaultFixedMessageBitLength`.
- Flutter Embed: Text | Audio tabs; record payload then cover; Extract: play/save recovered WAV.
- WPF EmbedView / ExtractView parity + AppStrings.
- Core: `PayloadEnvelope` (Dart + C#); tests green (19 Core incl. audio round-trip); Desktop build OK; removed missing `.mat` from Core csproj / Flutter pubspec (JSON AE remains).
- Follow-up: ASTG-aware `lsb_codec_test` / `stego_engine_test`; Settings/Embed hints (~4 s @ 8 kHz); workspace title/status bar colors.

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

- Created `wordpress/` with SEO post for **صوت‌نهان** (xwav.ir / Myket).
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

## 2026-06-14 — Gemini en promo aligned to real screenshots (Part 79)

- `SocialMediaContent/gemini/en/gemini-create-video-promo.json` — reference images switched from `wordpress/en/images/*.webp` to `screenshotsReal/screenshots/en/` (1.jpg, 2.jpg, 4–10.png).
- Nine scenes remapped: splash → quick guide → embed recording → metrics → extract → full guide → settings → languages → about/outro.
- App name/version synced to **Audio Steganography v1.2.6**; Myket CTA moved to scene 9 voiceover + post end card (no Myket banner in screenshot set).


## 2026-07-27 — Colorful semantic icons (design-auditor)

- Palette: `AppIconAccents` / WPF `Icon*Brush` — meaning-driven hues (embed violet · extract teal · settings amber · about rose · verify green · share blue · save violet · help sky · create emerald).
- Flutter: `AccentIcon` · `AccentGlowIcon` · `AccentActionIconButton`; nav · About tiles · result/extract actions · toolbar FAB glow.
- WPF: theme brushes + colored nav/FABs/About/action buttons; soft DropShadow on FABs/hero.
- Grades (auditor): Design B+ · AI Slop A- · A11y B+ (semantic color, not rainbow slop).

## 2026-07-27 — Fix Flutter web .woff2 404 spam (font fallback CDN)

- Root cause: post-process mapped `fonts.gstatic.com/s/` → `assets/fonts/` without shipping Noto Color Emoji woff2 → Network red 404 flood.
- Fix: `_flutter-web-no-cdn.ps1` rewrites fallback base to `about:invalid#karavi-offline-fonts/` (zero CDN, no local requests); idempotent repair of old `assets/fonts/` base.
- App text still from pubspec Roboto + Noto Sans Arabic TTF.
