"""Build the light, published version of the site.

index.html keeps every image embedded (easy to edit). This script writes
docs/index.html plus docs/assets/*, with each image saved once, resized
for how big it is shown, and loaded lazily below the first screen.
GitHub Pages serves docs/ (Settings → Pages → main /docs); the same folder
can be dragged into Netlify.

Run from the project folder (macOS, uses `sips`):
    python3 tools/build_deploy.py
"""
import base64, hashlib, pathlib, re, shutil, subprocess, tempfile

ROOT = pathlib.Path(__file__).resolve().parent.parent
SRC, OUT = ROOT / "index.html", ROOT / "docs"
ASSETS = OUT / "assets"

IMG = re.compile(r'<img([^>]*?)src="data:(image/[a-z+.-]+);base64,([A-Za-z0-9+/=]+)"([^>]*)>')


def slug(text):
    s = re.sub(r"[^a-z0-9]+", "-", text.lower()).strip("-")
    return s[:40] or "image"


def image_size(path):
    out = subprocess.run(["sips", "-g", "pixelWidth", "-g", "pixelHeight", str(path)],
                         check=True, capture_output=True, text=True).stdout
    return [int(n) for n in re.findall(r"pixel(?:Width|Height): (\d+)", out)]


def plan(attrs):
    """Return (max_side_px, format, quality) for an <img> based on how it is used."""
    alt = (re.search(r'alt="([^"]*)"', attrs) or [None, ""])[1]
    width = re.search(r'width[=:]"?(\d+)', attrs)
    if "QR" in alt:
        return 700, "jpeg", 92          # keep payment QR codes crisp and scannable
    if width and int(width.group(1)) <= 60:
        return 128, None, 85            # small icons: keep their own format
    if alt.startswith("AI image"):
        return 1200, "jpeg", 80         # gallery, opens full size on tap
    return 840, "jpeg", 80              # book covers


def main():
    html = SRC.read_text(encoding="utf-8")
    if OUT.exists():
        shutil.rmtree(OUT)
    ASSETS.mkdir(parents=True)
    tmp = pathlib.Path(tempfile.mkdtemp())
    saved = {}      # content hash -> asset path
    count = 0

    def replace(m):
        nonlocal count
        before, mime, data, after = m.groups()
        attrs = before + after
        key = hashlib.md5(data.encode()).hexdigest()[:8]
        if key not in saved:
            side, fmt, quality = plan(attrs)
            ext_in = "png" if mime == "image/png" else "jpg"
            fmt = fmt or ("png" if ext_in == "png" else "jpeg")
            ext_out = "png" if fmt == "png" else "jpg"
            alt = (re.search(r'alt="([^"]*)"', attrs) or [None, ""])[1]
            raw = tmp / f"{key}.{ext_in}"
            raw.write_bytes(base64.b64decode(data))
            name = f"{slug(alt)}-{key}.{ext_out}"
            cmd = ["sips", "-s", "format", fmt]
            if max(image_size(raw)) > side:   # shrink only, never enlarge
                cmd += ["-Z", str(side)]
            if fmt == "jpeg":
                cmd += ["-s", "formatOptions", str(quality)]
            subprocess.run(cmd + [str(raw), "--out", str(ASSETS / name)], check=True, capture_output=True)
            saved[key] = f"assets/{name}"
        count += 1
        # The first screen (showcase covers) loads right away; everything else lazily.
        lazy = "" if count <= 6 or "loading=" in attrs else ' loading="lazy"'
        return f'<img{before}src="{saved[key]}"{after}{lazy}>'

    out = IMG.sub(replace, html)
    if "data:image" in out:
        print("warning: some embedded images were not converted")
    (OUT / "index.html").write_text(out, encoding="utf-8")
    (OUT / ".nojekyll").write_text("")   # GitHub Pages: serve files as-is, no Jekyll build
    shutil.rmtree(tmp)

    total = sum(p.stat().st_size for p in OUT.rglob("*") if p.is_file())
    page = (OUT / "index.html").stat().st_size
    print(f"{count} images -> {len(saved)} files")
    print(f"page: {page / 1024:.0f} KB, total with images: {total / 1024:.0f} KB")


if __name__ == "__main__":
    main()
