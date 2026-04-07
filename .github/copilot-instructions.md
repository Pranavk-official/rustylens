# RustyLens — Project Guidelines

> For deep documentation, see [CLAUDE.md](../CLAUDE.md).

## Overview

Lightweight Linux desktop app for image preview and OCR text extraction. Rust 2024 edition + GTK4 + libadwaita. Two modes: `--capture` (XDG portal screenshot → OCR) and windowed GUI (file chooser → image preview + drag-to-select OCR).

**Application ID:** `io.github.pranavk_official.RustyLens`

## Build and Test

```bash
cargo build                          # Dev build
cargo build --release                # Release build
./target/debug/rustylens             # GUI mode
./target/debug/rustylens --capture   # Screenshot + OCR mode
```

System deps (Debian/Ubuntu): `sudo apt install clang libleptonica-dev libtesseract-dev tesseract-ocr-eng`
System deps (Arch): `sudo pacman -S clang leptonica tesseract tesseract-data-eng`

No test suite yet. When adding tests: integration tests in `tests/` for portal/UI logic; unit tests for pure functions (e.g. `parse_tsv_words`).

## Architecture

| Module | Responsibility |
|--------|---------------|
| `src/main.rs` | Entry point, `--capture` flag, app setup |
| `src/ui.rs` | `AppState`, window construction, word selection, draw callbacks |
| `src/portal.rs` | Shared tokio runtime, `spawn_background`/`spawn_portal`, XDG portal wrappers, `uri_to_path` |
| `src/ocr.rs` | `OcrResult`/`OcrWord` types, `ocr_file`, `installed_languages`, TSV parsing |

## Key Types

```rust
struct OcrWord { x: i32, y: i32, w: i32, h: i32, text: String }  // image-coordinate bbox
struct OcrResult { full_text: String, words: Vec<OcrWord>, img_w: u32, img_h: u32 }

#[derive(Clone)]
struct AppState {
    picture: gtk::Picture,
    drawing_area: gtk::DrawingArea,
    text_buffer: gtk::TextBuffer,
    copy_btn: gtk::Button,
    toast_overlay: adw::ToastOverlay,
    lang_dropdown: gtk::DropDown,
    ocr_result: Rc<RefCell<Option<OcrResult>>>,
    selected_words: Rc<RefCell<BTreeSet<usize>>>,
    anchor_index: Rc<RefCell<Option<usize>>>,
}
```

## Conventions

### Async: GLib ↔ background threads

**Never block the GLib main loop.** Always use the helpers in `portal.rs`:

- **`spawn_portal(future_fn, callback)`** — runs an async closure on the shared persistent `tokio::runtime` (stored in `OnceLock`). Required for ashpd/zbus portal calls — zbus caches D-Bus connections, so creating a new runtime per call breaks subsequent requests.
- **`spawn_background(work, callback)`** — runs a blocking closure on `std::thread`. Use for leptess OCR.

Both helpers send results back via `std::sync::mpsc`, polled with `glib::timeout_add_local` at 16 ms. The `callback` closure is non-`Send` and runs on the main thread, so `Rc<RefCell<T>>` is safe to capture there.

**Do not** use `glib::MainContext::spawn_local` or create new `tokio::Runtime` instances directly.

### Widget state in closures

`AppState` is cheaply cloned into closures (all fields are GObject refs or `Rc`). Use `widget.downgrade()` + `.upgrade()` only to break ownership cycles with the window.

### Error handling

- `ocr_file()` returns `Result<OcrResult, String>` — errors are shown in the `TextView`
- Log unexpected errors to stderr via `eprintln!()`; no UI error dialogs

### Portal URIs vs file paths

`uri_to_path()` in `portal.rs` strips `file://` and percent-decodes (e.g. `%20` → space). Always use it when converting ashpd URIs to POSIX paths.

## Flatpak

Manifest: `io.github.pranavk_official.RustyLens.json` (GNOME Platform 49, Rust + LLVM20 SDK extensions). Bundles leptonica, tesseract, and tessdata_fast. No `--share=network`.

When adding portal features, do **not** add explicit `--talk-name=org.freedesktop.portal.*` to `finish-args` — Flathub forbids this. Portals work automatically via `--socket=wayland`/`--device=dri`. See [CLAUDE.md](../CLAUDE.md) for Flatpak build details and bindgen/pkg-config notes.

## Release Checklist

### Patch / Minor Release
- [ ] Bump version in `Cargo.toml`
- [ ] Update `CHANGELOG.md` and `docs/changelog.md` with new entry
- [ ] Update version references in `docs/index.md`
- [ ] Update `data/io.github.pranavk_official.RustyLens.metainfo.xml` — add `<release>` entry
- [ ] Commit, tag (`git tag v0.x.y`), push tag → triggers CI release workflow

### Flathub Submission (first time)
- [ ] Screenshots committed and pushed to `main` (`data/screenshots/*.png`)
- [ ] Run lint: `flatpak run --command=flatpak-builder-lint org.flatpak.Builder manifest io.github.pranavk_official.RustyLens.json`
- [ ] Run lint: `flatpak run --command=flatpak-builder-lint org.flatpak.Builder appstream data/io.github.pranavk_official.RustyLens.metainfo.xml`
- [ ] Fork https://github.com/flathub/flathub
- [ ] Create branch `new-pr/io.github.pranavk_official.RustyLens`
- [ ] Add `io.github.pranavk_official.RustyLens.json` + `cargo-sources.json` to the branch
- [ ] Submit PR to `flathub/flathub`

### Flathub Update (subsequent releases)
- [ ] Bump version in `Cargo.toml` and tag the release (`git tag v0.x.y && git push --tags`)
- [ ] Update `tag` + `commit` SHA in manifest (`rustylens` module source) to the new tag
- [ ] Regenerate `cargo-sources.json` if `Cargo.lock` changed: `uvx flatpak-cargo-generator ./Cargo.lock -o cargo-sources.json`
- [ ] Add `<release>` entry to `data/io.github.pranavk_official.RustyLens.metainfo.xml`
- [ ] Run lint: `flatpak run --command=flatpak-builder-lint org.flatpak.Builder manifest io.github.pranavk_official.RustyLens.json`
- [ ] Run lint: `flatpak run --command=flatpak-builder-lint org.flatpak.Builder appstream data/io.github.pranavk_official.RustyLens.metainfo.xml`
- [ ] PR to your Flathub fork's `master` branch
