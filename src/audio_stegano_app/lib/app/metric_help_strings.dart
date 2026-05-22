import '../features/shared/embed_metric_kind.dart';
import 'app_locale.dart';
import 'app_strings.dart';

class _M {
  final String fa;
  final String en;
  final String ar;
  final String fr;
  const _M(this.fa, this.en, this.ar, this.fr);
}

/// Multilingual titles and bodies for embed quality metric help popups.
extension MetricHelpStrings on AppStrings {
  String _mt(_M m) => switch (locale) {
    AppLocale.fa => m.fa,
    AppLocale.en => m.en,
    AppLocale.ar => m.ar,
    AppLocale.fr => m.fr,
  };

  String get metricHelpTapHint => _mt(
    const _M(
      'برای توضیح هر متریک، روی آن بزنید.',
      'Tap a metric chip for a full explanation.',
      'اضغط على أي مقياس لعرض الشرح الكامل.',
      'Appuyez sur une pastille pour l’explication complète.',
    ),
  );

  String metricHelpTitle(EmbedMetricKind kind) => _mt(
    switch (kind) {
      EmbedMetricKind.duration => const _M(
        'مدت زمان صوت',
        'Audio duration',
        'مدة الصوت',
        'Durée audio',
      ),
      EmbedMetricKind.bitsEmbedded => const _M(
        'بیت‌های جاسازی‌شده',
        'Bits embedded',
        'البتات المدمجة',
        'Bits intégrés',
      ),
      EmbedMetricKind.capacity => const _M(
        'ظرفیت نهان‌نگاری',
        'Embedding capacity',
        'سعة الإخفاء',
        'Capacité d’intégration',
      ),
      EmbedMetricKind.utilization => const _M(
        'بهره‌وری ظرفیت',
        'Capacity utilisation',
        'استخدام السعة',
        'Utilisation de la capacité',
      ),
      EmbedMetricKind.msgBitLength => const _M(
        'طول پیام (بیت)',
        'Message length (bits)',
        'طول الرسالة (بت)',
        'Longueur du message (bits)',
      ),
      EmbedMetricKind.snr => const _M(
        'نسبت سیگنال به نویز (SNR)',
        'Signal-to-noise ratio (SNR)',
        'نسبة الإشارة إلى الضوضاء (SNR)',
        'Rapport signal/bruit (SNR)',
      ),
      EmbedMetricKind.psnr => const _M(
        'نسبت اوج سیگنال به نویز (PSNR)',
        'Peak signal-to-noise ratio (PSNR)',
        'ذروة نسبة الإشارة إلى الضوضاء (PSNR)',
        'Rapport signal/bruit de crête (PSNR)',
      ),
      EmbedMetricKind.ber => const _M(
        'نرخ خطای بیت (BER)',
        'Bit error rate (BER)',
        'معدل خطأ البت (BER)',
        'Taux d’erreur binaire (BER)',
      ),
      EmbedMetricKind.npcr => const _M(
        'نرخ تغییر نمونه‌ها (NPCR)',
        'Number of changed samples (NPCR)',
        'نسبة العينات المتغيرة (NPCR)',
        'Taux d’échantillons modifiés (NPCR)',
      ),
      EmbedMetricKind.uaci => const _M(
        'شدت تغییر میانگین (UACI)',
        'Uniform average change intensity (UACI)',
        'شدة التغيير المتوسط الموحّد (UACI)',
        'Intensité moyenne uniforme de changement (UACI)',
      ),
    },
  );

  String metricHelpBody(EmbedMetricKind kind) => _mt(
    switch (kind) {
      EmbedMetricKind.duration => const _M(
        'مدت زمان فایل صوتی نهان‌نگاری‌شده (stego) بر حسب ثانیه است. از تقسیم تعداد نمونه‌های PCM بر نرخ نمونه‌برداری (مثلاً ۴۴٬۱۰۰ هرتز) به‌دست می‌آید.\n\n'
        'این مقدار به شما می‌گوید پیام در چه مدت صوتی پنهان شده است؛ برای مقایسه با طول فایل اصلی (cover) و برآورد زمان پخش مفید است.',
        'The duration is the length of the watermarked (stego) audio file in seconds: sample count divided by the sample rate (e.g. 44,100 Hz).\n\n'
        'It tells you how long the carrier audio is after embedding and helps compare with the original cover length and playback time.',
        'المدة هي طول ملف الصوت المخفي (stego) بالثواني: عدد العينات مقسوماً على معدل العينات (مثلاً 44100 هرتز).\n\n'
        'تُبيّن مدة الحامل الصوتي بعد الإخفاء وتساعد على مقارنته بالملف الأصلي (cover) وزمن التشغيل.',
        'La durée est la longueur du fichier audio watermarké (stego) en secondes : nombre d’échantillons divisé par la fréquence d’échantillonnage (ex. 44 100 Hz).\n\n'
        'Elle indique la durée du support audio après intégration et permet de la comparer au cover d’origine et au temps de lecture.',
      ),
      EmbedMetricKind.bitsEmbedded => const _M(
        'تعداد بیت‌های واقعی پیام که در نمونه‌های صوتی با روش LSB و کلید آشوب لاجستیک جاسازی شده‌اند (مطابق embed_extract_data.m).\n\n'
        'این عدد می‌تواند کوچک‌تر از «طول پیام (بیت)» باشد اگر از padding یا طول ثابت ۲^۱۸ استفاده کنید؛ برای استخراج باید همان msg_len تنظیم‌شده را بدانید.',
        'The count of message bits actually embedded into audio samples via LSB with the logistic chaos key (as in embed_extract_data.m).\n\n'
        'It may be less than the configured message bit length when fixed padding is used; extraction still requires the same msg_len you used when embedding.',
        'عدد بتات الرسالة المدمجة فعلياً في العينات عبر LSB والمفتاح الفوضوي اللوجستي (كما في embed_extract_data.m).\n\n'
        'قد يكون أقل من طول الرسالة المُعدّ إذا وُجد حشو أو طول ثابت؛ الاستخراج يحتاج نفس msg_len المستخدم عند الإخفاء.',
        'Nombre de bits du message réellement intégrés dans les échantillons via LSB et clé logistique (embed_extract_data.m).\n\n'
        'Peut être inférieur à la longueur configurée avec remplissage fixe ; l’extraction exige le même msg_len qu’à l’intégration.',
      ),
      EmbedMetricKind.capacity => const _M(
        'حداکثر تعداد بیت‌هایی که این فایل صوتی می‌تواند در LSB نمونه‌ها ذخیره کند — در پیاده‌سازی فعلی تقریباً یک بیت به ازای هر نمونه مونو.\n\n'
        'ظرفیت بالاتر یعنی فایل طولانی‌تر یا نرخ نمونه‌برداری بیشتر؛ اگر پیام شما از ظرفیت بیشتر باشد، نهان‌نگاری با خطا متوقف می‌شود.',
        'Maximum number of bits this audio can carry in sample LSBs — in the current implementation roughly one bit per mono sample.\n\n'
        'Higher capacity means longer audio or higher sample rate. If your message needs more bits than capacity, embedding fails.',
        'أقصى عدد من البتات التي يمكن لهذا الصوت تخزينها في LSB العينات — تقريباً بت واحد لكل عينة مونو.\n\n'
        'سعة أكبر تعني ملفاً أطول أو معدل عينات أعلى. إذا تجاوزت الرسالة السعة، يفشل الإخفاء.',
        'Nombre maximal de bits stockables dans les LSB des échantillons — environ un bit par échantillon mono.\n\n'
        'Une capacité plus grande correspond à un audio plus long ou un débit d’échantillonnage plus élevé. Au-delà, l’intégration échoue.',
      ),
      EmbedMetricKind.utilization => const _M(
        'درصد استفاده از ظرفیت: (بیت جاسازی‌شده ÷ ظرفیت) × ۱۰۰.\n\n'
        'مقدار نزدیک به ۱۰۰٪ یعنی تقریباً تمام ظرفیت LSB مصرف شده (مثلاً با طول پیام ثابت ۲^۱۸). مقادیر کم یعنی پیام کوتاه‌تر نسبت به طول صوت — معمولاً کیفیت شنیداری بهتر و SNR بالاتر.',
        'Percentage of capacity used: (bits embedded ÷ capacity) × 100.\n\n'
        'Near 100% means almost all LSB capacity is used (e.g. fixed 262144-bit mode). Lower values mean a shorter message relative to audio length — often better perceived quality and higher SNR.',
        'نسبة استخدام السعة: (البتات المدمجة ÷ السعة) × 100.\n\n'
        'قرب 100% يعني استهلاك معظم سعة LSB (مثل الوضع الثابت 2^18). قيم أقل تعني رسالة أقصر بالنسبة لطول الصوت — غالباً جودة مسموعة أفضل وSNR أعلى.',
        'Pourcentage de capacité utilisée : (bits intégrés ÷ capacité) × 100.\n\n'
        'Proche de 100 % : presque toute la capacité LSB est utilisée (ex. mode fixe 2^18). Plus bas : message court par rapport à l’audio — souvent meilleure qualité audible et SNR plus élevé.',
      ),
      EmbedMetricKind.msgBitLength => const _M(
        'طول کل جریان بیت هنگام نهان‌نگاری (msg_len) — شامل بیت‌های پیام UTF-8 و در حالت طول ثابت، padding تا رسیدن به اندازهٔ از پیش‌تعیین‌شده (مثلاً ۲^۱۸ بیت).\n\n'
        'برای رمزگشایی باید دقیقاً همین عدد را وارد کنید؛ در تنظیمات «محدودیت طول پیام ثابت» این مقدار خودکار است و در UI نمایش داده نمی‌شود.',
        'Total bit-stream length used when embedding (msg_len), including UTF-8 message bits and, in fixed-length mode, zero padding up to the configured size (e.g. 2^18 bits).\n\n'
        'Extraction must use exactly this value. With “fixed default message bit length” enabled in settings, it is applied automatically and the field is hidden on the extract tab.',
        'طول تيار البتات الكامل عند الإخفاء (msg_len)، بما في ذلك UTF-8 والحشو في الوضع الثابت حتى الحجم المحدد (مثلاً 2^18).\n\n'
        'يجب إدخال نفس القيمة عند الاستخراج. مع «الطول الثابت» في الإعدادات يُطبَّق تلقائياً ويُخفى الحقل في تبويب الاستخراج.',
        'Longueur totale du flux de bits à l’intégration (msg_len), bits UTF-8 inclus, et en mode longueur fixe remplissage jusqu’à la taille configurée (ex. 2^18).\n\n'
        'L’extraction doit utiliser exactement cette valeur. Avec la limite fixe dans les réglages, elle est automatique et le champ est masqué à l’extraction.',
      ),
      EmbedMetricKind.snr => const _M(
        'SNR (دسی‌بل): توان سیگنال اصلی (cover) نسبت به توان اختلاف cover و stego. از evaluate_stego.m: 10·log10(Σx²/Σ(x−y)²).\n\n'
        'هرچه SNR بالاتر باشد، تغییرات ناشی از نهان‌نگاری کمتر و صدای stego به اصل نزدیک‌تر است. مقادیر بسیار بالا (>۴۰ dB) معمولاً به معنای اختلاف شنیداری ناچیز است.',
        'SNR (dB): power of the cover signal versus the power of (cover − stego). From evaluate_stego.m: 10·log10(Σx²/Σ(x−y)²).\n\n'
        'Higher SNR means smaller embedding distortion and stego closer to the original. Very high values (>40 dB) usually imply barely audible change.',
        'SNR (ديسيبل): قدرة الإشارة الأصلية (cover) مقابل قدرة الفرق بين cover وstego. من evaluate_stego.m: 10·log10(Σx²/Σ(x−y)²).\n\n'
        'كلما زاد SNR قلّ التشويه واقترب stego من الأصل. قيم عالية جداً (>40 dB) تعني غالباً فرقاً مسموعاً ضئيلاً.',
        'SNR (dB) : puissance du cover divisée par la puissance de (cover − stego). D’après evaluate_stego.m : 10·log10(Σx²/Σ(x−y)²).\n\n'
        'Un SNR plus élevé indique une distorsion plus faible. Des valeurs très hautes (>40 dB) signifient en général une altération à peine audible.',
      ),
      EmbedMetricKind.psnr => const _M(
        'PSNR (دسی‌بل): معیار کیفیت بر اساس MSE بین cover و stego؛ در سیگنال نرمال‌شده amplitude=1 از 10·log10(1/MSE) استفاده می‌شود (همان evaluate_stego.m).\n\n'
        'PSNR بالاتر = کیفیت بهتر و تفاوت کمتر بین موج اصلی و نهان‌نگاری‌شده. معمولاً همراه SNR تفسیر می‌شود؛ برای گزارش پایان‌نامه و مقایسه پارامترهای r و x0 مفید است.',
        'PSNR (dB): quality metric from MSE between cover and stego; for normalized amplitude=1 signals the code uses 10·log10(1/MSE) (evaluate_stego.m).\n\n'
        'Higher PSNR means better fidelity. It complements SNR and is useful when comparing chaos parameters r and x0 in experiments.',
        'PSNR (ديسيبل): مقياس جودة من MSE بين cover وstego؛ للإشارة المُطبّعة سعة=1 يُستخدم 10·log10(1/MSE) (evaluate_stego.m).\n\n'
        'PSNR أعلى = ولاء أفضل. يكمّل SNR ومفيد لمقارنة معاملات الفوضى r وx0 في التجارب.',
        'PSNR (dB) : métrique dérivée de la MSE entre cover et stego ; pour amplitude normalisée =1 : 10·log10(1/MSE) (evaluate_stego.m).\n\n'
        'Un PSNR plus élevé indique une meilleure fidélité. Il complète le SNR pour comparer r et x0.',
      ),
      EmbedMetricKind.ber => const _M(
        'BER (درصد): درصد بیت‌های پیامی که پس از استخراج با متن اصلی فرق دارند — در تأیید فوری (Verify) یا evaluate_stego.m محاسبه می‌شود.\n\n'
        '۰٪ یعنی بازیابی کامل؛ هرچه BER بالاتر باشد، کلید اشتباه، msg_len نادرست، یا آسیب به فایل محتمل است. این متریک «کیفیت بازیابی متن» است، نه کیفیت شنیداری.',
        'BER (%): percentage of message bits that differ after extraction versus the original text — computed during in-app Verify or in evaluate_stego.m.\n\n'
        '0% means perfect recovery. Higher BER suggests wrong key, wrong msg_len, or file damage. This measures text recovery quality, not audible audio quality.',
        'BER (٪): نسبة بتات الرسالة المختلفة بعد الاستخراج عن النص الأصلي — تُحسب في التحقق الفوري أو evaluate_stego.m.\n\n'
        '0% استرداد كامل. BER أعلى يشير إلى مفتاح خاطئ أو msg_len خاطئ أو تلف الملف. يقيس جودة استرداد النص وليس الصوت.',
        'BER (%) : pourcentage de bits de message erronés après extraction par rapport au texte d’origine (Verify ou evaluate_stego.m).\n\n'
        '0 % = récupération parfaite. Un BER élevé indique clé/msg_len incorrect ou fichier altéré. Mesure la récupération du texte, pas la qualité audible.',
      ),
      EmbedMetricKind.npcr => const _M(
        'NPCR (درصد): «نرخ تعداد نمونه‌های تغییرکرده» — در evaluate_stego.m با مقایسه دو سیگنال stego که فقط کلید آشوب (x0) آن‌ها اختلاف جزئی دارد (۱e−10) سنجیده می‌شود.\n\n'
        'NPCR بالا یعنی حساسیت زیاد به کلید: تغییر کوچک در کلید → تغییر گسترده در خروجی. معیار امنیتی است، نه کیفیت شنیداری؛ برای ارزیابی آشوب لاجستیک در پایان‌نامه گزارش می‌شود.',
        'NPCR (%): “number of changed samples rate” — in evaluate_stego.m, compare two stego signals built with keys that differ only slightly in x0 (1e−10).\n\n'
        'High NPCR means strong key sensitivity: a tiny key change alters many samples. It is a security metric, not perceptual quality; reported for logistic chaos evaluation.',
        'NPCR (٪): «نسبة العينات المتغيرة» — في evaluate_stego.m بمقارنة إشارتي stego بمفتاح يختلف قليلاً في x0 (1e−10).\n\n'
        'NPCR مرتفع يعني حساسية عالية للمفتاح. مقياس أمني وليس جودة مسموعة؛ يُستخدم لتقييم الفوضى اللوجستية.',
        'NPCR (%) : « taux d’échantillons modifiés » — dans evaluate_stego.m, comparaison de deux stego dont les clés diffèrent légèrement en x0 (1e−10).\n\n'
        'Un NPCR élevé traduit une forte sensibilité à la clé. Métrique de sécurité, pas de qualité audible ; utile pour l’évaluation du chaos logistique.',
      ),
      EmbedMetricKind.uaci => const _M(
        'UACI (درصد): «شدت تغییر میانگین یکنواخت» — میانگین قدر مطلق تفاوت دو سیگنال stego (با کلیدهای اندکی متفاوت) نسبت به دامنه نرمال‌شده (evaluate_stego.m).\n\n'
        'همراه NPCR امنیت کلید را توصیف می‌کند: UACI بالاتر یعنی تغییرات دامنه‌ای بیشتر هنگام جابه‌جایی کلید. برای ۱D audio همان ایده NPCR/UACI تصویر دوبعدی است.',
        'UACI (%): “uniform average change intensity” — mean absolute difference between two stego signals (slightly different keys), normalized (evaluate_stego.m).\n\n'
        'Together with NPCR it describes key security: higher UACI means larger amplitude changes when the key changes. For 1D audio it mirrors the 2D image UACI idea.',
        'UACI (٪): «شدة التغيير المتوسط الموحّد» — متوسط الفرق المطلق بين إشارتي stego (مفتاحان مختلفان قليلاً)، مُطبّع (evaluate_stego.m).\n\n'
        'مع NPCR يصف أمان المفتاح: UACI أعلى يعني تغييرات سعة أكبر عند تغيير المفتاح.',
        'UACI (%) : « intensité moyenne uniforme de changement » — moyenne des |différences| entre deux stego (clés légèrement différentes), normalisée (evaluate_stego.m).\n\n'
        'Avec le NPCR, décrit la sécurité de la clé : un UACI plus élevé implique des changements d’amplitude plus grands si la clé change.',
      ),
    },
  );
}
