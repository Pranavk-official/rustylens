# RustyLens

A lightweight, open-source OCR tool for the Linux desktop. Open an image or capture a screenshot, and RustyLens extracts the text using Tesseract — with bounding-box overlays and drag-to-select word copying.

Built with Rust, GTK4, and libadwaita.

[![Version](https://img.shields.io/github/v/release/Pranavk-official/rustylens?label=version&color=0078d7)](https://github.com/Pranavk-official/rustylens/releases/latest)
[![License](https://img.shields.io/badge/license-GPL--3.0--or--later-blue)](LICENSE)
[![CI](https://img.shields.io/github/actions/workflow/status/Pranavk-official/rustylens/ci.yml?branch=main&label=CI)](https://github.com/Pranavk-official/rustylens/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/actions/workflow/status/Pranavk-official/rustylens/release.yml?label=release)](https://github.com/Pranavk-official/rustylens/actions/workflows/release.yml)
[![Downloads](https://img.shields.io/github/downloads/Pranavk-official/rustylens/total?label=installs&color=brightgreen)](https://github.com/Pranavk-official/rustylens/releases)
[![Docs](https://img.shields.io/badge/docs-online-blue)](https://pranavk-official.github.io/rustylens/)
[![Built with Rust](https://img.shields.io/badge/built%20with-Rust-orange?logo=rust)](https://www.rust-lang.org)
[![GTK4](https://img.shields.io/badge/GTK-4-blueviolet?logo=gnome)](https://gtk.org)

## Screenshots

![RustyLens main window — bounding-box OCR overlay](data/screenshots/main-window.png)

![RustyLens screenshot mode — XDG portal capture](data/screenshots/screenshot-mode.png)

## Demo

<video controls src="demo/demo.mp4" title="Demo"></video>

> If the video does not play in your browser, [download it here](demo/demo.mp4).

## Features

- **OCR text extraction** — supports 100+ languages; auto-detects all installed Tesseract language packs
- **Drag-to-select** — click or drag across highlighted words to select them, then Ctrl+C to copy
- **Bounding-box overlay** — recognised words are highlighted on the image preview
- **Screenshot mode** — `rustylens --capture` grabs a screenshot via the XDG portal and runs OCR immediately
- **Language selector** — dropdown showing human-readable names ("English", "Japanese", "Chinese (Simplified)"); "Auto (all)" uses every installed pack
- **Copy all text** — one-click button to copy the full extracted text
- **Flatpak-ready** — fully sandboxed with portal-based screenshot integration

## Quick Start

Clone the repository and run the installer. It auto-detects your distro and downloads the correct native binary and English language pack:

```bash
git clone https://github.com/Pranavk-official/rustylens.git
cd rustylens
./install.sh --minimal
```

Then launch:

```bash
rustylens
```

For other install formats (AppImage, Flatpak, manual), see [Installation](#installation).

## Installation

### With `install.sh` (recommended for Linux)

`install.sh` auto-detects your distro (Arch, Ubuntu/Debian, Fedora/RHEL), downloads the matching native binary from GitHub Releases, and sets up Tesseract language packs. On unknown distros (Alpine, Void, openSUSE), it falls back to the AppImage automatically.

**Choose your language packs:**

```bash
./install.sh --minimal                    # English only (default)
./install.sh --european                   # Western + Eastern European
./install.sh --asian                      # East Asian (CJK, Korean, Vietnamese)
./install.sh --full                       # All language groups
./install.sh --langs "eng fra jpn"        # Custom selection
./install.sh --no-langs                   # Skip language packs entirely
```

**Choose your install format:**

```bash
./install.sh --minimal                    # Auto-detect distro; download native binary
./install.sh -A --minimal                 # Force AppImage (bundled libs, any distro)
./install.sh -F                           # Flatpak (fully sandboxed, 128 language packs)
./install.sh --local ./RustyLens-x86_64.AppImage  # Install from a local file
```

Installs to `~/.local/bin/rustylens` by default. Override with `--prefix /usr/local`.

**Update and uninstall:**

```bash
./install.sh --update                     # Re-download latest release in the same format
./install.sh --uninstall                  # Remove binary, desktop entry, and icon
```

**Non-interactive / CI:**

```bash
NONINTERACTIVE=1 ./install.sh --minimal
```

### Pre-built releases (manual)

Download from [GitHub Releases](https://github.com/Pranavk-official/rustylens/releases):

| File | Description |
|------|-------------|
| `rustylens-linux-x86_64-arch.tar.gz` | Native binary for Arch / Garuda / Manjaro (leptonica 1.84+) |
| `rustylens-linux-x86_64-ubuntu.tar.gz` | Native binary for Debian / Ubuntu / Mint / Pop |
| `rustylens-linux-x86_64-fedora.tar.gz` | Native binary for Fedora / RHEL / Rocky / Alma / Nobara |
| `rustylens-linux-x86_64.tar.gz` | Generic binary (same as ubuntu build, backward compat) |
| `rustylens.flatpak` | Self-contained Flatpak bundle — all 128 language packs included |
| `RustyLens-x86_64.AppImage` | Portable AppImage — GTK4 and all libraries bundled |
| `RustyLens-*-apple-darwin.dmg` | macOS DMG with bundled dylibs (requires Tesseract tessdata) |
| `rustylens-windows-x86_64.zip` | Windows zip with bundled DLLs and English tessdata |

> **Choosing a Linux binary:** native tarballs link against your distro's leptonica version,
> avoiding ABI mismatches (e.g. `liblept.so` version conflicts). The AppImage and Flatpak bundle
> all libraries, so no system OCR libraries are needed.

#### Native binary

Install the runtime libraries for your distro, then extract the binary:

**Arch Linux:**

```bash
sudo pacman -S leptonica tesseract
sudo pacman -S tesseract-data-eng               # English (or other language packs)
tar xzf rustylens-linux-x86_64-arch.tar.gz
install -Dm755 rustylens ~/.local/bin/rustylens
```

**Debian / Ubuntu:**

```bash
sudo apt install libleptonica-dev libtesseract-dev tesseract-ocr-eng
tar xzf rustylens-linux-x86_64-ubuntu.tar.gz
install -Dm755 rustylens ~/.local/bin/rustylens
```

**Fedora:**

```bash
sudo dnf install leptonica tesseract tesseract-langpack-eng
tar xzf rustylens-linux-x86_64-fedora.tar.gz
install -Dm755 rustylens ~/.local/bin/rustylens
```

To register the app in your desktop launcher, also install the `.desktop` entry and icon from the cloned repo:

```bash
install -Dm644 data/io.github.pranavk_official.RustyLens.desktop \
  ~/.local/share/applications/io.github.pranavk_official.RustyLens.desktop
install -Dm644 data/icons/hicolor/scalable/apps/io.github.pranavk_official.RustyLens.svg \
  ~/.local/share/icons/hicolor/scalable/apps/io.github.pranavk_official.RustyLens.svg
```

#### Flatpak bundle

```bash
flatpak install --user rustylens.flatpak
```

#### AppImage

```bash
chmod +x RustyLens-x86_64.AppImage
./RustyLens-x86_64.AppImage
```

Or copy it to your `PATH` for system-wide access:

```bash
install -Dm755 RustyLens-x86_64.AppImage ~/.local/bin/rustylens
```

### Building from source

> **For developers and contributors.** End users should use `install.sh` or a pre-built release.

**System dependencies:**

| Distro | Command |
|--------|---------|
| **Arch** | `sudo pacman -S clang gtk4 libadwaita leptonica tesseract` |
| **Debian/Ubuntu** | `sudo apt install clang libgtk-4-dev libadwaita-1-dev libleptonica-dev libtesseract-dev` |
| **Fedora** | `sudo dnf install clang gtk4-devel libadwaita-devel leptonica-devel tesseract-devel` |
| **macOS** | `brew install gtk4 libadwaita leptonica tesseract` |
| **Windows** | Install MSYS2/MINGW64; `pacman -S mingw-w64-x86_64-{gtk4,libadwaita,leptonica,tesseract}` |

Also install [Rust 1.85+](https://rustup.rs) (required for the 2024 edition).

```bash
git clone https://github.com/Pranavk-official/rustylens.git
cd rustylens
cargo build --release
```

The binary is at `target/release/rustylens` (~2 MB).

#### Install from source

```bash
cargo install --path .

# Register the desktop entry and icon:
install -Dm644 data/io.github.pranavk_official.RustyLens.desktop \
  ~/.local/share/applications/io.github.pranavk_official.RustyLens.desktop
install -Dm644 data/icons/hicolor/scalable/apps/io.github.pranavk_official.RustyLens.svg \
  ~/.local/share/icons/hicolor/scalable/apps/io.github.pranavk_official.RustyLens.svg
```

#### Build a local AppImage

Produces a portable `RustyLens-x86_64.AppImage` (~50 MB) without needing Flatpak.

Additional dependency: `squashfs-tools` (and `pkg-config` on some distros). `linuxdeploy` is downloaded automatically if not present.

```bash
./build-appimage.sh                  # Full build (cargo + AppImage)
./build-appimage.sh --skip-build     # Reuse existing binary
./build-appimage.sh --install        # Build and install to ~/.local/bin/rustylens
./build-appimage.sh --clean          # Clean build artefacts first
```

Or with Make:

```bash
make appimage          # Build AppImage
make appimage-install  # Build + install to ~/.local/bin
```

#### Build the Flatpak locally

```bash
# One-time SDK setup:
flatpak install flathub org.gnome.Platform//49 org.gnome.Sdk//49
flatpak install flathub org.freedesktop.Sdk.Extension.rust-stable//25.08

# Build and install:
flatpak-builder --user --install --force-clean build-dir io.github.pranavk_official.RustyLens.json
```

### Makefile quick reference

```bash
make build          # cargo build --release
make run            # Build + run GUI
make appimage       # Build AppImage
make install        # Install AppImage + desktop entry to ~/.local
make install-langs  # Install English Tesseract pack (edit LANGS= to change)
make test-docker    # Run full Docker test suite (install.sh + build-appimage.sh)
make clean          # cargo clean + remove AppDir / AppImage artefacts
make release        # Build + tag a new release commit
```

### Uninstall

```bash
# Via install.sh (recommended):
./install.sh --uninstall

# Standalone binary (installed manually):
rm ~/.local/bin/rustylens
rm ~/.local/share/applications/io.github.pranavk_official.RustyLens.desktop
rm ~/.local/share/icons/hicolor/scalable/apps/io.github.pranavk_official.RustyLens.svg

# cargo install:
cargo uninstall rustylens

# Flatpak:
flatpak uninstall --user io.github.pranavk_official.RustyLens

# AppImage:
rm ~/.local/bin/rustylens
```

## Usage

### GUI mode

```bash
rustylens
```

1. Click **Open Image** to pick an image through your desktop's file chooser.
2. OCR runs automatically — extracted text appears in the panel below the image.
3. **Select text**: click on any highlighted word to select it, or click and drag across multiple words to select a range. Press **Ctrl+C** to copy selected words to the clipboard.
4. Use **Copy All Text** to copy everything at once.
5. Change the OCR language from the dropdown in the header bar. "Auto (all)" uses every installed language pack.

### Screenshot mode

```bash
rustylens --capture
```

Opens an interactive screenshot selection (via the XDG Desktop Portal), then loads the captured image for OCR.

## Managing OCR Languages

RustyLens automatically detects all Tesseract language packs installed on your system by scanning the tessdata directory (typically `/usr/share/tessdata/`). To add a new language:

1. Install the language pack for your distro (e.g., `sudo pacman -S tesseract-data-fra` for French).
2. Restart RustyLens — the new language appears in the dropdown with its full name (e.g. "French" rather than `fra`).

The "Auto (all)" option uses all installed languages simultaneously. For best accuracy and speed, select the specific language you need.

Some common language codes for `install.sh --langs` and `--capture` mode:

| Code | Language |
|------|----------|
| `eng` | English |
| `jpn` | Japanese |
| `chi_sim` | Chinese (Simplified) |
| `chi_tra` | Chinese (Traditional) |
| `kor` | Korean |
| `deu` | German |
| `fra` | French |
| `spa` | Spanish |
| `ara` | Arabic |
| `hin` | Hindi |

For the full list of codes, see the [Tesseract data files documentation](https://tesseract-ocr.github.io/tessdoc/Data-Files-in-different-versions.html).

## How It Works

1. **Image loading** — `gtk::FileDialog` opens the native file chooser (GTK4 transparently uses the XDG portal when running inside a Flatpak). The selected `GFile` path is passed directly to Tesseract.
2. **OCR** — runs on a background thread to avoid blocking the UI. Tesseract processes the image and returns both the full text and per-word bounding boxes (via TSV output).
3. **Bounding boxes** — a transparent `gtk::DrawingArea` overlay renders word rectangles using Cairo, scaled to match the image's "Contain" fit.
4. **Word selection** — a `GestureDrag` handler lets you click or drag across highlighted words to select a range. Ctrl+C copies selected words in reading order.
5. **Portal integration** — the XDG Screenshot Portal (via ashpd/zbus) handles the `--capture` screenshot mode, running on a shared persistent Tokio runtime for reliable D-Bus communication.

## Project Structure

```
.
├── src/
│   ├── main.rs               Entry point, CLI flag, application setup
│   ├── ui.rs                 Window construction, word selection, drawing callbacks
│   ├── portal.rs             XDG Screenshot Portal wrapper, shared Tokio runtime, background tasks
│   └── ocr.rs                Tesseract OCR via leptess, language detection, TSV bbox parsing
├── data/
│   ├── icons/hicolor/scalable/apps/
│   │   └── *.svg             App icon
│   ├── *.desktop             Desktop entry
│   └── *.metainfo.xml        AppStream metadata
├── build-appimage.sh         Local AppImage builder (two-pass linuxdeploy + mksquashfs)
├── install.sh                Cross-distro installer: native binary, AppImage, Flatpak, and tessdata
├── local-scripts/            Local-only scripts (not committed)
│   ├── test-install.sh       Docker test harness for install.sh
│   ├── test-build-appimage.sh  Docker test harness for build-appimage.sh
│   └── test-makefile.sh      Docker test harness for Makefile targets
├── Makefile                  Developer task shortcuts
├── Cargo.toml
├── CHANGELOG.md
└── io.github.pranavk_official.RustyLens.json  Flatpak manifest
```

## Contributing

Contributions are welcome! Please open an issue or pull request. For full documentation see the [docs site](https://pranavk-official.github.io/rustylens/).

When building for development, use the debug build for faster compile times:

```bash
cargo build
./target/debug/rustylens
```

There is no test suite yet. When adding tests, prefer integration tests in `tests/` for portal/UI logic and unit tests for pure functions (e.g., `parse_tsv_words`).

## License

This project is licensed under the [GNU General Public License v3.0 or later](LICENSE).
