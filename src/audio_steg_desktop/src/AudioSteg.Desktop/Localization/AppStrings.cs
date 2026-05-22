namespace AudioSteg.Desktop.Localization;

public sealed class AppStrings
{
    private readonly AppLanguage _lang;

    public AppStrings(AppLanguage lang) => _lang = lang;

    private string T(string fa, string en, string ar, string fr) => _lang switch
    {
        AppLanguage.Fa => fa,
        AppLanguage.En => en,
        AppLanguage.Ar => ar,
        AppLanguage.Fr => fr,
        _ => fa,
    };

    public string AppTitle => T(
        "نهان‌نگاری پیام در صوت", "Audio Steganography",
        "إخفاء الرسالة في الصوت", "Stéganographie du message audio");
    public string AppShortTitle => T(
        "صوت‌نهان", "AudioSteg",
        "صوت خفي", "AudioSteg");
    public string EmbedTab => T("نهان‌نگاری", "Embed", "إخفاء", "Intégrer");
    public string ExtractTab => T("رمزگشایی", "Extract", "استخراج", "Extraire");
    public string SettingsTab => T("تنظیمات", "Settings", "الإعدادات", "Paramètres");
    public string AboutUsTab => T("درباره ما", "About us", "من نحن", "À propos");
    public string TextHint => T(
        "متن پیام را اینجا تایپ کنید…", "Type your secret message…",
        "اكتب رسالتك السرية هنا…", "Saisissez votre message secret…");
    public string StartRecording => T("شروع ضبط", "Start Recording", "بدء التسجيل", "Démarrer l’enregistrement");
    public string StopRecording => T("پایان ضبط", "Stop Recording", "إيقاف التسجيل", "Arrêter l’enregistrement");
    public string SaveStego => T(
        "ذخیره فایل نهان‌نگاری شده", "Save stego file",
        "حفظ ملف الإخفاء", "Enregistrer le fichier stégo");
    public string SuccessSaved => T("فایل ذخیره شد", "File saved", "تم حفظ الملف", "Fichier enregistré");
    public string EmbedCompleteTitle => T(
        "نهان‌نگاری انجام شد", "Embedding complete", "اكتمل الإخفاء", "Intégration terminée");
    public string EmbedRecoveryMessage => T(
        "برای بازیابی عبارت نهانگاری‌شده عدد طول پیام را یادداشت فرمایید",
        "To recover the hidden phrase, please note the message length number",
        "لاستعادة العبارة المخفية، يُرجى تدوين رقم طول الرسالة",
        "Pour récupérer la phrase cachée, notez le nombre de bits du message");
    public string EmbedRecoveryCopied => T(
        "عدد در حافظه کپی شد.", "Value copied to clipboard.",
        "تم نسخ الرقم إلى الحافظة.", "Valeur copiée dans le presse-papiers.");
    public string EmbedRecoveryOk => T("متوجه شدم", "Got it", "حسناً", "Compris");
    public string EmbedRecoveryCapacityHint(int capacityBits) => _lang switch
    {
        AppLanguage.Fa => $"ظرفیت کل فایل صوتی: {capacityBits} بیت",
        AppLanguage.En => $"Total audio capacity: {capacityBits} bits",
        AppLanguage.Ar => $"السعة الكلية للصوت: {capacityBits} بت",
        AppLanguage.Fr => $"Capacité audio totale : {capacityBits} bits",
        _ => $"ظرفیت کل فایل صوتی: {capacityBits} بیت",
    };
    public string ColorSeed => T("رنگ تم", "Theme color", "لون المظهر", "Couleur du thème");
    public string LoadAudioFile => T("بارگذاری فایل", "Upload file", "رفع ملف", "Importer un fichier");
    public string PickFile => T(
        "انتخاب فایل صوتی (WAV/MP3)", "Pick audio file (WAV/MP3)",
        "اختر ملف صوت (WAV/MP3)", "Choisir un fichier audio (WAV/MP3)");
    public string AudioFileLoaded(string name) => _lang switch
    {
        AppLanguage.Fa => $"فایل بارگذاری شد: {name}",
        AppLanguage.En => $"Audio loaded: {name}",
        AppLanguage.Ar => $"تم تحميل الملف: {name}",
        AppLanguage.Fr => $"Fichier chargé : {name}",
        _ => $"فایل بارگذاری شد: {name}",
    };
    public string ErrorNoAudioLoaded => T(
        "ابتدا فایل صوتی را بارگذاری کنید.",
        "Load an audio file first.",
        "حمّل ملفًا صوتيًا أولًا.",
        "Chargez d’abord un fichier audio.");
    public string ExtractedText => T("متن استخراج شده", "Extracted text", "النص المستخرج", "Texte extrait");
    public string NoText => T("چیزی استخراج نشد", "Nothing extracted", "لم يُستخرج شيء", "Rien n’a été extrait");
    public string Copy => T("کپی", "Copy", "نسخ", "Copier");
    public string Copied => T("کپی شد", "Copied", "تم النسخ", "Copié");
    public string ThemeMode => T("تم", "Theme", "المظهر", "Thème");
    public string ThemeLight => T("روشن", "Light", "فاتح", "Clair");
    public string ThemeDark => T("تاریک", "Dark", "داكن", "Sombre");
    public string ThemeSystem => T("سیستم", "System", "النظام", "Système");
    public string Language => T("زبان", "Language", "اللغة", "Langue");
    public string Persian => T("فارسی", "Persian", "الفارسية", "Persan");
    public string English => T("انگلیسی", "English", "الإنجليزية", "Anglais");
    public string Arabic => T("عربی", "Arabic", "العربية", "Arabe");
    public string French => T("فرانسوی", "French", "الفرنسية", "Français");
    public string EmbedBehaviorSettings => T(
        "رفتار نهان‌نگاری", "Embed behavior", "سلوك الإخفاء", "Comportement d’intégration");
    public string ShowEmbedRecoveryDialog => T(
        "نمایش بازگردانی پس از نهان‌نگاری",
        "Show recovery prompt after embed",
        "عرض مطالبة الاستعادة بعد الإخفاء",
        "Afficher l’invite de récupération après intégration");
    public string ShowEmbedRecoveryDialogHint => T(
        "پس از نهان‌نگاری، پنجرهٔ یادآوری طول پیام (بیت) برای بازیابی نمایش داده شود.",
        "After embedding, show a dialog reminding you to save the message length (bits) for recovery.",
        "بعد الإخفاء، يُعرض مربع حوار لتذكيرك بحفظ طول الرسالة (بت) للاستعادة.",
        "Après l’intégration, afficher une boîte de dialogue pour noter la longueur du message (bits).");
    public string LogisticParams => T(
        "پارامترهای آشوب لاجستیک", "Logistic chaos params",
        "معاملات الفوضى اللوجستية", "Paramètres du chaos logistique");
    public string RParam => T("پارامتر r", "r parameter", "معامل r", "Paramètre r");
    public string X0Param => T("مقدار اولیه x0", "x0 initial", "القيمة الابتدائية x0", "Valeur initiale x0");
    public string LogisticRRangeHint => T(
        "بازه مجاز: ۳٫۵ تا ۴٫۰", "Allowed range: 3.5 to 4.0",
        "النطاق المسموح: 3.5 إلى 4.0", "Plage autorisée : 3,5 à 4,0");
    public string LogisticX0RangeHint => T(
        "بازه مجاز: ۰٫۰۱ تا ۰٫۹۹", "Allowed range: 0.01 to 0.99",
        "النطاق المسموح: 0.01 إلى 0.99", "Plage autorisée : 0,01 à 0,99");
    public string LogisticInvalidValue => T(
        "مقدار خارج از بازه مجاز است.", "Value is outside the allowed range.",
        "القيمة خارج النطاق المسموح.", "La valeur est hors de la plage autorisée.");
    public string LogisticMapPreviewHint => T(
        "پیش‌نمایش دنبالهٔ آشوب با پارامترهای فعلی (خط چین: آستانهٔ کلید باینری)",
        "Chaos sequence preview for current r and x0 (dashed: binary key threshold)",
        "معاينة تسلسل الفوضى للمعاملات الحالية (متقطع: عتبة المفتاح الثنائي)",
        "Aperçu de la séquence chaotique pour r et x0 actuels (pointillé : seuil clé binaire)");
    public string DefaultFixedMessageBitLimit(int bits) => _lang switch
    {
        AppLanguage.Fa => $"محدودیت طول پیام پیش‌فرض {bits} بیت",
        AppLanguage.Ar => $"حد طول الرسالة الافتراضي: {bits} بت",
        AppLanguage.Fr => $"Limite de longueur par défaut : {bits} bits",
        _ => $"Default message length limit: {bits} bits",
    };
    public string DefaultFixedMessageBitLimitHint(int bits) => _lang switch
    {
        AppLanguage.Fa =>
            $"نهان‌نگاری و رمزگشایی همیشه با {bits} بیت انجام می‌شود؛ طول پیام از شما پرسیده نمی‌شود.",
        AppLanguage.Ar =>
            $"الإخفاء والاستخراج دائماً بـ {bits} بت؛ لا يُطلب طول الرسالة.",
        AppLanguage.Fr =>
            $"Intégration et extraction à {bits} bits ; la longueur n’est pas demandée.",
        _ => $"Embed and extract always use {bits} bits; message length is not asked.",
    };
    public string MessageBitsUsed(int used) => _lang switch
    {
        AppLanguage.Fa => $"{used} بیت استفاده‌شده",
        AppLanguage.Ar => $"{used} بت مستخدم",
        AppLanguage.Fr => $"{used} bits utilisés",
        _ => $"{used} bits used",
    };
    public string MessageBitsUsedAndRemaining(int used, int remaining) => _lang switch
    {
        AppLanguage.Fa => $"{used} بیت استفاده‌شده — {remaining} بیت باقی‌مانده",
        AppLanguage.Ar => $"{used} بت مستخدم — {remaining} بت متبقٍ",
        AppLanguage.Fr => $"{used} bits utilisés — {remaining} bits restants",
        _ => $"{used} bits used — {remaining} bits remaining",
    };
    public string Reset => T("بازنشانی", "Reset", "إعادة تعيين", "Réinitialiser");
    public string Play => T("پخش", "Play", "تشغيل", "Lecture");
    public string Pause => T("مکث", "Pause", "إيقاف مؤقت", "Pause");
    public string StopPlayback => T("توقف پخش", "Stop", "إيقاف التشغيل", "Arrêter");
    public string Verify => T("تأیید فوری", "Verify roundtrip", "تحقق فوري", "Vérification rapide");
    public string Verifying => T("در حال تأیید…", "Verifying…", "جارٍ التحقق…", "Vérification…");
    public string Processing => T("در حال پردازش…", "Processing…", "جارٍ المعالجة…", "Traitement…");
    public string Recording => T("در حال ضبط…", "Recording…", "جارٍ التسجيل…", "Enregistrement…");
    public string ErrorEmpty => T(
        "متن نمی‌تواند خالی باشد.", "Text cannot be empty.",
        "لا يمكن أن يكون النص فارغاً.", "Le texte ne peut pas être vide.");
    public string ErrorNoRecording => T(
        "صدایی ضبط نشده است.", "No recorded audio.",
        "لم يُسجَّل صوت.", "Aucun enregistrement audio.");
    public string ErrorTooLong => T(
        "متن طولانی‌تر از ظرفیت صدای ضبط شده است.", "Text too long for the recorded audio.",
        "النص أطول من سعة الصوت المسجل.", "Texte trop long pour l’audio enregistré.");
    public string KeyMismatch => T(
        "کلید/پارامترها صحیح نیستند یا داده‌ای پیدا نشد.", "Wrong key/params or no payload found.",
        "المفتاح/المعاملات غير صحيحة أو لم يُعثر على بيانات.", "Clé/paramètres incorrects ou aucune charge utile.");
    public string QualityMetrics => T(
        "متریک‌های کیفیت", "Quality metrics", "مقاييس الجودة", "Métriques de qualité");
    public string AudioEqualizer => T("اکولایزر صدا", "Audio equalizer", "معادل الصوت", "Égaliseur audio");
    public string AudioLevel => T("سطح صدا", "Audio level", "مستوى الصوت", "Niveau audio");
    public string CompareWaveformTitle => T(
        "مقایسه سیگنال صوتی", "Audio signal comparison",
        "مقارنة إشارة الصوت", "Comparaison du signal audio");
    public string CoverWaveLegend => T(
        "صدای اصلی (پوشش)", "Original audio (cover)",
        "الصوت الأصلي (الغلاف)", "Audio original (cover)");
    public string StegoWaveLegend => T(
        "صدای نهان‌نگاری‌شده", "Watermarked audio (stego)",
        "الصوت المخفي", "Audio watermarké (stégo)");
    public string Duration => T("مدت زمان", "Duration", "المدة", "Durée");
    public string Capacity => T("ظرفیت", "Capacity", "السعة", "Capacité");
    public string BitsEmbedded => T("بیت جاسازی شده", "Bits embedded", "البتات المدمجة", "Bits intégrés");
    public string Utilization => T(
        "بهره‌وری ظرفیت", "Capacity utilisation",
        "استخدام السعة", "Utilisation de la capacité");
    public string MsgBitLength => T(
        "طول پیام (بیت)", "Message length (bits)",
        "طول الرسالة (بت)", "Longueur du message (bits)");
    public string MsgBitLengthHint => T(
        "طول پیام به بیت (msg_len)", "Message length in bits (msg_len)",
        "طول الرسالة بالبت (msg_len)", "Longueur du message en bits (msg_len)");
    public string MsgBitLengthHelper => T(
        "همان مقداری که هنگام نهان‌نگاری استفاده شد — مانند main_steganography.m",
        "Same value used when embedding — as in main_steganography.m",
        "نفس القيمة المستخدمة عند الإخفاء — كما في main_steganography.m",
        "Même valeur qu’à l’intégration — comme dans main_steganography.m");
    public string ErrorBitLengthEmpty => T(
        "طول پیام (بیت) را وارد کنید.", "Enter the message length in bits.",
        "أدخل طول الرسالة بالبت.", "Saisissez la longueur du message en bits.");
    public string ErrorBitLengthInvalid => T(
        "طول پیام باید عدد مثبت باشد.", "Message length must be a positive number.",
        "يجب أن يكون طول الرسالة رقماً موجباً.", "La longueur du message doit être positive.");
    public string VerifyMatch => T(
        "تأیید موفق ✓ متن استخراج‌شده با اصل یکی است.", "Verified ✓ extracted text matches the original.",
        "تم التحقق ✓ النص المستخرج يطابق الأصل.", "Vérifié ✓ le texte extrait correspond à l’original.");
    public string VerifyMismatch => T(
        "تأیید ناموفق! متن استخراج‌شده با اصل تطابق ندارد.", "Mismatch! extracted text differs from the original.",
        "فشل التحقق! النص المستخرج يختلف عن الأصل.", "Échec ! le texte extrait diffère de l’original.");
    public string VerifyEmpty => T(
        "چیزی استخراج نشد — embed با شکست مواجه شده است.", "Nothing extracted — embed seems broken.",
        "لم يُستخرج شيء — يبدو أن الإخفاء فشل.", "Rien extrait — l’intégration semble avoir échoué.");
    public string AboutTitle => T("درباره برنامه", "About this app", "حول التطبيق", "À propos de l’application");
    public string AboutVersion => T("نسخه", "Version", "الإصدار", "Version");
    public string AboutAlgoBody => T(
        "فقط بر اساس اسکریپت‌های متلب:\n• embed_extract_data.m\n• logistic_map_keygen.m\n• evaluate_stego.m\n• main_steganography.m",
        "Based only on MATLAB scripts:\n• embed_extract_data.m\n• logistic_map_keygen.m\n• evaluate_stego.m\n• main_steganography.m",
        "فقط بناءً على سكربتات MATLAB:\n• embed_extract_data.m\n• logistic_map_keygen.m\n• evaluate_stego.m\n• main_steganography.m",
        "Uniquement basé sur les scripts MATLAB :\n• embed_extract_data.m\n• logistic_map_keygen.m\n• evaluate_stego.m\n• main_steganography.m");
    public string AboutProfileTitle => T("علیرضا کاروی", "Alireza Karavi", "علیرضا کاروی", "Alireza Karavi");
    public string AboutBio => T(
        "توسعه‌دهنده نرم‌افزار و مدیر فنی در شرکت NTK؛ فارغ‌التحصیل مهندسی صنایع (کارشناسی) و هوش مصنوعی و رباتیک (کارشناسی ارشد). بیش از ۱۷ سال تجربه در توسعه وب، C#، موبایل (Flutter) و معماری سامانه‌های سازمانی و CMS. این اپلیکیشن بخشی از پژوهش پایان‌نامه «نهان‌نگاری مخفی سیگنال صوتی با نگاشت آشوب لاجستیک» است.",
        "Software developer and senior IT lead at NTK; B.Sc. Industrial Engineering, M.Sc. AI & Robotics. 17+ years in web, C#, Flutter, and enterprise/CMS systems. This app is part of thesis research on audio steganography via logistic chaos mapping.",
        "مطوّر برمجيات ومدير تقني في NTK؛ بكالوريوس هندسة صناعية وماجستير ذكاء اصطناعي وروبوتات. أكثر من 17 عاماً في الويب وC# وFlutter. هذا التطبيق جزء من أطروحة إخفاء الصوت.",
        "Développeur logiciel et responsable technique chez NTK ; ingénierie industrielle et master IA & robotique. 17+ ans en web, C#, Flutter. Application liée à la thèse sur la stéganographie audio.");
    public string AboutSupervisorSection => T("استاد راهنما", "Supervisor", "المشرف", "Directeur de thèse");
    public string AboutSupervisorName => T("دکتر مهدی مصلح", "Dr. Mehdi Mosleh", "الدكتور مهدي مصلح", "Dr. Mehdi Mosleh");
    public string AboutLinksSection => T("پیوندها", "Links", "روابط", "Liens");
    public string AboutGitHubApp => T(
        "مخزن GitHub — اپلیکیشن", "GitHub — application repo",
        "مستودع GitHub — التطبيق", "GitHub — dépôt application");
    public string AboutGitHubThesis => T(
        "مخزن GitHub — پایان‌نامه", "GitHub — thesis repo",
        "مستودع GitHub — الأطروحة", "GitHub — dépôt thèse");
    public string AboutPersonalSite => T("وب‌سایت شخصی", "Personal website", "الموقع الشخصي", "Site personnel");
    public string AboutCompanySite => T("وب‌سایت شرکت NTK", "NTK company website", "موقع شركة NTK", "Site NTK");
    public string AboutContactSection => T("تماس", "Contact", "اتصل بنا", "Contact");
    public string AboutCall => T("تماس", "Call", "اتصال", "Appeler");
    public string AboutEmail => T("ایمیل", "Email", "البريد", "E-mail");
    public string AboutThesis => T(
        "پایان‌نامه: نهان‌نگاری مخفی سیگنال صوتی با نگاشت آشوب لاجستیک",
        "Thesis: Audio Signal Stealth Steganography via Logistic Chaos Mapping",
        "أطروحة: إخفاء إشارة الصوت عبر الخريطة الفوضوية اللوجستية",
        "Thèse : stéganographie audio furtive par carte chaotique logistique");
    public string SnrLabel => "SNR (dB)";
    public string PsnrLabel => "PSNR (dB)";
    public string BerLabel => "BER (%)";
    public string NpcrLabel => "NPCR (%)";
    public string UaciLabel => "UACI (%)";
}
