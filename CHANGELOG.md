# Changelog

All notable changes to RustyLens will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.0] - 2026-04-07

### Added

- `install.sh` now auto-detects the distro family (Arch/Garuda/Manjaro, Ubuntu/Debian,
  Fedora/RHEL/Rocky, …) and downloads the matching distro-native binary tarball from
  GitHub releases, eliminating shared-library ABI mismatches (e.g. `liblept.so.5` vs
  `liblept.so.6` between Ubuntu and Arch). Falls back to the AppImage automatically on
  unknown distros (Alpine, Void, openSUSE, etc.) or when no distro-specific asset exists.
- Release workflow now produces three distro-native Linux binary tarballs:
  - `rustylens-linux-x86_64-ubuntu.tar.gz` — built on ubuntu-24.04 (leptonica 1.82)
  - `rustylens-linux-x86_64-arch.tar.gz`   — built in archlinux container (leptonica 1.84+)
  - `rustylens-linux-x86_64-fedora.tar.gz` — built in fedora container
  The generic `rustylens-linux-x86_64.tar.gz` (same as ubuntu build) is kept for
  backward compatibility with older `install.sh` versions.
- `install.sh --update`: fetch the latest release from GitHub and replace the
  installed binary in-place; re-downloads the same format (binary or AppImage)
  that was originally installed; optionally updates Tesseract language packs when
  `--langs` flags are passed alongside `--update`.
- `install.sh --appimage`: opt-in flag to install/update as an AppImage instead
  of the default standalone binary tarball.
- `install.sh --local PATH`: install from a local file (binary or AppImage) instead
  of downloading from GitHub; usable with `--update` for offline upgrades.
- OCR language dropdown now shows human-readable names (e.g. "English", "Japanese",
  "Chinese (Simplified)") instead of raw Tesseract language codes (`eng`, `jpn`,
  `chi_sim`). New `lang_display_name()` function in `ocr.rs` covers all ~100 standard
  Tesseract language codes.
- MkDocs Material documentation site (`docs/`) with full user-facing content:
  getting-started guide, installation options (install script, releases, build from
  source), usage guides (GUI, screenshot capture, language selection), CLI reference,
  architecture and project-structure reference, and contributing guide.
- `docs.yml` GitHub Actions workflow: builds and deploys the documentation site to
  GitHub Pages on every push to `main` that touches `docs/**`, `mkdocs.yml`, or
  `CHANGELOG.md`.

### Changed

- `install.sh` default behaviour changed: the script now auto-detects the distro and
  downloads the appropriate native binary tarball from GitHub releases. Pass `--appimage`
  to force AppImage install on any distro.
- Install method is persisted as `binary-ubuntu`, `binary-arch`, `binary-fedora`, or
  `appimage` to `$PREFIX/share/rustylens/.install_method` so that `--update` re-downloads
  the correct distro tarball. Old stored value `"binary"` is treated as `binary-ubuntu`.
- File chooser migrated from `ashpd` FileChooser portal (`portal::pick_file()`) to
  GTK4's native `gtk::FileDialog` API; GTK4 transparently invokes the portal when
  running inside a Flatpak sandbox, removing the manual async portal plumbing from
  `portal.rs`.

### Fixed

- `liblept.so: cannot open shared object file` error on Arch Linux / Garuda / Manjaro
  and other distros that ship a different leptonica ABI than the ubuntu build runner.
  Each distro family now gets a binary linked against its own leptonica version.

## [0.1.9] - 2026-04-07

### Fixed

- CI: switch Linux `build` job from `ubuntu-latest` to `ubuntu-24.04` — Ubuntu 22.04 ships
  GTK 4.6 which is incompatible with the `v4_12` feature flag; Ubuntu 24.04 has GTK 4.14.
- CI: add `components: clippy` to `dtolnay/rust-toolchain@stable` so clippy is installed.
- CI: mark `check-macos` and `check-windows` jobs as `continue-on-error: true` so a
  platform-specific failure does not block the overall CI status.
- macOS CI: fix `tokio::runtime::Builder::new_multi_thread()` → `new_current_thread()` —
  the `rt-multi-thread` feature is not enabled.
- Windows CI: set `LEPTONICA_*` and `TESSERACT_*` env vars so `leptonica-sys`/`tesseract-sys`
  bypass their vcpkg (MSVC-only) code path and use MSYS2/MINGW64 libraries instead.
- Windows release: propagate the same `LEPTONICA_*` and `TESSERACT_*` env vars to the
  `windows` release build step (the CI fix was not applied to the release workflow).

## [0.1.8] - 2026-04-07

### Added

- macOS support: file chooser uses native NSOpenPanel via `rfd`; screenshot uses `screencapture -i`.
- Windows support: file chooser uses native IFileDialog via `rfd`.
- `ashpd` (XDG Desktop Portal) is now a Linux-only dependency; `rfd` is used on macOS and Windows.
- GitHub Actions CI now checks compilation on macOS (`check-macos`) and Windows (`check-windows`) on every push.
- Release workflow now publishes a macOS DMG (`RustyLens-<arch>-apple-darwin.dmg`) and
  a Windows zip (`rustylens-windows-x86_64.zip`) alongside the existing Linux artifacts.

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
