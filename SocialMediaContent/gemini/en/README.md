# Gemini Create Video — English (en)

JSON prompt for **Gemini Veo 3.1** — ~54 second **Audio Stegano** promo (fully English).

## File

[`gemini-create-video-promo.json`](gemini-create-video-promo.json)

## Reference images

From [`../../wordpress/en/images/`](../../wordpress/en/images/)

## Quick start

1. Open [Google AI Studio — Veo](https://aistudio.google.com/models/veo-3).
2. For each scene in `scenes[]` (1–9):
   - Mode: **Image to video**
   - Upload `referenceImagePath`
   - Paste `veoPrompt`
   - **16:9**, **1080p**, **6s**, model **Veo 3.1 Fast**
3. Narration: use `voiceover` (English TTS or record)
4. Stitch clips per `assemblyInstructions`

## Links

- Myket: https://myket.ir/app/ir.ntk.audiowmark.app  
- Site: http://xwave.ir/en/  

Persian version: [`../fa/`](../fa/)
