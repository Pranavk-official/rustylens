# Contributing

Contributions are welcome. This page covers how to set up a development environment and the conventions used in the codebase.

---

## Getting the code

```bash
git clone https://github.com/Pranavk-official/rustylens.git
cd rustylens
```

---

## Building for development

Use the debug build for faster compile times:

```bash
cargo build
./target/debug/rustylens
```

Or with Make:

```bash
make run     # build (debug) + run GUI
```

---

## Code conventions

### Never block the GLib main loop

All UI work must run on the GLib main thread. Blocking calls belong in `spawn_background` or `spawn_portal`. See [Architecture](reference/architecture.md) for the full pattern.

### Error handling

- `ocr_file()` returns `Result<OcrResult, String>`. OCR errors are shown in the `TextView`.
- Log unexpected runtime errors to stderr via `eprintln!()`. No UI error dialogs for internal errors.

### Adding portal features

When adding a new XDG portal call, add the corresponding `--talk-name` to `finish-args` in the Flatpak manifest (`io.github.pranavk_official.RustyLens.json`).

---

## Tests

There is no test suite yet.

When adding tests, prefer:

- **Integration tests** in `tests/` for portal/UI logic.
- **Unit tests** for pure functions (e.g. `parse_tsv_words`, `uri_to_path`).

---

## Opening issues and pull requests

Please open an [issue](https://github.com/Pranavk-official/rustylens/issues) or [pull request](https://github.com/Pranavk-official/rustylens/pulls) on GitHub. Describe the problem or change clearly, and include steps to reproduce for bugs.

---

## License

RustyLens is licensed under the [GNU General Public License v3.0 or later](https://github.com/Pranavk-official/rustylens/blob/main/LICENSE). Contributions are accepted under the same license.
