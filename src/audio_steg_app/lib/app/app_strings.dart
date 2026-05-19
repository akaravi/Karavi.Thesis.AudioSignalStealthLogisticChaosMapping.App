import 'package:flutter/widgets.dart';

import 'app_locale.dart';

/// Built-in localization: fa (base), en, ar, fr — no gen_l10n.
class _S {
  final String fa;
  final String en;
  final String ar;
  final String fr;
  const _S(this.fa, this.en, this.ar, this.fr);
}

class AppStrings {
  final AppLocale locale;
  const AppStrings(this.locale);

  static AppStrings of(BuildContext context) {
    return AppStrings(
      AppLocaleCodes.fromLanguageCode(
        Localizations.localeOf(context).languageCode,
      ),
    );
  }

  String _t(_S s) => switch (locale) {
    AppLocale.fa => s.fa,
    AppLocale.en => s.en,
    AppLocale.ar => s.ar,
    AppLocale.fr => s.fr,
  };

  /// Full product name — explains hiding text messages inside audio files.
  String get appTitle => _t(
    const _S(
      'نهان‌نگاری پیام در صوت',
      'Audio Steganography',
      'إخفاء الرسالة في الصوت',
      'Stéganographie du message audio',
    ),
  );

  /// Short label for home screen, PWA icon, and task switcher.
  String get appShortTitle =>
      _t(const _S('صوت‌نهان', 'AudioSteg', 'صوت خفي', 'AudioSteg'));
  String get embedTab =>
      _t(const _S('نهان‌نگاری', 'Embed', 'إخفاء', 'Intégrer'));
  String get extractTab =>
      _t(const _S('رمزگشایی', 'Extract', 'استخراج', 'Extraire'));
  String get settingsTab =>
      _t(const _S('تنظیمات', 'Settings', 'الإعدادات', 'Paramètres'));
  String get aboutUsTab =>
      _t(const _S('درباره ما', 'About us', 'من نحن', 'À propos'));
  String get textHint => _t(
    const _S(
      'متن پیام را اینجا تایپ کنید…',
      'Type your secret message…',
      'اكتب رسالتك السرية هنا…',
      'Saisissez votre message secret…',
    ),
  );
  String get startRecording => _t(
    const _S(
      'شروع ضبط',
      'Start Recording',
      'بدء التسجيل',
      'Démarrer l’enregistrement',
    ),
  );
  String get stopRecording => _t(
    const _S(
      'پایان ضبط',
      'Stop Recording',
      'إيقاف التسجيل',
      'Arrêter l’enregistrement',
    ),
  );
  String get cancelRecording =>
      _t(const _S('لغو', 'Cancel', 'إلغاء', 'Annuler'));
  String get saveStego => _t(
    const _S(
      'ذخیره فایل نهان‌نگاری شده',
      'Save stego file',
      'حفظ ملف الإخفاء',
      'Enregistrer le fichier stégo',
    ),
  );
  String get share =>
      _t(const _S('اشتراک‌گذاری', 'Share', 'مشاركة', 'Partager'));
  String get shareStego => _t(
    const _S(
      'اشتراک‌گذاری فایل صوتی',
      'Share stego audio file',
      'مشاركة ملف الصوت',
      'Partager le fichier audio stégo',
    ),
  );
  String get fromFile =>
      _t(const _S('از فایل', 'From file', 'من ملف', 'Depuis un fichier'));
  String get loadAudioFile => _t(
    const _S('بارگذاری فایل', 'Upload file', 'رفع ملف', 'Importer un fichier'),
  );
  String get audioSourceOr => _t(const _S('یا', 'or', 'أو', 'ou'));
  String get pickFile => _t(
    const _S(
      'انتخاب فایل صوتی (WAV/MP3)',
      'Pick audio file (WAV/MP3)',
      'اختر ملف صوت (WAV/MP3)',
      'Choisir un fichier audio (WAV/MP3)',
    ),
  );

  String audioFileLoaded(String name) => switch (locale) {
    AppLocale.fa => 'فایل بارگذاری شد: $name',
    AppLocale.en => 'Audio loaded: $name',
    AppLocale.ar => 'تم تحميل الملف: $name',
    AppLocale.fr => 'Fichier chargé : $name',
  };
  String get errorNoAudioLoaded => _t(
    const _S(
      'ابتدا فایل صوتی را بارگذاری کنید.',
      'Load an audio file first.',
      'حمّل ملفًا صوتيًا أولًا.',
      'Chargez d’abord un fichier audio.',
    ),
  );

  String get extractedText => _t(
    const _S(
      'متن استخراج شده',
      'Extracted text',
      'النص المستخرج',
      'Texte extrait',
    ),
  );
  String get noText => _t(
    const _S(
      'چیزی استخراج نشد',
      'Nothing extracted',
      'لم يُستخرج شيء',
      'Rien n’a été extrait',
    ),
  );
  String get copy => _t(const _S('کپی', 'Copy', 'نسخ', 'Copier'));
  String get copied => _t(const _S('کپی شد', 'Copied', 'تم النسخ', 'Copié'));
  String get themeMode => _t(const _S('تم', 'Theme', 'المظهر', 'Thème'));
  String get themeLight => _t(const _S('روشن', 'Light', 'فاتح', 'Clair'));
  String get themeDark => _t(const _S('تاریک', 'Dark', 'داكن', 'Sombre'));
  String get themeSystem =>
      _t(const _S('سیستم', 'System', 'النظام', 'Système'));
  String get language => _t(const _S('زبان', 'Language', 'اللغة', 'Langue'));
  String get chooseLanguage => _t(
    const _S(
      'زبان برنامه را انتخاب کنید',
      'Choose your language',
      'اختر لغة التطبيق',
      'Choisissez votre langue',
    ),
  );
  String get persian => _t(const _S('فارسی', 'Persian', 'الفارسية', 'Persan'));
  String get english =>
      _t(const _S('انگلیسی', 'English', 'الإنجليزية', 'Anglais'));
  String get arabic => _t(const _S('عربی', 'Arabic', 'العربية', 'Arabe'));
  String get french =>
      _t(const _S('فرانسوی', 'French', 'الفرنسية', 'Français'));
  String get embedBehaviorSettings => _t(
    const _S(
      'رفتار نهان‌نگاری',
      'Embed behavior',
      'سلوك الإخفاء',
      'Comportement d’intégration',
    ),
  );
  String get showEmbedRecoveryDialog => _t(
    const _S(
      'نمایش بازگردانی پس از نهان‌نگاری',
      'Show recovery prompt after embed',
      'عرض مطالبة الاستعادة بعد الإخفاء',
      'Afficher l’invite de récupération après intégration',
    ),
  );
  String get showEmbedRecoveryDialogHint => _t(
    const _S(
      'پس از نهان‌نگاری، پنجرهٔ یادآوری طول پیام (بیت) برای بازیابی نمایش داده شود.',
      'After embedding, show a dialog reminding you to save the message length (bits) for recovery.',
      'بعد الإخفاء، يُعرض مربع حوار لتذكيرك بحفظ طول الرسالة (بت) للاستعادة.',
      'Après l’intégration, afficher une boîte de dialogue pour noter la longueur du message (bits).',
    ),
  );
  String get logisticParams => _t(
    const _S(
      'پارامترهای آشوب لاجستیک',
      'Logistic chaos params',
      'معاملات الفوضى اللوجستية',
      'Paramètres du chaos logistique',
    ),
  );
  String get rParam =>
      _t(const _S('پارامتر r', 'r parameter', 'معامل r', 'Paramètre r'));
  String get x0Param => _t(
    const _S(
      'مقدار اولیه x0',
      'x0 initial',
      'القيمة الابتدائية x0',
      'Valeur initiale x0',
    ),
  );
  String get logisticRRangeHint => _t(
    const _S(
      'بازه مجاز: ۳٫۵ تا ۴٫۰',
      'Allowed range: 3.5 to 4.0',
      'النطاق المسموح: 3.5 إلى 4.0',
      'Plage autorisée : 3,5 à 4,0',
    ),
  );
  String get logisticX0RangeHint => _t(
    const _S(
      'بازه مجاز: ۰٫۰۱ تا ۰٫۹۹',
      'Allowed range: 0.01 to 0.99',
      'النطاق المسموح: 0.01 إلى 0.99',
      'Plage autorisée : 0,01 à 0,99',
    ),
  );
  String get logisticInvalidValue => _t(
    const _S(
      'مقدار خارج از بازه مجاز است.',
      'Value is outside the allowed range.',
      'القيمة خارج النطاق المسموح.',
      'La valeur est hors de la plage autorisée.',
    ),
  );
  String get colorSeed =>
      _t(const _S('رنگ تم', 'Theme color', 'لون المظهر', 'Couleur du thème'));
  String get permissionDenied => _t(
    const _S(
      'دسترسی به میکروفن رد شد.',
      'Microphone permission denied.',
      'تم رفض إذن الميكروفون.',
      'Autorisation du microphone refusée.',
    ),
  );
  String get errorEmpty => _t(
    const _S(
      'متن نمی‌تواند خالی باشد.',
      'Text cannot be empty.',
      'لا يمكن أن يكون النص فارغاً.',
      'Le texte ne peut pas être vide.',
    ),
  );
  String get errorTooLong => _t(
    const _S(
      'متن طولانی‌تر از ظرفیت صدای ضبط شده است.',
      'Text too long for the recorded audio.',
      'النص أطول من سعة الصوت المسجل.',
      'Texte trop long pour l’audio enregistré.',
    ),
  );
  String get successSaved => _t(
    const _S(
      'فایل ذخیره شد',
      'File saved',
      'تم حفظ الملف',
      'Fichier enregistré',
    ),
  );
  String get embedCompleteTitle => _t(
    const _S(
      'نهان‌نگاری انجام شد',
      'Embedding complete',
      'اكتمل الإخفاء',
      'Intégration terminée',
    ),
  );
  String get embedRecoveryMessage => _t(
    const _S(
      'برای بازیابی عبارت نهانگاری‌شده عدد طول پیام را یادداشت فرمایید',
      'To recover the hidden phrase, please note the message length number',
      'لاستعادة العبارة المخفية، يُرجى تدوين رقم طول الرسالة',
      'Pour récupérer la phrase cachée, notez le nombre de bits du message',
    ),
  );

  String embedRecoveryCapacityHint(int capacityBits) => switch (locale) {
    AppLocale.fa => 'ظرفیت کل فایل صوتی: $capacityBits بیت',
    AppLocale.en => 'Total audio capacity: $capacityBits bits',
    AppLocale.ar => 'السعة الكلية للصوت: $capacityBits بت',
    AppLocale.fr => 'Capacité audio totale : $capacityBits bits',
  };

  String get embedRecoveryCopied => _t(
    const _S(
      'عدد در حافظه کپی شد.',
      'Value copied to clipboard.',
      'تم نسخ الرقم إلى الحافظة.',
      'Valeur copiée dans le presse-papiers.',
    ),
  );

  String shareRecoveryBitsText(int bits) => switch (locale) {
    AppLocale.fa =>
      'طول پیام برای رمزگشایی (بیت): $bits\n(صوت‌نهان — نهان‌نگاری پیام در صوت)',
    AppLocale.en =>
      'Message bit length for extraction (bits): $bits\n(AudioSteg — Audio Steganography)',
    AppLocale.ar =>
      'طول الرسالة للاستخراج (بت): $bits\n(إخفاء الرسالة في الصوت)',
    AppLocale.fr =>
      'Longueur du message pour extraction (bits) : $bits\n(Stéganographie audio)',
  };
  String get embedRecoveryOk =>
      _t(const _S('متوجه شدم', 'Got it', 'حسناً', 'Compris'));
  String get duration => _t(const _S('مدت زمان', 'Duration', 'المدة', 'Durée'));
  String get capacity => _t(const _S('ظرفیت', 'Capacity', 'السعة', 'Capacité'));
  String get bitsEmbedded => _t(
    const _S(
      'بیت جاسازی شده',
      'Bits embedded',
      'البتات المدمجة',
      'Bits intégrés',
    ),
  );
  String get snrLabel => 'SNR (dB)';
  String get psnrLabel => 'PSNR (dB)';
  String get berLabel => 'BER (%)';
  String get npcrLabel => 'NPCR (%)';
  String get uaciLabel => 'UACI (%)';
  String get msgBitLength => _t(
    const _S(
      'طول پیام (بیت)',
      'Message length (bits)',
      'طول الرسالة (بت)',
      'Longueur du message (bits)',
    ),
  );
  String get msgBitLengthHint => _t(
    const _S(
      'طول پیام به بیت (msg_len)',
      'Message length in bits (msg_len)',
      'طول الرسالة بالبت (msg_len)',
      'Longueur du message en bits (msg_len)',
    ),
  );
  String get msgBitLengthHelper => _t(
    const _S(
      'همان مقداری که هنگام نهان‌نگاری استفاده شد — مانند main_steganography.m',
      'Same value used when embedding — as in main_steganography.m',
      'نفس القيمة المستخدمة عند الإخفاء — كما في main_steganography.m',
      'Même valeur qu’à l’intégration — comme dans main_steganography.m',
    ),
  );
  String get errorBitLengthEmpty => _t(
    const _S(
      'طول پیام (بیت) را وارد کنید.',
      'Enter the message length in bits.',
      'أدخل طول الرسالة بالبت.',
      'Saisissez la longueur du message en bits.',
    ),
  );
  String get errorBitLengthInvalid => _t(
    const _S(
      'طول پیام باید عدد مثبت باشد.',
      'Message length must be a positive number.',
      'يجب أن يكون طول الرسالة رقماً موجباً.',
      'La longueur du message doit être un nombre positif.',
    ),
  );
  String get reset =>
      _t(const _S('بازنشانی', 'Reset', 'إعادة تعيين', 'Réinitialiser'));
  String get play => _t(const _S('پخش', 'Play', 'تشغيل', 'Lecture'));
  String get pause => _t(const _S('مکث', 'Pause', 'إيقاف مؤقت', 'Pause'));
  String get stopPlayback =>
      _t(const _S('توقف پخش', 'Stop', 'إيقاف التشغيل', 'Arrêter'));
  String get readyToRecord => _t(
    const _S(
      'آماده ضبط…',
      'Ready to record…',
      'جاهز للتسجيل…',
      'Prêt à enregistrer…',
    ),
  );
  String get recording => _t(
    const _S('در حال ضبط…', 'Recording…', 'جارٍ التسجيل…', 'Enregistrement…'),
  );
  String get processing => _t(
    const _S('در حال پردازش…', 'Processing…', 'جارٍ المعالجة…', 'Traitement…'),
  );
  String get keyMismatch => _t(
    const _S(
      'کلید/پارامترها صحیح نیستند یا داده‌ای پیدا نشد.',
      'Wrong key/params or no payload found.',
      'المفتاح/المعاملات غير صحيحة أو لم يُعثر على بيانات.',
      'Clé/paramètres incorrects ou aucune charge utile trouvée.',
    ),
  );

  String get qualityMetrics => _t(
    const _S(
      'متریک‌های کیفیت',
      'Quality metrics',
      'مقاييس الجودة',
      'Métriques de qualité',
    ),
  );
  String get audioEqualizer => _t(
    const _S(
      'اکولایزر صدا',
      'Audio equalizer',
      'معادل الصوت',
      'Égaliseur audio',
    ),
  );
  String get audioLevel =>
      _t(const _S('سطح صدا', 'Audio level', 'مستوى الصوت', 'Niveau audio'));
  String get compareWaveformTitle => _t(
    const _S(
      'مقایسه سیگنال صوتی',
      'Audio signal comparison',
      'مقارنة إشارة الصوت',
      'Comparaison du signal audio',
    ),
  );
  String get coverWaveLegend => _t(
    const _S(
      'صدای اصلی (پوشش)',
      'Original audio (cover)',
      'الصوت الأصلي (الغلاف)',
      'Audio original (cover)',
    ),
  );
  String get stegoWaveLegend => _t(
    const _S(
      'صدای نهان‌نگاری‌شده',
      'Watermarked audio (stego)',
      'الصوت المخفي',
      'Audio watermarké (stégo)',
    ),
  );
  String get utilization => _t(
    const _S(
      'بهره‌وری ظرفیت',
      'Capacity utilisation',
      'استخدام السعة',
      'Utilisation de la capacité',
    ),
  );
  String get verify => _t(
    const _S(
      'تأیید فوری',
      'Verify roundtrip',
      'تحقق فوري',
      'Vérification rapide',
    ),
  );
  String get verifying => _t(
    const _S('در حال تأیید…', 'Verifying…', 'جارٍ التحقق…', 'Vérification…'),
  );
  String get verifyMatch => _t(
    const _S(
      'تأیید موفق ✓ متن استخراج‌شده با اصل یکی است.',
      'Verified ✓ extracted text matches the original.',
      'تم التحقق ✓ النص المستخرج يطابق الأصل.',
      'Vérifié ✓ le texte extrait correspond à l’original.',
    ),
  );
  String get verifyMismatch => _t(
    const _S(
      'تأیید ناموفق! متن استخراج‌شده با اصل تطابق ندارد.',
      'Mismatch! extracted text differs from the original.',
      'فشل التحقق! النص المستخرج يختلف عن الأصل.',
      'Échec ! le texte extrait diffère de l’original.',
    ),
  );
  String get verifyEmpty => _t(
    const _S(
      'چیزی استخراج نشد — embed با شکست مواجه شده است.',
      'Nothing extracted — embed seems broken.',
      'لم يُستخرج شيء — يبدو أن الإخفاء فشل.',
      'Rien extrait — l’intégration semble avoir échoué.',
    ),
  );

  String get aboutTitle => _t(
    const _S(
      'درباره برنامه',
      'About this app',
      'حول التطبيق',
      'À propos de l’application',
    ),
  );
  String get aboutVersion =>
      _t(const _S('نسخه', 'Version', 'الإصدار', 'Version'));
  String get aboutAuthor =>
      _t(const _S('پدیدآور', 'Author', 'المؤلف', 'Auteur'));
  String get aboutAlgo =>
      _t(const _S('الگوریتم', 'Algorithm', 'الخوارزمية', 'Algorithme'));
  String get aboutAlgoBody => _t(
    const _S(
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
      'فقط بناءً على سكربتات MATLAB:\n'
          '• embed_extract_data.m\n'
          '• logistic_map_keygen.m\n'
          '• evaluate_stego.m\n'
          '• main_steganography.m',
      'Uniquement basé sur les scripts MATLAB :\n'
          '• embed_extract_data.m\n'
          '• logistic_map_keygen.m\n'
          '• evaluate_stego.m\n'
          '• main_steganography.m',
    ),
  );
  String get aboutThesis => _t(
    const _S(
      'پایان‌نامه: نهان‌نگاری مخفی سیگنال صوتی با نگاشت آشوب لاجستیک',
      'Thesis: Audio Signal Stealth Steganography via Logistic Chaos Mapping',
      'أطروحة: إخفاء إشارة الصوت عبر الخريطة الفوضوية اللوجستية',
      'Thèse : stéganographie audio furtive par carte chaotique logistique',
    ),
  );
  String get close => _t(const _S('بستن', 'Close', 'إغلاق', 'Fermer'));

  String get usageGuideTitle =>
      _t(const _S('راهنمای سریع', 'Quick guide', 'دليل سريع', 'Guide rapide'));
  String get usageGuidePurpose => _t(
    const _S(
      'این برنامه برای نهان‌نگاری متن در فایل صوتی با LSB و نقشه آشوب لاجستیک '
          '(پژوهش پایان‌نامه) ساخته شده است. پیام داخل موج صدا پنهان می‌شود و با '
          'همان کلید و پارامترها قابل استخراج است.',
      'This app hides text inside audio using LSB and a logistic chaos map '
          '(thesis research). The message is embedded in the waveform and can be '
          'recovered with the same key and parameters.',
      'يخفي هذا التطبيق النص داخل الصوت باستخدام LSB وخريطة الفوضى اللوجستية '
          '(بحث أطروحة). تُدمج الرسالة في الموجة ويمكن استعادتها بنفس المفتاح والمعاملات.',
      'Cette application cache du texte dans l’audio via LSB et une carte du chaos '
          'logistique (thèse). Le message est intégré dans l’onde et récupérable avec '
          'les mêmes paramètres.',
    ),
  );
  String get usageGuideStepEmbed => _t(
    const _S(
      'نهان‌نگاری: پیام را بنویسید، سپس صدا را ضبط کنید یا فایل WAV/MP3 بارگذاری کنید. '
          'پس از پردازش، عدد طول پیام (بیت) را حتماً یادداشت کنید.',
      'Embed: Type your message, then record audio or upload a WAV/MP3 file. '
          'After processing, note the message length in bits.',
      'الإخفاء: اكتب رسالتك، ثم سجّل الصوت أو ارفع ملف WAV/MP3. '
          'بعد المعالجة، دوّن طول الرسالة بالبت.',
      'Intégrer : saisissez le message, enregistrez ou importez un WAV/MP3. '
          'Notez ensuite la longueur du message en bits.',
    ),
  );
  String get usageGuideStepExtract => _t(
    const _S(
      'رمزگشایی: فایل نهان‌نگاری‌شده را انتخاب کنید و طول پیام (بیت) را وارد کنید. '
          'پارامترهای آشوب باید با زمان نهان‌نگاری یکسان باشند.',
      'Extract: Open the stego audio file and enter the message length in bits. '
          'Chaos parameters must match those used when embedding.',
      'الاستخراج: افتح ملف الإخفاء وأدخل طول الرسالة بالبت. '
          'يجب أن تطابق معاملات الفوضى مع وقت الإخفاء.',
      'Extraire : ouvrez le fichier stégo et saisissez la longueur en bits. '
          'Les paramètres du chaos doivent correspondre à l’intégration.',
    ),
  );
  String get usageGuideStepSettings => _t(
    const _S(
      'تنظیمات: تم، زبان و پارامترهای r و x0 را می‌توانید تغییر دهید. '
          'مقادیر r و x0 را دستی یا با اسلایدر در بازه مجاز وارد کنید.',
      'Settings: Change theme, language, and logistic r / x0. '
          'Enter parameters manually or with sliders within the allowed range.',
      'الإعدادات: غيّر المظهر واللغة ومعاملات r و x0 يدوياً أو بالمنزلق.',
      'Paramètres : thème, langue, r et x0 — saisie manuelle ou curseurs.',
    ),
  );
  String get usageGuideStepAbout => _t(
    const _S(
      'درباره ما: معرفی پروژه، استاد راهنما و پیوندهای تماس.',
      'About: project info, supervisor, and links.',
      'من نحن: معلومات المشروع والمشرف وروابط التواصل.',
      'À propos : projet, encadrant et liens.',
    ),
  );
  String get usageGuideContinue =>
      _t(const _S('شروع استفاده', 'Get started', 'بدء الاستخدام', 'Commencer'));

  String get splashTitleAudio => _t(
    const _S('سیگنال صوتی', 'Audio signal', 'إشارة صوتية', 'Signal audio'),
  );
  String get splashSubtitleAudio => _t(
    const _S(
      'نهان‌نگاری مخفی در بستر امواج صدا',
      'Stealth embedding inside sound waves',
      'إخفاء خفي داخل موجات الصوت',
      'Intégration furtive dans les ondes sonores',
    ),
  );
  String get splashTitleStego => _t(
    const _S(
      'نهان‌نگاری آشوب لاجستیک',
      'Logistic chaos steganography',
      'إخفاء الفوضى اللوجستي',
      'Stéganographie chaos logistique',
    ),
  );
  String get splashSubtitleStego => _t(
    const _S(
      'امنیت پیام با نقشه آشوب و LSB',
      'Message security via chaos map & LSB',
      'أمان الرسالة عبر خريطة الفوضى و LSB',
      'Sécurité du message via carte chaotique et LSB',
    ),
  );

  String get aboutProfileTitle => _t(
    const _S(
      'علیرضا کاروی',
      'Alireza Karavi',
      'علیرضا کاروی',
      'Alireza Karavi',
    ),
  );
  String get aboutSupervisorSection => _t(
    const _S('استاد راهنما', 'Supervisor', 'المشرف', 'Directeur de thèse'),
  );
  String get aboutSupervisorLabel =>
      _t(const _S('استاد راهنما', 'Supervisor', 'المشرف', 'Encadrant'));
  String get aboutSupervisorName => _t(
    const _S(
      'دکتر مهدی مصلح',
      'Dr. Mehdi Mosleh',
      'الدكتور مهدي مصلح',
      'Dr. Mehdi Mosleh',
    ),
  );
  String get aboutBio => _t(
    const _S(
      'توسعه‌دهنده نرم‌افزار و مدیر فنی در شرکت NTK؛ فارغ‌التحصیل مهندسی صنایع (کارشناسی) '
          'و هوش مصنوعی و رباتیک (کارشناسی ارشد). بیش از ۱۷ سال تجربه در توسعه وب، '
          'C#، موبایل (Flutter) و معماری سامانه‌های سازمانی و CMS. '
          'این اپلیکیشن بخشی از پژوهش پایان‌نامه «نهان‌نگاری مخفی سیگنال صوتی با نگاشت آشوب لاجستیک» است.',
      'Software developer and senior IT lead at NTK; B.Sc. Industrial Engineering, '
          'M.Sc. AI & Robotics. 17+ years in web, C#, Flutter, and enterprise/CMS systems. '
          'This app is part of thesis research on audio steganography via logistic chaos mapping.',
      'مطوّر برمجيات ومدير تقني في NTK؛ بكالوريوس هندسة صناعية وماجستير ذكاء اصطناعي وروبوتات. '
          'أكثر من 17 عاماً في الويب وC# وFlutter. هذا التطبيق جزء من أطروحة إخفاء الصوت.',
      'Développeur logiciel et responsable technique chez NTK ; ingénierie industrielle '
          'et master IA & robotique. 17+ ans en web, C#, Flutter. Application liée à la thèse '
          'sur la stéganographie audio par chaos logistique.',
    ),
  );
  String get aboutLinksSection =>
      _t(const _S('پیوندها', 'Links', 'روابط', 'Liens'));
  String get aboutGitHubApp => _t(
    const _S(
      'مخزن GitHub — اپلیکیشن',
      'GitHub — application repo',
      'مستودع GitHub — التطبيق',
      'GitHub — dépôt application',
    ),
  );
  String get aboutGitHubThesis => _t(
    const _S(
      'مخزن GitHub — پایان‌نامه',
      'GitHub — thesis repo',
      'مستودع GitHub — الأطروحة',
      'GitHub — dépôt thèse',
    ),
  );
  String get aboutPersonalSite => _t(
    const _S(
      'وب‌سایت شخصی',
      'Personal website',
      'الموقع الشخصي',
      'Site personnel',
    ),
  );
  String get aboutCompanySite => _t(
    const _S(
      'وب‌سایت شرکت NTK',
      'NTK company website',
      'موقع شركة NTK',
      'Site NTK',
    ),
  );
  String get aboutContactSection =>
      _t(const _S('تماس', 'Contact', 'اتصل بنا', 'Contact'));
  String get aboutPhoneLandline =>
      _t(const _S('تلفن ثابت', 'Landline', 'هاتف أرضي', 'Fixe'));
  String get aboutPhoneMobile =>
      _t(const _S('موبایل', 'Mobile', 'جوال', 'Mobile'));
  String get aboutOpenLinkFailed => _t(
    const _S(
      'باز کردن پیوند ممکن نشد.',
      'Could not open the link.',
      'تعذر فتح الرابط.',
      'Impossible d’ouvrir le lien.',
    ),
  );
}
