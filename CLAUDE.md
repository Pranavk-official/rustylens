# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

RustyLens — lightweight Linux desktop app for image preview and OCR text extraction. Rust + GTK4 + libadwaita. Two modes: `--capture` (portal screenshot → OCR) and windowed GUI (file chooser → image preview + drag-to-select OCR).

**Application ID:** `com.example.RustyLens`

## Build & Run

```bash
cargo build                          # Dev build
cargo build --release                # Release build (~2 MB)
./target/debug/rustylens             # GUI mode
./target/debug/rustylens --capture   # Screenshot + OCR mode
```

System deps (Arch): `sudo pacman -S clang leptonica tesseract tesseract-data-eng`
System deps (Debian/Ubuntu): `sudo apt install clang libleptonica-dev libtesseract-dev tesseract-ocr-eng`

No test suite yet. When adding tests, prefer integration tests in `tests/` for portal/UI logic and unit tests for pure functions (e.g., `parse_tsv_words`).

## Architecture

```
src/
  main.rs     — entry point, CLI flag, app setup
  ui.rs       — AppState, window construction, drag-to-select, drawing callbacks
  portal.rs   — shared tokio runtime, spawn_background/spawn_portal, XDG portal wrappers, uri_to_path
  ocr.rs      — OcrResult/OcrWord types, ocr_file, installed_languages, TSV parsing
```

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

### Widget state in closures

`AppState` (GTK widget refs + `Rc<RefCell<..>>`) is cheaply cloned into closures. Use `widget.downgrade()` + `.upgrade()` only to break ownership cycles with the window.

### Drag-to-select

`GestureDrag` on the `DrawingArea` tracks a selection rectangle. `draw_ocr_boxes` highlights words overlapping the drag. On release, `words_in_drag` collects word text in reading order and copies to clipboard. The `ImageTransform` struct (scale + offset) is shared between drawing and hit-testing.

### Portal URIs vs file paths

ashpd returns `ashpd::Uri` (a string wrapper). `uri_to_path()` strips `file://` and percent-decodes (e.g. `%20` → space).

## Flatpak

Manifest: `com.example.RustyLens.json` (GNOME Platform 46, Rust SDK extension). When adding new portal features, add the corresponding `--talk-name` to `finish-args`.
