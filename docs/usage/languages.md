# OCR Languages

RustyLens uses Tesseract for OCR and supports all Tesseract language packs — over 100 languages in total.

---

## How language detection works

At startup, RustyLens scans the tessdata directory (typically `/usr/share/tessdata/`) for `.traineddata` files and populates the language dropdown automatically. Any language pack you install is picked up on the next launch.

---

## Installing language packs

### Via `install.sh`

The easiest way to add languages:

```bash
./install.sh --european        # Western + Eastern European
./install.sh --asian           # CJK, Korean, Vietnamese, Thai
./install.sh --langs "fra jpn" # Custom selection
```

See [install.sh](../installation/install-script.md) for the full list of language group flags.

### Via your package manager

=== "Arch"
    ```bash
    sudo pacman -S tesseract-data-fra   # French
    sudo pacman -S tesseract-data-jpn   # Japanese
    ```

=== "Debian / Ubuntu"
    ```bash
    sudo apt install tesseract-ocr-fra
    sudo apt install tesseract-ocr-jpn
    ```

=== "Fedora"
    ```bash
    sudo dnf install tesseract-langpack-fra
    sudo dnf install tesseract-langpack-jpn
    ```

### Direct tessdata download

If your package manager does not carry a specific language, download it directly from the [tessdata_fast](https://github.com/tesseract-ocr/tessdata_fast) repository:

```bash
sudo curl -fsSL \
  https://github.com/tesseract-ocr/tessdata_fast/raw/main/fra.traineddata \
  -o /usr/share/tessdata/fra.traineddata
```

Or use `--download` with `install.sh` to force direct download for all selected languages:

```bash
./install.sh --langs "fra jpn" --download
```

---

## Common language codes

| Code | Language |
|------|----------|
| `eng` | English |
| `deu` | German |
| `fra` | French |
| `spa` | Spanish |
| `ita` | Italian |
| `por` | Portuguese |
| `rus` | Russian |
| `jpn` | Japanese |
| `chi_sim` | Chinese (Simplified) |
| `chi_tra` | Chinese (Traditional) |
| `kor` | Korean |
| `ara` | Arabic |
| `hin` | Hindi |
| `ben` | Bengali |
| `vie` | Vietnamese |
| `tha` | Thai |

For the complete list of codes, see the [Tesseract data files documentation](https://tesseract-ocr.github.io/tessdoc/Data-Files-in-different-versions.html).

---

## Using multiple languages

The **Auto (all)** option in the dropdown runs OCR using every installed language simultaneously. This is helpful when you are unsure of the image's language, but increases processing time and may reduce per-language accuracy.

For best results, select the specific language that matches your image content.
