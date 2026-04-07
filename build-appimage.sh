#!/usr/bin/env bash
# build-appimage.sh — Build a RustyLens AppImage locally.
#
# Key design: two-pass linuxdeploy approach.
#   Pass 1: deploy shared libraries into AppDir (no --output).
#   Pass 2: package AppDir into an AppImage (no --executable, so no re-deploy).
# Between the two passes we delete libs that MUST come from the host
# (wayland, vulkan, GL/EGL, dbus, systemd, udev, xcb) to prevent segfaults.
#
# linuxdeploy is downloaded automatically if not found locally.
#
# Usage:
#   ./build-appimage.sh [--skip-build] [--install] [--clean] [-h]

set -euo pipefail

PROGDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROGDIR"

APP_ID="io.github.pranavk_official.RustyLens"

# ── Architecture (normalise arm64 → aarch64 to match linuxdeploy naming) ─────
ARCH="$(uname -m)"
case "$ARCH" in arm64) ARCH="aarch64" ;; esac

OUTPUT="RustyLens-${ARCH}.AppImage"
LINUXDEPLOY_URL="https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-${ARCH}.AppImage"

SKIP_BUILD=0
DO_INSTALL=0
DO_CLEAN=0

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

# ── Helpers ───────────────────────────────────────────────────────────────────
have_cmd() { command -v "$1" &>/dev/null; }

need_cmd() {
  if ! have_cmd "$1"; then
    die "Required command not found: $1"
  fi
}

# Download a URL to a destination file.
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
    die "Neither curl nor wget found. Install one to download linuxdeploy."
  fi
}

# Source distro info for better messages
DISTRO_NAME="unknown"
if [ -f /etc/os-release ]; then
  # shellcheck source=/dev/null
  . /etc/os-release
  DISTRO_NAME="${PRETTY_NAME:-${NAME:-unknown}}"
fi

# ── Help ──────────────────────────────────────────────────────────────────────
usage() {
  cat <<EOF
${BOLD}build-appimage.sh${NC} — Build a RustyLens AppImage from source.

  ${BOLD}Usage:${NC}
    ./build-appimage.sh [OPTIONS]

  ${BOLD}Options:${NC}
    --skip-build   Skip \`cargo build --release\` (reuse existing binary)
    --install      Copy the finished AppImage to ~/.local/bin/rustylens
    --clean        Remove AppDir and temp files before building
    -h, --help     Show this help

  ${BOLD}Requirements:${NC}
    cargo, pkg-config, GTK4 / libadwaita / leptonica / tesseract dev headers
    squashfs-tools (mksquashfs)
    linuxdeploy — downloaded automatically if not found in ./linuxdeploy or PATH

  ${BOLD}Dep install hints:${NC}
    Arch:   pacman -S gtk4 libadwaita leptonica tesseract squashfs-tools
    Debian: apt install libgtk-4-dev libadwaita-1-dev libleptonica-dev \\
                        libtesseract-dev squashfs-tools
    Fedora: dnf install gtk4-devel libadwaita-devel leptonica-devel \\
                        tesseract-devel squashfs-tools
    Alpine: apk add gtk4.0-dev libadwaita-dev leptonica-dev \\
                    tesseract-ocr-dev squashfs-tools

  ${BOLD}Packaging strategy:${NC}
    linuxdeploy is used ONLY to resolve and copy shared library deps.
    The AppImage is then assembled with mksquashfs + the runtime stub
    extracted from linuxdeploy itself, bypassing a second linuxdeploy
    invocation that would re-bundle the excluded libs.

  ${BOLD}Example:${NC}
    ./build-appimage.sh --install
    ./build-appimage.sh --skip-build   # fast rebuild after minor source edits
EOF
}

# ── Arg parsing ───────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-build) SKIP_BUILD=1 ; shift ;;
    --install)    DO_INSTALL=1 ; shift ;;
    --clean)      DO_CLEAN=1   ; shift ;;
    -h|--help)    usage ; exit 0 ;;
    *) die "Unknown option: $1  (run with --help for usage)" ;;
  esac
done

# ── Optional clean ────────────────────────────────────────────────────────────
if [[ $DO_CLEAN -eq 1 ]]; then
  info "Cleaning AppDir and temp files…"
  rm -rf AppDir _runtime.elf _app.squashfs
  success "Clean done"
fi

# ── Find or auto-download linuxdeploy ────────────────────────────────────────
LINUXDEPLOY=""
find_linuxdeploy() {
  if [[ -x "$PROGDIR/linuxdeploy" ]]; then
    LINUXDEPLOY="$PROGDIR/linuxdeploy"
  elif have_cmd linuxdeploy; then
    LINUXDEPLOY="linuxdeploy"
  else
    warn "linuxdeploy not found — downloading from GitHub…"
    have_cmd curl || have_cmd wget \
      || die "Need curl or wget to download linuxdeploy."
    local dest="$PROGDIR/linuxdeploy"
    download_file "$LINUXDEPLOY_URL" "$dest" \
      || die "Failed to download linuxdeploy from:\n  $LINUXDEPLOY_URL"
    chmod +x "$dest"
    success "linuxdeploy downloaded: $dest"
    LINUXDEPLOY="$dest"
  fi
}
find_linuxdeploy

# mksquashfs is needed for manual AppImage assembly
have_cmd mksquashfs || die "mksquashfs not found.
Install squashfs-tools:
  Arch:   sudo pacman -S squashfs-tools
  Debian: sudo apt install squashfs-tools
  Fedora: sudo dnf install squashfs-tools
  Alpine: sudo apk add squashfs-tools"

# ── Libs that MUST come from the host — never bundle ─────────────────────────
# Bundling these causes segfaults or GPU/compositor breakage:
#   wayland     client and compositor libs must be identical versions
#   vulkan      ICD loader is tightly coupled to the GPU driver
#   GL / EGL    actual implementation lives in the GPU driver stack
#   dbus-1      ABI must match the running dbus-daemon
#   systemd     kernel/udev interface must match the running kernel
#   xcb / X11   must match the running X server protocol version
EXCLUDE_PATTERNS=(
  "libwayland-client"
  "libwayland-cursor"
  "libwayland-egl"
  "libwayland-server"
  "libvulkan"
  "libGL"
  "libGLX"
  "libGLdispatch"
  "libEGL"
  "libdrm"
  "libdbus-1"
  "libsystemd"
  "libudev"
  "libXau"
  "libXdmcp"
  "libxcb"
  "libxcb-render"
  "libxcb-shm"
  "libxcb-util"
)

# ────────────────────────────────────────────────────────────────────────────
# STEP 1 — Build
# ────────────────────────────────────────────────────────────────────────────
if [[ $SKIP_BUILD -eq 0 ]]; then
  info "Building release binary…"
  need_cmd cargo
  cargo build --release
  BIN_SIZE="$(du -sh target/release/rustylens | cut -f1)"
  success "target/release/rustylens  (${BIN_SIZE})"
else
  [[ -f target/release/rustylens ]] \
    || die "target/release/rustylens not found — run without --skip-build first."
  info "Skipping build (reusing existing binary)"
fi

# ── Find GTK libdir (handles multi-arch and non-standard paths) ───────────────
find_gtk_libdir() {
  local ld
  if ld="$(pkg-config --variable=libdir gtk4 2>/dev/null)" && [[ -n "$ld" ]]; then
    echo "$ld"; return 0
  fi
  # Fall back to common locations across distros
  local candidates=(
    /usr/lib
    /usr/lib64
    /usr/lib/x86_64-linux-gnu
    /usr/lib/aarch64-linux-gnu
    /usr/lib/arm-linux-gnueabihf
    /usr/local/lib
  )
  for d in "${candidates[@]}"; do
    [[ -d "${d}/gtk-4.0" ]] && { echo "$d"; return 0; }
  done
  die "Cannot find GTK4 library directory.
Install GTK4 dev package:
  Arch:   sudo pacman -S gtk4
  Debian: sudo apt install libgtk-4-dev
  Fedora: sudo dnf install gtk4-devel
  (Distro: ${DISTRO_NAME})"
}

GTK_LIBDIR="$(find_gtk_libdir)"
success "GTK libdir: ${GTK_LIBDIR}"

# ── Find gdk-pixbuf-query-loaders (path varies per distro) ───────────────────
find_gdk_pixbuf_query() {
  local cmds=(
    gdk-pixbuf-query-loaders
    gdk-pixbuf-query-loaders-64
  )
  for cmd in "${cmds[@]}"; do
    have_cmd "$cmd" && { echo "$cmd"; return 0; }
  done
  local paths=(
    /usr/lib/x86_64-linux-gnu/gdk-pixbuf-2.0/gdk-pixbuf-query-loaders
    /usr/lib/aarch64-linux-gnu/gdk-pixbuf-2.0/gdk-pixbuf-query-loaders
    /usr/lib64/gdk-pixbuf-2.0/gdk-pixbuf-query-loaders
    /usr/libexec/gdk-pixbuf-query-loaders
    /usr/lib/gdk-pixbuf-2.0/gdk-pixbuf-query-loaders
  )
  for p in "${paths[@]}"; do
    [[ -x "$p" ]] && { echo "$p"; return 0; }
  done
  echo ""  # not found — caller skips cache generation
}

# ────────────────────────────────────────────────────────────────────────────
# STEP 2 — Fresh AppDir skeleton
# ────────────────────────────────────────────────────────────────────────────
info "Creating fresh AppDir…"
rm -rf AppDir
mkdir -p \
  AppDir/usr/bin \
  AppDir/usr/share/applications \
  AppDir/usr/share/metainfo \
  AppDir/usr/share/icons/hicolor/scalable/apps

install -Dm755 target/release/rustylens \
  AppDir/usr/bin/rustylens

cp "data/${APP_ID}.desktop" \
   "AppDir/usr/share/applications/${APP_ID}.desktop"
cp "data/${APP_ID}.metainfo.xml" \
   "AppDir/usr/share/metainfo/${APP_ID}.metainfo.xml"
cp "data/icons/hicolor/scalable/apps/${APP_ID}.svg" \
   "AppDir/usr/share/icons/hicolor/scalable/apps/${APP_ID}.svg"

# AppImage spec: desktop file and icon also at AppDir root
cp "data/${APP_ID}.desktop" AppDir/
cp "data/icons/hicolor/scalable/apps/${APP_ID}.svg" AppDir/

success "AppDir skeleton ready"

# ────────────────────────────────────────────────────────────────────────────
# STEP 3 — Bundle safe GTK / GLib / GDK assets
# ────────────────────────────────────────────────────────────────────────────
info "Bundling GTK4 / GLib assets…"

mkdir -p AppDir/usr/share/icons
cp -r /usr/share/icons/Adwaita AppDir/usr/share/icons/ 2>/dev/null \
  && success "Adwaita icon theme" || warn "Adwaita not found — skipping"
cp -r /usr/share/icons/hicolor AppDir/usr/share/icons/ 2>/dev/null || true

if [[ -d "${GTK_LIBDIR}/gtk-4.0" ]]; then
  mkdir -p AppDir/usr/lib/gtk-4.0
  cp -r "${GTK_LIBDIR}/gtk-4.0/"* AppDir/usr/lib/gtk-4.0/
  success "GTK4 immodules / print backends"
fi

mkdir -p AppDir/usr/lib/gdk-pixbuf-2.0
if cp -r "${GTK_LIBDIR}/gdk-pixbuf-2.0/"* AppDir/usr/lib/gdk-pixbuf-2.0/ 2>/dev/null; then
  GDK_PIXBUF_QUERY="$(find_gdk_pixbuf_query)"
  if [[ -n "$GDK_PIXBUF_QUERY" ]]; then
    GDK_PIXBUF_MODULEDIR=AppDir/usr/lib/gdk-pixbuf-2.0/2.10.0/loaders \
      "$GDK_PIXBUF_QUERY" \
      > AppDir/usr/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache 2>/dev/null || true
    success "GDK-Pixbuf loaders + cache"
  else
    warn "gdk-pixbuf-query-loaders not found — skipping cache generation"
  fi
fi

mkdir -p AppDir/usr/share/glib-2.0/schemas
cp /usr/share/glib-2.0/schemas/*.xml \
   AppDir/usr/share/glib-2.0/schemas/ 2>/dev/null || true
have_cmd glib-compile-schemas \
  && glib-compile-schemas AppDir/usr/share/glib-2.0/schemas/ \
  && success "GLib schemas compiled" \
  || warn "glib-compile-schemas not found — skipping"

# ────────────────────────────────────────────────────────────────────────────
# STEP 4 — Deploy shared library dependencies (pass 1, no packaging)
# ────────────────────────────────────────────────────────────────────────────
info "Deploying shared library dependencies (linuxdeploy pass 1)…"
APPIMAGE_EXTRACT_AND_RUN=1 NO_STRIP=1 "$LINUXDEPLOY" \
  --appdir AppDir \
  --executable target/release/rustylens \
  --desktop-file "data/${APP_ID}.desktop" \
  --icon-file "data/icons/hicolor/scalable/apps/${APP_ID}.svg" \
  2>&1 | grep -E 'Copying file|WARNING|ERROR' | head -60 || true
success "Libraries deployed into AppDir/usr/lib/"

# ────────────────────────────────────────────────────────────────────────────
# STEP 5 — Purge host-specific libs
# ────────────────────────────────────────────────────────────────────────────
info "Removing host-specific libs (wayland / vulkan / GL / dbus / xcb)…"
removed=0
for pat in "${EXCLUDE_PATTERNS[@]}"; do
  for f in "AppDir/usr/lib/${pat}.so"* "AppDir/usr/lib/${pat}-"*.so*; do
    [[ -e "$f" ]] || continue
    rm -f "$f"
    (( removed++ )) || true
  done
done
success "Removed ${removed} host-specific libs"

# Safety check: warn if any excluded lib is still present
STILL_PRESENT=()
for pat in libwayland-client libvulkan libGL libdbus-1 libsystemd libudev; do
  for f in "AppDir/usr/lib/${pat}"*.so*; do
    [[ -e "$f" ]] && STILL_PRESENT+=("$f")
  done
done
if [[ ${#STILL_PRESENT[@]} -gt 0 ]]; then
  warn "Some host-specific libs were not removed — may cause runtime issues:"
  for f in "${STILL_PRESENT[@]}"; do warn "  $f"; done
else
  success "CLEAN — no segfault-causing libs bundled"
fi

# ────────────────────────────────────────────────────────────────────────────
# STEP 6 — Write AppRun
# ────────────────────────────────────────────────────────────────────────────
info "Writing AppDir/AppRun…"
cat > AppDir/AppRun << 'APPRUN'
#!/bin/bash
SELF="$(readlink -f "$0")"
HERE="${SELF%/*}"
export PATH="${HERE}/usr/bin:${PATH}"
export LD_LIBRARY_PATH="${HERE}/usr/lib:${LD_LIBRARY_PATH}"
export XDG_DATA_DIRS="${HERE}/usr/share:${XDG_DATA_DIRS:-/usr/share}"
export GSETTINGS_SCHEMA_DIR="${HERE}/usr/share/glib-2.0/schemas"
export GDK_PIXBUF_MODULE_FILE="${HERE}/usr/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache"
export GTK_PATH="${HERE}/usr/lib/gtk-4.0"
export GTK_IM_MODULE_FILE=""
export GSK_RENDERER="${GSK_RENDERER:-ngl}"
exec "${HERE}/usr/bin/rustylens" "$@"
APPRUN
chmod +x AppDir/AppRun
success "AppRun written"

# ────────────────────────────────────────────────────────────────────────────
# STEP 7 — Assemble AppImage (mksquashfs + linuxdeploy ELF runtime)
#
# We do NOT use linuxdeploy --output appimage because a second linuxdeploy
# invocation re-scans the binary and re-bundles the libs we just removed.
# Instead:
#   a) extract the ELF runtime stub from linuxdeploy itself
#   b) squash AppDir with mksquashfs
#   c) concatenate: runtime + squashfs = self-contained AppImage
# ────────────────────────────────────────────────────────────────────────────
info "Extracting AppImage runtime from linuxdeploy…"
SQFS_OFFSET="$(APPIMAGE_EXTRACT_AND_RUN=1 "$LINUXDEPLOY" --appimage-offset 2>/dev/null)" \
  || die "Could not read SquashFS offset from linuxdeploy AppImage."
dd if="$LINUXDEPLOY" of="$PROGDIR/_runtime.elf" \
   bs=1 count="$SQFS_OFFSET" 2>/dev/null
success "Runtime stub: ${SQFS_OFFSET} bytes"

info "Squashing AppDir → squashfs…"
mksquashfs AppDir "$PROGDIR/_app.squashfs" \
  -root-owned -noappend -comp gzip \
  > /dev/null
success "squashfs: $(du -sh "$PROGDIR/_app.squashfs" | cut -f1)"

info "Assembling AppImage…"
rm -f "$OUTPUT"
cat "$PROGDIR/_runtime.elf" "$PROGDIR/_app.squashfs" > "$OUTPUT"
chmod a+x "$OUTPUT"
rm -f "$PROGDIR/_runtime.elf" "$PROGDIR/_app.squashfs"

[[ -f "$OUTPUT" ]] || die "AppImage assembly failed."
success "$(ls -lh "$OUTPUT")"

# ────────────────────────────────────────────────────────────────────────────
# STEP 8 — Optional install
# ────────────────────────────────────────────────────────────────────────────
if [[ $DO_INSTALL -eq 1 ]]; then
  info "Installing to ~/.local/bin/rustylens…"
  mkdir -p "$HOME/.local/bin"
  cp "$OUTPUT" "$HOME/.local/bin/rustylens"
  chmod +x "$HOME/.local/bin/rustylens"
  success "Installed: ~/.local/bin/rustylens"
  echo -e "  Run: ${BOLD}rustylens${NC}  (ensure ~/.local/bin is in \$PATH)"
fi

echo ""
echo -e "${GREEN}${BOLD}Done!${NC}  ${PROGDIR}/${OUTPUT}"
