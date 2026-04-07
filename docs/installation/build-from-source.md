# Build from Source

Building from source gives you the latest code and full control over the build. This is the recommended path for contributors.

## Prerequisites

Install Rust 1.85+ (required for the 2024 edition):

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

Install system dependencies for your distro:

=== "Arch"
    ```bash
    sudo pacman -S clang gtk4 libadwaita leptonica tesseract
    ```

=== "Debian / Ubuntu"
    ```bash
    sudo apt install clang libgtk-4-dev libadwaita-1-dev libleptonica-dev libtesseract-dev
    ```

=== "Fedora"
    ```bash
    sudo dnf install clang gtk4-devel libadwaita-devel leptonica-devel tesseract-devel
    ```

=== "macOS"
    ```bash
    brew install gtk4 libadwaita leptonica tesseract
    ```

---

## Build

```bash
git clone https://github.com/Pranavk-official/rustylens.git
cd rustylens
cargo build --release
```

The binary is at `target/release/rustylens` (~2 MB).

For a fast debug build during development:

```bash
cargo build
./target/debug/rustylens
```

---

## Install from source

```bash
cargo install --path .

# Register the desktop entry and icon:
install -Dm644 data/io.github.pranavk_official.RustyLens.desktop \
  ~/.local/share/applications/io.github.pranavk_official.RustyLens.desktop
install -Dm644 data/icons/hicolor/scalable/apps/io.github.pranavk_official.RustyLens.svg \
  ~/.local/share/icons/hicolor/scalable/apps/io.github.pranavk_official.RustyLens.svg
```

---

## Build an AppImage locally

Produces a portable `RustyLens-x86_64.AppImage` (~50 MB). Requires `squashfs-tools`. `linuxdeploy` is downloaded automatically.

```bash
./build-appimage.sh              # Full build (cargo + AppImage)
./build-appimage.sh --skip-build # Reuse existing binary
./build-appimage.sh --install    # Build and install to ~/.local/bin/rustylens
./build-appimage.sh --clean      # Clean build artefacts first
```

Or via Make:

```bash
make appimage          # Build AppImage
make appimage-install  # Build + install to ~/.local/bin
```

---

## Build the Flatpak locally

```bash
# One-time SDK setup:
flatpak install flathub org.gnome.Platform//49 org.gnome.Sdk//49
flatpak install flathub org.freedesktop.Sdk.Extension.rust-stable//25.08

# Build and install:
flatpak-builder --user --install --force-clean build-dir io.github.pranavk_official.RustyLens.json
```

---

## Makefile reference

```bash
make build          # cargo build --release
make run            # Build + run GUI
make appimage       # Build AppImage
make install        # Install AppImage + desktop entry to ~/.local
make install-langs  # Install English Tesseract pack (edit LANGS= to change)
make test-docker    # Run full Docker test suite
make clean          # cargo clean + remove AppDir / AppImage artefacts
make release        # Build + tag a new release commit
```
