# Changelog

All notable changes to RustyLens will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.7] - 2026-04-07

### Added

- `install.sh` — cross-distro installer for the AppImage and Tesseract language packs.
  Supports: Arch (pacman), Debian/Ubuntu (apt), Fedora/RHEL (dnf), openSUSE (zypper),
  Alpine (apk), Void Linux (xbps-install); falls back to direct tessdata download on
  unknown distros.
  Language group flags: `--minimal`, `--european`, `--asian`, `--cyrillic`, `--arabic`,
  `--indic`, `--full`, `--langs "<codes>"`, `--no-langs`.
  Additional flags: `--prefix`, `--appimage`, `--no-desktop`, `--download`, `--yes`, `--uninstall`.
  Non-interactive / CI mode via `NONINTERACTIVE=1` or `CI=true` env vars.
- `build-appimage.sh` — cross-distro AppImage builder using a two-pass linuxdeploy
  strategy (deploy-only pass, purge host-specific libs, manual mksquashfs + ELF runtime
  assembly). Auto-downloads linuxdeploy if not present. Flags: `--skip-build`,
  `--install`, `--clean`.
- `Makefile` — common developer tasks: `make build`, `make run`, `make appimage`,
  `make install`, `make install-langs`, `make test-docker`, `make clean`, `make release`.

### Fixed

- AppImage: exclude `libwayland-*`, `libvulkan`, `libGL*`, `libEGL`, `libdrm`,
  `libdbus-1`, `libsystemd`, `libudev`, `libXau`, `libXdmcp`, `libxcb*` from the
  bundle — bundling these caused segfaults because they must come from the host.

## [0.1.6] - 2026-04-07

### Fixed

- Fix Flatpak CI: vendor Rust dependencies before `flatpak-builder` invocation so crates are available offline during the build
- Add `--check crates.io` diagnostic step to surface DNS/network issues earlier in the Flatpak job

### Changed

- Refactor nested `if let` chains in `portal.rs` and `ui.rs` to Rust 2024 `let`-chain syntax for cleaner control flow
- Add `*.logs.txt` to `.gitignore`

## [0.1.5] - 2026-04-06

### Fixed

- Fix Flatpak CI: remove `--offline` and vendored-sources cargo config — `vendor/` is gitignored and absent in CI checkout; allow flatpak-builder to fetch crates online
- Fix AppImage CI: remove redundant `mv *.AppImage` rename step — linuxdeploy already creates the output as `RustyLens-x86_64.AppImage`; the previous guard (`if [ ! -f ... ]`) did not prevent the exit-1 error reliably

## [0.1.3] - 2026-04-06

### Fixed

- Fix Flatpak CI: use `ghcr.io/flathub-infra/flatpak-github-actions:gnome-49` (old Docker Hub image removed)
- Fix AppImage CI: add `NO_STRIP=1` to skip linuxdeploy's bundled strip that fails on Arch's `.relr.dyn` ELF sections

## [0.1.2] - 2026-04-06

### Fixed

- Fix CI build: remove `.cargo/config.toml` that forced vendored sources (vendor dir is gitignored, breaking CI)
- Generate cargo vendor config at Flatpak build time instead of committing it

### Changed

- Add `/.cargo/` to `.gitignore`

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
