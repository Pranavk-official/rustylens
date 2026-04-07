# Installation Overview

RustyLens offers several installation methods. Choose the one that fits your workflow:

| Method | Best for | Notes |
|--------|----------|-------|
| [`install.sh`](install-script.md) | Most Linux users | Auto-detects distro (Arch / Ubuntu / Fedora), downloads distro-native binary |
| [AppImage](releases.md#appimage) | Any distro, no root needed | Portable, bundles all GTK4 libs; use `install.sh -A` |
| [Flatpak](releases.md#flatpak) | Sandboxed install | Includes all 128 language packs; use `install.sh -F` |
| [Build from source](build-from-source.md) | Developers / contributors | Requires Rust toolchain |

---

## Quick decision guide

**I want the simplest install:**
→ Use `install.sh --minimal`. It auto-detects your distro and installs a native binary.

**My distro is not Arch, Ubuntu/Debian, or Fedora:**
→ Use `install.sh -A --minimal`. The AppImage bundles all libraries and runs on any glibc-based distro.

**I want full sandboxing (Flatpak):**
→ Use `install.sh -F`. This installs the Flatpak bundle directly from GitHub Releases. All 128 Tesseract language packs are included.

**I want to contribute or build custom:**
→ Follow the [Build from Source](build-from-source.md) guide.

---

## System requirements

- **OS:** Linux x86_64
- **Display:** Wayland or X11 with GTK4 support
- **Native binary:** glibc 2.38+, GTK 4.12+, libadwaita 1.5+, leptonica, libtesseract
- **AppImage / Flatpak:** no system OCR libraries needed (all bundled)

!!! note "macOS and Windows"
    Experimental macOS and Windows builds are published in releases but are not the primary focus. See the [Releases page](releases.md) for download links.
