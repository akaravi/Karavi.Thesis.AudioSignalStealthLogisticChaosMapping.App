# Gemini Create Video — Audio Stegano promo

JSON prompts for **Google Gemini Create Video (Veo 3.1)** — ~54s promotional film.

Parent: [`../`](../) (`SocialMediaContent`)

| Locale | Folder | Voiceover | Screenshots |
|--------|--------|-----------|-------------|
| Persian | [`fa/`](fa/) | `voiceoverDiacritics` (full tashkil) | `wordpress/fa/images/` |
| English | [`en/`](en/) | `voiceover` (English only) | `wordpress/en/images/` |

## Files per locale

| File | Purpose |
|------|---------|
| `gemini-create-video-promo.json` | 9 scenes, Veo prompts, assembly |
| `README.md` | Quick start for that locale |

## Regenerate screenshots

```powershell
python SocialMediaContent/wordpress/scripts/convert-screenshots-to-webp.py
```

## Raster text rule

PIL-generated banners = **English only**. Persian in fa prompt uses diacritics for TTS only.
