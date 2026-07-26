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
