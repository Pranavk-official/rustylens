#!/usr/bin/env bash
# install.sh — Install RustyLens with Tesseract OCR language packs.
#
# Supports: Arch (pacman), Debian/Ubuntu (apt), Fedora/RHEL (dnf),
#           openSUSE (zypper), Alpine (apk), Void Linux (xbps-install).
#           Falls back to direct tessdata download on unknown distros.
#
# Usage:
#   ./install.sh [LANGUAGE OPTIONS] [OPTIONS]
#
# Quick examples:
#   ./install.sh --minimal              # English only (default)
#   ./install.sh --european             # Western + Eastern European
#   ./install.sh --asian                # East Asian (CJK + Korean + Vietnamese)
#   ./install.sh --full                 # Every language group
#   ./install.sh --langs "eng fra jpn"  # Custom selection
#   ./install.sh --no-langs             # AppImage only, no tessdata
#   ./install.sh --uninstall            # Remove RustyLens
#   ./install.sh --minimal --yes        # Non-interactive (CI)
#
# Environment overrides:
#   NONINTERACTIVE=1   Equivalent to --yes (skip all prompts)
#   CI=true            Same — set automatically by GitHub Actions etc.
#   RUSTYLENS_PREFIX   Override install prefix (same as --prefix)

set -euo pipefail

APP_ID="io.github.pranavk_official.RustyLens"
APP_NAME="rustylens"
TESSDATA_BASE="https://github.com/tesseract-ocr/tessdata_fast/raw/main"

# ── Architecture (normalise arm64 → aarch64 for AppImage naming) ─────────────
ARCH="$(uname -m)"
case "$ARCH" in arm64) ARCH="aarch64" ;; esac

# ── GitHub release endpoint ───────────────────────────────────────────────────
GITHUB_REPO="Pranavk-official/rustylens"
RELEASE_API="https://api.github.com/repos/${GITHUB_REPO}/releases/latest"

# ── Sudo wrapper (empty when already root, e.g. in Docker CI) ────────────────
SUDO_CMD="sudo"
[ "$(id -u)" = "0" ] && SUDO_CMD=""

# ── Non-interactive / CI mode ─────────────────────────────────────────────────
YES=0
{ [ "${CI:-}" = "true" ] || [ "${NONINTERACTIVE:-}" = "1" ]; } && YES=1

# ── TTY-aware colours ─────────────────────────────────────────────────────────
if [ -t 1 ]; then
  RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
  CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
else
  RED=''; GREEN=''; YELLOW=''; CYAN=''; BOLD=''; NC=''
fi

info()    { echo -e "${CYAN}==>${NC} ${BOLD}$*${NC}"; }
success() { echo -e "${GREEN}  ✓${NC} $*"; }
warn()    { echo -e "${YELLOW}  !${NC} $*"; }
die()     { echo -e "${RED}Error:${NC} $*" >&2; exit 1; }
ask()     { echo -e "${BOLD}$*${NC}"; }

# ── Helpers ───────────────────────────────────────────────────────────────────
have_cmd() { command -v "$1" &>/dev/null; }

need_cmd() {
  if ! have_cmd "$1"; then
    die "Required command not found: $1"
  fi
}

# Download a URL to a destination file.
# Uses curl if available (with progress only on TTY), falls back to wget.
download_file() {
  local url="$1" dest="$2"
  if have_cmd curl; then
    if [ -t 1 ]; then
      curl -fL --progress-bar "$url" -o "$dest"
    else
      curl -fsSL "$url" -o "$dest"
    fi
  elif have_cmd wget; then
    if [ -t 1 ]; then
      wget --show-progress "$url" -O "$dest"
    else
      wget -q "$url" -O "$dest"
    fi
  else
    die "Neither curl nor wget found. Install one to download files."
  fi
}

# ── Source distro info (for friendly error messages) ─────────────────────────
DISTRO_NAME="unknown"
if [ -f /etc/os-release ]; then
  # shellcheck source=/dev/null
  . /etc/os-release
  DISTRO_NAME="${PRETTY_NAME:-${NAME:-unknown}}"
fi

# ── Language name→code mappings ──────────────────────────────────────────────
# Codes are Tesseract language identifiers (packages and .traineddata filenames).
#
# Group: minimal
LANGS_MINIMAL=(eng)

# Group: european — Western + Eastern European scripts
LANGS_EUROPEAN=(eng deu fra spa ita por nld pol ces ron swe dan fin nor hun tur)

# Group: asian — East & South-East Asian
LANGS_ASIAN=(jpn chi_sim chi_tra kor vie tha)

# Group: cyrillic — Cyrillic-script languages
LANGS_CYRILLIC=(rus ukr bul bel srp)

# Group: arabic — Arabic-script + Hebrew
LANGS_ARABIC=(ara fas urd heb)

# Group: indic — South Asian scripts
LANGS_INDIC=(hin ben tam tel mar kan mal pan)

# Group: full — everything above combined (deduped via assoc array in add_langs)
LANGS_FULL=(
  eng
  deu fra spa ita por nld pol ces ron swe dan fin nor hun tur
  jpn chi_sim chi_tra kor vie tha
  rus ukr bul bel srp
  ara fas urd heb
  hin ben tam tel mar kan mal pan
)

# ── Defaults ─────────────────────────────────────────────────────────────────
PREFIX="${RUSTYLENS_PREFIX:-${HOME}/.local}"
INSTALL_METHOD="binary"  # "binary" (tarball) or "appimage"; --appimage sets this
LOCAL_SRC=""             # path to a local file; set by --local PATH
SELECTED_LANGS=()
NO_LANGS=0
NO_DESKTOP=0
DO_UNINSTALL=0
DO_UPDATE=0
FORCE_DOWNLOAD=0  # download .traineddata directly even if a pkg manager is available

# ── Usage ────────────────────────────────────────────────────────────────────
usage() {
  cat <<EOF
${BOLD}install.sh${NC} — Install RustyLens with Tesseract OCR language support.

  ${BOLD}Usage:${NC}
    ./install.sh [LANGUAGE OPTIONS] [OPTIONS]

  ${BOLD}Language options${NC} (pick one or more; default: --minimal):
    --minimal      English only                            (~10 MB tessdata)
    --european     Western + Eastern European              (eng deu fra spa ita por
                                                            nld pol ces ron swe dan
                                                            fin nor hun tur)
    --asian        East & South-East Asian                 (jpn chi_sim chi_tra kor
                                                            vie tha)
    --cyrillic     Cyrillic-script languages               (rus ukr bul bel srp)
    --arabic       Arabic-script languages + Hebrew        (ara fas urd heb)
    --indic        South Asian / Indic scripts             (hin ben tam tel mar kan
                                                            mal pan)
    --full         All of the above
    --langs LIST   Custom codes, space- or comma-separated (e.g. "eng fra jpn")
    --no-langs     Skip Tesseract language installation entirely

  ${BOLD}Install options:${NC}
    --appimage        Install as AppImage instead of standalone binary
    --local PATH      Install from a local file instead of downloading from GitHub
    --prefix DIR      Installation prefix  (default: ~/.local)
                      Also read from \$RUSTYLENS_PREFIX
    --no-desktop      Skip .desktop file registration
    --download        Force direct tessdata download instead of package manager
    --yes, -y         Non-interactive; skip all y/N prompts (also: NONINTERACTIVE=1)
    --uninstall       Remove RustyLens (binary, desktop entry, icon)
    --update          Download and install the latest release from GitHub
    -h, --help        Show this help

  ${BOLD}Installation layout:${NC}
    Binary:   PREFIX/bin/rustylens
    Desktop:  PREFIX/share/applications/${APP_ID}.desktop
    Icon:     PREFIX/share/icons/hicolor/scalable/apps/${APP_ID}.svg
    Tessdata: System dir (pkg manager) or PREFIX/share/tessdata (--download)

  ${BOLD}Examples:${NC}
    ./install.sh --minimal                           # binary from GitHub + English
    ./install.sh --appimage --minimal                # AppImage from GitHub + English
    ./install.sh --local ./RustyLens-x86_64.AppImage # install a local AppImage
    ./install.sh --european --asian
    ./install.sh --full --download
    ./install.sh --langs "eng fra jpn chi_sim"
    ./install.sh --uninstall
    ./install.sh --update
    NONINTERACTIVE=1 ./install.sh --minimal  # CI / scripted install
EOF
}

# ── Arg parsing ──────────────────────────────────────────────────────────────
declare -A _SEEN_LANGS=()

add_langs() {
  for lang in "$@"; do
    if [[ -z "${_SEEN_LANGS[$lang]+set}" ]]; then
      SELECTED_LANGS+=("$lang")
      _SEEN_LANGS[$lang]=1
    fi
  done
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --minimal)   add_langs "${LANGS_MINIMAL[@]}"  ; shift ;;
    --european)  add_langs "${LANGS_EUROPEAN[@]}" ; shift ;;
    --asian)     add_langs "${LANGS_ASIAN[@]}"    ; shift ;;
    --cyrillic)  add_langs "${LANGS_CYRILLIC[@]}" ; shift ;;
    --arabic)    add_langs "${LANGS_ARABIC[@]}"   ; shift ;;
    --indic)     add_langs "${LANGS_INDIC[@]}"    ; shift ;;
    --full)      add_langs "${LANGS_FULL[@]}"     ; shift ;;
    --langs)
      [[ $# -gt 1 ]] || die "--langs requires an argument"
      IFS=', ' read -ra _custom <<< "$2"
      add_langs "${_custom[@]}"
      shift 2 ;;
    --no-langs)   NO_LANGS=1        ; shift ;;
    --download)   FORCE_DOWNLOAD=1  ; shift ;;
    --appimage)   INSTALL_METHOD="appimage" ; shift ;;
    --local)
      [[ $# -gt 1 ]] || die "--local requires a path argument"
      LOCAL_SRC="$2" ; shift 2 ;;
    --prefix)
      [[ $# -gt 1 ]] || die "--prefix requires a path argument"
      PREFIX="$2" ; shift 2 ;;
    --no-desktop) NO_DESKTOP=1  ; shift ;;
    --uninstall)  DO_UNINSTALL=1; shift ;;
    --update)     DO_UPDATE=1   ; shift ;;
    --yes|-y)     YES=1         ; shift ;;
    -h|--help)    usage ; exit 0 ;;
    *) die "Unknown option: $1  (run with --help for usage)" ;;
  esac
done

# Default to minimal if no language option was given
[[ ${#SELECTED_LANGS[@]} -gt 0 || $NO_LANGS -eq 1 ]] \
  || add_langs "${LANGS_MINIMAL[@]}"

BIN_DIR="${PREFIX}/bin"
SHARE_DIR="${PREFIX}/share"
DESKTOP_DIR="${SHARE_DIR}/applications"
ICONS_DIR="${SHARE_DIR}/icons/hicolor/scalable/apps"
LOCAL_TESSDATA="${SHARE_DIR}/tessdata"
METADATA_FILE="${SHARE_DIR}/${APP_NAME}/.install_method"

# ── Detect package manager ────────────────────────────────────────────────────
detect_pm() {
  if   have_cmd pacman;       then echo "pacman"
  elif have_cmd apt-get;      then echo "apt"
  elif have_cmd dnf;          then echo "dnf"
  elif have_cmd zypper;       then echo "zypper"
  elif have_cmd apk;          then echo "apk"
  elif have_cmd xbps-install; then echo "xbps"
  else                             echo "none"
  fi
}

# Convert a Tesseract lang code to the system package name for a given PM.
pkg_name() {
  local lang="$1" pm="$2"
  local dashed="${lang//_/-}"    # chi_sim → chi-sim
  case "$pm" in
    pacman) echo "tesseract-data-${dashed}"          ;;
    apt)    echo "tesseract-ocr-${dashed}"           ;;
    dnf)    echo "tesseract-langpack-${lang}"        ;;
    zypper) echo "tesseract-ocr-traineddata-${lang}" ;;
    apk)    echo "tesseract-ocr-data-${dashed}"      ;;
    xbps)   echo "tesseract-ocr-${dashed}"           ;;
  esac
}

# Return 0 if the package is already installed.
is_pkg_installed() {
  local pkg="$1" pm="$2"
  case "$pm" in
    pacman) pacman -Q "$pkg"    &>/dev/null ;;
    apt)    dpkg -s "$pkg"      &>/dev/null ;;
    dnf)    rpm -q "$pkg"       &>/dev/null ;;
    zypper) rpm -q "$pkg"       &>/dev/null ;;
    apk)    apk info -e "$pkg"  &>/dev/null ;;
    xbps)   xbps-query "$pkg"   &>/dev/null ;;
    *)      return 1 ;;
  esac
}

# ── Verify a file looks like an ELF AppImage ─────────────────────────────────
verify_appimage() {
  local path="$1"
  if have_cmd file; then
    file "$path" | grep -q "ELF" && return 0 || return 1
  else
    # Read first 4 bytes (ELF magic: 0x7f 'E' 'L' 'F')
    local magic
    magic="$(od -A n -N 4 -t x1 "$path" 2>/dev/null | tr -d ' \n')"
    [ "$magic" = "7f454c46" ] && return 0 || return 1
  fi
}

# ── Uninstall ─────────────────────────────────────────────────────────────────
do_uninstall() {
  info "Uninstalling RustyLens from ${PREFIX}…"

  local removed=0
  local TARGETS=(
    "${BIN_DIR}/${APP_NAME}"
    "${DESKTOP_DIR}/${APP_ID}.desktop"
    "${ICONS_DIR}/${APP_ID}.svg"
    "$METADATA_FILE"
  )

  for f in "${TARGETS[@]}"; do
    if [[ -f "$f" ]]; then
      rm -f "$f"
      success "Removed: $f"
      (( removed++ )) || true
    fi
  done

  command -v update-desktop-database &>/dev/null \
    && update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true
  command -v gtk-update-icon-cache &>/dev/null \
    && gtk-update-icon-cache -f -t "${SHARE_DIR}/icons/hicolor" 2>/dev/null || true

  if [[ $removed -eq 0 ]]; then
    warn "Nothing found to remove under ${PREFIX}"
  else
    success "RustyLens removed."
  fi

  # Optionally remove downloaded tessdata
  if [[ -d "$LOCAL_TESSDATA" ]] && ls "$LOCAL_TESSDATA"/*.traineddata &>/dev/null 2>&1; then
    echo ""
    local answer="n"
    if [[ $YES -eq 1 ]]; then
      answer="n"  # non-interactive: keep tessdata by default
      warn "Non-interactive mode: keeping tessdata in ${LOCAL_TESSDATA}"
    else
      ask "Remove downloaded tessdata in ${LOCAL_TESSDATA}? [y/N]"
      read -r answer
    fi
    if [[ "$answer" =~ ^[Yy]$ ]]; then
      rm -f "${LOCAL_TESSDATA}"/*.traineddata
      success "Tessdata removed from ${LOCAL_TESSDATA}"
    fi
  fi
}

# ── Install tessdata via package manager ──────────────────────────────────────
install_langs_pm() {
  local pm="$1"; shift
  local langs=("$@")
  local to_install=()

  for lang in "${langs[@]}"; do
    local pkg; pkg="$(pkg_name "$lang" "$pm")"
    is_pkg_installed "$pkg" "$pm" || to_install+=("$pkg")
  done

  if [[ ${#to_install[@]} -eq 0 ]]; then
    success "All requested language packs already installed."
    return 0
  fi

  info "Installing ${#to_install[@]} language package(s) via ${pm}…"
  echo "  ${to_install[*]}"

  case "$pm" in
    pacman) $SUDO_CMD pacman -S --noconfirm "${to_install[@]}" ;;
    apt)    $SUDO_CMD apt-get install -y "${to_install[@]}"    ;;
    dnf)    $SUDO_CMD dnf install -y "${to_install[@]}"        ;;
    zypper) $SUDO_CMD zypper install -y "${to_install[@]}"     ;;
    apk)    $SUDO_CMD apk add --no-cache "${to_install[@]}"    ;;
    xbps)   $SUDO_CMD xbps-install -y "${to_install[@]}"       ;;
  esac
}

# ── Install tessdata via direct download ──────────────────────────────────────
install_langs_download() {
  local langs=("$@")

  have_cmd curl || have_cmd wget \
    || die "Neither curl nor wget found. Install one to download tessdata."

  mkdir -p "$LOCAL_TESSDATA"

  for lang in "${langs[@]}"; do
    local dest="${LOCAL_TESSDATA}/${lang}.traineddata"
    if [[ -f "$dest" ]]; then
      success "Already present: ${lang}.traineddata"
      continue
    fi

    info "Downloading ${lang}.traineddata…"
    local url="${TESSDATA_BASE}/${lang}.traineddata"
    download_file "$url" "$dest" \
      || { warn "Failed to download ${lang}.traineddata"; rm -f "$dest"; continue; }

    [[ -f "$dest" ]] && success "${lang}.traineddata → ${dest}"
  done

  echo ""
  echo -e "  ${YELLOW}Note:${NC} To use these files, set:"
  echo -e "    ${BOLD}export TESSDATA_PREFIX=${LOCAL_TESSDATA}${NC}"
  echo -e "  Add that to your ~/.bashrc or ~/.profile."
}

# ── Fetch a release asset URL from GitHub ────────────────────────────────────
# Prints "tag|download_url" to stdout. Dies on failure.
fetch_release_asset() {
  local pattern="$1"
  local tmp_json
  tmp_json="$(mktemp /tmp/rustylens-release-XXXXXX.json)"

  download_file "$RELEASE_API" "$tmp_json" \
    || { rm -f "$tmp_json"; die "Failed to fetch release info from GitHub."; }

  local tag url
  tag="$(grep '"tag_name"' "$tmp_json" \
    | sed 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')"
  url="$(grep '"browser_download_url"' "$tmp_json" \
    | grep "$pattern" \
    | sed 's/.*"browser_download_url"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' \
    | head -1)"
  rm -f "$tmp_json"

  [[ -n "$tag" ]] || die "Could not determine latest version from GitHub API."
  [[ -n "$url" ]] || die "No release asset matching '${pattern}' found in ${tag}."
  echo "${tag}|${url}"
}

# ── Save install method to metadata file ──────────────────────────────────────
save_install_metadata() {
  mkdir -p "${SHARE_DIR}/${APP_NAME}"
  echo "$INSTALL_METHOD" > "$METADATA_FILE"
}

# ── Install AppImage ──────────────────────────────────────────────────────────
# If LOCAL_SRC is set, installs from that path; otherwise downloads from GitHub.
install_appimage() {
  local src="$LOCAL_SRC"
  local tmp_img=""

  if [[ -z "$src" ]]; then
    info "Fetching latest AppImage from GitHub…"
    local result; result="$(fetch_release_asset "RustyLens-${ARCH}.AppImage")"
    local tag="${result%%|*}" url="${result##*|}"
    tmp_img="$(mktemp /tmp/rustylens-XXXXXX.AppImage)"
    info "Downloading RustyLens ${tag} (AppImage)…"
    download_file "$url" "$tmp_img" \
      || { rm -f "$tmp_img"; die "Download failed."; }
    src="$tmp_img"
  else
    [[ -f "$src" ]] || die "Local file not found: ${src}"
  fi

  verify_appimage "$src" \
    || { rm -f "$tmp_img"; die "File does not look like a valid AppImage (ELF check failed): ${src}"; }

  info "Installing AppImage → ${BIN_DIR}/${APP_NAME}…"
  mkdir -p "$BIN_DIR"
  cp "$src" "${BIN_DIR}/${APP_NAME}"
  chmod +x "${BIN_DIR}/${APP_NAME}"
  [[ -n "$tmp_img" ]] && rm -f "$tmp_img"
  success "${BIN_DIR}/${APP_NAME}  ($(du -sh "${BIN_DIR}/${APP_NAME}" | cut -f1))"
}

# ── Install standalone binary (tarball from GitHub or local file) ─────────────
install_binary() {
  local src="$LOCAL_SRC"
  local tmp_tar=""

  if [[ -z "$src" ]]; then
    info "Fetching latest binary from GitHub…"
    local result; result="$(fetch_release_asset "rustylens-linux-${ARCH}.tar.gz")"
    local tag="${result%%|*}" url="${result##*|}"
    tmp_tar="$(mktemp /tmp/rustylens-XXXXXX.tar.gz)"
    info "Downloading rustylens ${tag} (binary)…"
    download_file "$url" "$tmp_tar" \
      || { rm -f "$tmp_tar"; die "Download failed."; }
    src="$tmp_tar"
  else
    [[ -f "$src" ]] || die "Local file not found: ${src}"
  fi

  info "Installing binary → ${BIN_DIR}/${APP_NAME}…"
  mkdir -p "$BIN_DIR"
  if [[ "$src" == *.tar.gz || "$src" == *.tgz ]]; then
    tar xzf "$src" -C "$BIN_DIR" rustylens
  else
    cp "$src" "${BIN_DIR}/${APP_NAME}"
  fi
  chmod +x "${BIN_DIR}/${APP_NAME}"
  [[ -n "$tmp_tar" ]] && rm -f "$tmp_tar"
  success "${BIN_DIR}/${APP_NAME}  ($(du -sh "${BIN_DIR}/${APP_NAME}" | cut -f1))"
}

# ── Install .desktop + icon ───────────────────────────────────────────────────
install_desktop() {
  local desktop_src="data/${APP_ID}.desktop"
  local icon_src="data/icons/hicolor/scalable/apps/${APP_ID}.svg"

  mkdir -p "$DESKTOP_DIR" "$ICONS_DIR"

  if [[ -f "$desktop_src" ]]; then
    sed "s|Exec=rustylens|Exec=${BIN_DIR}/${APP_NAME}|g" \
      "$desktop_src" > "${DESKTOP_DIR}/${APP_ID}.desktop"
    success "Desktop entry → ${DESKTOP_DIR}/${APP_ID}.desktop"
  else
    warn "data/${APP_ID}.desktop not found — skipping desktop entry"
  fi

  if [[ -f "$icon_src" ]]; then
    cp "$icon_src" "${ICONS_DIR}/${APP_ID}.svg"
    success "Icon → ${ICONS_DIR}/${APP_ID}.svg"
  else
    warn "Icon not found at data/icons/… — skipping"
  fi

  command -v update-desktop-database &>/dev/null \
    && update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true
  command -v gtk-update-icon-cache &>/dev/null \
    && gtk-update-icon-cache -f -t "${SHARE_DIR}/icons/hicolor" 2>/dev/null || true
}

# ── Update ────────────────────────────────────────────────────────────────────
do_update() {
  local installed_bin="${BIN_DIR}/${APP_NAME}"
  [[ -f "$installed_bin" ]] \
    || die "RustyLens is not installed at ${installed_bin}. Run without --update to install first."

  # Determine install method: saved metadata wins unless overridden by --appimage flag
  if [[ -f "$METADATA_FILE" ]]; then
    local saved_method; saved_method="$(cat "$METADATA_FILE")"
    # Only use saved method when the user didn't explicitly pass --appimage
    [[ "$INSTALL_METHOD" == "binary" ]] && INSTALL_METHOD="$saved_method"
  fi

  # If a local file was provided, reinstall from it directly (no GitHub check needed)
  if [[ -n "$LOCAL_SRC" ]]; then
    info "Updating from local file: ${LOCAL_SRC}"
    if [[ "$INSTALL_METHOD" == "appimage" ]]; then
      install_appimage
    else
      install_binary
    fi
    save_install_metadata
    return 0
  fi

  # Get current version
  local current_ver
  current_ver="$("$installed_bin" --version 2>/dev/null | awk '{print $2}')" || true
  [[ -n "$current_ver" ]] || current_ver="unknown"
  info "Installed version : ${current_ver}  (format: ${INSTALL_METHOD})"

  # Select the right GitHub asset based on install method
  local asset_pattern
  if [[ "$INSTALL_METHOD" == "appimage" ]]; then
    asset_pattern="RustyLens-${ARCH}.AppImage"
  else
    asset_pattern="rustylens-linux-${ARCH}.tar.gz"
  fi

  info "Checking for updates…"
  local tmp_json
  tmp_json="$(mktemp /tmp/rustylens-update-XXXXXX.json)"

  download_file "$RELEASE_API" "$tmp_json" \
    || { rm -f "$tmp_json"; die "Failed to fetch release info from GitHub."; }

  local latest_ver download_url
  latest_ver="$(grep '"tag_name"' "$tmp_json" \
    | sed 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')"
  download_url="$(grep '"browser_download_url"' "$tmp_json" \
    | grep "$asset_pattern" \
    | sed 's/.*"browser_download_url"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' \
    | head -1)"
  rm -f "$tmp_json"

  [[ -n "$latest_ver" ]] || die "Could not determine latest version from GitHub API."
  [[ -n "$download_url" ]] || die "No ${asset_pattern} found in release ${latest_ver}."

  info "Latest version    : ${latest_ver}"

  # Already up to date?
  local cur_stripped="${current_ver#v}" latest_stripped="${latest_ver#v}"
  if [[ "$cur_stripped" == "$latest_stripped" ]]; then
    success "RustyLens is already up to date (${latest_ver})."
    return 0
  fi

  echo ""
  echo -e "  ${BOLD}Update available:${NC} ${current_ver} → ${latest_ver}  (${INSTALL_METHOD})"
  echo -e "  Binary: ${installed_bin}"
  echo ""

  if [[ $YES -eq 0 ]]; then
    ask "Download and install ${latest_ver}? [Y/n]"
    read -r answer
    [[ "$answer" =~ ^[Nn]$ ]] && { warn "Update cancelled."; return 0; }
  fi

  # Download the new release to a temp file, then replace the installed binary
  local tmp_file
  if [[ "$INSTALL_METHOD" == "appimage" ]]; then
    tmp_file="$(mktemp /tmp/rustylens-XXXXXX.AppImage)"
    info "Downloading ${asset_pattern} (${latest_ver})…"
    download_file "$download_url" "$tmp_file" \
      || { rm -f "$tmp_file"; die "Download failed."; }
    verify_appimage "$tmp_file" \
      || { rm -f "$tmp_file"; die "Downloaded file does not look like a valid AppImage (ELF check failed)."; }
    cp "$tmp_file" "$installed_bin"
    chmod +x "$installed_bin"
  else
    tmp_file="$(mktemp /tmp/rustylens-XXXXXX.tar.gz)"
    info "Downloading ${asset_pattern} (${latest_ver})…"
    download_file "$download_url" "$tmp_file" \
      || { rm -f "$tmp_file"; die "Download failed."; }
    tar xzf "$tmp_file" -C "$BIN_DIR" rustylens
    chmod +x "$installed_bin"
  fi
  rm -f "$tmp_file"

  success "Updated to ${latest_ver}.  ($(du -sh "$installed_bin" | cut -f1))"

  # Optionally update language packs if any --langs flags were passed
  if [[ $NO_LANGS -eq 0 && ${#SELECTED_LANGS[@]} -gt 0 ]]; then
    echo ""
    info "Updating Tesseract language packs: ${SELECTED_LANGS[*]}"
    if [[ $FORCE_DOWNLOAD -eq 1 ]]; then
      install_langs_download "${SELECTED_LANGS[@]}"
    else
      local PM; PM="$(detect_pm)"
      if [[ "$PM" == "none" ]]; then
        warn "No supported package manager found. Falling back to direct download…"
        install_langs_download "${SELECTED_LANGS[@]}"
      else
        install_langs_pm "$PM" "${SELECTED_LANGS[@]}"
      fi
    fi
  fi
}

# ────────────────────────────────────────────────────────────────────────────
# MAIN
# ────────────────────────────────────────────────────────────────────────────

# Run from project root so relative paths (data/, etc.) resolve correctly
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if [[ $DO_UNINSTALL -eq 1 ]]; then
  do_uninstall
  exit 0
fi

if [[ $DO_UPDATE -eq 1 ]]; then
  do_update
  exit 0
fi

# ── Summary before doing anything ─────────────────────────────────────────────
echo ""
echo -e "${BOLD}RustyLens Installer${NC}"
echo -e "  Distro         : ${DISTRO_NAME}"
echo -e "  Architecture   : ${ARCH}"
if [[ -n "$LOCAL_SRC" ]]; then
  echo -e "  Source         : ${LOCAL_SRC} (local)"
else
  echo -e "  Source         : GitHub (latest release)"
fi
echo -e "  Format         : ${INSTALL_METHOD}"
echo -e "  Install prefix : ${PREFIX}"
if [[ $NO_LANGS -eq 1 ]]; then
  echo -e "  Tessdata       : skipped"
else
  echo -e "  Tessdata langs : ${SELECTED_LANGS[*]}"
  if [[ $FORCE_DOWNLOAD -eq 1 ]]; then
    echo -e "  Tessdata method: direct download → ${LOCAL_TESSDATA}"
  else
    PM="$(detect_pm)"
    echo -e "  Tessdata method: package manager (${PM})"
  fi
fi
echo ""

# ── 1. Install binary ─────────────────────────────────────────────────────────
if [[ "$INSTALL_METHOD" == "appimage" ]]; then
  install_appimage
else
  install_binary
fi
save_install_metadata

# ── 2. Install desktop entry ──────────────────────────────────────────────────
if [[ $NO_DESKTOP -eq 0 ]]; then
  install_desktop
fi

# ── 3. Install language packs ─────────────────────────────────────────────────
if [[ $NO_LANGS -eq 0 && ${#SELECTED_LANGS[@]} -gt 0 ]]; then
  info "Installing Tesseract language packs: ${SELECTED_LANGS[*]}"

  if [[ $FORCE_DOWNLOAD -eq 1 ]]; then
    install_langs_download "${SELECTED_LANGS[@]}"
  else
    PM="$(detect_pm)"
    if [[ "$PM" == "none" ]]; then
      warn "No supported package manager found on ${DISTRO_NAME}. Falling back to direct download…"
      install_langs_download "${SELECTED_LANGS[@]}"
    else
      install_langs_pm "$PM" "${SELECTED_LANGS[@]}"
    fi
  fi
fi

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}Installation complete!${NC}"
echo ""
echo -e "  ${BOLD}Run the app:${NC}"
echo -e "    ${CYAN}rustylens${NC}             # GUI mode (open an image)"
echo -e "    ${CYAN}rustylens --capture${NC}   # Screenshot + OCR mode"
echo ""
if [[ ":${PATH}:" != *":${BIN_DIR}:"* ]]; then
  echo -e "  ${YELLOW}Note:${NC} ${BIN_DIR} is not in your \$PATH."
  echo -e "  Add this to your ~/.bashrc or ~/.profile:"
  echo -e "    ${BOLD}export PATH=\"${BIN_DIR}:\$PATH\"${NC}"
  echo ""
fi
if [[ $NO_LANGS -eq 0 && $FORCE_DOWNLOAD -eq 1 ]]; then
  echo -e "  ${YELLOW}Note:${NC} Tessdata downloaded to ${LOCAL_TESSDATA}."
  echo -e "  If Tesseract can't find languages, add to ~/.bashrc:"
  echo -e "    ${BOLD}export TESSDATA_PREFIX=${LOCAL_TESSDATA}${NC}"
  echo ""
fi
