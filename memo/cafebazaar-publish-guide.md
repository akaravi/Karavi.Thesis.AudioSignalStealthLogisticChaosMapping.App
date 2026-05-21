# راهنمای انتشار «صوت‌نهان» در کافه‌بازار

مخزن: `Karavi.Thesis.AudioSignalStealthLogisticChaosMapping.App`  
پنل توسعه‌دهنده: [developers.cafebazaar.ir](https://developers.cafebazaar.ir/)  
فروشگاه: [cafebazaar.ir](https://cafebazaar.ir/)

---

## ۱. آنچه در پروژه آماده شده است

| مورد | مقدار / مسیر |
|------|----------------|
| شناسه بسته (Application ID) | `ir.ntk.audiowmark.app` |
| نام روی دستگاه | صوت‌نهان |
| نسخه | `src/audio_steg_app/pubspec.yaml` — مثلاً `1.0.0+1` (نام + کد build) |
| امضای Release | `src/audio_steg_app/android/key.properties` + `upload-keystore.jks` (**خارج از Git**) |
| نمونه تنظیمات کلید | `src/audio_steg_app/android/key.properties.example` |
| ساخت keystore (یک‌بار) | `src/audio_steg_app/android/scripts/create_release_keystore.ps1` |
| بیلد آماده بازار | `\_build-cafebazaar-release.ps1` (ریشه مخزن) |
| خروجی بیلد | `publish/cafebazaar/` |
| متن پیشنهادی فروشگاه | `publish/cafebazaar/LISTING.fa.md` |
| ProGuard | `src/audio_steg_app/android/app/proguard-rules.pro` |

**فرمت آپلود:** کافه‌بازار **AAB** و **APK** امضا‌شده release را می‌پذیرد. پیشنهاد: ابتدا فایل `.aab`.

---

## ۲. حساب توسعه‌دهنده (یک‌بار)

1. ثبت‌نام در [developers.cafebazaar.ir](https://developers.cafebazaar.ir/)
2. تأیید ایمیل و موبایل
3. احراز هویت (کارت ملی، آدرس، … طبق فرم بازار)
4. پذیرش قوانین انتشار اپ

---

## ۳. کلید امضا (یک‌بار — محرمانه)

```powershell
# از ریشه مخزن
.\src\audio_steg_app\android\scripts\create_release_keystore.ps1
```

سپس:

```powershell
Copy-Item src\audio_steg_app\android\key.properties.example src\audio_steg_app\android\key.properties
```

فایل `key.properties` را ویرایش کنید:

```properties
storePassword=رمز_کی‌استور
keyPassword=رمز_کلید
keyAlias=upload
storeFile=upload-keystore.jks
```

**هشدار امنیتی:**

- `upload-keystore.jks` و `key.properties` را **commit نکنید** (در `.gitignore` هستند).
- بدون این فایل‌ها، بیلد release با کلید **debug** امضا می‌شود و برای بازار قابل انتشار نیست.

---

## ۴. بیلد امضا‌شده برای آپلود

```powershell
# از ریشه مخزن
.\_build-cafebazaar-release.ps1
```

خروجی معمول در `publish/cafebazaar/`:

| فایل | کاربرد |
|------|--------|
| `AudioSteg_1.0.0_1.aab` | **آپلود اصلی** در پنل کافه‌بازار |
| `AudioSteg_1.0.0_1_arm64-v8a.apk` | نصب تست روی گوشی arm64 |
| `mapping_1.0.0_1.txt` | نگهداری برای رفع خطا (ProGuard / R8) |
| `LISTING.fa.md` | متن فروشگاه (کپی در پنل) |

**سوییچ‌های اختیاری:**

```powershell
.\_build-cafebazaar-release.ps1 -OutputDirectory D:\PublishKaravi\CafeBazaar
.\_build-cafebazaar-release.ps1 -AabOnly          # فقط باندل
.\_build-cafebazaar-release.ps1 -ApkOnly          # فقط APK
.\_build-cafebazaar-release.ps1 -UseFlutterIoCnMirror
```

---

## ۵. آپلود در پنل کافه‌بازار

1. ورود به پنل → افزودن / ویرایش اپ
2. شناسه بسته: `ir.ntk.audiowmark.app` (باید با پروژه یکی باشد)
3. آپلود `AudioSteg_<version>.aab` (یا APK امضا‌شده release)
4. پر کردن عنوان، توضیح کوتاه، توضیح کامل (فارسی)
5. آپلود آیکن و اسکرین‌شات
6. توضیح **دلیل مجوزها** (میکروفن، دسترسی فایل صوتی)
7. ارسال برای بررسی

---

## ۶. متن پیشنهادی فروشگاه (فارسی)

### عنوان (حدود ۳۰ کاراکتر)

صوت‌نهان — نهان‌نگاری پیام در صوت

### توضیح کوتاه

پنهان‌سازی و استخراج متن داخل فایل صوتی با نهان‌نگاری LSB و نگاشت آشوب لجستیک.

### توضیح کامل

**صوت‌نهان** ابزار پژوهشی/کاربردی برای **نهان‌نگاری پیام متنی در سیگنال صوتی** است (پایان‌نامه / NTK).

**قابلیت‌ها:**

- نهان‌نگاری (Embed): تایپ یا ضبط صدا، تولید فایل WAV استگانو
- رمزگشایی (Extract): بازیابی پیام از فایل یا ضبط میکروفن
- حالت دیجیتال و Over-the-Air (FSK)
- تنظیم seed و پارامترهای آشوب لجستیک
- رابط فارسی/انگلیسی/عربی/فرانسوی، تم روشن و تاریک

**مجوزها (دلیل استفاده):**

- **میکروفن:** ضبط صدا برای نهان‌نگاری و استخراج
- **دسترسی به فایل صوتی (Android 13+):** انتخاب فایل WAV/MP3 از حافظه

**حریم خصوصی:** پردازش صدا و متن روی دستگاه انجام می‌شود؛ ارسال خودکار به سرور در نسخه فعلی وجود ندارد.

**پشتیبانی:** karavi@ntk.ir

### دسته‌بندی پیشنهادی

ابزارها / آموزشی / امنیت (مطابق دسته‌های فعلی بازار)

### تصاویر

- آیکن: `src/audio_steg_app/assets/branding/app_icon.png` → خروجی **512×512**
- اسکرین‌شات: نهان‌نگاری، رمزگشایی، تنظیمات، درباره ما (حداقل ۲–۴ تصویر)

---

## ۷. چک‌لیست قبل از ارسال

- [ ] حساب developers.cafebazaar.ir فعال و احراز هویت شده
- [ ] `key.properties` و `upload-keystore.jks` ساخته شده (خارج از Git)
- [ ] `.\_build-cafebazaar-release.ps1` بدون خطا اجرا شده
- [ ] فایل آپلود **release** است (نه debug)
- [ ] متن فارسی و justification مجوزها در پنل پر شده
- [ ] آیکن و اسکرین‌شات آپلود شده
- [ ] فایل `mapping_*.txt` برای این نسخه ذخیره شده

---

## ۸. به‌روزرسانی نسخه بعدی

1. در `src/audio_steg_app/pubspec.yaml` نسخه را بالا ببرید، مثلاً:
   ```yaml
   version: 1.0.1+2
   ```
2. دوباره `.\_build-cafebazaar-release.ps1` را اجرا کنید
3. در پنل بازار، باندل/APK جدید با **versionCode** بالاتر آپلود کنید

---

## ۹. نکات فنی

- **حجم APK:** بیلد پیش‌فرض split-per-abi فقط **arm64-v8a** را در پکیج استقرار می‌گذارد (سبک‌تر از fat APK).
- **Minify:** `isMinifyEnabled` و `shrinkResources` در release فعال است.
- **تنظیمات استقرار:** `appsettings.json` در ریشه مخزن — برای Flutter در asset bundle است؛ روی اندروید در AAB گنجانده می‌شود.
- **بیلد همه پلتفرم‌ها:** `.\_build-all-projects.ps1` شامل Android در ZIP استقرار است؛ برای **فقط بازار** از `\_build-cafebazaar-release.ps1` استفاده کنید.

---

## ۱۰. عیب‌یابی رایج

| مشکل | راه‌حل |
|------|--------|
| `Release signing not configured` | `key.properties` و keystore را طبق بخش ۳ بسازید |
| `ANDROID_HOME` not found | Android SDK را نصب و متغیر محیطی را تنظیم کنید |
| APK با کلید debug | `key.properties` وجود ندارد — release به debug برمی‌گردد |
| رد شدن به‌خاطر مجوز | در پنل، توضیح فارسی برای میکروفن و فایل صوتی بنویسید |

---

*آخرین هم‌خوانی با Part 50 در `Cursor.01.plan.md` — آماده‌سازی انتشار کافه‌بازار.*
