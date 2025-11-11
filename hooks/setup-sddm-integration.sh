#!/usr/bin/env bash
# Setup script for Caelestia SDDM integration
# This script links the hook scripts to the user's config directory

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SDDM_CONFIG_DIR="${HOME}/.config/ii-sddm-theme"
CLI_CONFIG="${HOME}/.config/caelestia/cli.json"

echo "Setting up Caelestia SDDM integration..."

# Create SDDM config directory if it doesn't exist
mkdir -p "${SDDM_CONFIG_DIR}"

# Link or copy scripts to SDDM config directory
echo "Installing hook scripts..."
ln -sf "${SCRIPT_DIR}/caelestia-sddm-hook.sh" "${SDDM_CONFIG_DIR}/caelestia-hook.sh"
ln -sf "${SCRIPT_DIR}/sddm-theme-apply.sh" "${SDDM_CONFIG_DIR}/sddm-theme-apply.sh"
ln -sf "${SCRIPT_DIR}/generate-sddm-colors.py" "${SDDM_CONFIG_DIR}/generate-sddm-colors.py"
ln -sf "${SCRIPT_DIR}/generate-sddm-settings.py" "${SDDM_CONFIG_DIR}/generate-sddm-settings.py"

echo "Scripts installed to ${SDDM_CONFIG_DIR}"

# Update cli.json to use the hook
if [[ -f "${CLI_CONFIG}" ]]; then
  echo "Updating ${CLI_CONFIG}..."
  
  # Check if jq is available for JSON manipulation
  if command -v jq >/dev/null 2>&1; then
    # Use jq to update the config
    TMP_FILE=$(mktemp)
    jq '.wallpaper.postHook = "'"${SDDM_CONFIG_DIR}/caelestia-hook.sh"' \"$WALLPAPER_PATH\""' \
      "${CLI_CONFIG}" > "${TMP_FILE}"
    mv "${TMP_FILE}" "${CLI_CONFIG}"
    echo "Configuration updated successfully"
  else
    echo "WARNING: jq not found. Please manually update ${CLI_CONFIG}"
    echo "Set wallpaper.postHook to: ${SDDM_CONFIG_DIR}/caelestia-hook.sh \"\$WALLPAPER_PATH\""
  fi
else
  echo "Creating ${CLI_CONFIG}..."
  mkdir -p "$(dirname "${CLI_CONFIG}")"
  cat > "${CLI_CONFIG}" <<EOF
{
  "wallpaper": {
    "postHook": "${SDDM_CONFIG_DIR}/caelestia-hook.sh \"\$WALLPAPER_PATH\""
  }
}
EOF
  echo "Configuration created"
fi

# Test if Colors.qml can be generated
echo ""
echo "Testing Colors.qml generation..."
if python3 "${SCRIPT_DIR}/generate-sddm-colors.py" > /dev/null 2>&1; then
  echo "✓ Colors.qml generation test passed"
else
  echo "✗ Colors.qml generation test failed"
  echo "  Make sure Caelestia has generated a scheme at ~/.local/state/caelestia/scheme.json"
fi

# Check sudo permissions
echo ""
echo "Checking sudo configuration..."
if sudo -n "${SDDM_CONFIG_DIR}/sddm-theme-apply.sh" --help >/dev/null 2>&1; then
  echo "✓ Sudo is configured for passwordless execution"
else
  echo "⚠ Sudo may require a password"
  echo ""
  echo "For automatic updates without password prompts, add this to /etc/sudoers.d/caelestia-sddm:"
  echo "  ${USER} ALL=(ALL) NOPASSWD: ${SDDM_CONFIG_DIR}/sddm-theme-apply.sh"
  echo ""
  echo "You can do this by running:"
  echo "  echo '${USER} ALL=(ALL) NOPASSWD: ${SDDM_CONFIG_DIR}/sddm-theme-apply.sh' | sudo tee /etc/sudoers.d/caelestia-sddm"
  echo "  sudo chmod 0440 /etc/sudoers.d/caelestia-sddm"
fi

echo ""
echo "Setup complete!"
echo ""
echo "Test the integration by changing your wallpaper:"
echo "  caelestia wallpaper --file /path/to/image.jpg"
echo ""
echo "Check the logs at: ${SDDM_CONFIG_DIR}/hook.log"
