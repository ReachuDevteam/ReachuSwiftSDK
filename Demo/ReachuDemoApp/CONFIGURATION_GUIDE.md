# 🎨 ReachuDemoApp Configuration Guide

## Overview

ReachuDemoApp uses the Reachu SDK configuration system that allows you to customize the app's appearance, behavior, and features through a JSON configuration file.

## Configuration File

**Location:** `ReachuDemoApp/Configuration/reachu-config.json`

This is the **main configuration file** that the app loads on startup.

### Alternative Configurations

The `Configuration/` folder contains several example configurations you can use as reference:

| File | Description |
|------|-------------|
| `reachu-config.json` | **Main config** - Used by the app |
| `reachu-config-example.json` | Complete example with all options |
| `reachu-config-automatic.json` | Automatic theme switching |
| `reachu-config-dark-streaming.json` | Dark theme optimized for streaming |
| `reachu-config-brand-example.json` | Brand customization example |
| `reachu-config-starter.json` | Minimal starter configuration |

## How Configuration Works

### 1. App Initialization

In `ReachuDemoAppApp.swift`:

```swift
init() {
    // Loads reachu-config.json from the Configuration folder
    ConfigurationLoader.loadConfiguration()
    
    // Configuration is now available globally
    ReachuConfiguration.shared.theme.name
    ReachuConfiguration.shared.cartConfiguration.floatingCartDisplayMode
    // etc.
}
```

### 2. SDK Components Use Configuration

All Reachu SDK components automatically read from `ReachuConfiguration.shared`:

```swift
// Example: Cart indicator reads its display settings from config
RFloatingCartIndicator()
// Automatically uses:
// - floatingCartDisplayMode from config
// - floatingCartSize from config
// - floatingCartPosition from config
// - Theme colors from config
```

## Key Configuration Sections

### 🎨 Theme Configuration

```json
"theme": {
  "name": "Reachu Demo Theme",
  "mode": "automatic",  // "light", "dark", or "automatic"
  "lightColors": {
    "primary": "#007AFF",
    "secondary": "#5856D6"
    // ... more colors
  },
  "darkColors": {
    "primary": "#0A84FF",
    "secondary": "#5E5CE6"
    // ... more colors
  }
}
```

**Theme modes:**
- `"light"` - Always use light theme
- `"dark"` - Always use dark theme
- `"automatic"` - Follow system settings

### 🛒 Cart Configuration

```json
"cart": {
  "floatingCartPosition": "bottomRight",
  "floatingCartDisplayMode": "compact",
  "floatingCartSize": "medium",
  "autoSaveCart": true,
  "showCartNotifications": true
}
```

**Display Modes:**
- `"iconOnly"` - Circle icon with badge only (smallest)
- `"minimal"` - Icon + item count
- `"compact"` - Icon + item count + price (recommended)
- `"full"` - Icon + item count + price + arrow (complete)

**Sizes:**
- `"small"` - Compact size
- `"medium"` - Standard size (recommended)
- `"large"` - Large size for better visibility

**Positions:**
- `"topLeft"`, `"topCenter"`, `"topRight"`
- `"centerLeft"`, `"centerRight"`
- `"bottomLeft"`, `"bottomCenter"`, `"bottomRight"`

### 🎭 UI Configuration

```json
"ui": {
  "showProductBrands": true,
  "showProductDescriptions": true,
  "enableAnimations": true,
  "enableHapticFeedback": true,
  "imageQuality": "high"
}
```

### 🌐 Network Configuration

```json
"network": {
  "timeout": 30.0,
  "retryAttempts": 3,
  "enableCaching": true,
  "enableLogging": true,
  "logLevel": "debug"
}
```

**Log Levels:**
- `"error"` - Only errors
- `"warning"` - Warnings and errors
- `"info"` - General information
- `"debug"` - Detailed debugging info

### 📺 Live Show Configuration

```json
"liveShow": {
  "autoJoinChat": true,
  "enableEmojis": true,
  "enableShoppingDuringStream": true,
  "videoQuality": "auto"
}
```

## Customization Examples

### Example 1: Dark Mode Only

```json
{
  "theme": {
    "name": "Dark Theme",
    "mode": "dark",
    "darkColors": {
      "primary": "#00D4FF",
      "secondary": "#FF00D4",
      "background": "#000000",
      "surface": "#1A1A1A"
    }
  }
}
```

### Example 2: Minimal Cart Icon

```json
{
  "cart": {
    "floatingCartPosition": "topRight",
    "floatingCartDisplayMode": "iconOnly",
    "floatingCartSize": "small"
  }
}
```

### Example 3: Brand Colors

```json
{
  "theme": {
    "lightColors": {
      "primary": "#FF6B6B",      // Brand red
      "secondary": "#4ECDC4",    // Brand teal
      "background": "#FFF8F0"    // Warm white
    }
  }
}
```

## Testing Configuration Changes

### Method 1: Edit and Rebuild

1. Edit `reachu-config.json`
2. Clean build folder (⌘⇧K)
3. Run app (⌘R)
4. Check console logs:
   ```
   🚀 [ReachuDemoApp] Loading Reachu SDK configuration...
   ✅ [ReachuDemoApp] Reachu SDK configured successfully
   🎨 [ReachuDemoApp] Theme: Reachu Demo Theme
   🎨 [ReachuDemoApp] Mode: automatic
   🛒 [ReachuDemoApp] Cart Display: compact
   ```

### Method 2: Swap Configurations

```bash
# Backup current config
cp Configuration/reachu-config.json Configuration/reachu-config-backup.json

# Try a different config
cp Configuration/reachu-config-dark-streaming.json Configuration/reachu-config.json

# Rebuild and run
```

## Troubleshooting

### Configuration not loading?

**Check console logs:**
```
❌ Failed to load configuration: ...
```

**Common issues:**
1. **Invalid JSON syntax** - Use a JSON validator
2. **File not in bundle** - Check Target Membership in Xcode
3. **Wrong file name** - Must be exactly `reachu-config.json`

### Colors not applying?

**Verify theme mode:**
```json
{
  "theme": {
    "mode": "automatic",  // Change to "light" or "dark" to force
    // ...
  }
}
```

**Check if colors are valid hex:**
```json
"primary": "#007AFF",  ✅ Correct
"primary": "007AFF",   ❌ Missing #
"primary": "#GGG",     ❌ Invalid hex
```

### Cart indicator not showing?

**Check cart configuration:**
```json
{
  "cart": {
    "floatingCartDisplayMode": "compact",  // Not "iconOnly" if you want full display
    "floatingCartSize": "medium"           // Not "small" if barely visible
  }
}
```

## Best Practices

1. **Always validate JSON** before committing changes
2. **Keep a backup** of working configurations
3. **Use meaningful names** for custom color schemes
4. **Test in both light and dark modes** if using automatic theme
5. **Check console logs** for configuration load status
6. **Clean build** after configuration changes

## Integration with SDK Components

### Components that use configuration:

- ✅ `RFloatingCartIndicator` - Position, display mode, size, colors
- ✅ `RProductCard` - Animations, shadows, typography
- ✅ `RProductSlider` - Layout, spacing, animations
- ✅ `RCheckoutOverlay` - Theme colors, shadows
- ✅ `RLiveShowOverlay` - Live show settings, chat config
- ✅ All design system components - Colors, typography, spacing

### Custom configuration in code:

You can override configuration per-component:

```swift
// Uses config by default
RFloatingCartIndicator()

// Or override specific properties
RFloatingCartIndicator(
    position: .topRight,           // Override position
    displayMode: .minimal,         // Override display mode
    customPadding: EdgeInsets(...)  // Custom positioning
)
```

## Related Documentation

- `CONFIG_SWITCHING_GUIDE.md` - How to switch between configurations
- `ENVIRONMENT_SETUP.md` - Environment-specific settings
- `README.md` - General configuration overview

## Support

For issues or questions about configuration:
1. Check console logs for errors
2. Validate JSON syntax
3. Review example configurations
4. Test with minimal starter config

