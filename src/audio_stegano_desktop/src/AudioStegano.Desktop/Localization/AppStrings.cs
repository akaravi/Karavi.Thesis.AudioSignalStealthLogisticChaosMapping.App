namespace AudioStegano.Desktop.Localization;

public sealed partial class AppStrings
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
        "صوت‌نهان", "AudioStegano",
        "صوت خفي", "AudioStegano");
    public string EmbedTab => T("نهان‌نگاری", "Embed", "إخفاء", "Intégrer");
    public string ExtractTab => T("رمزگشایی", "Extract", "استخراج", "Extraire");
    public string SettingsTab => T("تنظیمات", "Settings", "الإعدادات", "Paramètres");
    public string AboutUsTab => T("درباره ما", "About us", "من نحن", "À propos");
    public string TextHint => T(
        "متن پیام را اینجا تایپ کنید…", "Type your secret message…",
        "اكتب رسالتك السرية هنا…", "Saisissez votre message secret…");
    public string EmbedPayloadTextTab => T("متن", "Text", "نص", "Texte");
    public string EmbedPayloadAudioTab => T("صوت", "Audio", "صوت", "Audio");
    public string EmbedPayloadImageTab => T("عکس", "Image", "صورة", "Image");
    public string EmbedPayloadAudioHint => T(
        "پیام صوتی کوتاه با کیفیت پایین (۸ کیلوهرتز) ضبط کنید — حدود ۴ ثانیه در سقف بیت تنظیمات؛ سپس صوت اصلی (پوشش) را ضبط یا بارگذاری کنید.",
        "Record a short low-quality (8 kHz) voice payload — about 4 seconds within the settings bit budget — then record or load the cover audio.",
        "سجّل رسالة صوتية قصيرة بجودة منخفضة (٨ كيلوهرتز) — حوالي ٤ ثوانٍ ضمن حد البت — ثم سجّل أو حمّل الصوت الغطاء.",
        "Enregistrez un message vocal court (8 kHz) — environ 4 s dans le budget de bits — puis enregistrez ou chargez l’audio de couverture.");
    public string EmbedPayloadAudioHintDynamic => T(
        "پیام صوتی را ضبط کنید؛ بیت مورد نیاز و حداقل زمان ضبط پوشش بر اساس طول پیام محاسبه می‌شود.",
        "Record a voice payload; required bits and minimum cover recording time are calculated from its length.",
        "سجّل الرسالة الصوتية؛ تُحسب البتات والمدة الدنيا لتسجيل الغطاء من طولها.",
        "Enregistrez le message vocal ; bits requis et durée minimale de couverture selon sa longueur.");
    public string EmbedPayloadImageHint => T(
        "یک عکس انتخاب کنید؛ به‌صورت JPEG فشرده می‌شود تا در سقف بیت تنظیمات جا شود. سپس صوت پوشش را ضبط یا بارگذاری کنید.",
        "Pick an image; it is compressed to JPEG to fit the settings bit budget. Then record or load the cover audio.",
        "اختر صورة؛ تُضغط إلى JPEG لتناسب حد البت. ثم سجّل أو حمّل صوت الغطاء.",
        "Choisissez une image ; elle est compressée en JPEG pour tenir dans le budget de bits. Puis enregistrez ou chargez l’audio de couverture.");
    public string EmbedPayloadImageHintDynamic => T(
        "یک عکس انتخاب کنید؛ بیت مورد نیاز و حداقل زمان ضبط پوشش بر اساس حجم فشرده‌شده محاسبه می‌شود.",
        "Pick an image; required bits and minimum cover recording time are calculated from the compressed size.",
        "اختر صورة؛ تُحسب البتات والمدة الدنيا لتسجيل الغطاء من الحجم المضغوط.",
        "Choisissez une image ; bits requis et durée minimale de couverture selon la taille compressée.");
    public string PickPayloadImage => T(
        "انتخاب عکس", "Pick image", "اختيار صورة", "Choisir une image");
    public string ClearPayloadImage => T(
        "حذف عکس", "Clear image", "مسح الصورة", "Effacer l’image");
    public string PayloadImageReady => T(
        "عکس آماده است — اکنون صوت پوشش را ضبط یا بارگذاری کنید.",
        "Image payload ready — now record or load the cover audio.",
        "الصورة جاهزة — سجّل أو حمّل صوت الغطاء الآن.",
        "Image prête — enregistrez ou chargez maintenant l’audio de couverture.");
    public string PayloadImageBudgetLabel(int usedBits, int budgetBits) => _lang switch
    {
        AppLanguage.Fa => $"بیت عکس: {usedBits} / {budgetBits}",
        AppLanguage.En => $"Image bits: {usedBits} / {budgetBits}",
        AppLanguage.Ar => $"بت الصورة: {usedBits} / {budgetBits}",
        AppLanguage.Fr => $"Bits image : {usedBits} / {budgetBits}",
        _ => $"بیت عکس: {usedBits} / {budgetBits}",
    };
    public string PayloadImageBitsRequired(int usedBits) => _lang switch
    {
        AppLanguage.Fa => $"بیت مورد نیاز عکس: {usedBits}",
        AppLanguage.En => $"Image bits required: {usedBits}",
        AppLanguage.Ar => $"بتات الصورة المطلوبة: {usedBits}",
        AppLanguage.Fr => $"Bits image requis : {usedBits}",
        _ => $"بیت مورد نیاز عکس: {usedBits}",
    };
    public string PayloadAudioBudgetLabel(int usedBits, int budgetBits) => _lang switch
    {
        AppLanguage.Fa => $"بیت پیام صوتی: {usedBits} / {budgetBits}",
        AppLanguage.En => $"Voice bits: {usedBits} / {budgetBits}",
        AppLanguage.Ar => $"بت الرسالة: {usedBits} / {budgetBits}",
        AppLanguage.Fr => $"Bits vocaux : {usedBits} / {budgetBits}",
        _ => $"بیت پیام صوتی: {usedBits} / {budgetBits}",
    };
    public string PayloadAudioBitsRequired(int usedBits) => _lang switch
    {
        AppLanguage.Fa => $"بیت مورد نیاز پیام صوتی: {usedBits}",
        AppLanguage.En => $"Voice bits required: {usedBits}",
        AppLanguage.Ar => $"بتات الرسالة المطلوبة: {usedBits}",
        AppLanguage.Fr => $"Bits vocaux requis : {usedBits}",
        _ => $"بیت مورد نیاز پیام صوتی: {usedBits}",
    };
    public string CoverRecordNeedHint(int bits, int seconds) => _lang switch
    {
        AppLanguage.Fa => $"حداقل ضبط پوشش حدود {seconds} ثانیه (برای {bits} بیت).",
        AppLanguage.En => $"Minimum cover recording ≈ {seconds} s (for {bits} bits).",
        AppLanguage.Ar => $"الحد الأدنى لتسجيل الغطاء ≈ {seconds} ثانية (لـ {bits} بت).",
        AppLanguage.Fr => $"Enregistrement couverture mini ≈ {seconds} s (pour {bits} bits).",
        _ => $"حداقل ضبط پوشش حدود {seconds} ثانیه (برای {bits} بیت).",
    };
    public string ErrorEmptyPayloadImage => T(
        "ابتدا یک عکس انتخاب کنید.",
        "Pick an image payload first.",
        "اختر صورة أولاً.",
        "Choisissez d’abord une image.");
    public string ErrorPayloadImageBudget => T(
        "عکس حتی پس از فشرده‌سازی در سقف بیت تنظیمات جا نمی‌شود.",
        "Image cannot fit the settings bit budget even after compression.",
        "لا يمكن للصورة أن تناسب حد البت حتى بعد الضغط.",
        "L’image ne tient pas dans le budget de bits même après compression.");
    public string ErrorPayloadImageDecode => T(
        "فایل تصویر پشتیبانی نمی‌شود یا خراب است.",
        "Unsupported or corrupt image file.",
        "ملف الصورة غير مدعوم أو تالف.",
        "Fichier image non pris en charge ou corrompu.");
    public string RecordPayloadAudio => T(
        "ضبط پیام صوتی", "Record voice payload",
        "تسجيل الرسالة الصوتية", "Enregistrer le message vocal");
    public string StopPayloadAudio => T(
        "پایان ضبط پیام", "Stop payload recording",
        "إيقاف تسجيل الرسالة", "Arrêter l’enregistrement du message");
    public string ClearPayloadAudio => T(
        "حذف پیام صوتی", "Clear voice payload",
        "مسح الرسالة الصوتية", "Effacer le message vocal");
    public string PayloadAudioReady => T(
        "پیام صوتی آماده است — اکنون صوت پوشش را ضبط یا بارگذاری کنید.",
        "Voice payload ready — now record or load the cover audio.",
        "الرسالة الصوتية جاهزة — سجّل أو حمّل صوت الغطاء الآن.",
        "Message vocal prêt — enregistrez ou chargez maintenant l’audio de couverture.");
    public string ErrorEmptyPayloadAudio => T(
        "ابتدا پیام صوتی را ضبط کنید.",
        "Record the voice payload first.",
        "سجّل الرسالة الصوتية أولاً.",
        "Enregistrez d’abord le message vocal.");
    public string ErrorPayloadAudioBudget => T(
        "طول پیام صوتی از سقف بیت تنظیمات بیشتر است.",
        "Voice payload exceeds the settings bit budget.",
        "تجاوزت الرسالة الصوتية حد البت في الإعدادات.",
        "Le message vocal dépasse le budget de bits des paramètres.");
    public string ExtractedAudio => T(
        "صوت استخراج‌شده", "Extracted audio",
        "الصوت المستخرج", "Audio extrait");
    public string ExtractedImage => T(
        "عکس استخراج‌شده", "Extracted image",
        "الصورة المستخرجة", "Image extraite");
    public string SaveExtractedImage => T(
        "ذخیره عکس استخراج‌شده", "Save extracted image",
        "حفظ الصورة المستخرجة", "Enregistrer l’image extraite");
    public string SaveExtractedAudio => T(
        "ذخیره صوت استخراج‌شده", "Save extracted audio",
        "حفظ الصوت المستخرج", "Enregistrer l’audio extrait");
    public string PlayExtractedAudio => T(
        "پخش صوت استخراج‌شده", "Play extracted audio",
        "تشغيل الصوت المستخرج", "Lire l’audio extrait");
    public string ExtractUnsupportedType => T(
        "این نوع محتوا در این نسخه پشتیبانی نمی‌شود.",
        "This content type is not supported in this version.",
        "نوع المحتوى هذا غير مدعوم في هذا الإصدار.",
        "Ce type de contenu n’est pas pris en charge dans cette version.");
    public string StartRecording => T("شروع ضبط", "Start Recording", "بدء التسجيل", "Démarrer l’enregistrement");
    public string StopRecording => T("پایان ضبط", "Stop Recording", "إيقاف التسجيل", "Arrêter l’enregistrement");
    public string SaveStego => T(
        "ذخیره فایل نهان‌نگاری شده", "Save stego file",
        "حفظ ملف الإخفاء", "Enregistrer le fichier stégo");
    public string SuccessSaved => T("فایل ذخیره شد", "File saved", "تم حفظ الملف", "Fichier enregistré");
    public string OperationSuccess => T(
        "عملیات با موفقیت انجام شد", "Operation completed successfully",
        "تمت العملية بنجاح", "Opération terminée avec succès");
    public string OperationSuccessSubtitle => T(
        "فایل نهان‌نگاری‌شده آماده ذخیره، اشتراک و مقایسه است.",
        "Your stego file is ready to save, share, and compare.",
        "ملف الإخفاء جاهز للحفظ والمشاركة والمقارنة.",
        "Le fichier stégo est prêt à être enregistré, partagé et comparé.");
    public string AnalysisSectionTitle => T(
        "تحلیل موج و کیفیت", "Waveform & quality analysis",
        "تحليل الموجة والجودة", "Analyse forme d’onde et qualité");
    public string EmbedCompleteTitle => T(
        "نهان‌نگاری انجام شد", "Embedding complete", "اكتمل الإخفاء", "Intégration terminée");
    public string ExtractCompleteTitle => T(
        "رمزگشایی انجام شد", "Extraction complete", "اكتمل الاستخراج", "Extraction terminée");
    public string ExtractSuccessSubtitle => T(
        "پیام بازیابی‌شده آماده کپی یا ذخیره است.",
        "Your recovered payload is ready to copy or save.",
        "الحمولة المستعادة جاهزة للنسخ أو الحفظ.",
        "La charge utile récupérée est prête à être copiée ou enregistrée.");
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
            $"نهان‌نگاری و رمزگشایی همیشه با {bits} بیت انجام می‌شود؛ طول پیام از شما پرسیده نمی‌شود. برای تب صوت Embed حدود ۴ ثانیه صوت ۸کیلوهرتز (PCM u8) در این سقف جا می‌شود.",
        AppLanguage.Ar =>
            $"الإخفاء والاستخراج دائماً بـ {bits} بت؛ لا يُطلب طول الرسالة. في تب الصوت حوالي ٤ ثوانٍ بصوت ٨ كيلوهرتز (PCM u8) ضمن هذا الحد.",
        AppLanguage.Fr =>
            $"Intégration et extraction à {bits} bits ; la longueur n’est pas demandée. Onglet Audio : environ 4 s de voix 8 kHz PCM u8 dans ce budget.",
        _ =>
            $"Embed and extract always use {bits} bits; message length is not asked. On the Embed Audio tab, about 4 seconds of 8 kHz PCM u8 voice fits this budget.",
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
    public string RecordingMinProgress => T(
        "در حال رسیدن به حداقل زمان لازم برای نهان‌نگاری…",
        "Reaching the minimum duration required for steganography…",
        "جارٍ الوصول إلى الحد الأدنى من المدة المطلوبة…",
        "Atteinte de la durée minimale requise…");
    public string RecordingMinRemaining(int seconds) => _lang switch
    {
        AppLanguage.Fa => $"حدود {seconds} ثانیه تا حداقل زمان",
        AppLanguage.Ar => $"حوالي {seconds} ثانية حتى الحد الأدنى",
        AppLanguage.Fr => $"Environ {seconds} s avant la durée minimale",
        _ => $"About {seconds} s until minimum duration",
    };
    public string RecordingMinReached => T(
        "حداقل زمان تأمین شد — می‌توانید ضبط را متوقف کنید",
        "Minimum duration reached — you can stop recording",
        "اكتملت المدة الدنيا — يمكنك إيقاف التسجيل",
        "Durée minimale atteinte — vous pouvez arrêter");
    public string PayloadRecordCapacityProgress => T(
        "در حال پر شدن ظرفیت فضای نهان‌نگاری برای صوت مخفی…",
        "Filling steganography capacity for the hidden voice…",
        "جارٍ ملء سعة الإخفاء للصوت المخفي…",
        "Remplissage de la capacité pour la voix cachée…");
    public string PayloadRecordCapacityRemaining(int seconds) => _lang switch
    {
        AppLanguage.Fa => $"حدود {seconds} ثانیه تا پر شدن ظرفیت",
        AppLanguage.Ar => $"حوالي {seconds} ثانية حتى امتلاء السعة",
        AppLanguage.Fr => $"Environ {seconds} s avant capacité pleine",
        _ => $"About {seconds} s until capacity is full",
    };
    public string PayloadRecordCapacityFull => T(
        "ظرفیت پر شد — ضبط متوقف می‌شود",
        "Capacity full — recording will stop",
        "امتلأت السعة — سيتوقف التسجيل",
        "Capacité pleine — arrêt de l’enregistrement");
    public string RecordingTooShort(int seconds) => _lang switch
    {
        AppLanguage.Fa =>
            $"هنوز ظرفیت کافی ضبط نشده. ادامه دهید (حدود {seconds} ثانیه بر اساس نمونه‌های واقعی).",
        AppLanguage.Ar =>
            $"لم تُسجَّل عينات كافية بعد. واصل (حوالي {seconds} ثانية حسب المخزن الفعلي).",
        AppLanguage.Fr =>
            $"Pas assez d’échantillons. Continuez (environ {seconds} s selon le tampon réel).",
        _ =>
            $"Not enough samples yet. Keep recording (about {seconds} s based on real buffer).",
    };
    public string ErrorEmpty => T(
        "متن نمی‌تواند خالی باشد.", "Text cannot be empty.",
        "لا يمكن أن يكون النص فارغاً.", "Le texte ne peut pas être vide.");
    public string ErrorNoRecording => T(
        "صدایی ضبط نشده است.", "No recorded audio.",
        "لم يُسجَّل صوت.", "Aucun enregistrement audio.");
    public string EmbedWarningTitle => T(
        "هشدار", "Warning", "تحذير", "Avertissement");
    public string ErrorTooLong => T(
        "طول صدای ضبط‌شده باید بیشتر باشد تا نهان‌نگاری امکان‌پذیر باشد. مجدداً شروع به ضبط صدا کنید.",
        "Recorded audio must be longer before steganography can succeed. Please start recording again.",
        "يجب أن يكون الصوت المسجَّل أطول ليكون الإخفاء ممكناً. ابدأ التسجيل من جديد.",
        "L’audio enregistré doit être plus long pour que l’intégration soit possible. Recommencez l’enregistrement.");

    public string ErrorCapacityExceeded(int neededBits, int availableBits) => _lang switch
    {
        AppLanguage.Fa =>
            $"این محتوا در فایل صوتی جا نمی‌شود و قابل نهان‌نگاری نیست.\nبیت مورد نیاز: {neededBits}\nبیت موجود (ظرفیت پوشش): {availableBits}\nفایل صوتی طولانی‌تر انتخاب کنید یا محتوای کوچک‌تری بدهید.",
        AppLanguage.En =>
            $"This payload does not fit in the cover audio and cannot be embedded.\nBits required: {neededBits}\nBits available (cover capacity): {availableBits}\nUse a longer cover audio or a smaller payload.",
        AppLanguage.Ar =>
            $"هذا المحتوى لا يتسع في الصوت ولا يمكن إخفاؤه.\nالبتات المطلوبة: {neededBits}\nالبتات المتاحة (سعة الغلاف): {availableBits}\nاختر صوتاً أطول أو محتوى أصغر.",
        AppLanguage.Fr =>
            $"Cette charge utile ne tient pas dans l’audio de couverture.\nBits requis : {neededBits}\nBits disponibles (capacité) : {availableBits}\nChoisissez un audio plus long ou une charge plus petite.",
        _ =>
            $"این محتوا در فایل صوتی جا نمی‌شود و قابل نهان‌نگاری نیست.\nبیت مورد نیاز: {neededBits}\nبیت موجود (ظرفیت پوشش): {availableBits}\nفایل صوتی طولانی‌تر انتخاب کنید یا محتوای کوچک‌تری بدهید.",
    };
    public string ErrorMp3Decode => T(
        "خواندن فایل MP3 ممکن نشد. فایل را دوباره انتخاب کنید یا از WAV استفاده کنید.",
        "Could not read the MP3 file. Pick the file again or use WAV.",
        "تعذر قراءة ملف MP3. اختر الملف مرة أخرى أو استخدم WAV.",
        "Impossible de lire le MP3. Réessayez ou utilisez un WAV.");
    public string ErrorMp4Decode => T(
        "خواندن فایل MP4 ممکن نشد. فایل را دوباره انتخاب کنید یا از WAV استفاده کنید.",
        "Could not read the MP4 file. Pick the file again or use WAV.",
        "تعذر قراءة ملف MP4. اختر الملف مرة أخرى أو استخدم WAV.",
        "Impossible de lire le MP4. Réessayez ou utilisez un WAV.");
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
        "تأیید موفق ✓ محتوای استخراج‌شده با اصل یکی است (و فقط LSB نسبت به صوت پوشش تغییر کرده).",
        "Verified ✓ recovered payload matches the original (cover changed only in LSBs).",
        "تم التحقق ✓ المحتوى المستخرج يطابق الأصل (تغيّر الغطاء في LSB فقط).",
        "Vérifié ✓ charge utile identique à l’original (couverture modifiée seulement en LSB).");
    public string VerifyMismatch => T(
        "تأیید ناموفق! محتوای استخراج‌شده با اصل تطابق ندارد.",
        "Mismatch! recovered payload differs from the original.",
        "فشل التحقق! المحتوى المستخرج يختلف عن الأصل.",
        "Échec ! la charge utile extraite diffère de l’original.");
    public string ErrorEmbedIntegrity => T(
        "نهان‌نگاری رد شد: فایل استگو با پیام اصلی تطبیق ندارد (تست یکپارچگی لحظه‌ای ناموفق).",
        "Embed rejected: stego file failed the immediate integrity check against the original payload.",
        "رُفض الإخفاء: فشل فحص سلامة الملف المخفي مقابل المحتوى الأصلي.",
        "Intégration rejetée : le fichier stégo a échoué au contrôle d’intégrité immédiat.");
    public string VerifyEmpty => T(
        "چیزی استخراج نشد — embed با شکست مواجه شده است.", "Nothing extracted — embed seems broken.",
        "لم يُستخرج شيء — يبدو أن الإخفاء فشل.", "Rien extrait — l’intégration semble avoir échoué.");
    public string VerifyRecoveredTitle => T(
        "مقایسه محتوا — اصل نهان‌شده و بازیافت‌شده",
        "Payload compare — original hidden vs recovered",
        "مقارنة المحتوى — الأصلي المخفي والمستخرج",
        "Comparaison — original caché vs extrait");
    public string OriginalHiddenPayload => T(
        "محتوای اصلی نهان‌شده", "Original hidden payload",
        "المحتوى الأصلي المخفي", "Charge utile originale");
    public string RecoveredPayloadLabel => T(
        "محتوای بازیافت‌شده", "Recovered payload",
        "المحتوى المستخرج", "Charge utile extraite");
    public string PlayOriginalPayloadAudio => T(
        "پخش صوت اصلی نهان‌شده", "Play original hidden audio",
        "تشغيل الصوت الأصلي المخفي", "Lire l’audio original caché");
    public string VerifyAbListenTitle => T(
        "مقایسه شنیداری — آیا تفاوتی حس می‌کنید؟",
        "A/B listen — can you hear a difference?",
        "مقارنة سمعية — هل تلاحظ فرقاً؟",
        "Écoute A/B — entendez-vous une différence ?");
    public string AbListenOriginalShort => T("اصلی", "Original", "أصلي", "Original");
    public string AbListenStegoShort => T(
        "نهان‌نگاری‌شده", "Watermarked", "مُخفى", "Watermarké");
    public string PlayOriginalCover => T(
        "پخش صدای اصلی", "Play original",
        "تشغيل الأصلي", "Lire l’original");
    public string PlayStegoAudio => T(
        "پخش بعد از نهان‌نگاری", "Play after watermark",
        "تشغيل بعد الإخفاء", "Lire après stéganographie");
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
