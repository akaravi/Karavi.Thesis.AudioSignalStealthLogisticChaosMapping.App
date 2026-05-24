# AudioStegano Desktop (.NET 10 / WPF)

نسخه دسکتاپ ویندوز همان اپلیکیشن Flutter نهان‌نگاری صوتی — فقط الگوریتم MATLAB (LSB + Logistic-Chaos).

## پیش‌نیاز

- [.NET 10 SDK](https://dotnet.microsoft.com/download)
- Windows (WPF)

## ساخت و اجرا

```bash
cd src/audio_stegano_desktop
dotnet build AudioStegano.sln
dotnet test
dotnet run --project src/AudioStegano.Desktop
```

## ساختار

| پروژه | نقش |
|--------|-----|
| `AudioStegano.Core` | WAV I/O، `AudioWatermarking`، متریک‌ها |
| `AudioStegano.Desktop` | UI (Embed / Extract / Settings)، ضبط و پخش NAudio |
| `AudioStegano.Core.Tests` | xUnit — round-trip، متریک، کلید اشتباه |

## اسکریپت‌های MATLAB

- `embed_extract_data.m`
- `logistic_map_keygen.m`
- `evaluate_stego.m`
- `main_steganography.m`

## تنظیمات

ذخیره در `%LocalAppData%\AudioStegano.Desktop\settings.json` — تم، زبان (fa/en/ar/fr)، پارامترهای `r` و `x0`.

لاگ جلسه (عیب‌یابی): `%LocalAppData%\AudioStegano.Desktop\logs\desktop_session.log`

روی ویندوز، دکمهٔ «بارگذاری فایل» در تب نهان‌نگاری حتی وقتی `ShowEmbedLoadFileButton` در `appsettings.json` برابر `false` است نمایش داده می‌شود (پیش‌فرض موبایل).

## باز کردن با (Open with) — ویندوز

- در **تنظیمات** گزینهٔ «باز کردن با ویندوز» را فعال کنید تا برنامه در منوی Open with اکسپلورر برای `wav` / `mp3` / `mp4` ظاهر شود (ثبت per-user در HKCU).
- یا از ریشهٔ مخزن: `.\_register-windows-open-with.ps1` (اختیاری: `-ExePath`, `-Unregister`).
- اگر برنامه در حال اجرا باشد، فایل بازشده به تب **رمزگشایی** هدایت می‌شود (تک‌نمونه، Named Pipe `Karavi.AudioStegano.Desktop.OpenFile.v1`).

نسخه Flutter Windows همان رفتار را با pipe جداگانه `Karavi.AudioStegano.Flutter.OpenFile.v1` در `windows/runner/single_instance.cpp` دارد.
