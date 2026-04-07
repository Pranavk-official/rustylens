# Getting Started

This guide walks you through installing RustyLens and running it for the first time. You will end up with a working OCR tool on your Linux desktop.

**What you need:**

- A Linux desktop (x86_64)
- `curl` or `wget`
- Root access for installing Tesseract language packs (optional — `--download` avoids this)

---

## Step 1 — Run the installer

The `install.sh` script auto-detects your distribution, downloads the correct native binary, and sets up the English Tesseract language pack.

```bash
curl -fsSL https://raw.githubusercontent.com/Pranavk-official/rustylens/main/install.sh | bash -s -- --minimal
```

The installer will:

1. Detect your distro (Arch, Debian/Ubuntu, Fedora, or fall back to AppImage)
2. Download the matching binary from [GitHub Releases](https://github.com/Pranavk-official/rustylens/releases/latest)
3. Install it to `~/.local/bin/rustylens`
4. Install the desktop entry and icon so the app appears in your launcher
5. Install the English Tesseract language pack via your package manager

!!! tip
    Make sure `~/.local/bin` is on your `PATH`. Most modern distros include it by default. If not, add this to your shell profile:
    ```bash
    export PATH="$HOME/.local/bin:$PATH"
    ```

---

## Step 2 — Launch RustyLens

```bash
rustylens
```

Or search for **RustyLens** in your application launcher (GNOME Shell, KDE Plasma, etc.).

---

## Step 3 — Extract text from an image

1. Click **Open Image** in the toolbar.
2. Select any image file (PNG, JPEG, TIFF, BMP, etc.) from the file chooser.
3. OCR runs automatically — extracted text appears in the panel below the image.
4. Highlighted word boxes appear on the image. Click or drag across them to select words, then press ++ctrl+c++ to copy.
5. Use **Copy All Text** to copy everything at once.

---

## Step 4 — Try screenshot mode (optional)

RustyLens can also capture a screenshot and run OCR on it directly:

```bash
rustylens --capture
```

An interactive selection overlay appears. Draw a rectangle around the area you want to OCR, and the extracted text appears immediately.

---

## What's next?

- Add more languages: [OCR Languages](usage/languages.md)
- All install options (AppImage, Flatpak, build from source): [Installation](installation/index.md)
- Full usage guide: [GUI Mode](usage/gui.md)
