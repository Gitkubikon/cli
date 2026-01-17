# SDDM Theme Integration for Caelestia

This document describes how Caelestia integrates with the ii-sddm-theme to provide automatic wallpaper and color scheme synchronization for your SDDM login screen.

## Overview

Caelestia uses a custom integration with [ii-sddm-theme](https://github.com/3d3f/ii-sddm-theme) that automatically updates your SDDM login screen whenever you change your wallpaper. The theme uses Material You color generation to extract colors from your wallpaper and create a cohesive, beautiful login experience.

### Features

- **Automatic Wallpaper Sync**: Your SDDM login screen uses the same wallpaper as your desktop
- **Material You Colors**: Colors are automatically extracted from your wallpaper using Caelestia's color generation
- **Seamless Integration**: Works with the existing `caelestia wallpaper` command
- **Lockscreen Aesthetic**: Replicates the illogical-impulse lockscreen design

## How It Works

```
┌─────────────────────────────────────────────────────────────┐
│  caelestia wallpaper --file /path/to/image.jpg              │
└─────────────────────────┬───────────────────────────────────┘
                          │
                          ├─ Extract colors from wallpaper
                          ├─ Generate Material You palette
                          ├─ Update Hyprland theme
                          ├─ Update application themes
                          │
                          └─ Run postHook (SDDM integration)
                             │
                             ├─ Read Caelestia scheme.json
                             ├─ Generate Colors.qml
                             ├─ Generate Settings.qml (if needed)
                             └─ Call sddm-theme-apply.sh
                                │
                                ├─ Copy wallpaper to SDDM theme
                                ├─ Copy Colors.qml to theme
                                ├─ Copy Settings.qml to theme
                                └─ ✓ SDDM theme updated!
```

## Installation

### Prerequisites

Required packages:
- `sddm` - The display manager
- `qt6-svg` - SVG support for Qt6
- `qt6-virtualkeyboard` - Virtual keyboard for SDDM
- `qt6-multimedia-ffmpeg` - Multimedia support

Install missing packages:
```bash
sudo pacman -S qt6-virtualkeyboard
```

### Automated Setup

Run the setup script from the Caelestia repository:

```bash
cd /path/to/Caelestia/cli/hooks
./setup-sddm-integration.sh
```

This will:
1. Create `~/.config/ii-sddm-theme/` directory
2. Symlink the hook scripts
3. Update `~/.config/caelestia/cli.json` to enable the postHook
4. Test color generation
5. Check sudo configuration

### Manual Setup

If you prefer manual installation:

1. **Create config directory and symlink scripts:**
   ```bash
   mkdir -p ~/.config/ii-sddm-theme
   ln -sf ~/Projects/Caelestia/cli/hooks/caelestia-sddm-hook.sh ~/.config/ii-sddm-theme/caelestia-hook.sh
   ln -sf ~/Projects/Caelestia/cli/hooks/sddm-theme-apply.sh ~/.config/ii-sddm-theme/sddm-theme-apply.sh
   ln -sf ~/Projects/Caelestia/cli/hooks/generate-sddm-colors.py ~/.config/ii-sddm-theme/generate-sddm-colors.py
   ln -sf ~/Projects/Caelestia/cli/hooks/generate-sddm-settings.py ~/.config/ii-sddm-theme/generate-sddm-settings.py
   chmod +x ~/.config/ii-sddm-theme/*.sh
   chmod +x ~/.config/ii-sddm-theme/*.py
   ```

2. **Update Caelestia CLI configuration:**
   
   Edit `~/.config/caelestia/cli.json`:
   ```json
   {
     "wallpaper": {
       "postHook": "~/.config/ii-sddm-theme/caelestia-hook.sh \"$WALLPAPER_PATH\""
     }
   }
   ```

3. **Install ii-sddm-theme:**
   ```bash
   # Clone the theme repository
   git clone --depth=1 https://github.com/3d3f/ii-sddm-theme /tmp/ii-sddm-theme
   cd /tmp/ii-sddm-theme
   
   # Install theme files
   sudo mkdir -p /usr/share/sddm/themes/ii-sddm-theme
   sudo cp -rf Assets Components Backgrounds Themes fonts Main.qml metadata.desktop \
     /usr/share/sddm/themes/ii-sddm-theme/
   
   # Install fonts
   sudo cp -r fonts/ii-sddm-theme-fonts /usr/share/fonts/
   sudo fc-cache -f
   ```

4. **Configure SDDM:**
   
   Create or edit `/etc/sddm.conf`:
   ```ini
   [General]
   InputMethod=qtvirtualkeyboard
   GreeterEnvironment=QML2_IMPORT_PATH=/usr/share/sddm/themes/ii-sddm-theme/Components/,QT_IM_MODULE=qtvirtualkeyboard
   
   [Theme]
   Current=ii-sddm-theme
   ```

5. **Configure passwordless sudo:**
   ```bash
   echo "$USER ALL=(ALL) NOPASSWD: $HOME/.config/ii-sddm-theme/sddm-theme-apply.sh" | \
     sudo tee /etc/sudoers.d/caelestia-sddm
   sudo chmod 0440 /etc/sudoers.d/caelestia-sddm
   ```

6. **Generate initial theme files:**
   ```bash
   python3 ~/.config/ii-sddm-theme/generate-sddm-colors.py > ~/.config/ii-sddm-theme/Colors.qml
   python3 ~/.config/ii-sddm-theme/generate-sddm-settings.py > ~/.config/ii-sddm-theme/Settings.qml
   ```

7. **Apply current wallpaper:**
   ```bash
   sudo ~/.config/ii-sddm-theme/sddm-theme-apply.sh -v "$(caelestia wallpaper)"
   ```

## Usage

Once installed, the integration works automatically:

```bash
# Change wallpaper (automatically updates SDDM)
caelestia wallpaper --file ~/Pictures/sunset.jpg

# Random wallpaper from directory (automatically updates SDDM)
caelestia wallpaper --random ~/Pictures/Wallpapers/

# The SDDM theme will update automatically in the background
```

## Configuration Files

### ~/.config/ii-sddm-theme/

This directory contains all SDDM integration files:

- **`caelestia-hook.sh`** - Main hook script called by Caelestia
- **`sddm-theme-apply.sh`** - Applies changes to the SDDM theme (requires sudo)
- **`generate-sddm-colors.py`** - Generates Colors.qml from Caelestia's scheme
- **`generate-sddm-settings.py`** - Generates Settings.qml with UI preferences
- **`Colors.qml`** - Generated color definitions for SDDM theme
- **`Settings.qml`** - UI/behavior settings for SDDM theme
- **`hook.log`** - Log file for hook execution
- **`apply.log`** - Log file for theme application

### ~/.config/caelestia/cli.json

Contains the wallpaper postHook configuration:

```json
{
  "wallpaper": {
    "postHook": "~/.config/ii-sddm-theme/caelestia-hook.sh \"$WALLPAPER_PATH\""
  }
}
```

### /etc/sddm.conf

SDDM configuration:

```ini
[General]
InputMethod=qtvirtualkeyboard
GreeterEnvironment=QML2_IMPORT_PATH=/usr/share/sddm/themes/ii-sddm-theme/Components/,QT_IM_MODULE=qtvirtualkeyboard

[Theme]
Current=ii-sddm-theme
```

## Customization

### Settings.qml

Edit `~/.config/ii-sddm-theme/Settings.qml` to customize the theme appearance:

```qml
QtObject {
    property string time_format: "h:mm ap"              // Time format
    property string background_clock_style: "digital"    // "none", "digital", "cookie"
    property string background_quote: "Welcome!"         // Custom message
    property bool background_showQuote: true             // Show/hide quote
    property bool lock_blur_enable: false                // Blur background
    property bool time_secondPrecision: true             // Show seconds
    property bool lock_materialShapeChars: true          // Material design input
}
```

After editing, regenerate the theme:

```bash
sudo ~/.config/ii-sddm-theme/sddm-theme-apply.sh -v "$(caelestia wallpaper)"
```

### Color Scheme

Colors are automatically generated from Caelestia's Material You palette at:
`~/.local/state/caelestia/scheme.json`

The color mapping is handled in `generate-sddm-colors.py` and includes:
- Primary, Secondary, Tertiary colors
- Surface colors with various elevation levels
- Error colors
- All Material You color roles

## Testing

Test the theme without logging out:

```bash
# Test mode (requires qt6-virtualkeyboard)
sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/ii-sddm-theme
```

## Troubleshooting

### Check logs

```bash
# Hook execution log
cat ~/.config/ii-sddm-theme/hook.log

# Theme application log
cat ~/.config/ii-sddm-theme/apply.log
```

### Manually trigger update

```bash
# Run the hook manually
~/.config/ii-sddm-theme/caelestia-hook.sh "$(caelestia wallpaper)"

# Or apply directly with sudo
sudo ~/.config/ii-sddm-theme/sddm-theme-apply.sh -v "$(caelestia wallpaper)"
```

### Verify files

```bash
# Check if theme files exist
ls -la /usr/share/sddm/themes/ii-sddm-theme/

# Check wallpaper
ls -la /usr/share/sddm/themes/ii-sddm-theme/Backgrounds/

# Check QML files
ls -la /usr/share/sddm/themes/ii-sddm-theme/Components/{Colors,Settings}.qml
```

### Common Issues

**"No wallpaper path provided"**
- Make sure the postHook is configured in `~/.config/caelestia/cli.json`
- Check that `$WALLPAPER_PATH` is being passed correctly

**"Caelestia scheme not found"**
- Run `caelestia wallpaper --file /path/to/image.jpg` to generate a scheme
- Verify `~/.local/state/caelestia/scheme.json` exists

**"Permission denied"**
- Check sudo configuration: `sudo visudo -f /etc/sudoers.d/caelestia-sddm`
- Should contain: `nikita ALL=(ALL) NOPASSWD: /home/nikita/.config/ii-sddm-theme/sddm-theme-apply.sh`

**Theme not showing on login screen**
- Verify SDDM configuration: `cat /etc/sddm.conf`
- Restart SDDM: `sudo systemctl restart sddm` (will log you out!)
- Check SDDM logs: `journalctl -u sddm -b`

**Colors don't match desktop**
- Regenerate colors: `python3 ~/.config/ii-sddm-theme/generate-sddm-colors.py > ~/.config/ii-sddm-theme/Colors.qml`
- Apply theme: `sudo ~/.config/ii-sddm-theme/sddm-theme-apply.sh -v "$(caelestia wallpaper)"`

## File Structure

```
~/.config/ii-sddm-theme/
├── caelestia-hook.sh          → symlink to Caelestia/cli/hooks/caelestia-sddm-hook.sh
├── sddm-theme-apply.sh        → symlink to Caelestia/cli/hooks/sddm-theme-apply.sh
├── generate-sddm-colors.py    → symlink to Caelestia/cli/hooks/generate-sddm-colors.py
├── generate-sddm-settings.py  → symlink to Caelestia/cli/hooks/generate-sddm-settings.py
├── Colors.qml                 → Generated from Caelestia scheme
├── Settings.qml               → UI/behavior settings
├── hook.log                   → Hook execution logs
└── apply.log                  → Theme application logs

/usr/share/sddm/themes/ii-sddm-theme/
├── Assets/                    → Theme assets
├── Backgrounds/
│   └── background.png         → Current wallpaper (copied from user)
├── Components/
│   ├── Colors.qml             → Color scheme (synced from ~/.config)
│   ├── Settings.qml           → Theme settings (synced from ~/.config)
│   └── ...                    → Other QML components
├── Themes/
│   └── ii-sddm.conf           → Theme configuration
├── fonts/                     → Theme fonts
├── Main.qml                   → Main theme entry point
└── metadata.desktop           → Theme metadata
```

## Technical Details

### Color Generation

The `generate-sddm-colors.py` script reads Caelestia's Material You color palette from `~/.local/state/caelestia/scheme.json` and converts it to QML format with all the derived color properties expected by ii-sddm-theme.

Color mapping includes:
- All Material You surface colors (background, surface, surface variants)
- Primary, secondary, tertiary color roles
- State colors (hover, active, disabled)
- Layer colors (layer0-4 with transparency)
- Special colors (tooltip, scrim, shadow, outline)

### Hook Execution Flow

1. User runs: `caelestia wallpaper --file image.jpg`
2. Caelestia processes wallpaper and updates scheme
3. Caelestia calls postHook with `$WALLPAPER_PATH` environment variable
4. `caelestia-hook.sh` receives wallpaper path
5. Hook generates `Colors.qml` from current Caelestia scheme
6. Hook generates `Settings.qml` (if doesn't exist)
7. Hook calls `sddm-theme-apply.sh` with sudo
8. Apply script copies wallpaper to SDDM theme directory
9. Apply script copies QML files to SDDM theme Components/
10. SDDM theme is updated and ready for next login

### Security Considerations

The `sddm-theme-apply.sh` script requires sudo because it writes to `/usr/share/sddm/themes/`. To avoid password prompts on every wallpaper change, passwordless sudo is configured for this specific script only via `/etc/sudoers.d/caelestia-sddm`.

This is safe because:
- Only one specific script can run without password
- The script validates all inputs
- The script only writes to the SDDM theme directory
- User can review the script source code

## Uninstallation

To remove the SDDM integration:

```bash
# Remove theme files
sudo rm -rf /usr/share/sddm/themes/ii-sddm-theme
sudo rm -rf /usr/share/fonts/ii-sddm-theme-fonts

# Remove configuration
rm -rf ~/.config/ii-sddm-theme

# Remove sudo permissions
sudo rm -f /etc/sudoers.d/caelestia-sddm

# Remove postHook from cli.json
# Edit ~/.config/caelestia/cli.json and remove the wallpaper.postHook line

# Restore default SDDM theme
sudo nano /etc/sddm.conf
# Change Current= to another theme or remove the [Theme] section
```

## Credits

- **[ii-sddm-theme](https://github.com/3d3f/ii-sddm-theme)** - The SDDM theme used by this integration
- **[illogical impulse](https://github.com/end-4/dots-hyprland)** - Original lockscreen design inspiration
- **Caelestia** - Material You color generation and theming system

## See Also

- [Caelestia CLI README](../README.md)
- [ii-sddm-theme Repository](https://github.com/3d3f/ii-sddm-theme)
- [SDDM Documentation](https://github.com/sddm/sddm)
