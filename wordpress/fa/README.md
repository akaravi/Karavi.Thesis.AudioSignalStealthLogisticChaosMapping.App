# WordPress — پست صوت‌نهان (فارسی)

محتوای آماده انتشار برای [xwave.ir](http://xwave.ir) — locale: **`fa`**

نسخه انگلیسی: [`../en/`](../en/)
## فایل‌ها

| فایل | کاربرد |
|------|--------|
| `post-content.html` | بدنه پست (HTML با heading، alt، لینک داخلی/خارجی) |
| `seo-meta.json` | عنوان SEO، meta description، slug، OG، ۱۰ tag پیشنهادی |
| `schema-software-application.jsonld` | Schema.org SoftwareApplication |
| `images/*.webp` | تصاویر Web (WebP) — منبع: اسکرین‌شات کافه‌بازار ۱۶:۹ |

## تصاویر (WebP)

| فایل | نقش |
|------|-----|
| `featured-splash-intro.webp` | **تصویر شاخص (Featured Image)** |
| `embed-message-input.webp` | نهان‌نگاری — ورودی |
| `embed-waveform-metrics.webp` | موج و متریک |
| `extract-audio-file.webp` | رمزگشایی |
| `extract-recovered-text.webp` | نتیجه استخراج |
| `settings-theme-language.webp` | تنظیمات |
| `banner-myket-download.webp` | بنر لینک مایکت |
| `banner-xwave-site.webp` | بنر لینک XWave |
| `app-icon-256.webp` | آیکن اپ |

## ۱۰ Tag پیشنهادی (WordPress)

1. نهان‌نگاری صوتی  
2. صوت‌نهان  
3. LSB  
4. نقشه آشوب لاجستیک  
5. امنیت اطلاعات  
6. اپلیکیشن اندروید  
7. NTK  
8. پردازش صوت  
9. استگانوگرافی  
10. مایکت  

## لینک‌های اصلی

- **اپ:** https://myket.ir/app/ir.ntk.audiowmark.app  
- **سایت:** http://xwave.ir  

## مراحل انتشار در WordPress

1. همه فایل‌های `images/` را در Media → Upload (پوشه `sot-nehan`) آپلود کنید.  
2. پست جدید → عنوان: `صوت‌نهان: نرم‌افزار نهان‌نگاری پیام در فایل صوتی`  
3. Featured Image: `featured-splash-intro.webp`  
4. محتوا: paste از `post-content.html` — مسیر `images/` را به URL مدیا جایگزین کنید.  
5. Yoast / Rank Math: مقادیر `seo-meta.json`  
6. Schema: JSON-LD از `schema-software-application.jsonld` (Header Footer Code Manager یا Rank Math Schema)  
7. Slug: `sot-nehan-audio-steganography-app`  
8. Tagها و دسته‌بندی را از `seo-meta.json` اضافه کنید.

## SEO چک‌لیست

- [x] Focus keyword در title، H1، lead و alt اول  
- [x] Meta description زیر ۱۶۰ کاراکتر  
- [x] Canonical و OG image  
- [x] Alt و title برای همه تصاویر  
- [x] `loading="lazy"` (به‌جز featured)  
- [x] لینک داخلی: xwave.ir، category/apps  
- [x] لینک خارجی: مایکت، GitHub، NTK  
- [x] Schema SoftwareApplication  
- [x] جملات کوتاه (حداکثر ~۳۰ کلمه)  
- [x] حداقل ۱۰۰۰ کلمه (~۱۸۰۰+)
- [x] آموزش گام‌به‌گام در انتهای پست (۷ مرحله + تمرین)

## تولید مجدد WebP

```powershell
python wordpress/scripts/convert-screenshots-to-webp.py
python wordpress/scripts/build-link-banners.py
```

اسکرین‌شات‌ها از `docs/cafebazaar/screenshots_16x9/` کپی می‌شوند.

### قانون متن روی تصاویر

| نوع | متن فارسی |
|-----|-----------|
| اسکرین‌شات اپ (کافه‌بازار/مایکت) | مجاز — از UI واقعی |
| بنر/گرافیک ساخته‌شده با PIL | **ممنوع** — فقط انگلیسی |
| `alt` / `title` در HTML | مجاز — روی فایل burn نمی‌شود |

