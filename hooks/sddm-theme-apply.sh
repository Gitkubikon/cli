#!/usr/bin/env bash
# ii-sddm-theme apply helper with debugging for Caelestia hooks
# Save as: ~/.config/ii-sddm-theme/sddm-theme-apply.sh
# Run with: sudo ~/.config/ii-sddm-theme/sddm-theme-apply.sh -v /path/to/wall.jpg

set -euo pipefail

# ---------------------- Early real-user detection ----------------------
REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME="$(getent passwd "${REAL_USER}" | cut -d: -f6 || true)"
if [[ -z "${REAL_HOME}" || ! -d "${REAL_HOME}" ]]; then
  echo "[ERROR] Could not resolve real user home for ${REAL_USER}" >&2
  exit 1
fi

# ---------------------- Defaults ----------------------
THEME_DIR="/usr/share/sddm/themes/ii-sddm-theme"
CFG_DIR="${REAL_HOME}/.config/ii-sddm-theme"
LOG_DIR="${REAL_HOME}/.config/ii-sddm-theme"
LOG_FILE="${LOG_DIR}/apply.log"
DRY_RUN=0
VERBOSE=0
WALL_ARG=""
COLORS_SRC=""
SETTINGS_SRC=""

# ---------------------- Logging helpers ----------------------
mkdir -p "${LOG_DIR}" || true
_ts(){ date "+%Y-%m-%d %H:%M:%S"; }
log(){ echo "[$(_ts)] $*" | tee -a "${LOG_FILE}"; }
run(){ if ((DRY_RUN)); then log "[DRY-RUN] $*"; else log "[RUN] $*"; eval "$@"; fi; }
die(){ log "[ERROR] $*"; exit 1; }

# ---------------------- Usage ----------------------
usage(){
  cat <<'USAGE'
Usage: sddm-theme-apply.sh [options] [WALLPAPER]
Options:
  -v, --verbose        Verbose output (enables bash -x)
  -n, --dry-run        Print actions without writing
      --colors PATH    Colors.qml to copy into theme (Matugen track)
      --settings PATH  Settings.json to copy (no-Matugen track)
  -h, --help           Show this help

If WALLPAPER is omitted, the script uses $WALLPAPER_PATH provided by Caelestia.
Run this script with sudo (the script writes to /usr/share/sddm/...)
USAGE
}

# ---------------------- Parse args ----------------------
while (( "$#" )); do
  case "$1" in
    -v|--verbose) VERBOSE=1; shift ;;
    -n|--dry-run) DRY_RUN=1; shift ;;
    --colors) COLORS_SRC="${2:-}"; shift 2 ;;
    --settings) SETTINGS_SRC="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    --) shift; break ;;
    *) WALL_ARG="$1"; shift ;;
  esac
done

if (( VERBOSE )); then set -x; fi

# ---------------------- Require root ----------------------
if [[ "${EUID}" -ne 0 ]]; then
  die "Run me with sudo. Example: sudo $0 -v /path/to/wall.jpg"
fi

# ---------------------- Info banner ----------------------
log "----- ii-sddm-theme apply start -----"
log "Real user      : ${REAL_USER}"
log "Real home      : ${REAL_HOME}"
log "Config dir     : ${CFG_DIR}"
log "Theme dir      : ${THEME_DIR}"
log "Log file       : ${LOG_FILE}"
log "Dry-run        : ${DRY_RUN}"
log "Verbose        : ${VERBOSE}"

# ---------------------- Ensure theme subdirs exist ----------------------
for d in Backgrounds Components Themes; do
  if [[ ! -d "${THEME_DIR}/${d}" ]]; then
    run "install -d -m 0755 '${THEME_DIR}/${d}'"
  fi
done

# ---------------------- Wallpaper ----------------------
# Normalize input: accept file:// URIs; if a directory is passed, pick newest image
WALL_RAW="${WALL_ARG:-${WALLPAPER_PATH:-}}"
# Strip leading file:// if present
WALL="${WALL_RAW#file://}"
log "Wallpaper input: '${WALL_RAW}' -> normalized: '${WALL}'"

pick_newest_image(){
  local dir="$1"
  local f
  f=$(ls -1t -- "$dir"/*.{jpg,jpeg,png,webp,avif,JPG,JPEG,PNG,WEBP,AVIF} 2>/dev/null | head -n1 || true)
  echo "$f"
}

if [[ -n "${WALL}" ]]; then
  if [[ -d "${WALL}" ]]; then
    CANDIDATE="$(pick_newest_image "${WALL}")"
    if [[ -n "${CANDIDATE}" && -f "${CANDIDATE}" ]]; then
      WALL="${CANDIDATE}"
      log "Directory provided; picked newest image: ${WALL}"
    else
      log "No images found in directory: ${WALL}. Skipping wallpaper step."
      WALL=""
    fi
  fi
fi

# Figure out what filename the theme actually uses from Themes/ii-sddm.conf
TARGET_NAME=""
CONF_FILE="${THEME_DIR}/Themes/ii-sddm.conf"
if [[ -f "${CONF_FILE}" ]]; then
  BG_LINE=$(grep -E '^Background="Backgrounds/.+"' "${CONF_FILE}" || true)
  if [[ -n "${BG_LINE}" ]]; then
    if [[ ${BG_LINE} =~ Background=\"Backgrounds/([^\"]+)\" ]]; then
      TARGET_NAME="${BASH_REMATCH[1]}"
      log "Theme config background filename detected: ${TARGET_NAME}"
    fi
  fi
fi
[[ -z "${TARGET_NAME}" ]] && TARGET_NAME="background.png"

if [[ -n "${WALL}" ]]; then
  if [[ ! -f "${WALL}" ]]; then
    log "[WARN] Wallpaper not found after normalization: ${WALL}. Skipping wallpaper step."
  else
    TARGET="${THEME_DIR}/Backgrounds/${TARGET_NAME}"
    log "Copy wallpaper: ${WALL} -> ${TARGET}"
    run "install -m 0644 '${WALL}' '${TARGET}'"
  fi
else
  log "No wallpaper provided (arg or $WALLPAPER_PATH). Skipping wallpaper step."
fi

# ---------------------- Colors (Matugen track) ----------------------


if [[ -z "${COLORS_SRC}" ]]; then COLORS_SRC="${CFG_DIR}/Colors.qml"; fi
if [[ -f "${COLORS_SRC}" ]]; then
  log "Sync Colors.qml: ${COLORS_SRC} -> ${THEME_DIR}/Components/Colors.qml"
  run "install -m 0644 '${COLORS_SRC}' '${THEME_DIR}/Components/Colors.qml'"
else
  log "Colors source not found: ${COLORS_SRC} (ok if not using Matugen)"
fi

# ---------------------- Settings (no-Matugen track) ----------------------
if [[ -z "${SETTINGS_SRC}" ]]; then SETTINGS_SRC="${CFG_DIR}/Settings.qml"; fi
if [[ -f "${SETTINGS_SRC}" ]]; then
  log "Sync Settings.qml: ${SETTINGS_SRC} -> ${THEME_DIR}/Components/Settings.qml"
  run "install -m 0644 '${SETTINGS_SRC}' '${THEME_DIR}/Components/Settings.qml'"
else
  log "Settings source not found: ${SETTINGS_SRC} (ok if not customized)"
fi

# ---------------------- Final checks ----------------------
if [[ -f "${THEME_DIR}/Backgrounds/current.jpg" ]]; then
  log "Wallpaper present: ${THEME_DIR}/Backgrounds/current.jpg"
else
  log "Wallpaper NOT present at ${THEME_DIR}/Backgrounds/current.jpg"
fi
if [[ -f "${THEME_DIR}/Components/Colors.qml" ]]; then
  log "Colors.qml present"
else
  log "Colors.qml not present (ok if not using Matugen)"
fi
if [[ -f "${THEME_DIR}/Components/Settings.qml" ]]; then
  log "Settings.qml present"
else
  log "Settings.qml not present (default will be used)"
fi

log "Done."
exit 0

