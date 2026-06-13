# WordPress — Audio Stegano posts

Ready-to-publish WordPress content for [xwave.ir](http://xwave.ir) about **Audio Stegano** (Persian name: *Sot-Nehan*).

| Locale | Folder | Language |
|--------|--------|----------|
| Persian | [`fa/`](fa/) | `fa_IR`, RTL |
| English | [`en/`](en/) | `en_US`, LTR |

## Files per locale

| File | Purpose |
|------|---------|
| `post-content.html` | Post body (headings, alt, internal/external links, tutorial) |
| `seo-meta.json` | SEO title, meta description, slug, OG, 10 tags |
| `schema-software-application.jsonld` | Schema.org SoftwareApplication |
| `images/*.webp` | WebP assets (Cafe Bazaar 16:9 screenshots + banners) |
| `README.md` | Publish checklist for that locale |

## Main links

- **App (Myket):** https://myket.ir/app/ir.ntk.audiowmark.app  
- **Site:** http://xwave.ir  

## Regenerate images (both locales)

```powershell
python wordpress/scripts/convert-screenshots-to-webp.py
```

Screenshots from `docs/cafebazaar/screenshots_16x9/`. Link banners use **English-only** raster text (PIL cannot render Persian correctly).

## Image text rule

| Type | Persian in raster |
|------|-------------------|
| App screenshots (store) | OK — real UI |
| PIL-generated banners | **No** — English only |
| HTML `alt` / `title` | OK — not burned into file |
