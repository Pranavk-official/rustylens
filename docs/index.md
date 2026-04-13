# RustyLens

**Lightweight OCR for the Linux desktop.** &nbsp;·&nbsp; v0.2.1

Open an image or capture a screenshot, and RustyLens extracts the text using Tesseract — with bounding-box overlays and drag-to-select word copying.

Built with Rust, GTK4, and libadwaita.

[![Version](https://img.shields.io/github/v/release/Pranavk-official/rustylens?label=version&color=0078d7)](https://github.com/Pranavk-official/rustylens/releases/latest)
[![License](https://img.shields.io/badge/license-GPL--3.0--or--later-blue)](https://github.com/Pranavk-official/rustylens/blob/main/LICENSE)
[![CI](https://img.shields.io/github/actions/workflow/status/Pranavk-official/rustylens/ci.yml?branch=main&label=CI)](https://github.com/Pranavk-official/rustylens/actions/workflows/ci.yml)
[![Downloads](https://img.shields.io/github/downloads/Pranavk-official/rustylens/total?label=installs&color=brightgreen)](https://github.com/Pranavk-official/rustylens/releases)

---

<div style="display:flex;gap:12px;flex-wrap:wrap;margin:1.5rem 0;">
  <a href="https://github.com/Pranavk-official/rustylens/releases/latest/download/RustyLens-x86_64.AppImage"
     style="display:inline-flex;align-items:center;gap:8px;padding:10px 20px;border-radius:6px;background:var(--md-primary-fg-color);color:var(--md-primary-bg-color);font-weight:600;text-decoration:none;font-size:0.9rem;">
    <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><path d="M12 16l-5-5h3V4h4v7h3l-5 5zm-7 4v-2h14v2H5z"/></svg>
    Download AppImage
  </a>
  <a href="https://github.com/Pranavk-official/rustylens/releases/latest/download/rustylens.flatpak"
     style="display:inline-flex;align-items:center;gap:8px;padding:10px 20px;border-radius:6px;border:2px solid var(--md-primary-fg-color);color:var(--md-primary-fg-color);font-weight:600;text-decoration:none;font-size:0.9rem;">
    <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z"/></svg>
    Download Flatpak
  </a>
</div>

---

## Screenshots

![RustyLens main window — bounding-box OCR overlay](assets/screenshots/main-window.png)

![RustyLens screenshot mode — XDG portal capture](assets/screenshots/screenshot-mode.png)

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

=== "curl"

    ```bash
    curl -fsSL https://pranavk-official.github.io/rustylens/install.sh | bash
    ```

=== "wget"

    ```bash
    wget -qO- https://pranavk-official.github.io/rustylens/install.sh | bash
    ```

Or download and inspect first:

=== "curl"

    ```bash
    curl -fsSL https://pranavk-official.github.io/rustylens/install.sh -o install.sh
    bash install.sh --minimal
    ```

=== "wget"

    ```bash
    wget -O install.sh https://pranavk-official.github.io/rustylens/install.sh
    bash install.sh --minimal
    ```

→ See [Getting Started](getting-started.md) for a step-by-step guide, or [Installation](installation/index.md) for all options.
