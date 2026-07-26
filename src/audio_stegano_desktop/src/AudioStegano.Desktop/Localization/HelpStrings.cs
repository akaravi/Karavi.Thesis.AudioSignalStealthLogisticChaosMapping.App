namespace AudioStegano.Desktop.Localization;

public sealed partial class AppStrings
{
    public string HelpTitle => T("راهنمای کامل", "Full guide", "الدليل الكامل", "Guide complet");
    public string HelpTooltip => T(
        "راهنمای استفاده",
        "Usage help",
        "دليل الاستخدام",
        "Aide à l’utilisation");

    public string HelpSectionOverview => T(
        "این برنامه چه می‌کند؟",
        "What this app does",
        "ماذا يفعل هذا التطبيق؟",
        "Ce que fait l’application");
    public string HelpOverviewBody => T(
        "صوت‌نهان ابزاری برای پنهان‌سازی پیام متنی داخل فایل صوتی است. متن شما با "
            + "روش LSB و یک کلید آشوب (پارامترهای r و x0) داخل موج صدا جاسازی می‌شود "
            + "و فقط با همان کلید و طول پیام قابل بازیابی است. تمام پردازش روی "
            + "دستگاه شما انجام می‌شود.",
        "AudioStegano hides a text message inside an audio file. Your text is embedded "
            + "in the waveform using LSB and a chaotic key (r and x0). The message "
            + "can only be recovered with the same key and message length. All "
            + "processing runs on your device.",
        "إخفاء الرسالة في الصوت يضع نصك داخل موجة صوتية بطريقة LSB ومفتاح فوضوي "
            + "(r و x0). يمكن استرجاع الرسالة فقط بنفس المفتاح وطول الرسالة. "
            + "تتم جميع المعالجة على جهازك.",
        "AudioStegano cache un message texte dans un fichier audio via LSB et une "
            + "clé chaotique (r et x0). Le message ne peut être récupéré qu’avec la "
            + "même clé et la même longueur. Tout est traité sur votre appareil.");

    public string HelpSectionTabs => T("تب‌های برنامه", "App tabs", "علامات التبويب", "Onglets de l’application");
    public string HelpTabsBody => T(
        "• نهان‌نگاری: پنهان‌سازی پیام در صوت\n"
            + "• رمزگشایی: استخراج پیام از فایل صوتی\n"
            + "• تنظیمات: تم (روشن/تاریک)، زبان و پارامترهای کلید (r و x0)\n"
            + "• درباره ما: معرفی پروژه و راه‌های ارتباط",
        "• Embed: hide a message inside audio\n"
            + "• Extract: recover the message from an audio file\n"
            + "• Settings: theme (light/dark), language and key params (r, x0)\n"
            + "• About: project info and contact links",
        "• الإخفاء: إدراج رسالة داخل الصوت\n"
            + "• الاستخراج: استرجاع الرسالة من ملف صوتي\n"
            + "• الإعدادات: المظهر (فاتح/داكن) واللغة ومعاملات المفتاح (r و x0)\n"
            + "• من نحن: معلومات المشروع وروابط التواصل",
        "• Intégrer : cacher un message dans l’audio\n"
            + "• Extraire : récupérer le message depuis un fichier audio\n"
            + "• Paramètres : thème (clair/sombre), langue et clé (r, x0)\n"
            + "• À propos : projet et contact");

    public string HelpSectionEmbedSteps => T(
        "مراحل نهان‌نگاری",
        "Embed steps",
        "خطوات الإخفاء",
        "Étapes d’intégration");
    public string HelpEmbedStep1 => T(
        "۱) متن پیام: در کادر «متن پیام را اینجا تایپ کنید…» متن مورد نظر را وارد کنید.",
        "1) Message: type your text into the “Type your secret message…” box.",
        "١) الرسالة: اكتب نصك في حقل «اكتب رسالتك السرية هنا…».",
        "1) Message : saisissez votre texte dans le champ « Saisissez votre message secret… ».");
    public string HelpEmbedStep2 => T(
        "۲) انتخاب منبع صدا: روی «شروع ضبط» بزنید تا با میکروفن صدا ضبط شود، یا "
            + "«بارگذاری فایل» را برای انتخاب WAV/MP3 از حافظه دستگاه بزنید.",
        "2) Choose audio source: tap “Start Recording” to record with the mic, or "
            + "“Upload file” to pick a WAV/MP3 from your device.",
        "٢) اختر مصدر الصوت: اضغط «بدء التسجيل» للتسجيل بالميكروفون، أو «رفع ملف» "
            + "لاختيار WAV/MP3 من جهازك.",
        "2) Source audio : appuyez sur « Démarrer l’enregistrement » pour le micro, "
            + "ou « Importer un fichier » pour choisir un WAV/MP3.");
    public string HelpEmbedStep3 => T(
        "۳) پایان ضبط و پردازش: اگر در حال ضبط هستید روی «پایان ضبط» بزنید؛ "
            + "پردازش به‌صورت خودکار آغاز می‌شود و فایل نهان‌نگاری‌شده ساخته می‌شود.",
        "3) Stop & process: tap “Stop Recording”; processing starts automatically "
            + "and the stego file is produced.",
        "٣) إنهاء التسجيل والمعالجة: اضغط «إيقاف التسجيل»؛ تبدأ المعالجة تلقائياً "
            + "وينشأ ملف الإخفاء.",
        "3) Arrêter et traiter : appuyez sur « Arrêter l’enregistrement » ; le "
            + "traitement démarre et produit le fichier stégo.");
    public string HelpEmbedStep4 => T(
        "۴) ثبت «طول پیام (بیت)»: پنجره‌ای ظاهر می‌شود که یک عدد را به‌عنوان طول "
            + "پیام به بیت نمایش می‌دهد. این عدد را حتماً کپی یا یادداشت کنید — "
            + "برای رمزگشایی الزامی است.",
        "4) Save the message-length: a dialog shows a bit length. You MUST copy or "
            + "note this number — it is required to recover the message.",
        "٤) احفظ «طول الرسالة (بت)»: يظهر مربع حوار يعرض عدد البتات. انسخ هذا "
            + "الرقم أو دوّنه — فهو ضروري للاستعادة.",
        "4) Notez la longueur (bits) : une boîte de dialogue affiche un nombre de "
            + "bits. Copiez ou notez impérativement ce nombre — il est requis pour "
            + "l’extraction.");
    public string HelpEmbedStep5 => T(
        "۵) پخش و مقایسه: صدای اصلی (پوشش) و صدای بعد از نهان‌نگاری را جداگانه پخش "
            + "کنید تا بشنوید آیا تفاوتی حس می‌کنید؛ نمودار موج و متریک‌های کیفیت "
            + "(SNR، PSNR، …) را هم ببینید.",
        "5) Play & compare: play original cover and watermarked stego separately to "
            + "judge perceptual difference; also compare waveforms and quality metrics "
            + "(SNR, PSNR, …).",
        "٥) التشغيل والمقارنة: شغّل الغلاف الأصلي والصوت بعد الإخفاء لمعرفة إن كان هناك "
            + "فرق مسموع؛ قارن الموجات ومقاييس الجودة (SNR، PSNR، …).",
        "5) Lecture et comparaison : écoutez l’original et le stégo séparément pour "
            + "juger la différence perceptuelle ; comparez aussi ondes et métriques "
            + "(SNR, PSNR, …).");
    public string HelpEmbedStep6 => T(
        "۶) تأیید فوری: پس از نهان‌سازی (و با دکمه «تأیید فوری») پیام استخراج می‌شود؛ "
            + "اصل نهان‌شده و نسخهٔ بازیافت‌شده (متن/صوت/عکس) کنار هم نمایش داده می‌شوند؛ "
            + "همچنین می‌توانید صدای پوشش و استگو را مقایسه کنید.",
        "6) Immediate verify: after embed (and via “Verify”) the payload is extracted; "
            + "original hidden vs recovered content (text/audio/image) are shown together; "
            + "you can also A/B-play cover vs stego.",
        "٦) تحقق فوري: بعد الإخفاء تُستخرج الرسالة؛ يُعرض الأصلي المخفي والمستخرج "
            + "(نص/صوت/صورة) معاً؛ ويمكنك أيضاً مقارنة الغلاف بالمخفي.",
        "6) Vérification rapide : extraction ; original caché vs extrait (texte/audio/image) "
            + "affichés ensemble ; écoute A/B cover vs stégo aussi.");
    public string HelpEmbedStep7 => T(
        "۷) ذخیره یا اشتراک‌گذاری: روی «ذخیره فایل نهان‌نگاری شده» بزنید یا از "
            + "آیکن اشتراک‌گذاری برای فرستادن فایل WAV استفاده کنید. توصیه: فایل را "
            + "به‌صورت «فایل» (Attachment) ارسال کنید، نه «صدای ضبط شده»، تا "
            + "فشرده‌سازی پیام‌رسان داده نهان را خراب نکند.",
        "7) Save or share: tap “Save stego file” or the share icon to send the WAV. "
            + "Tip: send it as a FILE attachment (not as voice/audio), so the "
            + "messenger does not recompress and destroy the hidden data.",
        "٧) الحفظ أو المشاركة: اضغط «حفظ ملف الإخفاء» أو أيقونة المشاركة لإرسال WAV. "
            + "انصح: أرسله كملف (مرفق) لا كرسالة صوتية لئلا يخرّب التطبيق ضغط البيانات.",
        "7) Enregistrer ou partager : « Enregistrer le fichier stégo » ou icône de "
            + "partage. Astuce : envoyez le WAV comme PIÈCE JOINTE (pas comme audio) "
            + "pour éviter la recompression.");
    public string HelpEmbedStep8 => T(
        "۸) نهان‌نگاری جدید: برای شروع دوباره و پاک کردن وضعیت فعلی، روی آیکن "
            + "«نهان‌نگاری جدید» در بالای صفحه بزنید.",
        "8) New embed: tap the “New embed” icon at the top to clear state and "
            + "start over.",
        "٨) إخفاء جديد: اضغط أيقونة «إخفاء جديد» في الأعلى لبدء جلسة جديدة.",
        "8) Nouvel intégration : touchez l’icône « Nouvel intégration » en haut pour "
            + "tout réinitialiser.");

    public string HelpSectionExtractSteps => T(
        "مراحل رمزگشایی",
        "Extract steps",
        "خطوات الاستخراج",
        "Étapes d’extraction");
    public string HelpExtractStep1 => T(
        "۱) انتخاب فایل: روی «انتخاب فایل صوتی (WAV/MP3)» بزنید و فایل "
            + "نهان‌نگاری‌شده را از حافظه دستگاه انتخاب کنید.",
        "1) Pick file: tap “Pick audio file (WAV/MP3)” and choose the stego file "
            + "from your device.",
        "١) اختر الملف: اضغط «اختر ملف صوت (WAV/MP3)» وحدّد ملف الإخفاء.",
        "1) Choisir le fichier : touchez « Choisir un fichier audio (WAV/MP3) » "
            + "et sélectionnez le fichier stégo.");
    public string HelpExtractStep2 => T(
        "۲) وارد کردن «طول پیام (بیت)»: همان عددی را که هنگام نهان‌نگاری ذخیره "
            + "کرده‌اید در کادر «طول پیام به بیت» وارد کنید. بدون این عدد، "
            + "رمزگشایی ممکن نیست.",
        "2) Enter message-length: type the same bit count you saved when embedding "
            + "into “Message length (bits)”. Without it, extraction is impossible.",
        "٢) أدخل «طول الرسالة (بت)»: نفس الرقم الذي حفظته عند الإخفاء. "
            + "بدونه لا يمكن الاستخراج.",
        "2) Saisissez la longueur (bits) : le même nombre qu’à l’intégration. "
            + "Sans cela, l’extraction est impossible.");
    public string HelpExtractStep3 => T(
        "۳) پارامترهای کلید: در تب تنظیمات، مقادیر r و x0 باید دقیقاً همان "
            + "مقادیری باشند که هنگام نهان‌نگاری استفاده شده‌اند.",
        "3) Key parameters: in Settings, r and x0 must match those used when embedding.",
        "٣) معاملات المفتاح: في الإعدادات يجب أن تطابق r و x0 قيم الإخفاء.",
        "3) Clé : dans Paramètres, r et x0 doivent correspondre à l’intégration.");
    public string HelpExtractStep4 => T(
        "۴) پخش (اختیاری): با دکمه‌های پخش/مکث/توقف می‌توانید مطمئن شوید فایل "
            + "انتخابی همان فایل صحیح است.",
        "4) Playback (optional): play/pause/stop to confirm the selected file is "
            + "the correct one.",
        "٤) التشغيل (اختياري): تشغيل/إيقاف للتأكد من الملف الصحيح.",
        "4) Lecture (optionnel) : lire/pause/arrêter pour vérifier le bon fichier.");
    public string HelpExtractStep5 => T(
        "۵) رمزگشایی: روی دکمه «رمزگشایی» بزنید. در صورت موفقیت، متن بازیابی‌شده "
            + "در کادر «متن استخراج شده» نمایش داده می‌شود.",
        "5) Extract: tap the “Extract” button. On success, the recovered text "
            + "appears in the “Extracted text” card.",
        "٥) الاستخراج: اضغط زر «استخراج». عند النجاح يظهر النص في بطاقة «النص المستخرج».",
        "5) Extraire : touchez « Extraire ». En cas de succès, le texte apparaît "
            + "dans la carte « Texte extrait ».");
    public string HelpExtractStep6 => T(
        "۶) کپی نتیجه: روی دکمه «کپی» در پایین کارت بزنید تا متن استخراج‌شده "
            + "به حافظه کپی شود.",
        "6) Copy result: tap the “Copy” button at the bottom of the result card "
            + "to copy the extracted text to clipboard.",
        "٦) انسخ النتيجة: اضغط زر «نسخ» في أسفل البطاقة لنسخ النص.",
        "6) Copier : touchez « Copier » au bas de la carte pour copier le texte.");

    public string HelpSectionTips => T("نکات مهم", "Important tips", "نصائح مهمة", "Conseils importants");
    public string HelpTipsBody => T(
        "• «طول پیام (بیت)» و مقادیر r و x0 برای رمزگشایی الزامی‌اند — همه را با هم "
            + "یادداشت کنید.\n"
            + "• پردازش فقط روی دستگاه شماست؛ پیام یا فایل به سرور ارسال نمی‌شود.\n"
            + "• خروجی فایل WAV است و نباید مجدداً فشرده‌سازی شود.\n"
            + "• هنگام ارسال فایل از پیام‌رسان‌ها، فایل را به‌صورت «فایل/سند» ضمیمه "
            + "کنید نه به‌صورت «صدای ضبط شده».",
        "• Message length (bits), r and x0 are required to extract — keep them "
            + "together.\n"
            + "• Processing is on-device; nothing is uploaded.\n"
            + "• Output is a WAV; do not recompress it.\n"
            + "• When sharing on messengers, send the file as a FILE/document "
            + "attachment, not as a voice message.",
        "• طول الرسالة (بت) و r و x0 ضرورية للاستخراج — احفظها معاً.\n"
            + "• المعالجة على الجهاز فقط؛ لا يُرفع شيء.\n"
            + "• الإخراج WAV ولا يجب ضغطه مرة أخرى.\n"
            + "• عند المشاركة عبر التطبيقات، أرسله كملف/مستند لا كرسالة صوتية.",
        "• La longueur (bits), r et x0 sont indispensables — conservez-les ensemble.\n"
            + "• Traitement local uniquement ; aucun envoi.\n"
            + "• La sortie est un WAV ; ne pas recompresser.\n"
            + "• Sur messagerie, envoyez le fichier comme PIÈCE JOINTE, pas comme "
            + "message vocal.");
}
