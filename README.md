# Ong Sike Books

Website for Ong Sike's Myanmar-language e-books and AI Image Prompts, with QR and WhatsApp payment.

## Files

- `index.html` — the full site with every image embedded. Edit this file.
- `deploy/` — the light version to upload to Netlify (`index.html` + `assets/`). Generated; don't edit by hand.
- `tools/build_deploy.py` — builds `deploy/` from `index.html` (macOS, uses `sips`).
- `gallery/` — source images for the AI image gallery.

## Update the live site

```bash
python3 tools/build_deploy.py
```

Then drag the whole `deploy` folder into your Netlify site's **Deploys** tab.
