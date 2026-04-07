# Pre-built Releases

All release assets are available at the [GitHub Releases page](https://github.com/Pranavk-official/rustylens/releases/latest).

---

## Linux

### Native binary tarballs

Distro-native binaries link against your distro's leptonica version, avoiding ABI mismatches.

| File | Distro |
|------|--------|
| `rustylens-linux-x86_64-arch.tar.gz` | Arch Linux, Garuda, Manjaro (leptonica 1.84+) |
| `rustylens-linux-x86_64-ubuntu.tar.gz` | Debian, Ubuntu, Mint, Pop!_OS |
| `rustylens-linux-x86_64-fedora.tar.gz` | Fedora, RHEL, Rocky, AlmaLinux, Nobara |
| `rustylens-linux-x86_64.tar.gz` | Generic (same as ubuntu build, for compatibility) |

Install the runtime libraries for your distro, then extract:

=== "Arch"
    ```bash
    sudo pacman -S leptonica tesseract tesseract-data-eng
    tar xzf rustylens-linux-x86_64-arch.tar.gz
    install -Dm755 rustylens ~/.local/bin/rustylens
    ```

=== "Debian / Ubuntu"
    ```bash
    sudo apt install libleptonica-dev libtesseract-dev tesseract-ocr-eng
    tar xzf rustylens-linux-x86_64-ubuntu.tar.gz
    install -Dm755 rustylens ~/.local/bin/rustylens
    ```

=== "Fedora"
    ```bash
    sudo dnf install leptonica tesseract tesseract-langpack-eng
    tar xzf rustylens-linux-x86_64-fedora.tar.gz
    install -Dm755 rustylens ~/.local/bin/rustylens
    ```

To register the desktop entry and icon:

```bash
install -Dm644 data/io.github.pranavk_official.RustyLens.desktop \
  ~/.local/share/applications/io.github.pranavk_official.RustyLens.desktop
install -Dm644 data/icons/hicolor/scalable/apps/io.github.pranavk_official.RustyLens.svg \
  ~/.local/share/icons/hicolor/scalable/apps/io.github.pranavk_official.RustyLens.svg
```

---

### AppImage

The AppImage bundles GTK4, libadwaita, leptonica, and tesseract — no system OCR libraries required. Works on any glibc-based distro.

```bash
chmod +x RustyLens-x86_64.AppImage
./RustyLens-x86_64.AppImage
```

Install to `PATH` for system-wide access:

```bash
install -Dm755 RustyLens-x86_64.AppImage ~/.local/bin/rustylens
```

!!! note
    The AppImage does **not** bundle Tesseract language packs. Install them separately or let `install.sh -A` handle it.

---

### Flatpak

The Flatpak bundle is fully sandboxed and includes all 128 Tesseract tessdata_fast language packs. No additional packages required.

```bash
flatpak install --user rustylens.flatpak
flatpak run io.github.pranavk_official.RustyLens
```

---

## macOS (experimental)

```
RustyLens-<arch>-apple-darwin.dmg
```

Mount the DMG and drag RustyLens to your Applications folder. Tesseract language packs must be installed separately (`brew install tesseract-lang`).

---

## Windows (experimental)

```
rustylens-windows-x86_64.zip
```

Extract the zip. All required DLLs and English tessdata are included in the archive.
