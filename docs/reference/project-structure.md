# Project Structure

```
rustylens/
├── src/
│   ├── main.rs               Entry point, CLI flag, GTK application setup
│   ├── ui.rs                 Window construction, gtk::FileDialog file chooser, word selection, drawing callbacks
│   ├── portal.rs             XDG Screenshot Portal, shared Tokio runtime, background task helpers, uri_to_path
│   └── ocr.rs                Tesseract OCR via leptess, lang_display_name, installed_languages, TSV parsing
│
├── data/
│   ├── icons/hicolor/scalable/apps/
│   │   └── io.github.pranavk_official.RustyLens.svg   App icon
│   ├── io.github.pranavk_official.RustyLens.desktop   Desktop entry (with --capture action)
│   └── io.github.pranavk_official.RustyLens.metainfo.xml   AppStream metadata
│
├── docs/                     MkDocs documentation source (this site)
│
├── .github/
│   └── workflows/
│       ├── ci.yml            Build + clippy on push/PR
│       ├── release.yml       Publish binary, Flatpak, AppImage on version tags
│       └── docs.yml          Deploy MkDocs to GitHub Pages
│
├── build-appimage.sh         Local AppImage builder (two-pass linuxdeploy + mksquashfs)
├── install.sh                Cross-distro installer: binary, AppImage, Flatpak, tessdata
├── Makefile                  Developer task shortcuts
├── Cargo.toml
├── Cargo.lock
├── CHANGELOG.md
├── mkdocs.yml                MkDocs configuration
└── io.github.pranavk_official.RustyLens.json   Flatpak manifest
```

---

## Key files

### `src/ocr.rs`

Defines the core OCR types:

```rust
struct OcrWord { x: i32, y: i32, w: i32, h: i32, text: String }
struct OcrResult { full_text: String, words: Vec<OcrWord>, img_w: u32, img_h: u32 }
```

`ocr_file(path, lang)` returns `Result<OcrResult, String>`.

`lang_display_name(code)` maps Tesseract codes to human-readable names (e.g. `"jpn"` → `"Japanese"`).

### `src/ui.rs`

Owns `AppState` — a cheaply-cloneable struct of GTK widget handles and `Rc<RefCell<T>>` state, shared into closures. Uses `gtk::FileDialog` for the native file chooser (GTK4 transparently invokes the XDG portal when inside a Flatpak).

### `src/portal.rs`

Exports `spawn_portal`, `spawn_background`, `request_screenshot`, and `uri_to_path`. The `pick_file` portal function was removed in v0.2.0 in favour of `gtk::FileDialog`. See [Architecture](architecture.md) for details.
