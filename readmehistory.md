# Read Me History

تاریخچه تمامی تغییرات اعمال شده روی پروژه به ترتیب زمانی.

| تاریخ | ساعت | Part | تغییر | فایل/مسیر |
|---|---|---|---|---|
| 2026-05-07 | 13:21 | 1 | ساخت پروژه Flutter چندسکویی | `audio_steg_app/` |
| 2026-05-07 | 13:23 | 1 | افزودن 94 dependency (riverpod, record, just_audio, file_picker, ...) | `audio_steg_app/pubspec.yaml` |
| 2026-05-07 | 13:24 | 1 | ساخت اسکفولد پوشه‌های Clean Architecture | `audio_steg_app/lib/{app,core,features,l10n}` |
| 2026-05-07 | 13:25 | 1 | ایجاد `Cursor.01.plan.md` و `readmehistory.md` | ریشه workspace |
| 2026-05-07 | 13:27 | 2 | پورت LogisticMap از متلب + تست (۹/۹ سبز) | `core/crypto/logistic_map.dart`, `test/core/logistic_map_test.dart` |
| 2026-05-07 | 13:32 | 3 | پیاده‌سازی WavIO، TextCodec، LsbCodec، Metrics + تست (۸/۸ سبز) | `core/audio/wav_io.dart`, `core/text/text_codec.dart`, `core/stego/lsb_codec.dart`, `core/stego/metrics.dart`, `test/core/lsb_codec_test.dart` |
| 2026-05-07 | 13:39 | 4 | پیاده‌سازی FSK codec با Hamming + CRC + chirp preamble؛ رفع باگ همگام‌سازی با جستجوی دومرحله‌ای؛ تست (۵/۵ سبز) | `core/stego/fsk_codec.dart`, `test/core/fsk_codec_test.dart` |
| 2026-05-07 | 13:42 | 5 | StegoEngine (Strategy)، AudioRecorder، AudioPlayer، PcmBuffer + تست auto-detect (۲۶/۲۶ کل) | `core/stego/stego_engine.dart`, `core/audio/audio_recorder.dart`, `core/audio/audio_player.dart`, `core/audio/pcm_buffer.dart` |
| 2026-05-07 | 13:44 | 6,7,8 | UI کامل: Embed/Extract/Settings + ویجت‌های مشترک + i18n FA/EN + تم روز/شب + RTL خودکار + HomeShell پاسخگو (NavBar/Rail) | `lib/features/**`, `lib/app/**`, `lib/main.dart` |
| 2026-05-07 | 13:45 | 8 | افزودن مجوز RECORD_AUDIO به AndroidManifest | `android/app/src/main/AndroidManifest.xml` |
| 2026-05-07 | 13:46 | 9 | اصلاح API جدید file_picker 11 (استاتیک)؛ رفع لینت use_build_context_synchronously؛ analyze=۰ | `features/embed/embed_screen.dart`, `features/extract/extract_screen.dart` |
| 2026-05-07 | 13:46 | 9 | بیلد موفق Windows release (~۳۴۷ ثانیه) | `build/windows/x64/runner/Release/audio_steg_app.exe` |
| 2026-05-07 | 13:46 | 9 | اجرای موفق پروسس Windows (Responding=True, pid ثبت شد) | `audio_steg_app/logs/app.pid` |
| 2026-05-07 | 13:46 | 9 | اسکریپت‌های `run_all.ps1` و `restart_all.ps1` طبق قانون کاربر | `scripts/run_all.ps1`, `scripts/restart_all.ps1` |
| 2026-05-07 | 13:48 | 9 | تلاش بیلد Android — مسدود به دلیل محدودیت شبکه میزبان (DNS aliyun, 403 googleapis) — مستندسازی شد | لاگ: `audio_steg_app/logs/gradle.log` |
| 2026-05-07 | 13:48 | 10 | تکمیل Result های همه Partها در پلن و تاریخچه | `Cursor.01.plan.md`, `readmehistory.md` |
| 2026-05-07 | 14:30 | post | افزودن `.gitignore` جامع در ریشه workspace (Flutter/Android/Windows/Linux/iOS/macOS/MATLAB/IDE/secrets/logs) | `.gitignore` |
| 2026-05-07 | 14:32 | post | بازنویسی `AudioRecorderService` با state machine (`RecorderState`)، mutex داخلی (`_runExclusive`) برای جلوگیری از race، broadcast `stateStream`، rollback ایمن در شکست start، و delete امن فایل tmp | `core/audio/audio_recorder.dart` |
| 2026-05-07 | 14:33 | post | افزودن `StegoRunner` با `compute()` برای اجرای embed/extract روی isolate جداگانه (UI thread freeze نمی‌شود) | `core/stego/stego_runner.dart` |
| 2026-05-07 | 14:34 | post | بازنویسی `EmbedScreen` و `ExtractScreen` با الگوی صحیح async: گارد سنکرون `_busy`، کنسل `ampSub` پیش از stop، چک `mounted` پس از هر await، capture `ScaffoldMessenger` پیش از await، استفاده از `StegoRunner` | `features/embed/embed_screen.dart`, `features/extract/extract_screen.dart` |
| 2026-05-07 | 14:35 | post | تست `async_safety_test.dart` برای mutex (سری‌سازی، release on throw، no-deadlock) — ۳/۳ سبز | `test/core/async_safety_test.dart` |
| 2026-05-07 | 14:38 | post | بیلد و restart ویندوز پس از بازآرایی async — pid=57040 responding=True، تست کل ۲۹/۲۹ | `build/windows/x64/runner/Release/audio_steg_app.exe` |
| 2026-05-07 | 14:43 | post | تجمیع همه توابع/متدهای نهان‌نگاری در `lib/core/stego/{crypto,text,codecs,engine,metrics}` با barrel `stego.dart`؛ حذف فولدرهای پراکنده `core/crypto/` و `core/text/`؛ به‌روزرسانی importها در صفحات و تست‌ها | `lib/core/stego/**`, `lib/features/**`, `test/core/**` |
| 2026-05-07 | 14:45 | post | بیلد و restart پس از بازآرایی فولدر — pid=47908 responding=True، analyze=۰، تست ۲۹/۲۹ | `build/windows/x64/runner/Release/audio_steg_app.exe` |
| 2026-05-07 | 14:55 | bugfix | **رفع کرش روی Stop ضبط در ویندوز.** علت: AudioEncoder.wav در record_windows.cpp در hot path stop باعث native termination می‌شد. راه‌حل: مهاجرت به `startStream(pcm16bits)` — بایت‌های raw را در `BytesBuilder` جمع و خودمان WAV می‌سازیم. هیچ تماس native با file I/O نمی‌رود. کاهش قابل توجه احتمال crash. | `core/audio/audio_recorder.dart` |
| 2026-05-07 | 14:55 | bugfix | افزودن `runZonedGuarded` + `FlutterError.onError` در `main.dart` تا هیچ uncaught exception پنجره را silent ببندد | `lib/main.dart` |
| 2026-05-07 | 14:55 | bugfix | RMS dBFS estimator روی Dart side (به‌جای پلاگین `onAmplitudeChanged` که روی Windows ناپایدار است) | `core/audio/audio_recorder.dart` |
| 2026-05-07 | 14:57 | bugfix | بیلد + restart پس از پایدارسازی ضبط — pid=45372 responding=True، analyze=۰، تست ۲۹/۲۹ | `build/windows/x64/runner/Release/audio_steg_app.exe` |
| 2026-05-07 | 15:05 | bugfix | **رفع کامل crash بعد از Stop ضبط.** ریشه‌یابی شد: `record_windows-1.0.7/windows/record.cpp` خط ۲۴۹ یک use-after-free دارد — `SafeRelease(m_pReader)` می‌تواند با callback `OnReadSample` در حال اجرا روی thread Media Foundation race کند، نتیجه access violation که هیچ Dart try/catch/runZonedGuarded نمی‌تواند بگیرد. **راه‌حل**: هرگز `recorder.stop()` یا `recorder.dispose()` صدا نمی‌زنیم. هر session یک `AudioRecorder` تازه می‌گیرد، در stop فقط Dart-side reference را drop و subscription را cancel می‌کنیم (که فقط EventChannel listener را unregister می‌کند، ایمن). native session با اتمام پروسس garbage collect می‌شود. trade-off: چند MB leak per session در مقابل صفر crash. | `core/audio/audio_recorder.dart` |
| 2026-05-07 | 15:08 | bugfix | بیلد + restart پس از fix قطعی — pid=27892 responding=True، analyze=۰ | `build/windows/x64/runner/Release/audio_steg_app.exe` |
| 2026-05-07 | 15:30 | 11 | افزودن `EmbedRunResult` غنی به `StegoRunner` با bitsEmbedded/capacityBits/snrDb/psnrDb (isolate-safe) | `core/stego/engine/stego_runner.dart` |
| 2026-05-07 | 15:31 | 11 | گسترش `EmbedOutcome` و `StegoEngine` برای محاسبه SNR/PSNR در هر دو مد (Digital+OTA با pad/trim کاور) و گزارش bitsEmbedded/capacityBits | `core/stego/engine/stego_engine.dart` |
| 2026-05-07 | 15:32 | 11 | افزودن کارت متریک‌های ارزیابی نهان‌نگاری در صفحه Embed (۶ chip: Duration/Bits/Capacity/Utilization/SNR/PSNR با tabular figures) | `features/embed/embed_screen.dart` |
| 2026-05-07 | 15:33 | 11 | افزودن دکمه Verify (روند-ترایپ) با banner سبز/قرمز برای تأیید فوری صحت embed بدون ذخیره فایل | `features/embed/embed_screen.dart` |
| 2026-05-07 | 15:34 | 11 | افزودن گارد ظرفیت Pre-flight برای LSB قبل از فراخوانی codec (پیام واضح به‌جای ArgumentError) | `features/embed/embed_screen.dart` |
| 2026-05-07 | 15:35 | 11 | افزودن دکمه Info در AppBar با `showAboutDialog` Material 3 (gradient logo، نسخه، مولف، الگوریتم، thesis) | `lib/app/home_shell.dart` |
| 2026-05-07 | 15:36 | 11 | افزودن ۱۴ کلید i18n فا/EN: qualityMetrics, utilization, verify*, about* و close | `lib/app/app_strings.dart` |
| 2026-05-07 | 15:37 | 11 | افزودن تست `reports bitsEmbedded, capacityBits, and SNR metrics` (SNR>40dB روی سینوس) | `test/core/stego_engine_test.dart` |
| 2026-05-07 | 15:38 | 11 | مقاوم‌سازی `restart_all.ps1` با parser-safe formatting و cleanup پروسس‌های یتیم | `scripts/restart_all.ps1` |
| 2026-05-07 | 15:40 | 11 | بیلد و restart پس از Part 11 — pid=57372 responding=True، analyze=۰، تست ۳۰/۳۰ سبز | `build/windows/x64/runner/Release/audio_steg_app.exe` |
