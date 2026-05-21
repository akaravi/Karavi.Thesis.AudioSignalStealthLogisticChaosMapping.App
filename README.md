# Audio Signal Stealth — Logistic Chaos Mapping

نهان‌نگاری صوتی بر پایه LSB و نقشه آشوب لاجستیک (پورت از اسکریپت‌های MATLAB).

## ساختار مخزن

```
├── src/
│   ├── audio_steg_app/       # Flutter (Windows / Linux / Android)
│   ├── audio_steg_desktop/   # .NET 10 WPF (Windows)
│   └── Matlab/               # مرجع الگوریتم (منبع حقیقت)
├── Cursor.01.plan.md
└── readmehistory.md
```

## اجرای سریع

### Flutter

```bash
cd src/audio_steg_app
flutter pub get
flutter run -d windows
```

### انتشار در کافه‌بازار (Android)

1. یک‌بار: `.\src\audio_steg_app\android\scripts\create_release_keystore.ps1` و `android\key.properties` از `key.properties.example`
2. بیلد امضا‌شده: `.\_build-cafebazaar-release.ps1` → خروجی در `publish/cafebazaar/`
3. متن فروشگاه: `publish/cafebazaar/LISTING.fa.md` — آپلود در https://developers.cafebazaar.ir/

### دسکتاپ .NET

```bash
cd src/audio_steg_desktop
dotnet build AudioSteg.sln
dotnet run --project src/AudioSteg.Desktop
```

### انتشار GitHub (همه پلتفرم‌ها با یک تگ)

پس از commit، تگ `publish` (یا `publish/1.0.0+2`) را push کنید — workflow خودکار APK/AAB، Web، Flutter Windows و .NET Desktop را می‌سازد و [GitHub Release](https://docs.github.com/en/repositories/releasing-projects-on-github/managing-releases-in-a-repository) ایجاد می‌کند.

```bash
git tag publish/1.0.0+1
git push origin publish/1.0.0+1
```

جزئیات secrets اندروید و فهرست فایل‌ها: [`docs/GITHUB_RELEASE.md`](docs/GITHUB_RELEASE.md).

بیلد محلی همان منطق CI:

```powershell
.\_build-github-release.ps1 -TagName publish
```

## نسخه برنامه (`update ver`)

برای افزایش یک‌پارچه **نسخه فرعی** (minor) و شماره build در Flutter و WPF:

```powershell
.\_update-ver.ps1
```

پیش‌نمایش بدون نوشتن فایل: `.\_update-ver.ps1 -WhatIf`

مثال: `1.0.0+1` → `1.1.0+2`. منبع حقیقت: `src/audio_steg_app/pubspec.yaml`.

## MATLAB

اسکریپت‌های مرجع در `src/Matlab/`.
