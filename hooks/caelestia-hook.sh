#!/usr/bin/env bash
# Caelestia wallpaper postHook wrapper
# Save as: ~/.config/ii-sddm-theme/caelestia-hook.sh
# Purpose: log what Caelestia passes, then call the SDDM apply script.

set -euo pipefail

LOG="$HOME/.config/ii-sddm-theme/hook.log"
mkdir -p "$(dirname "$LOG")"
{
  echo "---- $(date '+%F %T') ----"
  echo "argv[1]: ${1-}"
  echo "USER=$USER HOME=$HOME SHELL=$SHELL"
  env | sort | sed 's/^/ENV: /'
} >> "$LOG"

# Normalize arg (handle file:// URIs and directories)
RAW="${1-}"
WALL="${RAW#file://}"
if [[ -n "${WALL}" && -d "${WALL}" ]]; then
  CANDIDATE=$(ls -1t -- "$WALL"/*.{jpg,jpeg,png,webp,avif,JPG,JPEG,PNG,WEBP,AVIF} 2>/dev/null | head -n1 || true)
  if [[ -n "${CANDIDATE}" ]]; then
    WALL="${CANDIDATE}"
  fi
fi

# Call the apply script (NOPASSWD sudo recommended in /etc/sudoers.d)
if command -v sudo >/dev/null 2>&1; then
  sudo "$HOME/.config/ii-sddm-theme/sddm-theme-apply.sh" -v "${WALL:-}"
else
  "$HOME/.config/ii-sddm-theme/sddm-theme-apply.sh" -v "${WALL:-}"
fi

exit 0

