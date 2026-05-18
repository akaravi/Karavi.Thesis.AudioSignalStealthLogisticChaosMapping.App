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

  String get appTitle => _('نهان‌نگاری صوتی آشوب', 'Audio Chaos Steganography');
  String get embedTab => _('نهان‌نگاری', 'Embed');
  String get extractTab => _('رمزگشایی', 'Extract');
  String get settingsTab => _('تنظیمات', 'Settings');
  String get textHint =>
      _('متن پیام را اینجا تایپ کنید…', 'Type your secret message…');
  String get startRecording => _('شروع ضبط', 'Start Recording');
  String get stopRecording => _('پایان ضبط', 'Stop Recording');
  String get cancelRecording => _('لغو', 'Cancel');
  String get saveStego => _('ذخیره فایل نهان‌نگاری شده', 'Save stego file');
  String get fromFile => _('از فایل', 'From file');
  String get pickFile => _('انتخاب فایل WAV', 'Pick a WAV file');
  String get extractedText => _('متن استخراج شده', 'Extracted text');
  String get noText => _('چیزی استخراج نشد', 'Nothing extracted');
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
  String get berLabel => _('BER (%)', 'BER (%)');
  String get npcrLabel => _('NPCR (%)', 'NPCR (%)');
  String get uaciLabel => _('UACI (%)', 'UACI (%)');
  String get msgBitLength => _('طول پیام (بیت)', 'Message length (bits)');
  String get msgBitLengthHint =>
      _('طول پیام به بیت (msg_len)', 'Message length in bits (msg_len)');
  String get msgBitLengthHelper => _(
    'همان مقداری که هنگام نهان‌نگاری استفاده شد — مانند main_steganography.m',
    'Same value used when embedding — as in main_steganography.m',
  );
  String get errorBitLengthEmpty =>
      _('طول پیام (بیت) را وارد کنید.', 'Enter the message length in bits.');
  String get errorBitLengthInvalid => _(
    'طول پیام باید عدد مثبت باشد.',
    'Message length must be a positive number.',
  );
  String get reset => _('بازنشانی', 'Reset');
  String get play => _('پخش', 'Play');
  String get share => _('اشتراک‌گذاری', 'Share');
  String get readyToRecord => _('آماده ضبط…', 'Ready to record…');
  String get recording => _('در حال ضبط…', 'Recording…');
  String get processing => _('در حال پردازش…', 'Processing…');
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
    'فقط بر اساس اسکریپت‌های متلب:\n'
        '• embed_extract_data.m\n'
        '• logistic_map_keygen.m\n'
        '• evaluate_stego.m\n'
        '• main_steganography.m\n'
        '(train_deep_autoencoder.m اختیاری و در متلب غیرفعال است)',
    'Based only on MATLAB scripts:\n'
        '• embed_extract_data.m\n'
        '• logistic_map_keygen.m\n'
        '• evaluate_stego.m\n'
        '• main_steganography.m\n'
        '(train_deep_autoencoder.m is optional and disabled in MATLAB)',
  );
  String get aboutThesis => _(
    'پایان‌نامه: نهان‌نگاری مخفی سیگنال صوتی با نگاشت آشوب لاجستیک',
    'Thesis: Audio Signal Stealth Steganography via Logistic Chaos Mapping',
  );
  String get close => _('بستن', 'Close');
}
