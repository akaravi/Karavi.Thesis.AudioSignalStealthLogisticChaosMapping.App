# GitHub Release (tag `publish`)

وقتی روی مخزن **tag** با نام `publish` (یا با پسوند نسخه) push می‌کنید، workflow
[`.github/workflows/release-on-publish-tag.yml`](../.github/workflows/release-on-publish-tag.yml)
همهٔ خروجی‌های انتشار را می‌سازد و یک **GitHub Release** با فایل‌های پیوست ایجاد می‌کند.

## تگ‌های پشتیبانی‌شده

| تگ | نسخهٔ بیلد |
|----|------------|
| `publish` | از `pubspec.yaml` و `AudioSteg.Desktop.csproj` |
| `publish/1.0.0+2` | نام `1.0.0` و build number `2` |
| `publish-v1.0.0` | نام `1.0.0` (شماره بیلد از pubspec) |
| `publish_1.0.0+2` | همان الگوی بالا |

## خروجی‌های Release

| فایل | پلتفرم |
|------|--------|
| `KaraviThesis_AudioSteg_FlutterWeb_*.zip` | Flutter Web |
| `KaraviThesis_AudioSteg_FlutterWindows_*.zip` | Flutter Desktop (Windows) |
| `KaraviThesis_AudioSteg_DotNetDesktop_*.zip` | .NET WPF Desktop |
| `KaraviThesis_AudioSteg_Android_*.zip` | APK/AAB داخل ZIP |
| `AudioSteg_*_arm64-v8a.apk` | Flutter Android (arm64) |
| `AudioSteg_*.aab` | Flutter Android (App Bundle) |
| `KaraviThesis_AudioSteg_Build_*.zip` | بستهٔ ترکیبی (همه در یک ZIP) |
| `RELEASE_MANIFEST.txt` | فهرست فایل‌ها |

## نحوهٔ انتشار

```bash
git add .
git commit -m "chore: release 1.0.0+2"
git tag publish/1.0.0+2
git push origin main
git push origin publish/1.0.0+2
```

فقط push تگ workflow را اجرا می‌کند:

```bash
git push origin publish
```

## امضای Android (اختیاری ولی توصیه‌شده)

در **Settings → Secrets and variables → Actions** این secrets را اضافه کنید:

| Secret | توضیح |
|--------|--------|
| `ANDROID_KEYSTORE_BASE64` | فایل `upload-keystore.jks` به صورت Base64 |
| `ANDROID_KEYSTORE_PASSWORD` | رمز keystore |
| `ANDROID_KEY_PASSWORD` | رمز کلید |
| `ANDROID_KEY_ALIAS` | اختیاری؛ پیش‌فرض `upload` |

بدون این secrets، APK/AAB با **debug signing** ساخته می‌شود (برای تست CI مناسب است، نه فروشگاه).

تولید Base64 در PowerShell:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("src\audio_steg_app\android\upload-keystore.jks")) | Set-Clipboard
```

## بیلد محلی (همان منطق CI)

```powershell
.\_build-github-release.ps1 -TagName publish
# یا
.\_build-github-release.ps1 -TagName publish/1.0.0+2
```

خروجی: `publish/github-release/`

## Actions

وضعیت اجرا: تب **Actions** در GitHub → workflow **Release on publish tag**.
