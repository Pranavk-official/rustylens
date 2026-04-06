# Changelog

All notable changes to RustyLens will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
