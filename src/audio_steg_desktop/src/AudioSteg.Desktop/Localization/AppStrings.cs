namespace AudioSteg.Desktop.Localization;

public sealed class AppStrings
{
    private readonly AppLanguage _lang;

    public AppStrings(AppLanguage lang) => _lang = lang;

    private string T(string fa, string en) => _lang == AppLanguage.Fa ? fa : en;

    public string AppTitle => T("نهان‌نگاری صوتی آشوب", "Audio Chaos Steganography");
    public string EmbedTab => T("نهان‌نگاری", "Embed");
    public string ExtractTab => T("رمزگشایی", "Extract");
    public string SettingsTab => T("تنظیمات", "Settings");
    public string TextHint => T("متن پیام را اینجا تایپ کنید…", "Type your secret message…");
    public string StartRecording => T("شروع ضبط", "Start Recording");
    public string StopRecording => T("پایان ضبط", "Stop Recording");
    public string SaveStego => T("ذخیره فایل نهان‌نگاری شده", "Save stego file");
    public string SuccessSaved => T("فایل ذخیره شد", "File saved");
    public string ColorSeed => T("رنگ تم", "Theme color");
    public string LoadAudioFile => T("بارگذاری فایل صوتی", "Load audio file");
    public string PickFile => T("انتخاب فایل صوتی (WAV/MP3)", "Pick audio file (WAV/MP3)");
    public string AudioFileLoaded(string name) =>
        T($"فایل بارگذاری شد: {name}", $"Audio loaded: {name}");
    public string ExtractedText => T("متن استخراج شده", "Extracted text");
    public string NoText => T("چیزی استخراج نشد", "Nothing extracted");
    public string Copy => T("کپی", "Copy");
    public string Copied => T("کپی شد", "Copied");
    public string ThemeMode => T("تم", "Theme");
    public string ThemeLight => T("روشن", "Light");
    public string ThemeDark => T("تاریک", "Dark");
    public string ThemeSystem => T("سیستم", "System");
    public string Language => T("زبان", "Language");
    public string Persian => T("فارسی", "Persian");
    public string English => T("انگلیسی", "English");
    public string LogisticParams => T("پارامترهای آشوب لاجستیک", "Logistic chaos params");
    public string RParam => T("پارامتر r", "r parameter");
    public string X0Param => T("مقدار اولیه x0", "x0 initial");
    public string Reset => T("بازنشانی", "Reset");
    public string Play => T("پخش", "Play");
    public string Verify => T("تأیید فوری", "Verify roundtrip");
    public string Verifying => T("در حال تأیید…", "Verifying…");
    public string Processing => T("در حال پردازش…", "Processing…");
    public string Recording => T("در حال ضبط…", "Recording…");
    public string ErrorEmpty => T("متن نمی‌تواند خالی باشد.", "Text cannot be empty.");
    public string ErrorNoRecording => T("صدایی ضبط نشده است.", "No recorded audio.");
    public string ErrorTooLong => T("متن طولانی‌تر از ظرفیت صدای ضبط شده است.", "Text too long for the recorded audio.");
    public string KeyMismatch => T("کلید/پارامترها صحیح نیستند یا داده‌ای پیدا نشد.", "Wrong key/params or no payload found.");
    public string QualityMetrics => T("متریک‌های کیفیت", "Quality metrics");
    public string AudioEqualizer => T("اکولایزر صدا", "Audio equalizer");
    public string CompareWaveformTitle => T("مقایسه سیگنال صوتی", "Audio signal comparison");
    public string CoverWaveLegend => T("صدای اصلی (پوشش)", "Original audio (cover)");
    public string StegoWaveLegend => T("صدای نهان‌نگاری‌شده", "Watermarked audio (stego)");
    public string Duration => T("مدت زمان", "Duration");
    public string Capacity => T("ظرفیت", "Capacity");
    public string BitsEmbedded => T("بیت جاسازی شده", "Bits embedded");
    public string Utilization => T("بهره‌وری ظرفیت", "Capacity utilisation");
    public string MsgBitLength => T("طول پیام (بیت)", "Message length (bits)");
    public string MsgBitLengthHint => T("طول پیام به بیت (msg_len)", "Message length in bits (msg_len)");
    public string MsgBitLengthHelper => T(
        "همان مقداری که هنگام نهان‌نگاری استفاده شد — مانند main_steganography.m",
        "Same value used when embedding — as in main_steganography.m");
    public string ErrorBitLengthEmpty => T("طول پیام (بیت) را وارد کنید.", "Enter the message length in bits.");
    public string ErrorBitLengthInvalid => T("طول پیام باید عدد مثبت باشد.", "Message length must be a positive number.");
    public string VerifyMatch => T("تأیید موفق ✓ متن استخراج‌شده با اصل یکی است.", "Verified ✓ extracted text matches the original.");
    public string VerifyMismatch => T("تأیید ناموفق! متن استخراج‌شده با اصل تطابق ندارد.", "Mismatch! extracted text differs from the original.");
    public string VerifyEmpty => T("چیزی استخراج نشد — embed با شکست مواجه شده است.", "Nothing extracted — embed seems broken.");
    public string AboutTitle => T("درباره برنامه", "About this app");
    public string AboutAlgoBody => T(
        "فقط بر اساس اسکریپت‌های متلب:\n• embed_extract_data.m\n• logistic_map_keygen.m\n• evaluate_stego.m\n• main_steganography.m",
        "Based only on MATLAB scripts:\n• embed_extract_data.m\n• logistic_map_keygen.m\n• evaluate_stego.m\n• main_steganography.m");
    public string SnrLabel => "SNR (dB)";
    public string PsnrLabel => "PSNR (dB)";
    public string BerLabel => "BER (%)";
    public string NpcrLabel => "NPCR (%)";
    public string UaciLabel => "UACI (%)";
}
