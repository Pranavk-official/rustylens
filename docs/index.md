# RustyLens

**Lightweight OCR for the Linux desktop.** &nbsp;·&nbsp; v0.2.1

Open an image or capture a screenshot, and RustyLens extracts the text using Tesseract — with bounding-box overlays and drag-to-select word copying.

Built with Rust, GTK4, and libadwaita.

[![Version](https://img.shields.io/github/v/release/Pranavk-official/rustylens?label=version&color=0078d7)](https://github.com/Pranavk-official/rustylens/releases/latest)
[![License](https://img.shields.io/badge/license-GPL--3.0--or--later-blue)](https://github.com/Pranavk-official/rustylens/blob/main/LICENSE)
[![CI](https://img.shields.io/github/actions/workflow/status/Pranavk-official/rustylens/ci.yml?branch=main&label=CI)](https://github.com/Pranavk-official/rustylens/actions/workflows/ci.yml)
[![Downloads](https://img.shields.io/github/downloads/Pranavk-official/rustylens/total?label=installs&color=brightgreen)](https://github.com/Pranavk-official/rustylens/releases)

---

## Demo

<video controls width="100%" style="border-radius:6px;max-height:480px;">
  <source src="demo/demo.mp4" type="video/mp4">
  <p>Your browser does not support the video element.
  <a href="demo/demo.mp4">Download the demo video</a>.</p>
</video>

---

## Features

- **OCR text extraction** — supports 100+ languages via Tesseract; auto-detects all installed language packs
- **Human-readable language selector** — dropdown shows full language names ("English", "Japanese", "Chinese (Simplified)") instead of raw codes
- **Drag-to-select** — click or drag across highlighted words to select them, then ++ctrl+c++ to copy
- **Bounding-box overlay** — recognised words are highlighted directly on the image preview
- **Screenshot mode** — `rustylens --capture` grabs a screenshot via the XDG portal and runs OCR immediately
- **Copy all text** — one-click button to copy everything extracted
- **Distro-native binaries** — `install.sh` auto-detects Arch, Ubuntu/Debian, or Fedora and downloads the matching binary, eliminating library ABI mismatches
- **Flatpak-ready** — fully sandboxed with portal-based screenshot integration

---

## Install in one line

```bash
curl -fsSL https://raw.githubusercontent.com/Pranavk-official/rustylens/main/install.sh | bash
```

Or download and inspect first:

```bash
curl -fsSL https://raw.githubusercontent.com/Pranavk-official/rustylens/main/install.sh -o install.sh
bash install.sh --minimal
```

→ See [Getting Started](getting-started.md) for a step-by-step guide, or [Installation](installation/index.md) for all options.
