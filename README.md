# Ong Sike Books

Website for Ong Sike's Myanmar-language e-books and AI Image Prompts, with QR and WhatsApp payment.

Live: https://minaungchanko14-creator.github.io/E-Book-Website/

## Files

- `index.html` — the full site with every image embedded. Edit this file.
- `docs/` — the light published version (`index.html` + `assets/`). Generated; don't edit by hand.
- `tools/build_deploy.py` — builds `docs/` from `index.html` (macOS, uses `sips`).
- `gallery/` — source images for the AI image gallery.

## Update the live site

```bash
python3 tools/build_deploy.py
```

Commit and push. GitHub Pages serves `docs/` from `main` (Settings → Pages → Deploy from a branch → `main` / `/docs`).
For Netlify, drag the whole `docs` folder into your site's **Deploys** tab.
