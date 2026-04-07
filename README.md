# RustyLens

A lightweight, open-source OCR tool for the Linux desktop. Open an image or capture a screenshot, and RustyLens extracts the text using Tesseract — with bounding-box overlays and drag-to-select word copying.

Built with Rust, GTK4, and libadwaita.

[![Version](https://img.shields.io/github/v/release/Pranavk-official/rustylens?label=version&color=0078d7)](https://github.com/Pranavk-official/rustylens/releases/latest)
[![License](https://img.shields.io/badge/license-GPL--3.0--or--later-blue)](LICENSE)
[![CI](https://img.shields.io/github/actions/workflow/status/Pranavk-official/rustylens/ci.yml?branch=main&label=CI)](https://github.com/Pranavk-official/rustylens/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/actions/workflow/status/Pranavk-official/rustylens/release.yml?label=release)](https://github.com/Pranavk-official/rustylens/actions/workflows/release.yml)
[![Downloads](https://img.shields.io/github/downloads/Pranavk-official/rustylens/total?label=installs&color=brightgreen)](https://github.com/Pranavk-official/rustylens/releases)
[![Built with Rust](https://img.shields.io/badge/built%20with-Rust-orange?logo=rust)](https://www.rust-lang.org)
[![GTK4](https://img.shields.io/badge/GTK-4-blueviolet?logo=gnome)](https://gtk.org)

## Features

- **OCR text extraction** with support for 100+ languages (auto-detects all installed Tesseract language packs)
- **Drag-to-select** — click or drag across highlighted words to select them, then Ctrl+C to copy
- **Bounding-box overlay** — recognised words are highlighted on the image preview
- **Screenshot mode** — `rustylens --capture` grabs a screenshot via the XDG portal and runs OCR immediately
- **Language selector** — dropdown to pick a specific language or use all installed languages at once
- **Copy all text** — one-click button to copy the full extracted text
- **Flatpak-ready** — sandboxed with portal-based file chooser and screenshot integration

## Installation

### Prerequisites

**Runtime dependencies:**

- GTK 4.12+
- libadwaita 1.4+
- Tesseract OCR engine
- At least one Tesseract language data pack

**Build dependencies (in addition to the above):**

- Rust 1.70+ (install via [rustup](https://rustup.rs))
- clang (for C bindings)
- Leptonica and Tesseract development headers

### Arch Linux

```bash
sudo pacman -S clang leptonica tesseract

# Install language packs (at least one required):
sudo pacman -S tesseract-data-eng               # English
sudo pacman -S tesseract-data-jpn               # Japanese
sudo pacman -S tesseract-data                   # All languages
```

### Debian / Ubuntu

```bash
sudo apt install clang libleptonica-dev libtesseract-dev

# Install language packs (at least one required):
sudo apt install tesseract-ocr-eng              # English
sudo apt install tesseract-ocr-jpn              # Japanese
sudo apt install tesseract-ocr-all              # All languages
```

### Fedora

```bash
sudo dnf install clang leptonica-devel tesseract-devel

# Install language packs:
sudo dnf install tesseract-langpack-eng
```

### Pre-built releases

Download from [GitHub Releases](https://github.com/Pranavk-official/rustylens/releases):

| File | Description |
|------|-------------|
| `rustylens-linux-x86_64.tar.gz` | Standalone binary (requires system GTK4, libadwaita, Tesseract) |
| `rustylens.flatpak` | Self-contained Flatpak bundle with all 128 language packs |
| `RustyLens-x86_64.AppImage` | Portable AppImage with GTK4 and all libraries bundled |

#### AppImage — one-command install with `install.sh`

The bundled `install.sh` handles installation on any distro and manages Tesseract language packs automatically:

```bash
# English only (default)
./install.sh --minimal

# Western + Eastern European
./install.sh --european

# East Asian (CJK, Korean, Vietnamese)
./install.sh --asian

# All language groups
./install.sh --full

# Custom selection
./install.sh --langs "eng fra jpn"

# AppImage only — manage languages yourself
./install.sh --no-langs

# Non-interactive / CI
NONINTERACTIVE=1 ./install.sh --minimal
```

Installs to `~/.local/bin/rustylens` by default. Change with `--prefix /usr/local`.

```bash
# Uninstall
./install.sh --uninstall
```

#### Flatpak bundle

```bash
flatpak install --user rustylens.flatpak
```

#### Standalone binary

```bash
tar xzf rustylens-linux-x86_64.tar.gz
sudo install -Dm755 rustylens /usr/local/bin/rustylens
sudo install -Dm644 data/io.github.pranavk_official.RustyLens.desktop \
  /usr/share/applications/io.github.pranavk_official.RustyLens.desktop
sudo install -Dm644 data/icons/hicolor/scalable/apps/io.github.pranavk_official.RustyLens.svg \
  /usr/share/icons/hicolor/scalable/apps/io.github.pranavk_official.RustyLens.svg
```

### Build from source

```bash
git clone https://github.com/Pranavk-official/rustylens.git
cd rustylens
cargo build --release
```

The binary is at `target/release/rustylens` (~2 MB).

### Build a local AppImage with `build-appimage.sh`

Produces a portable `RustyLens-x86_64.AppImage` (~50 MB) without needing Flatpak.

#### System dependencies

| Distro | Command |
|--------|--------|
| **Arch** | `sudo pacman -S gtk4 libadwaita leptonica tesseract squashfs-tools pkg-config` |
| **Debian/Ubuntu** | `sudo apt install libgtk-4-dev libadwaita-1-dev libleptonica-dev libtesseract-dev squashfs-tools pkg-config clang` |
| **Fedora** | `sudo dnf install gtk4-devel libadwaita-devel leptonica-devel tesseract-devel squashfs-tools pkg-config clang` |
| **openSUSE** | `sudo zypper install gtk4-devel libadwaita-devel leptonica-devel tesseract-devel squashfs-tools pkg-config clang` |
| **Alpine** | `sudo apk add gtk4.0-dev libadwaita-dev leptonica-dev tesseract-ocr-dev squashfs-tools pkgconfig clang` |

`linuxdeploy` is downloaded automatically if not already present in the project root.

```bash
# Full build (cargo + AppImage):
./build-appimage.sh

# Skip cargo (reuse existing binary):
./build-appimage.sh --skip-build

# Build and install to ~/.local/bin/rustylens:
./build-appimage.sh --install

# Clean previous build artefacts first:
./build-appimage.sh --clean
```

Or with Make:

```bash
make appimage          # build AppImage
make appimage-install  # build + install to ~/.local/bin
```

### Install locally

```bash
cargo install --path .

# Add desktop entry (so it appears in your app launcher):
install -Dm644 data/io.github.pranavk_official.RustyLens.desktop \
  ~/.local/share/applications/io.github.pranavk_official.RustyLens.desktop
install -Dm644 data/icons/hicolor/scalable/apps/io.github.pranavk_official.RustyLens.svg \
  ~/.local/share/icons/hicolor/scalable/apps/io.github.pranavk_official.RustyLens.svg
```

### Build Flatpak locally

```bash
# Install the GNOME SDK (one-time setup):
flatpak install flathub org.gnome.Platform//49 org.gnome.Sdk//49
flatpak install flathub org.freedesktop.Sdk.Extension.rust-stable//25.08

# Build and install:
flatpak-builder --user --install --force-clean build-dir io.github.pranavk_official.RustyLens.json
```

### Makefile quick reference

```bash
make build          # cargo build --release
make run            # build + run GUI
make appimage       # build AppImage
make install        # install AppImage + desktop entry to ~/.local
make install-langs  # install English Tesseract pack (edit LANGS= to change)
make test-docker    # run full Docker test suite (install.sh + build-appimage.sh)
make clean          # cargo clean + remove AppDir / AppImage artefacts
make release        # build + tag a new release commit
```

### Uninstall

```bash
# Via install.sh:
./install.sh --uninstall

# Standalone binary:
sudo rm /usr/local/bin/rustylens
sudo rm /usr/share/applications/io.github.pranavk_official.RustyLens.desktop
sudo rm /usr/share/icons/hicolor/scalable/apps/io.github.pranavk_official.RustyLens.svg

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

## Project Structure

```
.
├── src/
│   ├── main.rs               Entry point, CLI flag, application setup
│   ├── ui.rs                 Window construction, word selection, drawing callbacks
│   ├── portal.rs             XDG portal wrappers (file chooser, screenshot), background tasks
│   └── ocr.rs                Tesseract OCR via leptess, language detection, TSV bbox parsing
├── data/
│   ├── icons/hicolor/scalable/apps/
│   │   └── *.svg             App icon
│   ├── *.desktop             Desktop entry
│   └── *.metainfo.xml        AppStream metadata
├── build-appimage.sh         Local AppImage builder (two-pass linuxdeploy + mksquashfs)
├── install.sh                Cross-distro AppImage + tessdata installer
├── local-scripts/            Local-only scripts (gitignored)
│   ├── test-install.sh       Docker test harness for install.sh
│   ├── test-build-appimage.sh Docker test harness for build-appimage.sh
│   └── test-makefile.sh      Docker test harness for Makefile targets
├── Makefile                  Developer task shortcuts
├── Cargo.toml
├── CHANGELOG.md
└── io.github.pranavk_official.RustyLens.json  Flatpak manifest
```

## How It Works

1. **Image loading** — the file chooser portal returns a `file://` URI, which is percent-decoded to a filesystem path and displayed in a `gtk::Picture` widget.
2. **OCR** — runs on a background thread to avoid blocking the UI. Tesseract processes the image and returns both the full text and per-word bounding boxes (via TSV output).
3. **Bounding boxes** — a transparent `gtk::DrawingArea` overlay renders word rectangles using Cairo, scaled to match the image's "Contain" fit.
4. **Word selection** — a `GestureDrag` handler lets you click or drag across highlighted words to select a range. Ctrl+C copies selected words in reading order.
5. **Portal integration** — XDG Desktop Portals (via ashpd/zbus) handle the file chooser and screenshot dialogs, running on a shared Tokio runtime for reliable D-Bus communication.

## Adding OCR Languages

RustyLens automatically detects all Tesseract language packs installed on your system by scanning the tessdata directory (typically `/usr/share/tessdata/`). To add a new language:

1. Install the language pack for your distro (e.g., `sudo pacman -S tesseract-data-fra` for French).
2. Restart RustyLens — the new language appears in the dropdown.

The "Auto (all)" option uses all installed languages simultaneously. For best accuracy and speed, select the specific language you need.

Tesseract language codes follow [ISO 639-3](https://tesseract-ocr.github.io/tessdoc/Data-Files-in-different-versions.html). Common examples:

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

## Contributing

Contributions are welcome! Please open an issue or pull request.

When building for development, use the debug build for faster compile times:

```bash
cargo build
./target/debug/rustylens
```

There is no test suite yet. When adding tests, prefer integration tests in `tests/` for portal/UI logic and unit tests for pure functions (e.g., `parse_tsv_words`).

## License

[GPL-3.0-or-later](https://www.gnu.org/licenses/gpl-3.0.html)
