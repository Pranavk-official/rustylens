# RustyLens

A lightweight, open-source OCR tool for the Linux desktop. Open an image or capture a screenshot, and RustyLens extracts the text using Tesseract — with bounding-box overlays and drag-to-select, similar to Google Lens.

Built with Rust, GTK4, and libadwaita.

![License](https://img.shields.io/badge/license-GPL--3.0--or--later-blue)

## Features

- **OCR text extraction** with support for 100+ languages (auto-detects all installed Tesseract language packs)
- **Drag-to-select** — draw a rectangle over the image to copy specific words, like Google Lens
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

- **`rustylens-linux-x86_64.tar.gz`** — standalone binary (requires system GTK4, libadwaita, and Tesseract)
- **`rustylens.flatpak`** — self-contained Flatpak bundle with all 128 language packs included

To install the Flatpak bundle:

```bash
flatpak install --user rustylens.flatpak
```

To install the standalone binary:

```bash
tar xzf rustylens-linux-x86_64.tar.gz
sudo install -Dm755 rustylens /usr/local/bin/rustylens
```

### Build from source

```bash
git clone https://github.com/Pranavk-official/rustylens.git
cd rustylens
cargo build --release
```

The binary is at `target/release/rustylens` (~2 MB).

### Install locally

```bash
cargo install --path .
```

### Build Flatpak locally

```bash
# Install the GNOME SDK (one-time setup):
flatpak install flathub org.gnome.Platform//46 org.gnome.Sdk//46
flatpak install flathub org.freedesktop.Sdk.Extension.rust-stable//24.08

# Build and install:
flatpak-builder --user --install --force-clean build-dir com.example.RustyLens.json
```

## Usage

### GUI mode

```bash
rustylens
```

1. Click **Open Image** to pick an image through your desktop's file chooser.
2. OCR runs automatically — extracted text appears in the panel below the image.
3. **Drag-to-select**: click and drag over the image to draw a selection rectangle. Words inside the rectangle are highlighted and copied to the clipboard on release.
4. Use **Copy All Text** to copy everything at once.
5. Change the OCR language from the dropdown in the header bar. "Auto (all)" uses every installed language pack.

### Screenshot mode

```bash
rustylens --capture
```

Opens an interactive screenshot selection (via the XDG Desktop Portal), then loads the captured image for OCR.

## Project Structure

```
src/
  main.rs     Entry point, CLI flag, application setup
  ui.rs       Window construction, drag-to-select, drawing callbacks
  portal.rs   XDG portal wrappers (file chooser, screenshot), background task helpers
  ocr.rs      Tesseract OCR via leptess, language detection, TSV bbox parsing
```

## How It Works

1. **Image loading** — the file chooser portal returns a `file://` URI, which is percent-decoded to a filesystem path and displayed in a `gtk::Picture` widget.
2. **OCR** — runs on a background thread to avoid blocking the UI. Tesseract processes the image and returns both the full text and per-word bounding boxes (via TSV output).
3. **Bounding boxes** — a transparent `gtk::DrawingArea` overlay renders word rectangles using Cairo, scaled to match the image's "Contain" fit.
4. **Drag-to-select** — a `GestureDrag` handler tracks the selection rectangle. On release, all overlapping words are collected in reading order and copied to the clipboard.
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
