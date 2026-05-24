namespace AudioStegano.Desktop.Localization;

public sealed partial class AppStrings
{
    public string EmbedNew => T("نهان‌نگاری جدید", "New embed", "إخفاء جديد", "Nouvel intégrage");
    public string ExtractNew => T("رمزگشایی جدید", "New extract", "استخراج جديد", "Nouvelle extraction");
    public string ShareStego => T(
        "اشتراک‌گذاری فایل صوتی",
        "Share stego audio file",
        "مشاركة ملف الصوت",
        "Partager le fichier audio stégo");
    public string ShareFileDownloaded => T(
        "فایل برای دانلود آماده شد.",
        "File is ready to download.",
        "الملف جاهز للتنزيل.",
        "Le fichier est prêt au téléchargement.");
    public string AudioSourceOr => T("یا", "or", "أو", "ou");

    public string ChooseLanguage => T(
        "زبان برنامه را انتخاب کنید",
        "Choose your language",
        "اختر لغة التطبيق",
        "Choisissez votre langue");

    public string UsageGuideTitle => T("راهنمای سریع", "Quick guide", "دليل سريع", "Guide rapide");
    public string UsageGuidePurpose => T(
        "این برنامه برای نهان‌نگاری متن در فایل صوتی با LSB و نقشه آشوب لاجستیک "
            + "(پژوهش پایان‌نامه) ساخته شده است. پیام داخل موج صدا پنهان می‌شود و با "
            + "همان کلید و پارامترها قابل استخراج است.",
        "This app hides text inside audio using LSB and a logistic chaos map "
            + "(thesis research). The message is embedded in the waveform and can be "
            + "recovered with the same key and parameters.",
        "يخفي هذا التطبيق النص داخل الصوت باستخدام LSB وخريطة الفوضى اللوجستية "
            + "(بحث أطروحة). تُدمج الرسالة في الموجة ويمكن استعادتها بنفس المفتاح والمعاملات.",
        "Cette application cache du texte dans l’audio via LSB et une carte du chaos "
            + "logistique (thèse). Le message est intégré dans l’onde et récupérable avec "
            + "les mêmes paramètres.");
    public string UsageGuideStepEmbed => T(
        "نهان‌نگاری: پیام را بنویسید، سپس صدا را ضبط کنید یا فایل WAV/MP3 بارگذاری کنید. "
            + "پس از پردازش، عدد طول پیام (بیت) را حتماً یادداشت کنید.",
        "Embed: Type your message, then record audio or upload a WAV/MP3 file. "
            + "After processing, note the message length in bits.",
        "الإخفاء: اكتب رسالتك، ثم سجّل الصوت أو ارفع ملف WAV/MP3. "
            + "بعد المعالجة، دوّن طول الرسالة بالبت.",
        "Intégrer : saisissez le message, enregistrez ou importez un WAV/MP3. "
            + "Notez ensuite la longueur du message en bits.");
    public string UsageGuideStepExtract => T(
        "رمزگشایی: فایل نهان‌نگاری‌شده را انتخاب کنید و طول پیام (بیت) را وارد کنید. "
            + "پارامترهای آشوب باید با زمان نهان‌نگاری یکسان باشند.",
        "Extract: Open the stego audio file and enter the message length in bits. "
            + "Chaos parameters must match those used when embedding.",
        "الاستخراج: افتح ملف الإخفاء وأدخل طول الرسالة بالبت. "
            + "يجب أن تطابق معاملات الفوضى مع وقت الإخفاء.",
        "Extraire : ouvrez le fichier stégo et saisissez la longueur en bits. "
            + "Les paramètres du chaos doivent correspondre à l’intégration.");
    public string UsageGuideStepSettings => T(
        "تنظیمات: تم، زبان و پارامترهای r و x0 را می‌توانید تغییر دهید. "
            + "مقادیر r و x0 را دستی یا با اسلایدر در بازه مجاز وارد کنید.",
        "Settings: Change theme, language, and logistic r / x0. "
            + "Enter parameters manually or with sliders within the allowed range.",
        "الإعدادات: غيّر المظهر واللغة ومعاملات r و x0 يدوياً أو بالمنزلق.",
        "Paramètres : thème, langue, r et x0 — saisie manuelle ou curseurs.");
    public string UsageGuideStepAbout => T(
        "درباره ما: معرفی پروژه، استاد راهنما و پیوندهای تماس.",
        "About: project info, supervisor, and links.",
        "من نحن: معلومات المشروع والمشرف وروابط التواصل.",
        "À propos : projet, encadrant et liens.");
    public string UsageGuideContinue => T("شروع استفاده", "Get started", "بدء الاستخدام", "Commencer");

    public string SplashTitleAudio => T("سیگنال صوتی", "Audio signal", "إشارة صوتية", "Signal audio");
    public string SplashSubtitleAudio => T(
        "نهان‌نگاری مخفی در بستر امواج صدا",
        "Stealth embedding inside sound waves",
        "إخفاء خفي داخل موجات الصوت",
        "Intégration furtive dans les ondes sonores");
    public string SplashTitleStego => T(
        "نهان‌نگاری آشوب لاجستیک",
        "Logistic chaos steganography",
        "إخفاء الفوضى اللوجستي",
        "Stéganographie chaos logistique");
    public string WindowsOpenWithTitle => T(
        "باز کردن با ویندوز (WAV / MP3 / MP4)",
        "Windows “Open with” (WAV / MP3 / MP4)",
        "فتح بـ Windows (WAV / MP3 / MP4)",
        "Ouvrir avec Windows (WAV / MP3 / MP4)");
    public string WindowsOpenWithHint => T(
        "این برنامه را در منوی «باز کردن با» اکسپلورر برای فایل‌های صوتی ثبت می‌کند (بدون نیاز به مدیر سیستم).",
        "Lists this app in Explorer’s “Open with” menu for audio files (per-user, no admin).",
        "يُظهر التطبيق في قائمة «فتح باستخدام» في Explorer (لكل مستخدم، دون مسؤول).",
        "Affiche l’app dans le menu « Ouvrir avec » d’Explorer (par utilisateur, sans admin).");
    public string WindowsOpenWithRegistered => T(
        "ثبت «باز کردن با» انجام شد.",
        "“Open with” registration applied.",
        "تم تسجيل «فتح باستخدام».",
        "Enregistrement « Ouvrir avec » effectué.");
    public string WindowsOpenWithFirstRunPrompt => T(
        "آیا می‌خواهید این برنامه در منوی «باز کردن با» ویندوز برای فایل‌های WAV/MP3/MP4 ثبت شود؟",
        "Register this app in Windows “Open with” for WAV/MP3/MP4 files?",
        "هل تريد تسجيل التطبيق في «فتح باستخدام» Windows لملفات WAV/MP3/MP4؟",
        "Enregistrer cette application dans « Ouvrir avec » Windows pour les fichiers WAV/MP3/MP4 ?");

    public string WindowsOpenWithUnregistered => T(
        "ثبت «باز کردن با» حذف شد.",
        "“Open with” registration removed.",
        "تم إلغاء تسجيل «فتح باستخدام».",
        "Enregistrement « Ouvrir avec » supprimé.");

    public string SplashSubtitleStego => T(
        "امنیت پیام با نقشه آشوب و LSB",
        "Message security via chaos map & LSB",
        "أمان الرسالة عبر خريطة الفوضى و LSB",
        "Sécurité du message via carte chaotique et LSB");
}
