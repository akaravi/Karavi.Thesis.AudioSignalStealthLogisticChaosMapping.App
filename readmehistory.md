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
| 2026-05-07 | 15:18 | run-all | اجرای کامل دستور `run all` طبق قانون کاربر (debug→build→run→list→health→logs)؛ analyze=۰، تست ۳۰/۳۰، بیلد ۳۹s، pid=43900 alive | `logs/{analyze,test,build,app.std*}.log` |
| 2026-05-07 | 15:22 | run-all | جایگزینی `IndexedStack` با `Stack(Offstage+TickerMode)` در `home_shell.dart` برای حذف warning AXTree و حفظ state تب‌ها | `lib/app/home_shell.dart` |
| 2026-05-07 | 15:24 | run-all | تأیید با web search: warning `AXTree error 19` یک باگ شناخته‌شده upstream Flutter engine (issue #98099, #98778, #103808) از Tooltip overlay است — benign، فقط یک‌بار در startup، رفتار اپ تأثیر نمی‌پذیرد | اسناد |
| 2026-05-07 | 15:25 | run-all | بیلد و restart نهایی — pid=52176 responding=True، stderr فقط ۱ خط (warning upstream)، CPU idle (1.05s/16s)، حافظه ثابت ۸۹.۵MB | `build/windows/x64/runner/Release/audio_steg_app.exe` |
| 2026-05-18 | 06:40 | 12 | حذف کامل روش FSK (Over-the-Air BFSK + Hamming + CRC) — فقط روش LSB + Logistic-Chaos (MATLAB port) باقی ماند | `core/stego/codecs/fsk_codec.dart` (deleted) |
| 2026-05-18 | 06:40 | 12 | حذف تست FSK | `test/core/fsk_codec_test.dart` (deleted) |
| 2026-05-18 | 06:40 | 12 | حذف ویجت mode switch | `features/shared/mode_switch.dart` (deleted) |
| 2026-05-18 | 06:41 | 12 | ساده‌سازی StegoEngine — حذف StegoMode enum و منطق OTA | `core/stego/engine/stego_engine.dart` |
| 2026-05-18 | 06:41 | 12 | ساده‌سازی StegoRunner — حذف پارامتر mode | `core/stego/engine/stego_runner.dart` |
| 2026-05-18 | 06:42 | 12 | ساده‌سازی embed_screen — حذف StegoModeSwitch | `features/embed/embed_screen.dart` |
| 2026-05-18 | 06:42 | 12 | ساده‌سازی extract_screen — حذف تب میکروفن (فقط file extraction) | `features/extract/extract_screen.dart` |
| 2026-05-18 | 06:43 | 12 | حذف رشته‌های i18n مربوط به FSK و به‌روزرسانی عنوان اپ | `lib/app/app_strings.dart` |
| 2026-05-18 | 06:43 | 12 | به‌روزرسانی تست engine — فقط LSB + تست wrong-key | `test/core/stego_engine_test.dart` |
| 2026-05-18 | 07:10 | 13 | هم‌ترازی کامل با ۵ فایل متلب: حذف TextCodec (هدر ۳۲بیت)، extract با msg_len، NPCR/UACI/BER در metrics | `core/stego/*` |
| 2026-05-18 | 07:11 | 13 | صفحه Extract: ورودی طول پیام (بیت) مطابق main_steganography.m | `features/extract/extract_screen.dart` |
| 2026-05-18 | 07:12 | 13 | StegoEngine: جریان embed+evaluate با کلید متمایز برای NPCR/UACI | `core/stego/engine/stego_engine.dart` |
| 2026-05-18 | 07:30 | 14 | انتقال هستهٔ watermarking به فایل واحد `audio_watermarking.dart` | `lib/core/stego/audio_watermarking.dart` |
| 2026-05-18 | 07:31 | 14 | فایل‌های قدیمی فقط re-export می‌کنند؛ API اصلی: `AudioWatermarking` | `stego.dart`, `lsb_codec.dart`, ... |
| 2026-05-18 | 10:15 | 15 | ساخت solution دسکتاپ .NET 10: Core (watermarking+WAV), Desktop (WPF), Tests (xUnit) | `audio_steg_desktop/` |
| 2026-05-18 | 10:16 | 15 | UI WPF: EmbedView (ضبط/embed/متریک/verify)، ExtractView (WAV+msg_len)، SettingsView (تم/زبان/r/x0) | `src/AudioSteg.Desktop/Views/` |
| 2026-05-18 | 10:17 | 15 | بیلد و تست: `dotnet build` ۰ خطا؛ `dotnet test` ۴/۴ Passed | `AudioSteg.sln` |
| 2026-05-18 | 11:00 | 16 | انتقال پروژه‌ها به `src/`: Flutter، .NET Desktop، Matlab | `src/audio_steg_app`, `src/audio_steg_desktop`, `src/Matlab` |
| 2026-05-18 | 11:01 | 16 | افزودن `README.md` ریشه با نقشه مخزن؛ حذف `lib/` orphan ریشه | `README.md` |
| 2026-05-18 | 11:35 | fix | رفع خطای cross-thread در EmbedView (خواندن MessageTextBox از Task.Run) | `Views/EmbedView.xaml.cs` |
| 2026-05-18 | 12:00 | ui | هم‌ترازی UI دسکتاپ با Flutter: Material3، ناوبری پایین/ریل، دکمه ضبط دایره‌ای، موج‌نما، چیپ متریک | `Themes/*`, `Controls/*`, `Views/*`, `MainWindow.*` |
| 2026-05-18 | 12:20 | feat | پشتیبانی MP3 در استخراج/ذخیره دیالوگ دسکتاپ — `AudioInputLoader` + NAudio | `AudioSteg.Core/Audio/AudioInputLoader.cs` |
| 2026-05-18 | 08:30 | monitor | لاگ فایل Flutter (`SessionLog`) + `monitor_flutter.ps1` + `flutter run -v` به `logs/flutter_run_monitor.log` برای پایش کرش هنگام تست | `lib/app/session_log.dart`, `scripts/monitor_flutter.ps1`, `logs/*` |
| 2026-05-18 | 08:40 | bugfix | کرش native ویندوز (`Lost connection`، بدون Dart error): `ExcludeSemantics` سراسری Win + تب‌های Offstage + موج‌نما؛ throttle setState موج‌نما ۸۰ms؛ لاگ مسیر ضبط/embed | `main.dart`, `home_shell.dart`, `waveform_view.dart`, `embed_screen.dart` |
| 2026-05-18 | 09:00 | ui | نمودار مقایسه cover/stego در صفحه نهان‌نگاری (دو رنگ، خط پیوسته/خط‌چین) — Flutter + WPF | `dual_waveform_chart.dart`, `DualWaveformControl`, `EmbedView`, `embed_screen.dart` |
| 2026-05-18 | 09:20 | feat | نام فایل ذخیره `stego_YYYY_MM_DD_HHMM_{msg_len}.wav`؛ خواندن WAV+MP3 در Flutter (FFmpeg) و دسکتاپ (NAudio) | `StegoFileNaming`, `audio_input_loader.dart`, embed/extract screens |
| 2026-05-18 | 09:45 | ui | اکولایزر ۳۲ باندی زنده هنگام ضبط (FFT) و پخش (timeline) — Flutter + WPF | `SpectrumAnalyzer`, `AudioEqualizerView`, `EqualizerControl`, embed views |
| 2026-05-18 | 10:00 | feat | دکمه «بارگذاری فایل صوتی» کنار ضبط در Embed — WAV/MP3 به‌جای ضبط زنده | `embed_screen.dart`, `EmbedView` |
| 2026-05-18 | 10:30 | fix | اکولایزر Flutter: نمایش واضح‌تر + بیلد مجدد؛ اسکریپت junction برای ویندوز بدون Developer Mode | `audio_equalizer_view.dart`, `ensure_windows_plugin_junctions.ps1` |
| 2026-05-18 | 14:10 | build | اسکریپت تجمیعی `_build-all-projects.ps1` (ریشه مخزن): restore/build/test/publish دسکتاپ، Flutter analyze/test/build windows، ZIP استقرار، ترمینال‌های dev اختیاری؛ آینه‌ی pub و retry مشابه Milad Tools | `_build-all-projects.ps1` |
| 2026-05-18 | 14:25 | build | پرسیدن مسیر ذخیره ZIP با `Read-Host` (مثل Milad Tools)؛ حذف پیش‌فرض خودکار `publish\releases` | `_build-all-projects.ps1` |
| 2026-05-18 | 14:40 | build | `flutter build web --release` در `_build-all-projects.ps1`؛ پوشه `audio_steg_app_web` در ZIP؛ افزودن پلتفرم web به Flutter (`web/index.html`, …) | `_build-all-projects.ps1`, `src/audio_steg_app/web/` |
| 2026-05-18 | 15:05 | fix | رفع شکست `flutter analyze` در بیلد: حذف `test/widget_test.dart` پیش‌فرض (ارجاع به `MyApp`)؛ حذف import اضافی `dart:typed_data` در `audio_player.dart` | `test/widget_test.dart`, `lib/core/audio/audio_player.dart` |
| 2026-05-18 | 15:35 | fix | رفع صفحه سفید Flutter Web: حذف `dart:io`/`Platform` از مسیر وب؛ import شرطی session_log، audio_player، audio_input_loader، native_file؛ `isNativeWindows` در main؛ `-WebBaseHref` در اسکریپت بیلد | `lib/**`, `web/index.html`, `_build-all-projects.ps1` |
| 2026-05-18 | 09:30 | fix | رفع نمایش زودهنگام «چیزی استخراج نشد» در تب رمزگشایی هنگام کلیک انتخاب فایل قبل از picker؛ اعتبارسنجی طول بیت در فیلد ورودی | `features/extract/extract_screen.dart` |
| 2026-05-18 | 10:17 | gitignore | تکمیل `.gitignore` ریشه: افزودن بخش .NET/C#/WPF (bin/, obj/, publish/, *.user, *.suo, _wpftmp, NuGet, Rider/ReSharper)؛ حذف فایل‌های ساختنی از ایندکس git با `git rm --cached` | `.gitignore` |
| 2026-05-18 | 20:15 | fix | رفع `MissingPluginException` برای ffmpeg_kit روی Windows: حذف `ffmpeg_kit_flutter`؛ MP3 با `audio_decoder` (Media Foundation / API بومی) | `pubspec.yaml`, `audio_input_loader_io.dart` |
| 2026-05-18 | 20:25 | fix | پشتیبانی MP3 در وب: `audio_input_loader_web.dart` + `audio_mp3_decoder.dart` (Web Audio API) | `lib/core/audio/` |
| 2026-05-18 | 20:35 | ui | کنترل پخش: هنگام play غیرفعال؛ pause و stop فعال — Flutter + WPF | `embed_screen.dart`, `EmbedView`, `AudioPlaybackService`, `audio_player_*.dart` |
| 2026-05-18 | 20:45 | ui | پاپ‌آپ پس از embed: نمایش msg_len (بیت) + هشدار ذخیره برای بازیابی + دکمه کپی — Flutter dialog + `RecoveryBitsDialog` WPF | `embed_screen.dart`, `Dialogs/RecoveryBitsDialog.*`, `AppStrings` |
| 2026-05-18 | 21:10 | ui | بازطراحی پنل «ضبط / بارگذاری»: دکمه‌های دایره‌ای هم‌اندازه، گرادیان، سایه، جداکننده «یا»، پس‌زمینه کارت — Flutter | `circle_action_button.dart`, `record_button.dart`, `embed_screen.dart`, `app_strings.dart` |
| 2026-05-18 | 21:25 | fix | رفع اسکرول موبایل: `TabScrollBody` (کیبورد، physics)، `Positioned.fill` تب‌ها، `NeverScrollableScrollPhysics` روی TextField، CSS وب | `tab_scroll_body.dart`, `home_shell.dart`, embed/extract/settings, `web/index.html` |
| 2026-05-19 | — | settings | تنظیم «نمایش بازگردانی پس از نهان‌نگاری» — Flutter (SharedPreferences) + WPF (`appsettings.json` + `settings.json`) | `settings_controller.dart`, `settings_screen.dart`, `embed_screen.dart`, `AppState.cs`, `appsettings.json` |
| 2026-05-19 | — | ui | بنر تأیید فوری زیر دکمه‌ها و بالای مشخصات؛ فعال‌سازی Play پس از پایان پخش — Flutter + WPF | `embed_screen.dart`, `audio_player_*.dart`, `EmbedView.*`, `AudioPlaybackService.cs` |
| 2026-05-19 | 16:40 | run | اجرای مجدد Flutter روی وب: `flutter run -d chrome --web-port=8080` — HTTP 200 | `logs/flutter_web_run.log` |
| 2026-05-19 | 16:30 | run-all | اجرای پروژه‌ها برای بررسی: dotnet 5/5 تست، flutter 24/24 تست، WPF pid + Flutter Release exe؛ analyze پس از حذف import اضافی | `logs/*`, `audio_player_io.dart` |
| 2026-05-19 | — | ui | به‌روزرسانی متن پاپ‌آپ پس از نهان‌نگاری: «برای بازیابی عبارت نهانگاری‌شده عدد طول پیام را یادداشت فرمایید» + عدد با آیکن کپی — Flutter و WPF | `app_strings.dart`, `AppStrings.cs`, `embed_screen.dart`, `RecoveryBitsDialog.*` |
| 2026-05-19 | — | ui | دکمه بارگذاری مربع (گوشه‌گرد) + برچسب «بارگذاری فایل» + آیکن upload — Flutter `ActionButtonShape.roundedSquare`، WPF `LoadFileButtonControl` | `circle_action_button.dart`, `LoadFileButtonControl.*`, `EmbedView.*`, `app_strings` |
| 2026-05-19 | — | ui | دکمه‌های عملیاتی (پخش/ذخیره/تأیید/…) بالای کارت موج‌نما و متریک کیفیت — Flutter + WPF Embed | `embed_screen.dart`, `EmbedView.xaml` |
| 2026-05-19 | — | theme | رنگ برند پروژه `#00B4B7` — Flutter seed، پالت WPF، manifest وب | `settings_controller.dart`, `LightTheme.xaml`, `DarkTheme.xaml`, `AppState.cs`, `manifest.json` |
| 2026-05-19 | — | feat | تب «درباره ما»: معرفی، GitHub، alikaravi.com، ntk.ir، تلفن‌ها — Flutter + WPF | `about_screen.dart`, `AboutView.*`, `home_shell.dart`, `MainWindow.*`, `url_launcher` |
| 2026-05-19 | — | feat | Flutter: دو اسپلش انیمیشنی صوتی/نهان‌نگاری؛ انتخاب یک‌باره زبان؛ استاد راهنما در درباره ما | `splash_flow_screen.dart`, `language_onboarding_screen.dart`, `app_bootstrap.dart`, `settings_controller.dart` |
| 2026-05-19 | — | ui | اکولایزر مدرن: میله گرادیان رنگی، متر سطح صدا، درصد peak، خطوط شبکه — Flutter + WPF | `audio_equalizer_view.dart`, `EqualizerControl.*`, `AppStrings` |
| 2026-05-19 | 17:15 | run-all | دیباگ/تست: dotnet build+5/5، flutter analyze صفر، flutter test 24/24؛ WPF در حال اجرا؛ Flutter Web localhost:8080 HTTP 200؛ Windows native مسدود symlink/Developer Mode | `logs/*`, `Cursor.01.plan.md` Part 25 |
| 2026-05-19 | 18:00 | ui+feat | کنتراست تم: AppBar/کارت نتیجه/دکمه‌ها با توکن‌های semantic؛ پارامتر r و x0 با ورود دستی + اسلایدر و محدودیت بازه — Flutter + WPF | `app_theme.dart`, `embed_screen.dart`, `logistic_param_field.dart`, `SettingsView.*`, `LogisticParamBounds.*` |
| 2026-05-19 | 18:20 | ui | تب درباره ما: کارت جداگانه «استاد راهنما» بالای پیوندها (هم‌سبک تماس) — Flutter + WPF | `about_screen.dart`, `AboutView.*`, `app_strings` |
| 2026-05-19 | 18:35 | ui | دکمه‌های پخش/مکث/توقف: فقط آیکن + Tooltip — Flutter + WPF Embed | `embed_screen.dart`, `EmbedView.*`, `SharedStyles.xaml` |
| 2026-05-19 | 19:00 | ui | زمان ضبط (mm:ss) کنار درصد سطح صدا بالای اکولایزر هنگام رکورد — Flutter + WPF | `audio_equalizer_view.dart`, `embed_screen.dart`, `EqualizerControl.*`, `EmbedView.xaml.cs` |
| 2026-05-19 | 19:30 | feat | اسپلش راهنمای کاربری یک‌بار پس از انتخاب زبان (کاربرد + مراحل نهان‌نگاری/رمزگشایی/تنظیمات) | `usage_guide_splash_screen.dart`, `app_bootstrap.dart`, `settings_controller.dart`, `app_strings.dart` |
| 2026-05-19 | 20:00 | i18n | افزودن زبان عربی (ar) و فرانسوی (fr) — Flutter + WPF؛ RTL برای fa/ar | `app_locale.dart`, `app_strings.dart`, `language_onboarding_screen.dart`, `AppStrings.cs`, `AppLanguage` |
| 2026-05-19 | 20:45 | git | رفع .gitignore: حذف ۲۶۰ فایل `bin/`/`obj/` از index (از جمله `AudioSteg.Desktop.dll`)؛ تقویت الگوهای `*.dll`/`*.pdb` | `.gitignore`, `git rm --cached` |
| 2026-05-19 | 21:10 | reset-all | توقف dart/chrome؛ بیلد dotnet+flutter؛ WPF و Flutter Web مجدد؛ health :8080=200؛ Windows native مسدود symlink | `logs/*`, `Cursor.01.plan.md` Part 29 |
| 2026-05-19 | 21:25 | feat | ترتیب onboarding: اسپلش اصلی (SplashFlow) قبل از انتخاب زبان؛ راهنمای کاربری بعد از زبان | `app_bootstrap.dart`, `Cursor.01.plan.md` Part 30 |
| 2026-05-19 | 22:00 | ui | صفحه رمزگشایی: پخش/مکث/توقف در یک ردیف با انتخاب فایل (پس از بارگذاری)؛ دکمه جدا برای استخراج — Flutter + WPF | `extract_screen.dart`, `ExtractView.*`, `app_strings`, `AppStrings.cs` |
| 2026-05-19 | 22:30 | build | اسکریپت `_build-flutter-web.ps1`: فقط Flutter `build web --release`، کپی به `publish\flutter\web`، ZIP اختیاری، dev server (chrome/edge/web-server) | `_build-flutter-web.ps1` |
| 2026-05-19 | 23:00 | branding | نام محصول: «نهان‌نگاری پیام در صوت» / Audio Steganography؛ کوتاه «صوت‌نهان» / AudioSteg — Flutter، WPF، PWA manifest، وب | `app_strings.dart`, `AppStrings.cs`, `manifest.json`, `index.html` |
| 2026-05-19 | 23:30 | feat | Flutter Embed: دکمه اشتراک‌گذاری کنار ذخیره (فایل WAV) و کنار کپی در دیالوگ طول پیام — `share_plus` | `embed_screen.dart`, `stego_share.dart`, `app_strings.dart` |
| 2026-05-19 | 23:45 | fix | حذف `share` تکراری در `app_strings.dart`؛ پرسش مسیر ZIP در ابتدای `_build-flutter-web.ps1` | `app_strings.dart`, `_build-flutter-web.ps1` |
| 2026-05-19 | 24:15 | config | تنظیمات استقرار embed: Flutter `assets/app-config.json`؛ WPF `appsettings.json` کنار exe — `ShowEmbedLoadFileButton`, `ShowEmbedRecoveryDialog` | `AppConfig.cs`, `appsettings.json`, `app_config.dart`, `EmbedView.*`, `embed_screen.dart` |
| 2026-05-19 | 24:30 | config | WPF: حذف `app-config.json` دسکتاپ؛ فقط `appsettings.json` (کنوانسیون .NET) | `AppConfig.cs`, `appsettings.json`, `AudioSteg.Desktop.csproj` |
| 2026-05-19 | 24:45 | build | رفع `flutter pub get` exit 69: آینه Tsinghua پس از flutter-io.cn؛ نادیده symlink اگر پکیج‌ها resolve شدند؛ حذف `test` تکراری از pubspec | `_build-flutter-web.ps1`, `_build-all-projects.ps1`, `pubspec.yaml` |
| 2026-05-19 | 25:00 | rule | قانون پروژه: ممنوعیت CDN برای فونت/CSS/JS در زمان اجرا — دارایی‌ها فقط از داخل repo | `.cursor/rules/no-external-cdn-assets.mdc`, `Cursor.01.plan.md` Part 36 |
| 2026-05-19 | 25:30 | fix | رفع دکمه اشتراک‌گذاری: فایل WAV موقت روی دسکتاپ؛ وب → دانلود؛ متن → کلیپبورد | `stego_share.dart`, `wav_xfile*.dart`, `embed_screen.dart`, `app_strings.dart` |
| 2026-05-19 | 26:00 | build | اسکریپت `_build-android-web.ps1` (قدیمی): بیلد APK/AAB اندروید + وب — جایگزین شد | — |
| 2026-05-19 | 19:54 | fix | بیلد اندروید: URL صحیح `download.flutter.io/` (بدون `/maven2/`) + `settingsEvaluated` برای آینه Aliyun؛ خروجی در `D:\PublishKaravi\ThesisAudioSteg` | `android/settings.gradle.kts`, `android/build.gradle.kts` |
| 2026-05-19 | 22:00 | build | تغییر نام و محدودسازی: `_build-flutter-android.ps1` — فقط Android (APK/AAB)، بدون وب؛ ZIP `KaraviThesis_AudioSteg_Android_*` | `_build-flutter-android.ps1` (حذف `_build-android-web.ps1`) |
| 2026-05-19 | 24:00 | build | `_build-flutter-android.ps1`: نام APK/AAB با ورژن pubspec — مثلاً `AudioSteg_1.0.0_1.apk`؛ ZIP هم شامل ورژن | `_build-flutter-android.ps1` |
| 2026-05-19 | 23:00 | feat | نسخه برنامه `1.0.0+1`: Flutter اسپلش اول + درباره (`package_info_plus`)؛ WPF درباره (`InformationalVersion` در csproj) | `pubspec.yaml`, `app_version.dart`, `splash_flow_screen.dart`, `about_screen.dart`, `AboutView.*`, `AppVersion.cs` |
| 2026-05-19 | 23:30 | ui | عکس پروفایل در کادر کنار نام در درباره — Flutter `CircleAvatar` + WPF `Image` دایره‌ای | `assets/images/about_profile.png`, `about_screen.dart`, `AboutView.*` |
| 2026-05-19 | 20:15 | fix | اشتراک در دیالوگ recovery: فایل WAV استگانو (نه متن طول پیام) — `shareStegoWavBytes` | `embed_screen.dart`, `stego_share.dart` |
| 2026-05-19 | 20:45 | feat | دکمه شناور «نهان‌نگاری جدید» بالای صفحه Embed — بازنشانی برای ساخت فایل تازه | `embed_screen.dart`, `app_strings.dart` |
| 2026-05-19 | 21:00 | content | تماس: موبایل با `tel:` و برچسب «تماس»؛ حذف تلفن ثابت؛ ایمیل `karavi@ntk.ir` | `about_constants.dart`, `about_screen.dart`, `AboutView.*`, `AppStrings.cs` |
| 2026-05-19 | 21:15 | ui | نصف ارتفاع بخش ضبط و بارگذاری فایل — Flutter `CircleActionButton`/`AudioSourceActionsPanel`؛ WPF کنترل‌ها | `circle_action_button.dart`, `RecordButtonControl.*`, `LoadFileButtonControl.xaml` |
| 2026-05-19 | 21:30 | fix | MP3: decode از مسیر فایل (نه فقط bytes)؛ رفع «failed to instantiate extractor» روی اندروید؛ `errorMp3Decode` | `audio_mp3_decoder.dart`, `audio_input_loader_io.dart`, embed/extract |
| 2026-05-19 | 21:00 | branding | آیکن برند: موج صوتی + قفل (`#00B4B7` روی `#121212`) — PWA `web/icons/*`، Android adaptive، Flutter Windows `.ico`، WPF `Assets/app.ico` + `ApplicationIcon` | `assets/branding/app_icon.png`, `pubspec.yaml`, `flutter_launcher_icons`, `AudioSteg.Desktop.csproj`, `MainWindow.xaml` |
| 2026-05-21 | — | config | Android: `applicationId` و `namespace` → `ir.ntk.audiowmark.app`؛ انتقال `MainActivity` | `android/app/build.gradle.kts`, `kotlin/ir/ntk/audiowmark/app/MainActivity.kt` |
| 2026-05-21 | — | config | یک منبع `appsettings.json` در ریشه repo؛ حذف `app-config.json`؛ Flutter asset + WPF Link از ریشه | `appsettings.json`, `pubspec.yaml`, `app_config.dart`, `AudioSteg.Desktop.csproj` |
| 2026-05-21 | — | build | رفع `flutter build windows` — symlink: junction + بیلد elevated (UAC)؛ `-SkipFlutterWindows` | `invoke_flutter_windows_build.ps1`, `_build-all-projects.ps1`, `restart_all.ps1` |
| 2026-05-21 | — | config | کپی `appsettings.json` به خروجی Flutter web/Windows؛ بارگذاری از فایل استقرار (IO/وب) | `copy_appsettings_to_flutter_outputs.ps1`, `app_config_loader*.dart`, `app_config.dart` |
| 2026-05-21 | — | build | `_build-all-projects.ps1`: بیلد Android APK + پوشه `audio_steg_app_android` در ZIP استقرار | `flutter_android_build.ps1`, `_build-all-projects.ps1`, `_build-flutter-android.ps1` |
