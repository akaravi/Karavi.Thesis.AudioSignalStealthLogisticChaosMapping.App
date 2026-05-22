# GitHub Release (tag `publish`)

## خطای Billing در Actions

اگر job با این پیام متوقف شد:

> *The job was not started because recent account payments have failed or your spending limit needs to be increased*

یعنی **اعتبار GitHub Actions** (پرداخت، سقف Spending limit، یا پایان دقیقهٔ رایگان در repo خصوصی) تمام شده — نه خطای اسکریپت پروژه.

**راه‌حل‌ها (یکی را انتخاب کنید):**

1. **Self-hosted runner (پیشنهادی، رایگان)** — workflow روی PC شما اجرا می‌شود، نه `windows-latest`:
   ```powershell
   .\scripts\ci\Setup-GitHubSelfHostedRunner.ps1
   cd .github-runner
   .\config.cmd --url https://github.com/OWNER/REPO --token TOKEN
   .\run.cmd
   .\scripts\ci\Enable-ReleaseWorkflowRepository.ps1 -SetVariable
   git push origin publish
   ```
   تا وقتی `SELF_HOSTED_RUNNER_READY=true` نشود، push تگ **job را skip** می‌کند (صف بی‌پایان نمی‌ماند).
2. **انتشار کامل محلی** — بدون Actions (پایین).
3. **Billing** — GitHub.com → Settings → Billing & plans (فقط اگر بخواهید runner ابری GitHub را دوباره فعال کنید).

---

وقتی روی مخزن **tag** با نام `publish` (یا با پسوند نسخه) push می‌کنید، workflow
[`.github/workflows/release-on-publish-tag.yml`](../.github/workflows/release-on-publish-tag.yml)
همهٔ خروجی‌های انتشار را می‌سازد و یک **GitHub Release** با فایل‌های پیوست ایجاد می‌کند.

## تگ‌های پشتیبانی‌شده

| تگ | نسخهٔ بیلد |
|----|------------|
| `publish` | از `pubspec.yaml` و `AudioStegano.Desktop.csproj` |
| `publish/1.0.0+2` | نام `1.0.0` و build number `2` |
| `publish-v1.0.0` | نام `1.0.0` (شماره بیلد از pubspec) |
| `publish_1.0.0+2` | همان الگوی بالا |

## خروجی‌های Release

| فایل | پلتفرم |
|------|--------|
| `KaraviThesis_AudioStegano_FlutterWeb_*.zip` | Flutter Web |
| `KaraviThesis_AudioStegano_FlutterWindows_*.zip` | Flutter Desktop (Windows) |
| `KaraviThesis_AudioStegano_DotNetDesktop_*.zip` | .NET WPF Desktop |
| `KaraviThesis_AudioStegano_Android_*.zip` | APK/AAB داخل ZIP |
| `AudioStegano_*_arm64-v8a.apk` | Flutter Android (arm64) |
| `AudioStegano_*.aab` | Flutter Android (App Bundle) |
| `KaraviThesis_AudioStegano_Build_*.zip` | بستهٔ ترکیبی (همه در یک ZIP) |
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
[Convert]::ToBase64String([IO.File]::ReadAllBytes("src\audio_stegano_app\android\upload-keystore.jks")) | Set-Clipboard
```

## بیلد محلی (همان منطق CI)

```powershell
.\_build-github-release.ps1 -TagName publish
# یا
.\_build-github-release.ps1 -TagName publish/1.0.0+2
```

خروجی: `publish/github-release/`

## انتشار محلی (بدون Actions — فوری)

توکن با دسترسی **repo** (یک‌بار):

```powershell
$env:GITHUB_TOKEN = "ghp_YOUR_PAT"
# یا: gh auth login
# یا فایل: %USERPROFILE%\.github-token
```

بیلد + تگ + Release + آپلود (بدون `gh` — از REST API):

```powershell
.\_publish-local-github-release.ps1 -TagName publish/1.0.0+2
```

فقط آپلود:

```powershell
.\_build-github-release.ps1 -TagName publish/1.0.0+2
.\_publish-local-github-release.ps1 -TagName publish/1.0.0+2 -SkipBuild -SkipPushTag
```

نصب اختیاری GitHub CLI:

```powershell
.\_publish-local-github-release.ps1 -TagName publish -InstallGhCli
```

امضای اندروید: همان `android\key.properties` محلی.

## Actions

وضعیت اجرا: تب **Actions** در GitHub → workflow **Release on publish tag**.
