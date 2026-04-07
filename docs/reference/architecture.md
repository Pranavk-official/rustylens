# Architecture

This page explains how RustyLens is structured internally and why key design decisions were made.

---

## Module overview

| Module | Responsibility |
|--------|---------------|
| `src/main.rs` | Entry point, `--capture` flag detection, GTK application setup |
| `src/ui.rs` | `AppState`, window construction, `gtk::FileDialog` file chooser, word selection, Cairo draw callbacks |
| `src/portal.rs` | Shared Tokio runtime, `spawn_background` / `spawn_portal`, XDG Screenshot Portal, `uri_to_path` |
| `src/ocr.rs` | `OcrResult` / `OcrWord` types, `ocr_file`, `lang_display_name`, `installed_languages`, TSV parsing |

---

## Data flow

```
User selects image (gtk::FileDialog)
        │
        │  GTK4's native file chooser; uses XDG portal
        │  automatically when inside a Flatpak sandbox.
        ▼
  load_image_path()
        │
        ├─► gtk::Picture  (displays image in UI)
        │
        └─► spawn_background(ocr_file)  ──► background thread (leptess)
                                                │
                                          OcrResult { full_text, words, img_w, img_h }
                                                │
                                          glib::timeout_add_local (16 ms poll)
                                                │
                                          main thread: update TextBuffer + DrawingArea
```

---

## GLib ↔ background thread pattern

GTK requires that all widget access happen on the GLib main thread. RustyLens uses two bridge helpers:

**`spawn_background(work, callback)`** — for blocking CPU work (OCR):

- Runs `work` on a `std::thread`. `LepTess` is `Send`, so it can be moved in.
- Sends the result back via `std::sync::mpsc`.
- A `glib::timeout_add_local` timer polls the channel every 16 ms.
- The `callback` runs on the main thread, so `Rc<RefCell<T>>` and GTK widgets are safe to capture.

**`spawn_portal(future_fn, callback)`** — for async portal / D-Bus calls (ashpd/zbus):

- Runs the async closure on a **shared persistent `tokio::Runtime`** (stored in `OnceLock`).
- zbus caches D-Bus connections to the runtime. Creating a new runtime per call loses the cached connection, causing subsequent portal requests to fail.
- Same `mpsc` + `timeout_add_local` pattern for results.

**Do not** use `glib::MainContext::spawn_local` for async portal calls, or create new `tokio::Runtime` instances directly.

---

## OCR pipeline

1. `ocr_file(path, lang)` creates a `LepTess` instance pointing at the image file.
2. `set_source_resolution(70)` suppresses Tesseract's "Invalid resolution 0 dpi" warning.
3. `get_tsv_text()` returns tab-separated output. Level 5 rows are word-level; columns 6–9 are the bounding box (x, y, w, h in image coordinates).
4. `parse_tsv_words` parses the TSV and returns `Vec<OcrWord>`.
5. `OcrResult` bundles `full_text`, `words`, and the source image dimensions (`img_w`, `img_h`).

---

## Language display names

`lang_display_name(code)` in `ocr.rs` maps every Tesseract language code to a human-readable string (e.g. `"jpn"` → `"Japanese"`, `"chi_sim"` → `"Chinese (Simplified)"`). It covers all ~100 standard codes and falls back to the raw code for any unknown value.

The language dropdown in `ui.rs` maintains two parallel lists:

- `lang_list` — raw Tesseract codes passed to `ocr_file()`
- `lang_display` — human-readable names shown in the UI, built by mapping `lang_list` through `lang_display_name()`

Index 0 in both lists is the "Auto (all)" option (empty code = join all installed codes with `+`).

---

## Word selection and drawing

A `GestureDrag` on the `DrawingArea` implements anchor-based range selection:

- **Press:** `word_index_at` finds the word under the cursor and sets it as the range anchor.
- **Drag update:** all words between the anchor index and the current pointer position are added to `selected_words` (a `BTreeSet<usize>`).
- **Release:** selection is finalised. Ctrl+C copies selected words in reading order (index order = TSV reading order).

Rendering uses an `ImageTransform { scale, offset_x, offset_y }` struct computed from the image's "Contain" fit inside the `DrawingArea`. The same transform is used for both drawing and hit-testing, so clicks map correctly regardless of window size.

---

## Portal URIs vs file paths

ashpd returns `ashpd::Uri` (a string like `file:///home/user/my%20image.png`). `uri_to_path()` in `portal.rs` strips the `file://` prefix and percent-decodes the path (e.g. `%20` → space) before passing it to Tesseract.
