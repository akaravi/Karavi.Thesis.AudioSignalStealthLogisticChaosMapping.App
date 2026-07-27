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

## Part 6 — Revert package name to ir.ntk.audiowmark.app

```json
{
  "promptSpecVersion": "1.1.0",
  "kind": "json-prompt",
  "part": 6,
  "title": "Revert package name to ir.ntk.audiowmark.app",
  "from": "ca.karavi.audiowmark.app",
  "to": "ir.ntk.audiowmark.app",
  "status": "done"
}
```

## Result 6

```json
{
  "part": 6,
  "status": "done",
  "verification": "grep: zero ca.karavi.audiowmark references; kotlin/ir/ntk/audiowmark/app restored."
}
```

## Part 7 — Enforce no-CDN law for Flutter web

```json
{
  "promptSpecVersion": "1.1.0",
  "kind": "json-prompt",
  "part": 7,
  "title": "No external CDN at runtime (repo law)",
  "userRequest": "در قوانین آمده است که ما مجاز به استفاده از هیچ cdn نیستیم",
  "solution": "_flutter-web-no-cdn.ps1 centralizes --no-web-resources-cdn for build/run; post-build Assert-KaraviFlutterWebOutputNoExternalCdn scans build/web for gstatic and missing canvaskit/",
  "files": [
    "_flutter-web-no-cdn.ps1",
    "_build-flutter-web.ps1",
    "_build-all-projects.ps1",
    "_run-all-local.ps1",
    ".cursor/rules/no-external-cdn-assets.mdc",
    "src/audio_stegano_app/web/index.html",
    "README.md"
  ],
  "status": "done"
}
```

## Result 7

```json
{
  "part": 7,
  "status": "done",
  "verification": "flutter build web --release --no-web-resources-cdn exit 0; Invoke-KaraviFlutterWebNoCdnPostProcess passes (local canvaskit/, useLocalCanvasKit:true); README flutter run includes --no-web-resources-cdn."
}

## Part 8 — Zero CDN in deploy output (strict)

```json
{
  "promptSpecVersion": "1.1.0",
  "kind": "json-prompt",
  "part": 8,
  "title": "هیچ cdn مجاز نیست — zero CDN in deploy output",
  "userRequest": "هیچ cdn مجاز نیست",
  "solution": "Repair-KaraviFlutterWebOutputRemoveExternalCdnLiterals patches gstatic CanvasKit/font URLs; Assert scans all deploy JS/HTML/JSON for forbidden CDN hosts; Invoke-KaraviFlutterWebNoCdnPostProcess wired in build scripts",
  "status": "done"
}
```

## Result 8

```json
{
  "part": 8,
  "status": "done",
  "verification": "Invoke-KaraviFlutterWebNoCdnPostProcess on build/web: patched files, findstr zero gstatic in deploy output."
}
```

## Part 9 — Android app stuck on loading spinner (not CDN)

```json
{
  "promptSpecVersion": "1.1.0",
  "kind": "json-prompt",
  "part": 9,
  "title": "اجرای اندروید در حالت لودینگ می‌ماند — بررسی CDN/آفلاین",
  "userRequest": "در اجرای برنامه اندروید خیلی در حالت لودینگ می‌ماند. بررسی کن از cdn استفاده نکرده باشی چون در اجرا اینترنتی دسترسی ندارد",
  "investigation": [
    "No CDN/network runtime assets: pubspec has no google_fonts/CDN deps; lib has no Image.network/NetworkImage/GoogleFonts/CDN hosts; web/index.html loads only local flutter_bootstrap.js; AndroidManifest has no INTERNET permission.",
    "Root cause is a platform-channel bug: widget_capture channel registered only in WidgetCaptureActivity, not MainActivity (launcher). consumeInitial() invoked getWidgetCaptureLaunch without try/catch, so normal launch threw MissingPluginException and _hydrate aborted before _hydrated=true -> infinite CircularProgressIndicator."
  ],
  "solution": "android_widget_capture_launch_io.dart: catch MissingPluginException/PlatformException and return null. app_bootstrap.dart: _hydrate try/catch + SessionLog, always set _hydrated=true so bootstrap never hangs.",
  "files": [
    "src/audio_stegano_app/lib/core/platform/android_widget_capture_launch_io.dart",
    "src/audio_stegano_app/lib/app/app_bootstrap.dart"
  ],
  "status": "done"
}
```

## Result 9

```json
{
  "part": 9,
  "status": "done",
  "verification": "flutter analyze on app_bootstrap.dart + android_widget_capture_launch_io.dart -> No issues found. No CDN usage confirmed across deps, lib, web/index.html, and Android manifest (no INTERNET permission)."
}
```

## Part 10 — update ver (1.2.5 → 1.2.6)

```json
{
  "promptSpecVersion": "1.1.0",
  "kind": "json-prompt",
  "part": 10,
  "title": "update ver — patch bump",
  "userRequest": "update ver",
  "command": ".\\_update-ver.ps1",
  "previousVersion": "1.2.5",
  "nextVersion": "1.2.6",
  "filesUpdated": [
    "src/audio_stegano_app/pubspec.yaml",
    "src/audio_stegano_desktop/src/AudioStegano.Desktop/AudioStegano.Desktop.csproj"
  ],
  "status": "done"
}
```

## Result 10

```json
{
  "part": 10,
  "status": "done",
  "verification": "_update-ver.ps1 exit 0; pubspec.yaml version 1.2.6; WPF Version/AssemblyVersion/FileVersion/InformationalVersion 1.2.6; readmehistory.md entry added."
}
```

## Part 11 — Flutter web invisible text (offline fonts)

```json
{
  "promptSpecVersion": "1.1.0",
  "kind": "json-prompt",
  "part": 11,
  "title": "Flutter web — fix blank text in no-CDN CanvasKit build",
  "userRequest": "در بیلد وب هیچ نوشته ای پیدا نیست",
  "rootCause": "_flutter-web-no-cdn.ps1 patches fonts.gstatic.com/s/ to assets/fonts/ without shipping woff2/ttf files; CanvasKit font fallback fails silently",
  "solution": "Bundle Roboto + Noto Sans Arabic in pubspec; AppTheme fontFamily/fallback; commit web/fonts woff2; Copy-KaraviFlutterWebBundledNotoFonts in post-process",
  "files": [
    "src/audio_stegano_app/pubspec.yaml",
    "src/audio_stegano_app/lib/app/app_theme.dart",
    "src/audio_stegano_app/assets/fonts/*.ttf",
    "src/audio_stegano_app/web/fonts/**/*.woff2",
    "_flutter-web-no-cdn.ps1"
  ],
  "status": "done"
}
```

## Result 11

```json
{
  "part": 11,
  "status": "done",
  "verification": "flutter build web --release --no-web-resources-cdn + Invoke-KaraviFlutterWebNoCdnPostProcess exit 0; FontManifest lists Roboto + Noto Sans Arabic; assets/fonts/roboto|notosansarabic|notosansoldpersian woff2 present; local HTTP 200 for font URLs."
}
```

## Part 12 — Android release signing law (E:\BANK publish key)

```json
{
  "promptSpecVersion": "1.1.0",
  "kind": "json-prompt",
  "part": 12,
  "title": "Android release must use E:\\BANK Android Key publish",
  "userRequest": "به قانون پروژه اضافه کن که بیلد های ریلیز اندروید با کلید E:\\BANK Android Key publish و پسورد key_password.txt",
  "solution": ".cursor/rules/android-release-signing.mdc (alwaysApply); _android-release-signing.ps1; Sync/Assert in _build-flutter-android.ps1 and _build-cafebazaar-release.ps1",
  "paths": {
    "keystore": "E:\\BANK Android Key publish\\key.jks",
    "passwords": "E:\\BANK Android Key publish\\key_password.txt"
  },
  "status": "done"
}
```

## Result 12

```json
{
  "part": 12,
  "status": "done",
  "verification": "Sync-KaraviAndroidKeyProperties + Assert-KaraviAndroidReleaseSigningConfigured exit 0; key.properties storeFile=E:/BANK Android Key publish/key.jks (gitignored)."
}
```

## Part 13 — Stego algorithm: logistic_positions (embed_message.m)

```json
{
  "promptSpecVersion": "1.1.0",
  "kind": "json-prompt",
  "part": 13,
  "title": "Align stego with train/embed_message.m chaotic LSB positions",
  "userRequest": "Study train/embed_message.m and train/extract_message.m; optimize steganography in App repo",
  "matlabSource": [
    "Karavi.Thesis.AudioSignalStealthLogisticChaosMapping/train/embed_message.m",
    "Karavi.Thesis.AudioSignalStealthLogisticChaosMapping/train/extract_message.m",
    "Karavi.Thesis.AudioSignalStealthLogisticChaosMapping/train/logistic_positions.m",
    "pipeline/logistic_map_keygen.m"
  ],
  "pipeline": "UTF-8 message -> bits -> XOR(logistic key) -> LSB at logistic_positions(r,x0,n,capacity)",
  "touchedFiles": [
    "src/audio_stegano_app/lib/core/stego/audio_watermarking.dart",
    "src/audio_stegano_app/test/core/lsb_codec_test.dart",
    "src/audio_stegano_desktop/src/AudioStegano.Core/Stego/LogisticPositions.cs",
    "src/audio_stegano_desktop/src/AudioStegano.Core/Stego/AudioWatermarking.cs"
  ],
  "breakingNote": "Sequential-LSB stego from older app builds is not readable after this change; re-embed required.",
  "aeXorMode": "ported with trained_autoencoder.mat + JSON weights; default xor_only"
}
```

## Result 13

```json
{
  "part": 13,
  "status": "done",
  "verification": "flutter test test/core/lsb_codec_test.dart test/core/stego_engine_test.dart — 12 passed; dotnet test AudioStegano.Core.Tests — 13 passed; BER 0 round-trip fa/en."
}
```

## Part 14 — trained_autoencoder.mat + ae_xor mode

```json
{
  "promptSpecVersion": "1.1.0",
  "kind": "json-prompt",
  "part": 14,
  "title": "Bundle trained_autoencoder.mat and enable ae_xor",
  "userRequest": "Project must include trained_autoencoder.mat to use autoencoder weights in stego",
  "assets": [
    "src/audio_stegano_app/assets/stego/trained_autoencoder.mat",
    "src/audio_stegano_app/assets/stego/trained_autoencoder.json",
    "src/audio_stegano_desktop/src/AudioStegano.Core/Stego/trained_autoencoder.mat",
    "scripts/export_trained_autoencoder.py"
  ],
  "runtime": "StegoEmbedMode xor_only | ae_xor; DefaultStegoEmbedMode in appsettings.json",
  "defaultMode": "xor_only",
  "status": "done"
}
```

## Result 14

```json
{
  "part": 14,
  "status": "done",
  "verification": "flutter test 13 passed; dotnet test 14 passed; mat+json present under assets/stego; ae_xor pipeline runs; xor_only BER 0 round-trip."
}
```

## Part 15 — Stego algorithm audit (autoencoder usage + mapminmax)

```json
{
  "promptSpecVersion": "1.1.0",
  "kind": "json-prompt",
  "part": 15,
  "title": "Verify full stego pipeline; fix ae_xor mapminmax; expose mode in settings",
  "userRequest": "Ensure algorithm steps are correct; user suspected autoencoder not used",
  "findings": {
    "defaultMode": "xor_only — autoencoder skipped at runtime unless ae_xor selected",
    "xor_onlyPipeline": "message_to_bits → XOR(logistic key) → LSB @ logistic_positions — verified",
    "ae_xorPipeline": "message_to_bits → round(net(mapminmax)) → XOR → LSB — fixed mapminmax",
    "matlabParity": "embed_message.m default embed_mode = xor_only; net loaded but unused in that branch"
  },
  "changes": [
    "MessageBlockAutoencoder mapminmax (Flutter + WPF)",
    "settings_screen SegmentedButton StegoEmbedMode",
    "stego_engine_test + WPF test exact ae_xor round-trip"
  ],
  "status": "done"
}
```

## Result 15

```json
{
  "part": 15,
  "status": "done",
  "verification": "flutter test stego_engine_test 4 passed; dotnet test 14 passed; ae_xor round-trip Test/پیام; xor_only unchanged."
}
```

## Part 16 — Autoencoder-only (remove xor_only)

```json
{
  "promptSpecVersion": "1.1.0",
  "kind": "json-prompt",
  "part": 16,
  "title": "Mandatory autoencoder; remove xor_only and mode selection",
  "userRequest": "Autoencoder must always be used; remove any path that skips it",
  "changes": [
    "Deleted StegoEmbedMode enum and xor_only branches",
    "MessageBlockAutoencoder required on EmbedMessage/ExtractMessage",
    "StegoRunner always loads trained_autoencoder.json",
    "Removed DefaultStegoEmbedMode from appsettings and settings UI"
  ],
  "status": "done"
}
```

## Result 16

```json
{
  "part": 16,
  "status": "done",
  "verification": "flutter test stego_engine + app_config 8 passed; dotnet test 14 passed; only ae_xor pipeline remains."
}
```

---

## Part 73 — WordPress post (SEO + WebP)

```json
{
  "part": 73,
  "title": "wordpress folder: SEO post, tags, WebP images, Myket + xwave links",
  "files": [
    "wordpress/post-content.html",
    "wordpress/seo-meta.json",
    "wordpress/schema-software-application.jsonld",
    "wordpress/images/*.webp",
    "wordpress/README.md",
    "wordpress/scripts/convert-screenshots-to-webp.py"
  ],
  "status": "done"
}
```

## Result 73

```json
{
  "part": 73,
  "status": "done",
  "deliverables": [
    "post-content.html with H1/H2/H3, 4+ paragraphs, max ~30 words per sentence",
    "10 WordPress tags in seo-meta.json",
    "featured-splash-intro.webp as featured image",
    "Myket and xwav.ir link banners with images",
    "internal links xwav.ir + category/apps; external Myket, GitHub, NTK"
  ]
}
```

---

## Part 73b — WordPress post 1000+ words + tutorial

```json
{
  "part": "73b",
  "title": "Expand post-content.html to 1000+ words; step-by-step tutorial at end",
  "status": "done"
}
```

## Result 73b

```json
{
  "part": "73b",
  "status": "done",
  "wordCount": "~1821",
  "tutorialSections": ["install", "key settings", "embed", "save/share", "extract", "troubleshooting", "reset", "practice exercise"]
}
```

---

## Part 74 — WordPress fa/ + en/ locale folders

```json
{
  "part": 74,
  "title": "Move wordpress content to fa/; create en/ with full English post",
  "status": "done"
}
```

## Result 74

```json
{
  "part": 74,
  "status": "done",
  "structure": {
    "wordpress/fa": "Persian post ~1826 words",
    "wordpress/en": "English post ~1524 words",
    "wordpress/scripts": "outputs images to both locales"
  }
}
```

---

## Part 75 — Gemini Create Video promo JSON

```json
{
  "part": 75,
  "title": "gemini-create-video-promo.json for Veo 3.1 promotional film",
  "status": "done"
}
```

## Result 75

```json
{
  "part": 75,
  "status": "done",
  "file": "wordpress/gemini-create-video-promo.json",
  "scenes": 9,
  "durationSeconds": 54,
  "persianRule": "voiceoverFaDiacritics with full tashkil for TTS"
}
```

---

## Part 76 — Move wordpress → SocialMediaContent/wordpress

```json
{
  "part": 76,
  "title": "Relocate wordpress folder under SocialMediaContent",
  "status": "done"
}
```

## Result 76

```json
{
  "part": 76,
  "status": "done",
  "newPath": "SocialMediaContent/wordpress/",
  "scriptsUpdated": ["convert-screenshots-to-webp.py", "build-link-banners.py"]
}
```

---

## Part 77 — Gemini → SocialMediaContent/gemini

```json
{
  "part": 77,
  "title": "Move Gemini promo files to SocialMediaContent/gemini",
  "status": "done"
}
```

## Result 77

```json
{
  "part": 77,
  "status": "done",
  "newPath": "SocialMediaContent/gemini/gemini-create-video-promo.json"
}
```

---

## Part 78 — Gemini prompts split fa / en

```json
{
  "part": 78,
  "title": "Split gemini prompts into fa/ and en/ locales",
  "status": "done"
}
```

## Result 78

```json
{
  "part": 78,
  "status": "done",
  "paths": [
    "SocialMediaContent/gemini/fa/gemini-create-video-promo.json",
    "SocialMediaContent/gemini/en/gemini-create-video-promo.json"
  ]
}
```

---

## Part 79 — Gemini en promo from screenshotsReal/en

```json
{
  "part": 79,
  "title": "Edit gemini/en/gemini-create-video-promo.json to use real en screenshots",
  "sourceFolder": "SocialMediaContent/screenshotsReal/screenshots/en",
  "status": "done"
}
```

## Result 79

```json
{
  "part": 79,
  "status": "done",
  "file": "SocialMediaContent/gemini/en/gemini-create-video-promo.json",
  "promptSpecVersion": "1.2.0",
  "referenceImagesBasePath": "SocialMediaContent/screenshotsReal/screenshots/en",
  "sceneMapping": [
    { "scene": 1, "file": "1.jpg", "title": "Splash hook" },
    { "scene": 2, "file": "4.png", "title": "Quick guide LSB chaos" },
    { "scene": 3, "file": "5.png", "title": "Embed recording" },
    { "scene": 4, "file": "6.png", "title": "Waveform metrics SNR PSNR" },
    { "scene": 5, "file": "7.png", "title": "Extract pick file" },
    { "scene": 6, "file": "8.png", "title": "Full guide bit length" },
    { "scene": 7, "file": "10.png", "title": "Settings chaos params" },
    { "scene": 8, "file": "2.jpg", "title": "Four languages" },
    { "scene": 9, "file": "9.png", "title": "About thesis outro Myket CTA" }
  ],
  "notes": "No file 3.png in en set; Myket banner replaced by post end card overlay"
}
```

---

## Part 80 — Payload type header + Embed audio tab

```json
{
  "part": 80,
  "title": "ASTG content-type envelope + Embed Text|Audio tab + typed extract (Flutter + WPF)",
  "status": "done",
  "scope": [
    "payload_envelope (Dart/C#)",
    "embed/extract typed + StegoRunner",
    "Flutter Embed/Extract UI",
    "WPF EmbedView/ExtractView parity",
    "legacy UTF-8 without magic"
  ]
}
```

## Result 80

```json
{
  "part": 80,
  "status": "done",
  "verification": {
    "dotnetTest": "18 passed (AudioStegano.Core.Tests)",
    "flutterEnvelopeTest": "6 passed (payload_envelope_test.dart)",
    "dotnetBuildDesktop": "succeeded",
    "envelope": "ASTG v1 Type Text|Image|Audio|Other; audio body 8kHz mono PCM u8",
    "legacy": "extract without magic → UTF-8 text"
  },
  "files": [
    "src/audio_stegano_app/lib/core/stego/payload_envelope.dart",
    "src/audio_stegano_desktop/src/AudioStegano.Core/Stego/PayloadEnvelope.cs",
    "embed_message / extract_message (Dart + C#)",
    "embed_screen.dart / extract_screen.dart",
    "EmbedView / ExtractView (WPF)"
  ]
}
```

---

## Part 81 — Extracted audio payload quality

```json
{
  "request": "فایل صوتی استخراج شده مشکل دارد — fix recovered payload audio quality",
  "tasks": [
    "Peak-normalize PCM u8 codec with peakAbs in audio meta (Dart + C#)",
    "Legacy 8-byte audio meta decode path retained",
    "Upsample extract play/save to 16 kHz (Flutter + WPF)",
    "Regression tests for quiet speech and export rate"
  ],
  "scope": ["payload_envelope.dart", "PayloadEnvelope.cs", "extract_screen.dart", "ExtractView.xaml.cs", "tests"],
  "constraints": ["ASTG version stays 1", "Flutter/WPF parity", "no CDN"]
}
```

## Result 81

```json
{
  "part": 81,
  "status": "done",
  "verification": {
    "dotnetTest": "24 passed (AudioStegano.Core.Tests)",
    "flutterCoreTest": "40 passed (test/core)",
    "rootCause": "quiet speech collapsed by >>8 u8 quantize → near silence",
    "fix": "peakAbs meta + DC remove + peak normalize; export upsample 16 kHz"
  },
  "files": [
    "src/audio_stegano_app/lib/core/stego/payload_envelope.dart",
    "src/audio_stegano_desktop/src/AudioStegano.Core/Stego/PayloadEnvelope.cs",
    "src/audio_stegano_app/lib/features/extract/extract_screen.dart",
    "src/audio_stegano_desktop/src/AudioStegano.Desktop/Views/ExtractView.xaml.cs"
  ]
}
```

---

## Part 82 — Fast payload speech + pre-deploy tests

```json
{
  "request": "extracted audio plays too fast; need pre-deploy coding tests",
  "tasks": [
    "Fix WPF StopAndRead sample-rate mislabel (8k capture stamped 44100)",
    "SampleRateReconcile from wall-clock on payload stop (Flutter + WPF)",
    "Duration regression tests Dart + C#",
    "_test-pre-deploy.ps1 gate before deploy"
  ],
  "scope": ["AudioCaptureService", "SampleRateReconcile", "embed UI", "tests", "_test-pre-deploy.ps1"],
  "constraints": ["re-embed required for old bad stego files", "Flutter/WPF parity"]
}
```

## Result 82

```json
{
  "part": 82,
  "status": "done",
  "verification": {
    "preDeployGate": "PASSED (_test-pre-deploy.ps1)",
    "dotnetTest": "29 passed",
    "flutterPreDeploy": "28 passed",
    "rootCause": "WPF StopAndRead default sampleRate=44100 while Start(8000)",
    "fix": "session rate + SampleRateReconcile + duration tests"
  },
  "files": [
    "src/audio_stegano_desktop/.../AudioCaptureService.cs",
    "src/audio_stegano_app/lib/core/audio/sample_rate_reconcile.dart",
    "src/audio_stegano_desktop/.../SampleRateReconcile.cs",
    "test/core/audio_payload_duration_test.dart",
    "AudioPayloadDurationTests.cs",
    "_test-pre-deploy.ps1"
  ]
}
```

## Part 83 — ASTG Image payload (hide/recover still image)

```json
{
  "promptSpecVersion": "1.1.0",
  "kind": "json-prompt",
  "part": 83,
  "title": "Image payload for stego hide/extract",
  "request": "میخواهم فایل عکس هم برای نهان شدن ایجاد کنی",
  "scope": [
    "ASTG type Image (0x02) pack/unpack JPEG/PNG body",
    "Compress to Settings bit budget (Flutter image package + WPF JpegBitmapEncoder)",
    "Embed UI Text|Audio|Image (Flutter + WPF)",
    "Extract preview + save recovered image (Flutter + WPF)",
    "i18n fa-first + tests"
  ],
  "constraints": ["no CDN", "Latin LTR N/A for image binary", "parity Flutter/WPF"]
}
```

## Result 83

```json
{
  "part": 83,
  "status": "done",
  "verification": "Flutter payload_envelope_test 10 passed; Core PayloadEnvelope 8 passed; WPF Desktop build 0 errors; flutter analyze image/embed/extract clean after unused-import fix",
  "files": [
    "payload_envelope.dart / PayloadEnvelope.cs",
    "payload_image_codec.dart / PayloadImageCodec.cs",
    "embed_screen.dart / EmbedView.xaml(.cs)",
    "extract_screen.dart / ExtractView.xaml(.cs)",
    "app_strings.dart / AppStrings.cs",
    "payload_envelope_test.dart / PayloadEnvelopeTests.cs"
  ]
}
```

## Part 84 — Immediate verify: extract + test recovered payload on Embed

```json
{
  "promptSpecVersion": "1.1.0",
  "kind": "json-prompt",
  "part": 84,
  "title": "Immediate verify extracts and allows testing",
  "request": "در تایید فوری باید بتوان همان لحظه استخراج را انجام داد و تست کرد",
  "scope": [
    "Auto-extract after embed success",
    "Show recovered text/audio/image with play/save/copy on Embed result",
    "Flutter + WPF parity; separate recovered player"
  ]
}
```

## Result 84

```json
{
  "part": 84,
  "status": "done",
  "verification": "WPF Desktop build green; flutter analyze embed_screen clean; history updated",
  "files": [
    "embed_screen.dart",
    "EmbedView.xaml / EmbedView.xaml.cs",
    "app_strings.dart / AppStrings.cs",
    "readmehistory.md"
  ]
}
```

## Part 85 — Immediate verify A/B listen cover vs stego

```json
{
  "promptSpecVersion": "1.1.0",
  "kind": "json-prompt",
  "part": 85,
  "title": "A/B play original and stego on immediate verify",
  "request": "در تایید فوری باید هر دو صدا یعنی صدای اصلی و صدا بعد از نهان نگاری قابل play باشد تا کاربر بررسی کند ایا تفاوتی حس می کند یا خیر",
  "scope": [
    "Labeled play original cover + play after watermark on Embed result",
    "Flutter + WPF parity; shared pause/stop; recovered player separate",
    "i18n + help steps"
  ]
}
```

## Result 85

```json
{
  "part": 85,
  "status": "done",
  "verification": "WPF Desktop build green; flutter analyze embed/strings clean; apps relaunched",
  "files": [
    "embed_screen.dart",
    "EmbedView.xaml / EmbedView.xaml.cs",
    "app_strings.dart / AppStrings.cs / HelpStrings.cs",
    "readmehistory.md"
  ]
}
```

## Part 86 — Immediate verify original vs recovered payload display

```json
{
  "promptSpecVersion": "1.1.0",
  "kind": "json-prompt",
  "part": 86,
  "title": "Show original hidden and recovered payload after verify",
  "request": "باید بعد از تایید سریع متن/صوت/عکس اصلی نهان‌شده و بازیافت‌شده هر دو نمایش داده شوند",
  "scope": [
    "Side-by-side original vs recovered for text, audio payload, image",
    "Flutter + WPF parity; play original hidden audio + recovered",
    "i18n + help"
  ]
}
```

## Result 86

```json
{
  "part": 86,
  "status": "done",
  "verification": "flutter analyze clean; WPF build green",
  "files": [
    "embed_screen.dart",
    "EmbedView.xaml / EmbedView.xaml.cs",
    "app_strings.dart / AppStrings.cs / HelpStrings.cs",
    "readmehistory.md"
  ]
}
```

## Part 87 — Cover record min duration + progress (fixed bit budget)

```json
{
  "promptSpecVersion": "1.1.0",
  "kind": "json-prompt",
  "part": 87,
  "title": "Gate cover recording until min duration for fixed bits",
  "request": "ضبط پوشش با بودجه بیت ثابت تا حداقل زمان لازم متوقف نشود + نوار پیشرفت",
  "scope": [
    "Block early stop when defaultFixedMessageBitLimit",
    "Progress bar toward min duration (bits/44100)",
    "Flutter + WPF; CoverRecordBudget helper + tests"
  ]
}
```

## Result 87

```json
{
  "part": 87,
  "status": "done",
  "verification": "flutter analyze clean; cover_record_budget tests; WPF build green",
  "files": [
    "cover_record_budget.dart / CoverRecordBudget.cs",
    "embed_screen.dart",
    "EmbedView.xaml / EmbedView.xaml.cs",
    "app_strings / AppStrings",
    "readmehistory.md"
  ]
}
```

## Part 87 — UI visual standard across all pages

```json
{
  "promptSpecVersion": "1.1.0",
  "kind": "json-prompt",
  "part": 87,
  "title": "Unify color and chrome across all pages",
  "request": "بر اساس styles های موجود قابلیت و رنگ بندی و همه موارد مربوطه را اصلاح کن به یک استاندارد در تمام صفحات برس",
  "scope": [
    "Flutter AppUiTokens + AppTheme (rail/bar/card/segment/chip/input)",
    "Shared AppSectionCard + PageToolbarFab across Embed/Extract/Settings/About",
    "Nav icons align with Embed reference (layers/search/settings/person)",
    "WPF SurfaceContainer + MaterialCard/ResultCard/Nav/FAB parity"
  ]
}
```

## Result 87

```json
{
  "part": 87,
  "status": "done",
  "verification": "flutter analyze (9 UI files) clean; WPF Desktop build 0 errors / 0 warnings",
  "files": [
    "app_ui_tokens.dart / app_theme.dart / home_shell.dart",
    "app_section_card.dart / page_toolbar_fab.dart",
    "embed_screen.dart / extract_screen.dart / settings_screen.dart / about_screen.dart",
    "LightTheme.xaml / DarkTheme.xaml / SharedStyles.xaml / MainWindow.xaml / ExtractView.xaml",
    "readmehistory.md"
  ]
}
```

## Part 88 — Soft purple theme light + dark

```json
{
  "promptSpecVersion": "1.1.0",
  "kind": "json-prompt",
  "part": 88,
  "title": "Soft purple theme for light and dark",
  "request": "رنگ ها کنار هم مسابق نیستند. تم نرم فاز را کلا بنفش کن و در دو تم تاریک و روشن",
  "scope": [
    "Soft purple brand default #7A68A8",
    "Flutter + WPF light/dark purple surfaces",
    "Legacy teal migration; purple seed swatches"
  ]
}
```

## Result 88

```json
{
  "part": 88,
  "status": "done",
  "verification": "flutter analyze theme/settings clean; WPF Desktop build 0 errors",
  "files": [
    "app_brand_colors.dart / app_theme.dart / settings_controller.dart / settings_screen.dart",
    "LightTheme.xaml / DarkTheme.xaml / ThemeManager.cs / AppState.cs / SettingsView.xaml.cs",
    "pubspec.yaml / web theme-color / cafebazaar_screenshots_test.dart",
    "readmehistory.md"
  ]
}
```

## Part 88 — Cover record gate: sample buffer not wall-clock

```json
{
  "promptSpecVersion": "1.1.0",
  "kind": "json-prompt",
  "part": 88,
  "title": "Fix cover min gate: use buffered samples",
  "request": "طول زمان اشتباه بود؛ کاربر قبل از حجم مورد نیاز stop کرد",
  "scope": [
    "Gate stop on bufferedMonoSampleCount >= requiredBits + margin",
    "Progress/remaining from real buffer; wall-clock only as UI hint",
    "Flutter + WPF + tests + i18n"
  ]
}
```

## Result 88

```json
{
  "part": 88,
  "status": "done",
  "verification": "flutter test cover_record_budget; flutter analyze clean; CoverRecordBudgetTests; WPF Desktop build green",
  "files": [
    "cover_record_budget.dart / CoverRecordBudget.cs",
    "audio_recorder.dart / AudioCaptureService.cs",
    "embed_screen.dart / EmbedView.xaml.cs",
    "app_strings / AppStrings",
    "cover_record_budget_test.dart / CoverRecordBudgetTests.cs",
    "readmehistory.md"
  ]
}
```

## Part 89 — Dual waveform clearer (peak normalize)

```json
{
  "promptSpecVersion": "1.1.0",
  "kind": "json-prompt",
  "part": 89,
  "title": "Make compare waveform more distinct",
  "request": "سیگنال مشخص تر باشد",
  "scope": [
    "Joint peak normalize cover/stego envelopes for display",
    "Thicker stroke + fill; remove WPF ChartHost 0.35 opacity",
    "Flutter DualWaveformChart + WPF DualWaveformControl + tests"
  ]
}
```

## Result 89

```json
{
  "part": 89,
  "status": "done",
  "verification": "flutter test waveform_display; WaveformDisplayTests; flutter analyze; WPF build",
  "files": [
    "waveform_display.dart / WaveformDisplay.cs",
    "dual_waveform_chart.dart",
    "DualWaveformControl.xaml / DualWaveformControl.xaml.cs",
    "readmehistory.md"
  ]
}
```

## Part 94 — PlaybackHub isolated Play/Pause sessions

```json
{
  "promptSpecVersion": "1.1.0",
  "kind": "json-prompt",
  "part": 94,
  "title": "Method-based playback hub — no cross-button interference",
  "request": "وضعیت دکمه های play pause با درستی عمل نمی کند؛ متدبیس بدون تداخل",
  "scope": [
    "PlaybackHub sessions per surface",
    "Embed A/B + payload split engines",
    "Extract via hub",
    "Stop on tab change Flutter+WPF"
  ]
}
```

## Result 94

```json
{
  "part": 94,
  "status": "done",
  "verification": "dart analyze hub/embed/extract/home_shell; WPF Debug build green",
  "files": [
    "playback_hub.dart",
    "PlaybackHub.cs",
    "embed_screen.dart / EmbedView.xaml.cs",
    "extract_screen.dart / ExtractView.xaml.cs",
    "home_shell.dart / MainWindow.xaml.cs",
    "readmehistory.md"
  ]
}
```

## Part 93 — Web boot loader: no top bar, center spinner

```json
{
  "promptSpecVersion": "1.1.0",
  "kind": "json-prompt",
  "part": 93,
  "title": "Remove Flutter web top progress bar; center loading spinner",
  "request": "نوار بالا را حذف کن و یک آیکن لودینگ در وسط صفحه قرار بده",
  "scope": ["web/index.html hide .flutter-loader", "CSS purple boot-spinner + Loading text"]
}
```

## Result 93

```json
{
  "part": 93,
  "status": "done",
  "verification": "index.html read-back; Flutter web restarted http://127.0.0.1:5320/",
  "files": ["src/audio_stegano_app/web/index.html", "readmehistory.md"]
}
```

## Part 92 — Dynamic bits/cover time when fixed budget off

```json
{
  "promptSpecVersion": "1.1.0",
  "kind": "json-prompt",
  "part": 92,
  "title": "Hide fixed 262144 when unchecked; dynamic cover bits/time from payload",
  "request": "با برداشتن تیک حجم پیش‌فرض عدد 262144 نشان داده نشود؛ بعد از بارگذاری عکس/صوت بیت و زمان ضبط پوشش دینامیک شود",
  "scope": [
    "Embed UI: fixed ON = used/budget; OFF = required bits + cover seconds",
    "CoverRequiredBits / _coverRequiredBits from live payload",
    "compressForEmbed without budget when fixed off",
    "Settings toggle refreshes Embed (WPF RefreshShell)"
  ]
}
```

## Result 92

```json
{
  "part": 92,
  "status": "done",
  "verification": "dart analyze embed_screen/app_strings/payload_image_codec; WPF Debug build green",
  "files": [
    "embed_screen.dart",
    "app_strings.dart",
    "payload_image_codec.dart / PayloadImageCodec.cs",
    "EmbedView.xaml(.cs)",
    "AppStrings.cs",
    "SettingsView.xaml.cs",
    "readmehistory.md"
  ]
}
```

## Part 91 — Capacity exceeded warning with bit counts

```json
{
  "promptSpecVersion": "1.1.0",
  "kind": "json-prompt",
  "part": 91,
  "title": "Warn when payload does not fit cover capacity",
  "request": "وقتی عکس/فایل در حجم صوت جا نشود هشدار با بیت مورد نیاز و بیت موجود",
  "scope": [
    "CapacityExceededException + pre-check before embed",
    "i18n needed vs available bits",
    "Flutter Embed + WPF EmbedView"
  ]
}
```

## Result 91

```json
{
  "part": 91,
  "status": "done",
  "verification": "capacity_exceeded tests; flutter analyze; WPF build",
  "files": [
    "capacity_exceeded_exception.dart / CapacityExceededException.cs",
    "embed_message.dart / EmbedMessage.cs",
    "embed_screen.dart / EmbedView.xaml.cs",
    "app_strings / AppStrings",
    "readmehistory.md"
  ]
}
```

## Part 90 — Remove theme color picker; fixed purple light/dark only

```json
{
  "promptSpecVersion": "1.1.0",
  "kind": "json-prompt",
  "part": 90,
  "title": "Remove color seed UI; fixed soft purple light/dark",
  "request": "انتخاب رنگ بندی تم را حذف کن و در همه صفحات تم بنفش با دو حالت روشن و تم تاریک",
  "scope": [
    "Remove Settings color-seed picker (Flutter + WPF)",
    "Fixed soft purple #7A68A8; Light/Dark only (migrate System → Light)",
    "Drop seed prefs; i18n cleanup themeSystem/ColorSeed"
  ]
}
```

## Result 90

```json
{
  "part": 90,
  "status": "done",
  "verification": "flutter analyze theme/settings/main + screenshot test clean; WPF Desktop build 0 errors 0 warnings",
  "files": [
    "settings_controller.dart / settings_screen.dart / app_theme.dart / app_brand_colors.dart / app_strings.dart / main.dart",
    "cafebazaar_screenshots_test.dart",
    "SettingsView.xaml / SettingsView.xaml.cs / ThemeManager.cs / AppState.cs / AppStrings.cs / HelpStrings.cs",
    "readmehistory.md"
  ]
}
```

## Part 91 — Embed/Extract loading, success, scroll, hide inputs

```json
{
  "promptSpecVersion": "1.1.0",
  "kind": "json-prompt",
  "part": 91,
  "title": "Loading + success dialog + scroll results + hide source panels",
  "request": "در زمان فعالیت‌هایی مانند نهان‌نگاری و یا رمزگشایی باید لودینگ نمایش بدهی. و در پایان رمزنگاری اعلام پیام موفقیت‌آمیز را اعلام کنی و سپس کمی اسکرول کنی روی بخش اعلام نتایج و بخش‌های رکورد و بارگزاری را تا فشردن دکمه درخواست جدید مخفی کنی",
  "scope": [
    "Show loading during embed and extract (Flutter + WPF)",
    "Success dialog then scroll to results after success",
    "Hide record/upload (embed) and pick/load (extract) until New FAB"
  ]
}
```

## Result 91

```json
{
  "part": 91,
  "status": "done",
  "verification": "WPF Desktop build 0 errors 0 warnings; flutter analyze embed/extract/app_strings: No issues found",
  "files": [
    "embed_screen.dart / extract_screen.dart / app_strings.dart",
    "EmbedView.xaml.cs / ExtractView.xaml / ExtractView.xaml.cs / AppStrings.cs",
    "readmehistory.md"
  ]
}
```

## Part 92 — Embed results redesign (Hero + Bento)

```json
{
  "promptSpecVersion": "1.1.0",
  "kind": "json-prompt",
  "part": 92,
  "title": "Embed results UI redesign — Before-After + Bento",
  "request": "بازطراحی قالب صفحه نتایج نهان‌نگاری (Flutter + WPF) با الگوی Before-After و بلوک‌های Bento، بدون تغییر بنفش برند",
  "scope": [
    "Hero + primary Save/Share CTAs + icon Verify/Copy",
    "A/B listen owns playback controls; no header Play/Pause/Stop",
    "Content compare responsive <560; analysis block separate",
    "Parity Flutter embed_screen + WPF EmbedView; tokens/i18n"
  ]
}
```

## Result 92

```json
{
  "part": 92,
  "status": "done",
  "verification": "flutter analyze embed_screen/app_ui_tokens/app_strings: No issues found; WPF Desktop build 0 errors 0 warnings",
  "files": [
    "embed_screen.dart / app_ui_tokens.dart / app_strings.dart",
    "EmbedView.xaml / EmbedView.xaml.cs / AppStrings.cs",
    "readmehistory.md"
  ]
}
```

## Part 95 — Extract results redesign (Hero + Bento parity)

```json
{
  "promptSpecVersion": "1.1.0",
  "kind": "json-prompt",
  "part": 95,
  "title": "Extract results UI — Hero + Bento parity with Embed",
  "request": "ادامه بده — هم‌ترازی قالب نتایج رمزگشایی با بازطراحی نتایج نهان‌نگاری",
  "scope": [
    "Hero success/error + extractSuccessSubtitle",
    "Primary CTAs Save/Play/Copy then payload content block",
    "Flutter extract_screen + WPF ExtractView parity"
  ]
}
```

## Result 95

```json
{
  "part": 95,
  "status": "done",
  "verification": "flutter analyze extract_screen/app_strings: No issues found; WPF Desktop build 0 errors 0 warnings",
  "files": [
    "extract_screen.dart / app_strings.dart",
    "ExtractView.xaml / ExtractView.xaml.cs / AppStrings.cs",
    "readmehistory.md"
  ]
}
```

## Part 96 — A/B listen design-auditor beautify

```json
{
  "promptSpecVersion": "1.1.0",
  "kind": "json-prompt",
  "part": 96,
  "title": "A/B listen panel — design-auditor beautify",
  "request": "/design-auditor بخش را زیباتر کن — مقایسه شنیداری",
  "scope": [
    "Dual A/B cards + transport bar (Pause/Stop labeled)",
    "Playing emphasis border; responsive <560",
    "Flutter embed_screen + WPF EmbedView; brand purple kept"
  ],
  "designAuditor": {
    "before": { "design": "C", "aiSlop": "B", "accessibility": "B" },
    "after": { "design": "B+", "aiSlop": "A-", "accessibility": "A-" }
  }
}
```

## Result 96

```json
{
  "part": 96,
  "status": "done",
  "verification": "flutter analyze embed_screen/app_strings: No issues found; WPF Desktop build 0 errors 0 warnings",
  "files": [
    "embed_screen.dart / app_strings.dart",
    "EmbedView.xaml / EmbedView.xaml.cs / AppStrings.cs",
    "readmehistory.md"
  ]
}
```

## Part 97 — Full-page busy overlay (block UI until process ends)

```json
{
  "promptSpecVersion": "1.1.0",
  "kind": "json-prompt",
  "part": 97,
  "title": "Full-viewport loading overlay during embed/extract",
  "request": "/ui-ux-pro-max باید لودینک روی کل صفحه باشد که تا پایان پروسس کاربر کاری انجام ندهد",
  "scope": [
    "Flutter HomeShell Stack + appBusyMessageProvider + AppBusyOverlay",
    "WPF MainWindow GlobalBusyOverlay + SetGlobalBusy from Embed/Extract",
    "Block tab/nav interaction while busy; Soft UI + brand purple spinner"
  ],
  "ux": {
    "antiPatternAvoided": "inline-only spinner while rest of UI remains interactive",
    "pattern": "modal scrim + centered status card; AbsorbPointer / IsHitTestVisible"
  }
}
```

## Result 97

```json
{
  "part": 97,
  "status": "done",
  "verification": "flutter analyze home_shell/busy_overlay/embed/extract: No issues found; WPF Desktop build 0 errors 0 warnings",
  "files": [
    "busy_overlay_provider.dart / app_busy_overlay.dart / home_shell.dart",
    "embed_screen.dart / extract_screen.dart",
    "MainWindow.xaml / MainWindow.xaml.cs",
    "EmbedView.xaml.cs / ExtractView.xaml.cs",
    "readmehistory.md"
  ]
}
```

## Part 98 — Save extracted: icon-only

```json
{
  "promptSpecVersion": "1.1.0",
  "kind": "json-prompt",
  "part": 98,
  "title": "Save extracted audio/image — icon only",
  "request": "آیکن ذخیره کفایت می کند",
  "scope": [
    "Extract primary Save CTA → IconButton/IconFilledButton + tooltip",
    "Embed recovered Save parity",
    "Keep Play with label; i18n strings remain for tooltip/dialogTitle"
  ]
}
```

## Result 98

```json
{
  "part": 98,
  "status": "done",
  "verification": "flutter analyze extract/embed: No issues found; WPF Desktop build 0 errors 0 warnings",
  "files": [
    "extract_screen.dart / embed_screen.dart",
    "ExtractView.xaml / ExtractView.xaml.cs",
    "EmbedView.xaml / EmbedView.xaml.cs",
    "readmehistory.md"
  ]
}
```

## Part 99 — Equalizer badges physical order

```json
{
  "promptSpecVersion": "1.1.0",
  "kind": "json-prompt",
  "part": 99,
  "title": "Equalizer header badges: intensity left, time right",
  "request": "زمان در سمت راست باشد و شدت صدا در سمت چپ",
  "scope": [
    "Force LTR badge row: volume% then duration",
    "Flutter audio_equalizer_view + WPF EqualizerControl"
  ]
}
```

## Result 99

```json
{
  "part": 99,
  "status": "done",
  "verification": "flutter analyze audio_equalizer_view: No issues found; WPF Desktop build 0 errors 0 warnings",
  "files": [
    "audio_equalizer_view.dart",
    "EqualizerControl.xaml.cs",
    "readmehistory.md"
  ]
}
```

## Part 100 — Embed results Soft UI delicate refine

```json
{
  "promptSpecVersion": "1.1.0",
  "kind": "json-prompt",
  "part": 100,
  "title": "Embed/Extract result panel — Soft UI delicate",
  "request": "/ui-ux-pro-max این بخش کمی ظریف تر شود",
  "scope": [
    "Icon toolbar CTAs; quiet section titles; softer banners/blocks",
    "Compact A/B listen + icon transport; icon content-compare actions",
    "Tokens: sectionGapResult/hero/block; Flutter + WPF parity; brand purple kept"
  ],
  "designSystem": "Soft UI Evolution (ui-ux-pro-max) — brand colors override pink suggestion"
}
```

## Result 100

```json
{
  "part": 100,
  "status": "done",
  "verification": "flutter analyze embed/extract/tokens: No issues found; WPF Desktop build 0 errors 0 warnings",
  "files": [
    "app_ui_tokens.dart / embed_screen.dart / extract_screen.dart",
    "EmbedView.xaml / EmbedView.xaml.cs",
    "readmehistory.md"
  ]
}
```

## Part 101 — Optimize web/app payload size

```json
{
  "promptSpecVersion": "1.1.0",
  "kind": "json-prompt",
  "part": 101,
  "title": "Reduce Flutter web and app asset size",
  "request": "حجم سایت و حجم اپلیکیشن زیاد است آن را بهینه کن",
  "scope": [
    "Font subset + icon compress + remove web/fonts",
    "tree-shake-icons; strip maps/symbols/skwasm/wimp from web output",
    "optimize_flutter_assets.py"
  ],
  "measured": {
    "buildWebBeforeMbApprox": 31,
    "buildWebAfterMb": 13.03,
    "bundledTtfAfterKb": 346
  }
}
```

## Result 101

```json
{
  "part": 101,
  "status": "done",
  "verification": "flutter build web --release --no-web-resources-cdn --tree-shake-icons OK; post-process WEB_TOTAL_MB=13.03; canvaskit-only retained",
  "files": [
    "assets/fonts/*.ttf / assets/branding/app_icon.png / web/icons",
    "pubspec.yaml / _flutter-web-no-cdn.ps1 / .gitignore",
    "scripts/optimize_flutter_assets.py / readmehistory.md"
  ]
}
```

## Part 102 — Equalizer badges + payload capacity progress

```json
{
  "promptSpecVersion": "1.1.0",
  "kind": "json-prompt",
  "part": 102,
  "title": "Equalizer volume/timer sides + secret-record capacity bar",
  "request": "شمارنده زمان راست · سطح صدا چپ · نوار ظرفیت هنگام ضبط صوت مخفی با تیک ظرفیت؛ بدون تیک حداقل زمان نسبت به نیاز نهان‌نگاری",
  "scope": [
    ".cursor/rules/equalizer-recording-capacity-ui.mdc",
    "Equalizer physical LTR badge layout",
    "Payload capacity progress + cover min dynamic bits"
  ]
}
```

## Result 102

```json
{
  "part": 102,
  "status": "done",
  "verification": "flutter analyze equalizer/embed/strings: No issues; WPF Desktop build succeeded",
  "files": [
    ".cursor/rules/equalizer-recording-capacity-ui.mdc",
    "audio_equalizer_view.dart / EqualizerControl.xaml.cs",
    "embed_screen.dart / EmbedView.xaml.cs",
    "app_strings.dart / AppStrings.cs / readmehistory.md"
  ]
}
```

## Part 103 — A/B Pause/Stop inside Play cards

```json
{
  "promptSpecVersion": "1.1.0",
  "kind": "json-prompt",
  "part": 103,
  "title": "A/B listen transport inside each Play card",
  "request": "دکمه های pause و stop در همان کادر هر play؛ تا play نشده مخفی؛ بعد از اتمام پخش مخفی",
  "scope": [
    ".cursor/rules/ab-listen-play-transport.mdc",
    "Flutter embed A/B panel",
    "WPF EmbedView AbListen cards"
  ]
}
```

## Result 103

```json
{
  "part": 103,
  "status": "done",
  "verification": "flutter analyze embed/playback: No issues; WPF Desktop build 0 errors 0 warnings",
  "files": [
    ".cursor/rules/ab-listen-play-transport.mdc",
    "embed_screen.dart / audio_player_io.dart / audio_player_web.dart / playback_hub.dart",
    "EmbedView.xaml / EmbedView.xaml.cs / readmehistory.md"
  ]
}
```

## Part 104 — Fix 140MB debug web Network bloat

```json
{
  "promptSpecVersion": "1.1.0",
  "kind": "json-prompt",
  "part": 104,
  "title": "Local web must serve release build/web not debug flutter run",
  "request": "140MB خیلی زیاده یک جا مشکل داری",
  "rootCause": "flutter run debug JIT (~1400 dart.lib.js); product build/web ~13MB",
  "scope": [
    "Start-KaraviFlutterWebStaticReleaseServer",
    "_run-all-local / _launch-dev-services",
    "flutter-web-release-default.mdc"
  ]
}
```

## Result 104

```json
{
  "part": 104,
  "status": "done",
  "verification": "static serve build/web HTTP 200; FULL_build_web_MB=13.03; dart_lib_js_count=0; MaterialIcons~16KB",
  "files": [
    "_flutter-web-no-cdn.ps1 / _run-all-local.ps1 / _launch-dev-services.ps1",
    ".cursor/rules/flutter-web-release-default.mdc / readmehistory.md"
  ]
}
```


## Part 104 - Colorful semantic icons (design-auditor)

```json
{
  "promptSpecVersion": "1.1.0",
  "kind": "json-prompt",
  "part": 104,
  "title": "Colorful semantic icons with soft glow",
  "request": "/design-auditor — make project icons colorful and give the app a special look",
  "designAuditor": {
    "design": "B+",
    "aiSlop": "A-",
    "accessibility": "B+",
    "notes": [
      "Finding: monochrome purple icons reduced scan hierarchy across nav/toolbar/About/actions",
      "Remediation: meaning-driven AppIconAccent palette (not rainbow decoration)",
      "Special effect: soft glow on FAB/hero/action fills; light+dark pairs",
      "Avoided AI-slop rainbow / purple-on-white gradient spam"
    ]
  },
  "touchedFiles": [
    "src/audio_stegano_app/lib/app/app_icon_accents.dart",
    "src/audio_stegano_app/lib/features/shared/accent_icon.dart",
    "src/audio_stegano_app/lib/features/shared/page_toolbar_fab.dart",
    "src/audio_stegano_app/lib/app/home_shell.dart",
    "src/audio_stegano_app/lib/features/about/about_screen.dart",
    "src/audio_stegano_app/lib/features/embed/embed_screen.dart",
    "src/audio_stegano_app/lib/features/extract/extract_screen.dart",
    "src/audio_stegano_app/lib/features/settings/settings_screen.dart",
    "src/audio_stegano_desktop/.../Themes/LightTheme.xaml",
    "src/audio_stegano_desktop/.../Themes/DarkTheme.xaml",
    "src/audio_stegano_desktop/.../Themes/SharedStyles.xaml",
    "src/audio_stegano_desktop/.../MainWindow.xaml.cs",
    "src/audio_stegano_desktop/.../Views/AboutView.xaml.cs",
    "src/audio_stegano_desktop/.../Views/EmbedView.xaml",
    "src/audio_stegano_desktop/.../Views/ExtractView.xaml"
  ]
}
```

## Result 104

```json
{
  "part": 104,
  "status": "done",
  "verification": "flutter analyze (touched files) clean; dotnet build AudioStegano.Desktop Debug 0 warnings/errors; semantic accents light/dark; Flutter+WPF parity for nav/About/actions/FABs",
  "remaining": "none"
}
```

## Part 105 — Fix stuck Loading (chromium CanvasKit 404)

```json
{
  "promptSpecVersion": "1.1.0",
  "kind": "json-prompt",
  "part": 105,
  "title": "Keep canvaskit/chromium for Chrome boot",
  "request": "صفحه لود نمی شود",
  "rootCause": "Remove-KaraviFlutterWebDebugArtifacts deleted canvaskit/chromium; flutter_bootstrap prefers chromium/canvaskit.js → 404 → stuck splash",
  "scope": [
    "_flutter-web-no-cdn.ps1 (keep chromium + assert)",
    "flutter-web-release-default.mdc",
    "rebuild + static serve 5320"
  ]
}
```

## Result 105

```json
{
  "part": 105,
  "status": "done",
  "verification": "chromium/canvaskit.js+wasm HTTP 200; browser past splash to Embed UI; post-process keeps chromium; Assert fails if chromium missing",
  "files": [
    "_flutter-web-no-cdn.ps1",
    ".cursor/rules/flutter-web-release-default.mdc",
    "readmehistory.md"
  ]
}
```

## Part 105 - Fix Flutter web woff2 404 spam

```json
{
  "promptSpecVersion": "1.1.0",
  "kind": "json-prompt",
  "part": 105,
  "title": "Neutralize CanvasKit font-fallback CDN without local woff2 404",
  "request": "Screenshot: Network flooded with .woff2 404 from main.dart.js",
  "rootCause": "Repair rewrote fonts.gstatic.com/s/ to assets/fonts/ but no Noto Color Emoji woff2 shipped; CanvasKit fallback requested hundreds of fake local paths",
  "fix": "Rewrite font CDN base to about:invalid#karavi-offline-fonts/ (zero CDN + no local 404); idempotent replace of prior assets/fonts/ base; keep pubspec Roboto+Noto TTF",
  "touchedFiles": ["_flutter-web-no-cdn.ps1"]
}
```

## Result 105

```json
{
  "part": 105,
  "status": "done",
  "verification": "Post-process patched main.dart.js (about:invalid base); Assert no gstatic; web restarted HTTP 200 on :5320; prior assets/fonts/ fallback base gone",
  "remaining": "Hard-refresh browser (Ctrl+Shift+R) to clear cached main.dart.js"
}
```

## Part 106 — Hide embed input after stego (SSOT)

```json
{
  "promptSpecVersion": "1.1.0",
  "kind": "json-prompt",
  "part": 106,
  "title": "Hide payload/record after successful embed until New",
  "request": "بعد از نهان نگاری بخش بالا مخفی نشد؛ با دکمه جدید ظاهر شود و نتایج قبلی مخفی",
  "rootCause": "Separate _embedInputHidden flag could desync from _stego (e.g. pick-image reset); UI must key off result presence",
  "fix": "Getter SSOT: hide input when _stego != null (embed) / extracted payloads (extract); WPF collapse AudioSourceCard with EmbedInputPanel",
  "touchedFiles": [
    "src/audio_stegano_app/lib/features/embed/embed_screen.dart",
    "src/audio_stegano_app/lib/features/extract/extract_screen.dart",
    "src/audio_stegano_desktop/.../Views/EmbedView.xaml.cs",
    "readmehistory.md"
  ]
}
```

## Result 106

```json
{
  "part": 106,
  "status": "done",
  "verification": "flutter analyze embed+extract clean; WPF Debug build 0 warnings/errors; web rebuild+static :5320 HTTP 200; input gated on _stego == null; New clears stego",
  "remaining": "Hard-refresh browser (Ctrl+Shift+R)"
}
```
