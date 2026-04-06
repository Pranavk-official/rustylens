# Changelog

All notable changes to RustyLens will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.1] - 2026-04-06

### Changed

- Rename app ID from `com.example.RustyLens` to `io.github.pranavk_official.RustyLens` for Flathub compatibility
- Replace drag-to-select rectangle with anchor-based range selection (visual only; Ctrl+C to copy)
- Upgrade Flatpak runtime from GNOME 46 to GNOME 49
- Add LLVM SDK extension to Flatpak manifest to fix `libclang` build error
- Downgrade bundled Tesseract from 5.5.0 to 5.4.1 for build compatibility
- Add `builddir` and `post-install` pkgconfig fixup to leptonica Flatpak module
- Simplify Flatpak cargo build commands
- Update CI release workflow to use `gnome-49` Flatpak image
- Bump Rust edition from 2021 to 2024
- Add `/vendor/` to `.gitignore`

### Added

- Desktop entry file with screenshot capture desktop action
- AppStream metainfo XML for Flathub listing
- SVG app icon
- Flatpak manifest installs desktop file, metainfo, and icon into standard paths
- AppImage build support via linuxdeploy with GTK4 plugin in CI release workflow

## [0.1.0] - 2026-04-06

### Added

- GTK4 + libadwaita GUI with image preview and OCR text panel
- Tesseract OCR integration via leptess with per-word bounding box overlay
- Click/drag on highlighted words to select and copy text to clipboard
- Auto-detection of all installed Tesseract language packs
- Language selector dropdown with "Auto (all)" mode
- Screenshot capture mode via `--capture` flag (XDG Desktop Portal)
- File chooser via XDG FileChooser Portal
- "Copy All Text" button
- Toast notifications for clipboard actions and errors
- Percent-decoding for portal file URIs (handles spaces and special characters)
- Flatpak manifest with bundled leptonica, tesseract, and all tessdata_fast language packs
- CI workflow (build + clippy on push/PR)
- Release workflow: auto-publishes binary + Flatpak bundle on version tags
- Changelog extracted into release notes automatically
- Optimized release profile (strip, LTO, opt-level=s) — ~1.9 MB binary
