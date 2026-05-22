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

ذخیره در `%LocalAppData%\AudioStegano.Desktop\settings.json` — تم، زبان (fa/en)، پارامترهای `r` و `x0`.
