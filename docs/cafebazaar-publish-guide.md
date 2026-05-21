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
| bundle-signer (رسمی کافه‌بازار) | `src/audio_steg_app/android/scripts/Invoke-CafeBazaarBundleSigner.ps1` |
| JAR ابزار bundle-signer | `CAFEBAZAAR_BUNDLESIGNER_JAR` یا `-BundleSignerJarPath`؛ وگرنه `android/tools/` (دانلود خودکار) |
| خروجی بیلد | `publish/cafebazaar/` |
| متن پیشنهادی فروشگاه | `publish/cafebazaar/LISTING.fa.md` |
| ProGuard | `src/audio_steg_app/android/app/proguard-rules.pro` |

**فرمت آپلود (App Bundle):** برای انتشار با **Android App Bundle**، کافه‌بازار کلید امضای شما را نگه نمی‌دارد. طبق [راهنمای App Bundle و Bundle Signer](https://developers.cafebazaar.ir/fa/guidelines/feature/app_bundle#Bundle-Signer) باید پس از ساخت AAB امضا‌شده، با ابزار رسمی **bundle-signer** فایل **`.bin`** بسازید و **همان `.bin`** را در پنل آپلود کنید.

**فرمت جایگزین:** **APK** امضا‌شده release (مثلاً arm64 برای تست) — بدون مرحله bundle-signer.

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
| `AudioSteg_1.0.0_1.bin` | **آپلود اصلی در پنل** (خروجی bundle-signer برای App Bundle) |
| `AudioSteg_1.0.0_1.aab` | باندل امضا‌شده مبنا (نگهداری محلی؛ آپلود مستقیم `.aab` در جریان bundle-signer لازم نیست) |
| `AudioSteg_1.0.0_1_arm64-v8a.apk` | نصب تست روی گوشی arm64 |
| `mapping_1.0.0_1.txt` | نگهداری برای رفع خطا (ProGuard / R8) |
| `LISTING.fa.md` | متن فروشگاه (کپی در پنل) |

**پیش‌نیاز bundle-signer:** Java 8 یا بالاتر (`JAVA_HOME` یا `java` در PATH).

**مسیر JAR (اولویت جستجو):**

1. پارامتر `-BundleSignerJarPath` در `\_build-cafebazaar-release.ps1`
2. متغیر محیطی `CAFEBAZAAR_BUNDLESIGNER_JAR`
3. `src/audio_steg_app/android/tools/bundlesigner-0.1.13.jar` (در صورت نبود، دانلود از GitHub)

**سوییچ‌های اختیاری:**

```powershell
.\_build-cafebazaar-release.ps1 -OutputDirectory D:\PublishKaravi\CafeBazaar
.\_build-cafebazaar-release.ps1 -AabOnly          # فقط AAB + .bin
.\_build-cafebazaar-release.ps1 -ApkOnly          # فقط APK (بدون bundle-signer)
.\_build-cafebazaar-release.ps1 -SkipBundleSigner # AAB بدون ساخت .bin (فقط توسعه)
.\_build-cafebazaar-release.ps1 -UseFlutterIoCnMirror
```

---

## ۴-الف. Bundle Signer (طبق کافه‌بازار)

مرجع: [developers.cafebazaar.ir — App Bundle / Bundle Signer](https://developers.cafebazaar.ir/fa/guidelines/feature/app_bundle#Bundle-Signer)

1. ابتدا AAB **release** با همان `upload-keystore.jks` بسازید (`flutter build appbundle` یا `\_build-cafebazaar-release.ps1`).
2. اسکریپت مخزن به‌صورت خودکار `genbin` را اجرا می‌کند (یا دستی):

```powershell
.\src\audio_steg_app\android\scripts\Invoke-CafeBazaarBundleSigner.ps1 `
  -BundlePath publish\cafebazaar\AudioSteg_1.0.0_1.aab `
  -OutputDirectory publish\cafebazaar
```

3. در پنل توسعه‌دهنده فایل **`AudioSteg_<version>.bin`** را آپلود کنید.

**پرچم‌های رسمی (مثال کافه‌بازار):** `--v2-signing-enabled true` ، `--v3-signing-enabled false` ، keystore همان `key.properties`.

**عیب‌یابی keystore:** اگر `Invalid keystore format` دیدید، keystore را به PKCS12 تبدیل کنید:

```powershell
keytool -importkeystore -srckeystore src\audio_steg_app\android\upload-keystore.jks `
  -destkeystore src\audio_steg_app\android\upload-keystore.pkcs12 `
  -deststoretype PKCS12
```

سپس در `key.properties` مقدار `storeFile` را به فایل جدید تغییر دهید و در صورت نیاز `--ks-type PKCS12` در اسکریپت (پیش‌فرض JKS است).

---

## ۵. آپلود در پنل کافه‌بازار

1. ورود به پنل → افزودن / ویرایش اپ
2. شناسه بسته: `ir.ntk.audiowmark.app` (باید با پروژه یکی باشد)
3. آپلود `AudioSteg_<version>.bin` (جریان App Bundle) **یا** APK امضا‌شده release
4. پر کردن عنوان، توضیح کوتاه، توضیح کامل (فارسی)
5. آپلود آیکن و اسکرین‌شات
6. توضیح **دلیل مجوزها** (میکروفن، دسترسی فایل صوتی)
7. ارسال برای بررسی

---

## ۶. متن پیشنهادی فروشگاه (فارسی)

### عنوان (حدود ۳۰ کاراکتر)

صوت‌نهان — نهان‌نگاری پیام در صوت

### توضیح کوتاه

پنهان‌سازی و استخراج پیام متنی داخل فایل صوتی — نهان‌نگاری روی دستگاه شما.

### توضیح کامل

متن به‌روز و آماده کپی: **`publish/cafebazaar/LISTING.fa.md`** (بدون اصطلاحات تخصصی پایان‌نامه یا نگاشت آشوب).

خلاصه — **صوت‌نهان** ابزار کاربردی برای **نهان‌نگاری پیام متنی در سیگنال صوتی** است (NTK).

**قابلیت‌ها:**

- نهان‌نگاری (Embed): تایپ یا ضبط صدا، تولید فایل WAV استگانو
- رمزگشایی (Extract): بازیابی پیام از فایل یا ضبط میکروفن
- تنظیم کلید نهان‌نگاری (seed و پارامترهای r و x0)
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
- [ ] فایل **`AudioSteg_*.bin`** (bundle-signer) برای آپلود App Bundle ساخته شده
- [ ] Java نصب است (برای bundle-signer)
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
| `bundle-signer` / Java | JDK 8+؛ `CAFEBAZAAR_BUNDLESIGNER_JAR` یا `-BundleSignerJarPath` یا دانلود به `android/tools/` |
| `Invalid keystore format` | تبدیل JKS به PKCS12 (بخش ۴-الف) |
| رد شدن به‌خاطر مجوز | در پنل، توضیح فارسی برای میکروفن و فایل صوتی بنویسید |

---

*آخرین هم‌خوانی با Part 50 در `Cursor.01.plan.md` — آماده‌سازی انتشار کافه‌بازار.*
