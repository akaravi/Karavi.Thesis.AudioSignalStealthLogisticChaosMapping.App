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

### دسکتاپ .NET

```bash
cd src/audio_steg_desktop
dotnet build AudioSteg.sln
dotnet run --project src/AudioSteg.Desktop
```

## MATLAB

اسکریپت‌های مرجع در `src/Matlab/`.
