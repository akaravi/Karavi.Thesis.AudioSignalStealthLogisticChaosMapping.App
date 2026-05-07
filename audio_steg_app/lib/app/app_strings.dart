import 'package:flutter/widgets.dart';

/// Lightweight built-in localization (Persian + English) so we don't need to
/// run the gen_l10n tool. Persian is the project's base language.
enum AppLocale { fa, en }

class AppStrings {
  final AppLocale locale;
  const AppStrings(this.locale);

  static AppStrings of(BuildContext context) {
    final loc = Localizations.localeOf(context).languageCode == 'en'
        ? AppLocale.en
        : AppLocale.fa;
    return AppStrings(loc);
  }

  String _(String fa, String en) => locale == AppLocale.fa ? fa : en;

  String get appTitle => _('بیسم نهان‌نگاری صوتی', 'Audio Steg Walkie-Talkie');
  String get embedTab => _('نهان‌نگاری', 'Embed');
  String get extractTab => _('رمزگشایی', 'Extract');
  String get settingsTab => _('تنظیمات', 'Settings');
  String get textHint =>
      _('متن پیام را اینجا تایپ کنید…', 'Type your secret message…');
  String get startRecording => _('شروع ضبط', 'Start Recording');
  String get stopRecording => _('پایان ضبط', 'Stop Recording');
  String get cancelRecording => _('لغو', 'Cancel');
  String get saveStego => _('ذخیره فایل نهان‌نگاری شده', 'Save stego file');
  String get mode => _('حالت', 'Mode');
  String get modeDigital => _('دیجیتال (LSB + Chaos)', 'Digital (LSB + Chaos)');
  String get modeOverAir =>
      _('هوایی (FSK + Chaos)', 'Over-the-Air (FSK + Chaos)');
  String get modeDigitalDesc => _(
    'وفادار به الگوریتم متلب. خروجی فقط با خواندن مستقیم فایل قابل رمزگشایی است.',
    'Faithful to the MATLAB algorithm. Decoder must read the file directly.',
  );
  String get modeOverAirDesc => _(
    'مقاوم در برابر اسپیکر→میکروفن. کمی صدای صفیر شنیده می‌شود.',
    'Robust over speaker→microphone. A faint chirp is audible.',
  );
  String get fromFile => _('از فایل', 'From file');
  String get fromMic => _('از میکروفن', 'From microphone');
  String get pickFile => _('انتخاب فایل WAV', 'Pick a WAV file');
  String get extractedText => _('متن استخراج شده', 'Extracted text');
  String get noText => _('چیزی استخراج نشد', 'Nothing extracted');
  String get listenLive => _('گوش دادن زنده', 'Listen live');
  String get stopListening => _('پایان گوش دادن', 'Stop listening');
  String get copy => _('کپی', 'Copy');
  String get copied => _('کپی شد', 'Copied');
  String get themeMode => _('تم', 'Theme');
  String get themeLight => _('روشن', 'Light');
  String get themeDark => _('تاریک', 'Dark');
  String get themeSystem => _('سیستم', 'System');
  String get language => _('زبان', 'Language');
  String get persian => _('فارسی', 'Persian');
  String get english => _('انگلیسی', 'English');
  String get logisticParams =>
      _('پارامترهای آشوب لاجستیک', 'Logistic chaos params');
  String get rParam => _('پارامتر r', 'r parameter');
  String get x0Param => _('مقدار اولیه x0', 'x0 initial');
  String get colorSeed => _('رنگ تم', 'Theme color');
  String get permissionDenied =>
      _('دسترسی به میکروفن رد شد.', 'Microphone permission denied.');
  String get errorEmpty =>
      _('متن نمی‌تواند خالی باشد.', 'Text cannot be empty.');
  String get errorTooLong => _(
    'متن طولانی‌تر از ظرفیت صدای ضبط شده است.',
    'Text too long for the recorded audio.',
  );
  String get successSaved => _('فایل ذخیره شد', 'File saved');
  String get duration => _('مدت زمان', 'Duration');
  String get capacity => _('ظرفیت', 'Capacity');
  String get bitsEmbedded => _('بیت جاسازی شده', 'Bits embedded');
  String get snrLabel => _('SNR (dB)', 'SNR (dB)');
  String get psnrLabel => _('PSNR (dB)', 'PSNR (dB)');
  String get reset => _('بازنشانی', 'Reset');
  String get play => _('پخش', 'Play');
  String get share => _('اشتراک‌گذاری', 'Share');
  String get readyToRecord => _('آماده ضبط…', 'Ready to record…');
  String get recording => _('در حال ضبط…', 'Recording…');
  String get processing => _('در حال پردازش…', 'Processing…');
  String get listening => _('در حال گوش دادن…', 'Listening…');
  String get keyMismatch => _(
    'کلید/پارامترها صحیح نیستند یا داده‌ای پیدا نشد.',
    'Wrong key/params or no payload found.',
  );

  // ─── Quality metrics & verify (Part 11) ─────────────────────────────
  String get qualityMetrics => _('متریک‌های کیفیت', 'Quality metrics');
  String get utilization => _('بهره‌وری ظرفیت', 'Capacity utilisation');
  String get verify => _('تأیید فوری', 'Verify roundtrip');
  String get verifying => _('در حال تأیید…', 'Verifying…');
  String get verifyMatch => _(
    'تأیید موفق ✓ متن استخراج‌شده با اصل یکی است.',
    'Verified ✓ extracted text matches the original.',
  );
  String get verifyMismatch => _(
    'تأیید ناموفق! متن استخراج‌شده با اصل تطابق ندارد.',
    'Mismatch! extracted text differs from the original.',
  );
  String get verifyEmpty => _(
    'چیزی استخراج نشد — embed با شکست مواجه شده است.',
    'Nothing extracted — embed seems broken.',
  );

  // ─── About dialog (Part 11) ─────────────────────────────────────────
  String get aboutTitle => _('درباره برنامه', 'About this app');
  String get aboutVersion => _('نسخه', 'Version');
  String get aboutAuthor => _('پدیدآور', 'Author');
  String get aboutAlgo => _('الگوریتم', 'Algorithm');
  String get aboutAlgoBody => _(
    'پیاده‌سازی دارت/فلاتر از روش نهان‌نگاری LSB+آشوب‌لاجستیک '
        '(Matlab/embed_extract_data.m) و افزودن مد مقاوم BFSK + Hamming(7,4) + '
        'CRC-16 برای انتقال هوایی اسپیکر→میکروفن.',
    'Dart/Flutter port of LSB + Logistic-Chaos steganography '
        '(Matlab/embed_extract_data.m) plus a robust BFSK + Hamming(7,4) + '
        'CRC-16 mode for over-the-air speaker→microphone transmission.',
  );
  String get aboutThesis => _(
    'پایان‌نامه: نهان‌نگاری مخفی سیگنال صوتی با نگاشت آشوب لاجستیک',
    'Thesis: Audio Signal Stealth Steganography via Logistic Chaos Mapping',
  );
  String get close => _('بستن', 'Close');
}
