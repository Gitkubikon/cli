#!/usr/bin/env bash
# Caelestia wallpaper + SDDM theme integration hook
# This script updates both the wallpaper and color scheme for ii-sddm-theme

set -euo pipefail

# Configuration
SDDM_CONFIG_DIR="${HOME}/.config/ii-sddm-theme"
LOG_FILE="${SDDM_CONFIG_DIR}/hook.log"
COLORS_QML="${SDDM_CONFIG_DIR}/Colors.qml"
SETTINGS_QML="${SDDM_CONFIG_DIR}/Settings.qml"
COLORS_GENERATOR="${SDDM_CONFIG_DIR}/generate-sddm-colors.py"
SETTINGS_GENERATOR="${SDDM_CONFIG_DIR}/generate-sddm-settings.py"
APPLY_SCRIPT="${SDDM_CONFIG_DIR}/sddm-theme-apply.sh"

# Logging
mkdir -p "$(dirname "$LOG_FILE")"
{
  echo "==== $(date '+%F %T') ===="
  echo "Caelestia SDDM Hook Started"
  echo "Wallpaper: ${1:-<none>}"
  echo "WALLPAPER_PATH env: ${WALLPAPER_PATH:-<not set>}"
} >> "$LOG_FILE"

# Determine wallpaper path
WALL_PATH="${1:-${WALLPAPER_PATH:-}}"

if [[ -z "${WALL_PATH}" ]]; then
  echo "ERROR: No wallpaper path provided" | tee -a "$LOG_FILE"
  exit 1
fi

# Normalize path (handle file:// URIs)
WALL_PATH="${WALL_PATH#file://}"

if [[ ! -f "${WALL_PATH}" ]]; then
  echo "ERROR: Wallpaper file not found: ${WALL_PATH}" | tee -a "$LOG_FILE"
  exit 1
fi

echo "Using wallpaper: ${WALL_PATH}" >> "$LOG_FILE"

# Generate Colors.qml from Caelestia's current scheme
echo "Generating Colors.qml..." >> "$LOG_FILE"
if [[ -x "${COLORS_GENERATOR}" ]]; then
  if python3 "${COLORS_GENERATOR}" > "${COLORS_QML}.tmp" 2>> "$LOG_FILE"; then
    mv "${COLORS_QML}.tmp" "${COLORS_QML}"
    echo "Colors.qml generated successfully" >> "$LOG_FILE"
  else
    echo "ERROR: Failed to generate Colors.qml" | tee -a "$LOG_FILE"
    rm -f "${COLORS_QML}.tmp"
    # Continue anyway - wallpaper will still be updated
  fi
else
  echo "WARNING: Colors generator not found or not executable: ${COLORS_GENERATOR}" >> "$LOG_FILE"
fi

# Generate Settings.qml if it doesn't exist
if [[ ! -f "${SETTINGS_QML}" ]]; then
  echo "Generating Settings.qml (first time)..." >> "$LOG_FILE"
  if [[ -x "${SETTINGS_GENERATOR}" ]]; then
    if python3 "${SETTINGS_GENERATOR}" > "${SETTINGS_QML}.tmp" 2>> "$LOG_FILE"; then
      mv "${SETTINGS_QML}.tmp" "${SETTINGS_QML}"
      echo "Settings.qml generated successfully" >> "$LOG_FILE"
    else
      echo "WARNING: Failed to generate Settings.qml" >> "$LOG_FILE"
      rm -f "${SETTINGS_QML}.tmp"
    fi
  else
    echo "WARNING: Settings generator not found: ${SETTINGS_GENERATOR}" >> "$LOG_FILE"
  fi
fi

# Call the SDDM apply script with sudo
echo "Applying changes to SDDM theme..." >> "$LOG_FILE"
if [[ -x "${APPLY_SCRIPT}" ]]; then
  if command -v sudo >/dev/null 2>&1; then
    sudo "${APPLY_SCRIPT}" -v "${WALL_PATH}" 2>> "$LOG_FILE"
    echo "SDDM theme updated successfully" >> "$LOG_FILE"
  else
    "${APPLY_SCRIPT}" -v "${WALL_PATH}" 2>> "$LOG_FILE"
    echo "SDDM theme updated (without sudo)" >> "$LOG_FILE"
  fi
else
  echo "ERROR: Apply script not found or not executable: ${APPLY_SCRIPT}" | tee -a "$LOG_FILE"
  exit 1
fi

echo "Hook completed successfully" >> "$LOG_FILE"
exit 0
