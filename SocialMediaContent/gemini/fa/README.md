# Gemini Create Video — فارسی (fa)

پرامپت JSON برای **Gemini Veo 3.1** — فیلم تبلیغاتی ~۵۴ ثانیه **صَوتُ‌نِهَان**

## فایل

[`gemini-create-video-promo.json`](gemini-create-video-promo.json)

## تصاویر مرجع

از [`../../wordpress/fa/images/`](../../wordpress/fa/images/)

## شروع سریع

1. [Google AI Studio — Veo](https://aistudio.google.com/models/veo-3) را باز کنید.
2. برای هر صحنه در `scenes[]` (۱–۹):
   - حالت **Image to video**
   - آپلود `referenceImagePath`
   - Paste کردن `veoPrompt`
   - **16:9**، **1080p**، **6s**، مدل **Veo 3.1 Fast**
3. گوینده: `voiceoverDiacritics` (با **اعراب کامل**) در TTS فارسی
4. چسباندن کلیپ‌ها طبق `assemblyInstructions`

## اعراب

هر خط فارسی در فیلدهای `voiceoverDiacritics` و `onScreenTextDiacritics` است. بدون اعراب در TTS استفاده نکنید.

## لینک‌ها

- مایکت: https://myket.ir/app/ir.ntk.audiowmark.app  
- سایت: http://xwave.ir  

نسخه انگلیسی: [`../en/`](../en/)
