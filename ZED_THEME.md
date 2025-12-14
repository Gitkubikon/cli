# Caelestia Theme for Zed Editor

The Caelestia theme system now supports the Zed editor! Your wallpaper-based color scheme will automatically sync to Zed just like it does for VS Code, Discord, terminals, and other applications.

## Features

- **Automatic Color Generation**: Theme colors are dynamically generated from your wallpaper using Material You color system
- **Consistent Theming**: Matches your entire Caelestia environment (shell, terminal, applications)
- **Full Zed Support**: Includes syntax highlighting, UI elements, terminal colors, and all Zed theme features
- **Easy Integration**: Automatically installs when you change wallpapers or schemes

## Installation

The theme is automatically generated and installed to `~/.config/zed/themes/caelestia.json` when you:

1. Change your wallpaper using Caelestia
2. Switch color schemes
3. Update your theme variant

## Manual Installation

If you need to reinstall or update manually:

```bash
# The theme will be generated when you run:
caelestia wallpaper <path-to-wallpaper>

# Or when you switch schemes:
caelestia scheme <scheme-name>
```

## Activating the Theme in Zed

1. Open Zed editor
2. Open the command palette (`Cmd+Shift+P` on macOS, `Ctrl+Shift+P` on Linux)
3. Type "theme" and select "theme selector: toggle"
4. Search for "Caelestia" and select it

Or edit your `~/.config/zed/settings.json`:

```json
{
  "theme": "Caelestia"
}
```

For automatic light/dark mode switching:

```json
{
  "theme": {
    "mode": "system",
    "light": "Caelestia",
    "dark": "Caelestia"
  }
}
```

## Configuration

Enable or disable Zed theme generation in `~/.config/caelestia/config.json`:

```json
{
  "theme": {
    "enableZed": true
  }
}
```

By default, Zed theming is enabled.

## Theme Structure

The Caelestia Zed theme includes:

- **UI Colors**: Background, surfaces, borders, buttons, and all interface elements
- **Syntax Highlighting**: Keywords, strings, comments, functions, types, and more
- **Terminal Colors**: Full 16-color ANSI palette integration
- **Editor Features**: Line numbers, gutters, selection, search highlights
- **Status Colors**: Success, error, warning, info states
- **Player Colors**: Collaborative editing cursor colors

## Customization

The theme automatically adapts to your chosen:

- **Wallpaper**: Primary colors extracted from your background
- **Scheme Variant**: Tonal Spot, Vibrant, Expressive, Content, Fidelity, Monochrome, Neutral, Fruitsalad, Rainbow
- **Light/Dark Mode**: Automatically adjusts tone and contrast

## Technical Details

### Theme Location
- Generated from template: `src/caelestia/data/templates/zed.json`
- Installed to: `~/.config/zed/themes/caelestia.json`

### Color Mapping
The theme uses Material Design 3 color tokens:
- Primary, Secondary, Tertiary color roles
- Surface and background variants
- Error, success, warning states
- 16-color terminal palette

### Syntax Highlighting
Based on Tree-sitter semantic highlighting with carefully chosen colors:
- Keywords: Magenta (term13)
- Functions: Blue (term12)
- Strings: Green (term10)
- Comments: Muted outline color
- Types: Yellow (term11)
- And many more...

## Troubleshooting

### Theme not appearing in Zed
1. Check that the file exists: `ls ~/.config/zed/themes/caelestia.json`
2. Verify JSON is valid: `jq . ~/.config/zed/themes/caelestia.json`
3. Restart Zed editor
4. Regenerate theme: `caelestia wallpaper <your-wallpaper>`

### Colors don't match other applications
The theme should automatically update when you change wallpapers. If colors are out of sync:
```bash
caelestia wallpaper <path-to-current-wallpaper>
```

### Theme looks wrong
Make sure you're using a recent version of Zed (v0.120.0+) that supports the v0.2.0 theme schema.

## Related

- [Zed Theme Documentation](https://zed.dev/docs/extensions/themes)
- [Zed Theme Schema](https://zed.dev/schema/themes/v0.2.0.json)
- [Material Design 3 Colors](https://m3.material.io/styles/color/overview)

## Example

Here's what happens when you change your wallpaper:

```bash
# Set a new wallpaper
caelestia wallpaper ~/Pictures/sunset.jpg

# This automatically:
# 1. Extracts primary colors from the image
# 2. Generates Material You color palette
# 3. Creates themes for all applications including Zed
# 4. Installs to ~/.config/zed/themes/caelestia.json
# 5. Theme is immediately available in Zed's theme selector
```

Enjoy your beautifully themed Zed editor! 🎨
