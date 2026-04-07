use std::path::PathBuf;

#[derive(Clone, Debug)]
pub struct OcrWord {
    pub x: i32,
    pub y: i32,
    pub w: i32,
    pub h: i32,
    pub text: String,
}

#[derive(Clone, Debug)]
pub struct OcrResult {
    pub full_text: String,
    pub words: Vec<OcrWord>,
    pub img_w: u32,
    pub img_h: u32,
}

/// Return the list of installed Tesseract language codes by scanning the
/// tessdata directory for `*.traineddata` files.
pub fn installed_languages() -> Vec<String> {
    let dirs: &[&str] = &[
        "/app/share/tessdata",
        "/usr/share/tessdata",
        "/usr/share/tesseract-ocr/5/tessdata",
        "/usr/share/tesseract-ocr/4.00/tessdata",
        "/usr/local/share/tessdata",
    ];

    let tessdata = std::env::var("TESSDATA_PREFIX")
        .map(PathBuf::from)
        .ok()
        .filter(|p| p.is_dir())
        .or_else(|| dirs.iter().map(PathBuf::from).find(|p| p.is_dir()));

    let Some(dir) = tessdata else {
        return vec!["eng".to_owned()];
    };

    let mut langs: Vec<String> = std::fs::read_dir(dir)
        .into_iter()
        .flatten()
        .filter_map(|e| e.ok())
        .filter_map(|e| {
            let name = e.file_name().to_string_lossy().to_string();
            name.strip_suffix(".traineddata").map(|s| s.to_owned())
        })
        .filter(|l| l != "osd") // osd is script detection, not a language
        .collect();

    langs.sort();
    if langs.is_empty() {
        langs.push("eng".to_owned());
    }
    langs
}

/// Map a Tesseract language code to a human-readable display name.
/// Falls back to the code itself for unknown codes.
pub fn lang_display_name(code: &str) -> &str {
    match code {
        "afr" => "Afrikaans",
        "amh" => "Amharic",
        "ara" => "Arabic",
        "aze" => "Azerbaijani",
        "bel" => "Belarusian",
        "ben" => "Bengali",
        "bod" => "Tibetan",
        "bos" => "Bosnian",
        "bul" => "Bulgarian",
        "cat" => "Catalan",
        "ces" => "Czech",
        "chi_sim" => "Chinese (Simplified)",
        "chi_tra" => "Chinese (Traditional)",
        "chr" => "Cherokee",
        "cos" => "Corsican",
        "cym" => "Welsh",
        "dan" => "Danish",
        "deu" => "German",
        "dzo" => "Dzongkha",
        "ell" => "Greek",
        "eng" => "English",
        "enm" => "Middle English",
        "epo" => "Esperanto",
        "est" => "Estonian",
        "eus" => "Basque",
        "fas" => "Persian",
        "fin" => "Finnish",
        "fra" => "French",
        "frk" => "Frankish",
        "frm" => "Middle French",
        "gle" => "Irish",
        "glg" => "Galician",
        "grc" => "Ancient Greek",
        "guj" => "Gujarati",
        "hat" => "Haitian Creole",
        "heb" => "Hebrew",
        "hin" => "Hindi",
        "hrv" => "Croatian",
        "hun" => "Hungarian",
        "hye" => "Armenian",
        "iku" => "Inuktitut",
        "ind" => "Indonesian",
        "isl" => "Icelandic",
        "ita" => "Italian",
        "jav" => "Javanese",
        "jpn" => "Japanese",
        "kan" => "Kannada",
        "kat" => "Georgian",
        "kaz" => "Kazakh",
        "khm" => "Khmer",
        "kir" => "Kyrgyz",
        "kor" => "Korean",
        "kur" => "Kurdish",
        "lao" => "Lao",
        "lat" => "Latin",
        "lav" => "Latvian",
        "lit" => "Lithuanian",
        "ltz" => "Luxembourgish",
        "mal" => "Malayalam",
        "mar" => "Marathi",
        "mkd" => "Macedonian",
        "mlt" => "Maltese",
        "mon" => "Mongolian",
        "mri" => "Maori",
        "msa" => "Malay",
        "mya" => "Burmese",
        "nep" => "Nepali",
        "nld" => "Dutch",
        "nor" => "Norwegian",
        "oci" => "Occitan",
        "ori" => "Odia",
        "pan" => "Punjabi",
        "pol" => "Polish",
        "por" => "Portuguese",
        "pus" => "Pashto",
        "ron" => "Romanian",
        "rus" => "Russian",
        "san" => "Sanskrit",
        "sin" => "Sinhala",
        "slk" => "Slovak",
        "slv" => "Slovenian",
        "snd" => "Sindhi",
        "spa" => "Spanish",
        "srp" => "Serbian",
        "sun" => "Sundanese",
        "swa" => "Swahili",
        "swe" => "Swedish",
        "syr" => "Syriac",
        "tam" => "Tamil",
        "tat" => "Tatar",
        "tel" => "Telugu",
        "tgk" => "Tajik",
        "tgl" => "Filipino",
        "tha" => "Thai",
        "tir" => "Tigrinya",
        "ton" => "Tongan",
        "tur" => "Turkish",
        "uig" => "Uyghur",
        "ukr" => "Ukrainian",
        "urd" => "Urdu",
        "uzb" => "Uzbek",
        "vie" => "Vietnamese",
        "yid" => "Yiddish",
        "yor" => "Yoruba",
        code => code,
    }
}

/// Run Tesseract OCR on the image at `path`. `lang` is a Tesseract language
/// string like `"eng"`, `"jpn"`, or `"eng+jpn+deu"` for multiple languages.
pub fn ocr_file(path: &str, lang: &str) -> Result<OcrResult, String> {
    let mut lt =
        leptess::LepTess::new(None, lang).map_err(|e| format!("Init OCR engine: {e}"))?;

    lt.set_image(path)
        .map_err(|e| format!("Load image: {e}"))?;

    // Suppress the "Invalid resolution 0 dpi" warning from Tesseract.
    lt.set_source_resolution(70);

    let (img_w, img_h) = lt.get_image_dimensions().unwrap_or((0, 0));

    let full_text = lt
        .get_utf8_text()
        .map_err(|e| format!("Extract text: {e}"))?
        .trim()
        .to_owned();

    let words = lt
        .get_tsv_text(0)
        .map(|tsv| parse_tsv_words(&tsv))
        .unwrap_or_default();

    Ok(OcrResult {
        full_text,
        words,
        img_w,
        img_h,
    })
}

/// Parse word-level bounding boxes from Tesseract's TSV output.
///
/// TSV columns (0-indexed):
/// `level  page_num  block_num  par_num  line_num  word_num  left  top  width  height  conf  text`
///
/// Only rows at level 5 (word) with confidence >= 0 are returned.
fn parse_tsv_words(tsv: &str) -> Vec<OcrWord> {
    let mut words = Vec::new();

    for line in tsv.lines().skip(1) {
        let cols: Vec<&str> = line.splitn(12, '\t').collect();
        if cols.len() < 12 {
            continue;
        }

        let level: i32 = cols[0].parse().unwrap_or(0);
        if level != 5 {
            continue;
        }

        let conf: f32 = cols[10].parse().unwrap_or(-1.0);
        if conf < 0.0 {
            continue;
        }

        let text = cols[11].trim();
        if text.is_empty() {
            continue;
        }

        let x: i32 = cols[6].parse().unwrap_or(0);
        let y: i32 = cols[7].parse().unwrap_or(0);
        let w: i32 = cols[8].parse().unwrap_or(0);
        let h: i32 = cols[9].parse().unwrap_or(0);

        if w > 0 && h > 0 {
            words.push(OcrWord {
                x,
                y,
                w,
                h,
                text: text.to_owned(),
            });
        }
    }

    words
}
