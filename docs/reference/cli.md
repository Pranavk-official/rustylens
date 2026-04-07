# CLI Reference

RustyLens has a minimal command-line interface. All image selection and interaction happens in the GUI.

## Synopsis

```
rustylens [--capture] [-h | --help]
```

---

## Options

### `--capture`

Launch in screenshot mode. Opens an interactive region-selection overlay via the XDG Desktop Portal, captures the selected area, loads it, and runs OCR immediately.

```bash
rustylens --capture
```

This flag is also wired to the **"Capture Screenshot"** desktop action in the `.desktop` file, so it can be triggered from a desktop launcher right-click menu.

### `-h` / `--help`

*(Handled by the GTK application framework — not directly implemented.)*

---

## Environment variables

| Variable | Effect |
|----------|--------|
| `TESSDATA_PREFIX` | Override the tessdata directory scanned for language packs. Default: `/usr/share/tessdata` (or `/app/share/tessdata` in Flatpak). |
| `GTK_DEBUG` | Standard GTK4 debug flags (e.g. `GTK_DEBUG=interactive` opens the GTK inspector). |

---

## Application ID

```
io.github.pranavk_official.RustyLens
```

Used for D-Bus identification, Flatpak sandboxing, and desktop file naming.
