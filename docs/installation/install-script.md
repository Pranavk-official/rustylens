# install.sh

`install.sh` is the recommended way to install RustyLens on Linux. It handles distro detection, binary download, Tesseract language packs, and desktop integration automatically.

## One-line install

```bash
curl -fsSL https://raw.githubusercontent.com/Pranavk-official/rustylens/main/install.sh | bash
```

Pass options via `bash -s --`:

```bash
curl -fsSL https://raw.githubusercontent.com/Pranavk-official/rustylens/main/install.sh | bash -s -- --european --yes
```

---

## Language options

| Flag | Languages installed | Approx. size |
|------|--------------------|-|
| `--minimal` *(default)* | English | ~10 MB |
| `--european` | Western + Eastern European (eng, deu, fra, spa, ita, por, nld, pol, ces, ron, swe, dan, fin, nor, hun, tur) | ~120 MB |
| `--asian` | East & South-East Asian (jpn, chi_sim, chi_tra, kor, vie, tha) | ~200 MB |
| `--cyrillic` | Cyrillic-script (rus, ukr, bul, bel, srp) | ~50 MB |
| `--arabic` | Arabic-script + Hebrew (ara, fas, urd, heb) | ~60 MB |
| `--indic` | South Asian (hin, ben, tam, tel, mar, kan, mal, pan) | ~90 MB |
| `--full` | All of the above | ~500 MB |
| `--langs "eng fra jpn"` | Custom selection | varies |
| `--no-langs` | Skip language install entirely | — |

You can combine multiple groups:

```bash
./install.sh --european --cyrillic
```

---

## Install format options

| Flag | Effect |
|------|--------|
| *(default)* | Auto-detect distro; download native binary tarball |
| `--appimage`, `-A` | Force AppImage install (bundled libs, any distro) |
| `--flatpak`, `-F` | Install Flatpak bundle from GitHub Releases |
| `--local PATH` | Install from a local file instead of downloading |

```bash
./install.sh -A --minimal                           # AppImage
./install.sh -F                                     # Flatpak
./install.sh --local ./RustyLens-x86_64.AppImage    # local file
```

---

## Other options

| Flag | Description |
|------|-------------|
| `--prefix DIR` | Install prefix (default: `~/.local`). Also: `$RUSTYLENS_PREFIX` |
| `--no-desktop` | Skip `.desktop` file and icon registration |
| `--download` | Force direct tessdata download instead of package manager |
| `--yes`, `-y` | Non-interactive; skip all prompts |
| `--update` | Re-download the latest release, replacing the installed binary |
| `--uninstall` | Remove binary, desktop entry, and icon |
| `-h`, `--help` | Show usage |

---

## Update and uninstall

```bash
./install.sh --update        # Re-download latest release in the same format
./install.sh --uninstall     # Remove binary, .desktop entry, and icon
```

---

## Non-interactive / CI mode

```bash
NONINTERACTIVE=1 ./install.sh --minimal
# or
./install.sh --minimal --yes
```

`CI=true` (set automatically by GitHub Actions) is also respected.

---

## Installation layout

After install, files are placed at:

```
~/.local/bin/rustylens
~/.local/share/applications/io.github.pranavk_official.RustyLens.desktop
~/.local/share/icons/hicolor/scalable/apps/io.github.pranavk_official.RustyLens.svg
~/.local/share/rustylens/.install_method
```

Override the prefix with `--prefix /usr/local` for a system-wide install (requires `sudo`).
