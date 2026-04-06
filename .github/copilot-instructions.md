# RustyLens — Project Guidelines

## Overview

Lightweight Linux desktop app for image preview and OCR text extraction. Rust + GTK4 + libadwaita, packaged as a Flatpak. Single-binary, two modes: headless `--capture` (screenshot portal → OCR → display) and windowed GUI (file chooser → image preview + OCR).

## Build and Test

```bash
cargo build                          # Dev build
cargo build --release                # Release build
./target/debug/rustylens             # GUI mode
./target/debug/rustylens --capture   # Screenshot + OCR mode
```

System build/runtime deps: `sudo apt install clang libleptonica-dev libtesseract-dev tesseract-ocr-eng`

No test suite exists yet. When adding tests, prefer integration tests in `tests/` for portal/UI logic and unit tests for pure functions (e.g., `parse_tsv_words`).

## Architecture

Currently a single-file app (`src/main.rs`). When splitting into modules, use this layout:

| Module | Responsibility |
|--------|---------------|
| `cli.rs` | clap argument parsing |
| `ui.rs` | Window construction, widget setup |
| `portal.rs` | ashpd screenshot/file-chooser wrappers |
| `ocr.rs` | leptess/Tesseract OCR wrappers |

**Application ID:** `io.github.pranavk_official.RustyLens`

## Key Types

```rust
struct OcrWord { x: i32, y: i32, w: i32, h: i32 }   // image-coordinate bbox
struct OcrResult { full_text: String, words: Vec<OcrWord>, img_w: u32, img_h: u32 }

#[derive(Clone)]
struct AppState {
    picture: gtk::Picture,           // image preview
    drawing_area: gtk::DrawingArea,  // transparent OCR overlay
    text_buffer: gtk::TextBuffer,    // extracted text
    copy_btn: gtk::Button,
    toast_overlay: adw::ToastOverlay,
    ocr_result: Rc<RefCell<Option<OcrResult>>>,  // shared, not Send
}
```

## Conventions

### Async: GLib ↔ background thread

GTK runs a GLib main loop. **Never block the GLib main loop.**

- **Portal calls** (ashpd): use `glib::MainContext::default().spawn_local(async { ... })`
- **Blocking OCR** (leptess): spawn with `std::thread::spawn`, send results back via `glib::MainContext::channel()`. The `Receiver::attach` callback does **not** require `Send`, so `Rc<RefCell<T>>` can be captured safely.

No tokio runtime is needed — `reqwest` and `tokio` are not dependencies.

### OCR pipeline

- `leptess::LepTess::new(None, "eng")` → init engine
- `lt.set_image(path)` → load image (accepts `&str` or `&Path`)
- `lt.set_source_resolution(70)` → suppress "Invalid resolution" warning
- `lt.get_utf8_text()` → full extracted text (String)
- `lt.get_tsv_text(0)` → TSV with word bboxes; parse with `parse_tsv_words()`
- `lt.get_image_dimensions()` → `Option<(u32, u32)>` original pixel size
- `LepTess: Send` — safe to move into `std::thread::spawn`

TSV word format (level == 5, conf >= 0): `left top width height` in columns 6–9.

### Overlay geometry (Contain fit)

```rust
let scale = (widget_w / img_w).min(widget_h / img_h);
let off_x = (widget_w - img_w * scale) / 2.0;
let off_y = (widget_h - img_h * scale) / 2.0;
// per word: draw_x = off_x + word.x * scale, etc.
```

### Widget state in closures

`AppState` is cheaply cloned (all fields are GObject refs or Rc). Pass `state.clone()` into closures. For cross-thread access use `glib::MainContext::channel` (not `Rc`). Use `widget.downgrade()` + `.upgrade()` only when necessary to break ownership cycles.

### Error handling

- Return `Box<dyn std::error::Error>` from async portal helpers
- `ocr_file()` returns `Result<OcrResult, String>` — string errors are shown in the TextView
- Log unexpected errors to stderr via `eprintln!()`

### Portal URIs vs. file paths

ashpd portals return `url::Url` values. Call `.to_string()` to get `file:///path/...`, then `uri_to_path()` (strips `file://`) to get the POSIX path.

## Flatpak

Manifest: `io.github.pranavk_official.RustyLens.json` (GNOME Platform 46, Rust SDK extension). No `--share=network` — the app is fully local.

Required D-Bus permissions for portals:
- `org.freedesktop.portal.Desktop`
- `org.freedesktop.portal.Screenshot`
- `org.freedesktop.portal.FileChooser`

When adding new portal features, add the corresponding `--talk-name` to `finish-args`.

## Incomplete Features

- Per-word text selection by clicking a bounding box
- Toast notifications for file-chooser errors

## Build and Test

```bash
cargo build                          # Dev build
cargo build --release                # Release build
./target/debug/rustylens             # GUI mode
./target/debug/rustylens --capture   # Headless screenshot mode
```

No test suite exists yet. When adding tests, prefer integration tests in `tests/` for portal/UI logic and unit tests for pure functions.

## Architecture

Currently a single-file app (`src/main.rs`). When splitting into modules, use this layout:

| Module | Responsibility |
|--------|---------------|
| `cli.rs` | clap argument parsing |
| `ui.rs` | Window construction, widget setup |
| `portal.rs` | ashpd screenshot/file-chooser wrappers |
| `upload.rs` | reqwest HTTP upload logic |

**Application ID:** `io.github.pranavk_official.RustyLens`

## Conventions

### Async: GLib ↔ Tokio bridging

This is the most critical pattern in the codebase. GTK runs a GLib main loop; Tokio has its own runtime. **Never block the GLib main loop.**

- **Portal calls** (ashpd): use `gtk::glib::MainContext::default().spawn_local(async { ... })`
- **Blocking network I/O** (reqwest/tokio): spawn a dedicated thread with `std::thread::spawn`, create a `tokio::runtime::Builder::new_current_thread()` inside, and send results back via `gtk::glib::MainContext::channel()`

### Widget state in closures

Use `widget.downgrade()` + `.upgrade()` to avoid prevent circular references. Mutable shared state uses `RefCell<T>` or `Rc<RefCell<T>>`.

### Error handling

- Return `Box<dyn std::error::Error>` from async helpers
- Log to stderr via `eprintln!()` — no UI error dialogs yet
- Portal/file functions return `Option` for user-cancellable operations

### Portal URIs vs. file paths

ashpd portals return `file://` URIs. Functions accepting file locations should document whether they expect a URI or a POSIX path. Use `.strip_prefix("file://")` when converting.

## Flatpak

Manifest: `io.github.pranavk_official.RustyLens.json` (GNOME Platform 46, Rust SDK extension).

Required D-Bus permissions for portals:
- `org.freedesktop.portal.Desktop`
- `org.freedesktop.portal.Screenshot`
- `org.freedesktop.portal.FileChooser`

When adding new portal features, add the corresponding `--talk-name` to `finish-args`.

## Incomplete Features

- `paste_image_from_clipboard()` — placeholder, returns `Ok(None)`
- `do_upload()` — placeholder, no real endpoint configured
- No toast notifications or UI error feedback
