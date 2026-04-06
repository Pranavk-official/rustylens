# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

RustyLens — lightweight Linux desktop app for image preview and OCR text extraction. Rust 2024 edition + GTK4 + libadwaita. Two modes: `--capture` (portal screenshot → OCR) and windowed GUI (file chooser → image preview + drag-to-select OCR + Ctrl+C to copy).

**Application ID:** `io.github.pranavk_official.RustyLens`

## Build & Run

```bash
cargo build                          # Dev build
cargo build --release                # Release build (~2 MB)
./target/debug/rustylens             # GUI mode
./target/debug/rustylens --capture   # Screenshot + OCR mode
```

System deps (Arch): `sudo pacman -S clang leptonica tesseract tesseract-data-eng`
System deps (Debian/Ubuntu): `sudo apt install clang libleptonica-dev libtesseract-dev tesseract-ocr-eng`

### Flatpak (local)

```bash
flatpak-builder --user --install --force-clean build-dir io.github.pranavk_official.RustyLens.json
```

No test suite yet. When adding tests, prefer integration tests in `tests/` for portal/UI logic and unit tests for pure functions (e.g., `parse_tsv_words`).

## Architecture

- `src/main.rs` — entry point, CLI flag, app setup
- `src/ui.rs` — `AppState`, window construction, word selection, drawing callbacks
- `src/portal.rs` — shared tokio runtime, `spawn_background`/`spawn_portal`, XDG portal wrappers, `uri_to_path`
- `src/ocr.rs` — `OcrResult`/`OcrWord` types, `ocr_file`, `installed_languages`, TSV parsing
- `data/` — desktop entry (with `--capture` action), AppStream metainfo XML, SVG icon
- `io.github.pranavk_official.RustyLens.json` — Flatpak manifest

## Key Patterns

### Async: GLib + background threads

GTK runs a GLib main loop. **Never block the GLib main loop.**

- **Portal calls** (ashpd/zbus require Tokio): use `spawn_portal()` — runs async work on a shared persistent `tokio::runtime` (via `OnceLock`), sends results back via `std::sync::mpsc`, polled with `glib::timeout_add_local` at 16ms.
- **Blocking OCR** (leptess): use `spawn_background()` — runs on a `std::thread`, same channel + timer pattern.

The shared runtime is critical — zbus caches D-Bus connections, so creating a new runtime per call breaks subsequent portal requests.

Both patterns keep non-`Send` types (`Rc<RefCell<T>>`, GTK widgets) on the main thread only.

### OCR via leptess

- `ocr_file(path, lang)` accepts a Tesseract language string (e.g. `"eng"`, `"eng+jpn"`)
- `installed_languages()` scans tessdata directories for `.traineddata` files
- `LepTess: Send` — safe to move into `std::thread::spawn`
- `set_source_resolution(70)` suppresses Tesseract's "Invalid resolution 0 dpi" warning
- TSV parsing: `splitn(12, '\t')`, filters level 5 (word-level) with conf >= 0, columns 6–9 for bbox

### Widget state in closures

`AppState` (GTK widget refs + `Rc<RefCell<..>>`) is cheaply cloned into closures. Use `widget.downgrade()` + `.upgrade()` only to break ownership cycles with the window.

### Word selection

`GestureDrag` on the `DrawingArea` implements anchor-based range selection. On press, `word_index_at` finds the word under the cursor and sets it as the anchor. During drag, all words between anchor and current index are selected (contiguous range via `BTreeSet`). Selection is visual only — `Ctrl+C` (via `gtk::ShortcutController` on the window) copies selected words in reading order. `draw_ocr_boxes` highlights selected words with stronger opacity. The `ImageTransform` struct (scale + offset) is shared between drawing and hit-testing.

### Portal URIs vs file paths

ashpd returns `ashpd::Uri` (a string wrapper). `uri_to_path()` strips `file://` and percent-decodes (e.g. `%20` → space).

## Flatpak

Manifest: `io.github.pranavk_official.RustyLens.json` (GNOME Platform 49, Rust + LLVM20 SDK extensions). Bundles leptonica, tesseract, and tessdata_fast.

- `LIBCLANG_PATH` and LLVM extension are required for `bindgen` (used by `leptonica-sys`)
- `LIBRARY_PATH=/app/lib` is set on the rustylens module so the Rust linker finds leptonica/tesseract
- `post-install` on leptonica copies `lept_Release.pc` → `lept.pc` for pkg-config discovery
- When adding new portal features, add the corresponding `--talk-name` to `finish-args`

## CI

- **ci.yml**: Build + clippy on push/PR (Ubuntu)
- **release.yml**: On `v*` tags, builds three artifacts: standalone binary (.tar.gz), Flatpak bundle (.flatpak via gnome-49 container), and AppImage (via linuxdeploy + GTK4 plugin on Arch container). Changelog section for the tag version is extracted into release notes.
