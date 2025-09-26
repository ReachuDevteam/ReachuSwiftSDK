# 🎨 Theme Configuration System - Complete Guide

## 🎯 **How Theme Configuration Works**

### **🔄 Three Configuration Modes**

#### **1. Automatic Mode (Recommended)**
```json
{
  "theme": {
    "mode": "automatic",
    // SDK provides intelligent defaults + your custom overrides
    "lightColors": {
      "primary": "#007AFF"      // ← Your brand color
      // background, surface, text → SDK defaults
    },
    "darkColors": {
      "primary": "#0066FF",     // ← Your brand color (darker)
      "background": "#000000"   // ← Your custom background
      // surface, text → SDK defaults
    }
  }
}
```

**Result:**
- **iOS Light Mode** → Uses lightColors (your primary + SDK defaults)
- **iOS Dark Mode** → Uses darkColors (your colors + SDK defaults)
- **Partial customization** → Only specify what you want to change

#### **2. Light Mode (Force Light)**
```json
{
  "theme": {
    "mode": "light",
    "lightColors": {
      "primary": "#FF6B35",     // ← Your orange brand
      "secondary": "#004E89"    // ← Your blue accent
      // background, surface, text → SDK light defaults
    }
  }
}
```

**Result:**
- **Always light theme** → Ignores iOS system setting
- **Your brand colors** → Primary/secondary custom
- **SDK defaults** → Background, surface, text optimized for light

#### **3. Dark Mode (Force Dark)**
```json
{
  "theme": {
    "mode": "dark",
    "darkColors": {
      "primary": "#0066FF",     // ← Streaming blue
      "background": "#000000",  // ← Pure black
      "surface": "#0D0D0F"      // ← Almost black
      // text colors → SDK dark defaults
    }
  }
}
```

**Result:**
- **Always dark theme** → Perfect for streaming apps
- **Your custom colors** → Background, surface, primary
- **SDK defaults** → Text colors optimized for dark

---

## 🏗️ **SDK Default Color Schemes**

### **📱 Light Mode Defaults (iOS Standard)**
```swift
public static let lightDefaults = ColorScheme(
    primary: Color(hex: "#007AFF"),           // iOS Blue
    secondary: Color(hex: "#5856D6"),         // iOS Purple
    success: Color(hex: "#34C759"),           // iOS Green
    warning: Color(hex: "#FF9500"),           // iOS Orange
    error: Color(hex: "#FF3B30"),             // iOS Red
    info: Color(hex: "#64D2FF"),              // iOS Light Blue
    background: Color(hex: "#F2F2F7"),        // iOS Light Gray
    surface: Color(hex: "#FFFFFF"),           // Pure White
    surfaceSecondary: Color(hex: "#F9F9F9"),  // Off White
    textPrimary: Color(hex: "#000000"),       // Black
    textSecondary: Color(hex: "#8E8E93"),     // iOS Gray
    textTertiary: Color(hex: "#C7C7CC"),      // Light Gray
    border: Color(hex: "#E5E5EA"),            // Light Border
    borderSecondary: Color(hex: "#D1D1D6")    // Lighter Border
)
```

### **🌙 Dark Mode Defaults (iOS Standard)**
```swift
public static let darkDefaults = ColorScheme(
    primary: Color(hex: "#0A84FF"),           // iOS Dark Blue
    secondary: Color(hex: "#5E5CE6"),         // iOS Dark Purple
    success: Color(hex: "#32D74B"),           // iOS Dark Green
    warning: Color(hex: "#FF9F0A"),           // iOS Dark Orange
    error: Color(hex: "#FF453A"),             // iOS Dark Red
    info: Color(hex: "#64D2FF"),              // iOS Dark Light Blue
    background: Color(hex: "#000000"),        // Pure Black
    surface: Color(hex: "#1C1C1E"),           // iOS Dark Gray
    surfaceSecondary: Color(hex: "#2C2C2E"),  // iOS Darker Gray
    textPrimary: Color(hex: "#FFFFFF"),       // White
    textSecondary: Color(hex: "#8E8E93"),     // iOS Dark Gray
    textTertiary: Color(hex: "#48484A"),      // Dark Gray
    border: Color(hex: "#38383A"),            // Dark Border
    borderSecondary: Color(hex: "#48484A")    // Darker Border
)
```

---

## ⚙️ **Configuration Logic**

### **🔄 Color Resolution Process**

```swift
// 1. Load JSON configuration
let config = loadFromJSON("reachu-config.json")

// 2. Create theme with smart defaults
func createTheme(from config: JSONThemeConfiguration) -> ReachuTheme {
    let mode = ThemeMode(rawValue: config.mode) ?? .automatic
    
    // 3. Build light colors (your overrides + SDK defaults)
    let lightColors = buildColorScheme(
        userColors: config.lightColors,
        defaults: ColorScheme.lightDefaults
    )
    
    // 4. Build dark colors (your overrides + SDK defaults)
    let darkColors = buildColorScheme(
        userColors: config.darkColors,
        defaults: ColorScheme.darkDefaults
    )
    
    return ReachuTheme(
        mode: mode,
        lightColors: lightColors,
        darkColors: darkColors
    )
}

// 5. Smart merge function
func buildColorScheme(
    userColors: JSONColorConfiguration?,
    defaults: ColorScheme
) -> ColorScheme {
    return ColorScheme(
        primary: userColors?.primary?.toColor() ?? defaults.primary,
        secondary: userColors?.secondary?.toColor() ?? defaults.secondary,
        background: userColors?.background?.toColor() ?? defaults.background,
        surface: userColors?.surface?.toColor() ?? defaults.surface,
        textPrimary: userColors?.textPrimary?.toColor() ?? defaults.textPrimary,
        // ... etc for all colors
    )
}
```

---

## 🎯 **Configuration Examples**

### **Example 1: Minimal Brand Override**
```json
{
  "theme": {
    "mode": "automatic",
    "lightColors": {
      "primary": "#FF6B35"      // ← Only your brand color
    },
    "darkColors": {
      "primary": "#FF8A5B"      // ← Slightly lighter for dark mode
    }
  }
}
```

**Result:**
- **Your brand primary** → Custom orange
- **Everything else** → SDK optimized defaults
- **Automatic switching** → iOS system preference

### **Example 2: Streaming App (Dark Focus)**
```json
{
  "theme": {
    "mode": "automatic",
    "lightColors": {
      "primary": "#007AFF",
      "background": "#F2F2F7"   // ← Light gray for light mode
    },
    "darkColors": {
      "primary": "#0066FF",
      "background": "#000000",  // ← Pure black for streaming
      "surface": "#0D0D0F"      // ← Almost black surface
    }
  }
}
```

**Result:**
- **Light mode** → Standard iOS with your primary
- **Dark mode** → Streaming-optimized black with your blue

### **Example 3: Force Brand Theme**
```json
{
  "theme": {
    "mode": "light",           // ← Always light
    "lightColors": {
      "primary": "#D4AF37",     // ← Gold
      "secondary": "#8B4513",   // ← Brown
      "background": "#FFFEF7",  // ← Cream
      "surface": "#FFFFFF"      // ← White
    }
  }
}
```

**Result:**
- **Always light** → Ignores iOS dark mode
- **Luxury brand** → Gold/brown/cream palette
- **Custom background** → Cream instead of default gray

---

## 🔧 **Implementation in SDK**

### **Current System Enhancement**

```swift
// Enhanced ConfigurationLoader
private static func createTheme(from config: JSONThemeConfiguration?) -> ReachuTheme {
    guard let config = config else { return .default }
    
    let mode = ThemeMode(rawValue: config.mode ?? "automatic") ?? .automatic
    
    // Smart color building with defaults
    let lightColors = buildColorScheme(
        userColors: config.lightColors,
        defaults: .lightDefaults  // ← SDK provides these
    )
    
    let darkColors = buildColorScheme(
        userColors: config.darkColors,
        defaults: .darkDefaults   // ← SDK provides these
    )
    
    return ReachuTheme(
        name: config.name ?? "Custom Theme",
        mode: mode,
        lightColors: lightColors,
        darkColors: darkColors
    )
}
```

### **Default Color Schemes**

```swift
// Add to ReachuCore/Configuration/DefaultColorSchemes.swift
extension ColorScheme {
    public static let lightDefaults = ColorScheme(
        primary: Color(hex: "#007AFF"),      // iOS Blue
        background: Color(hex: "#F2F2F7"),   // iOS Light Gray
        surface: Color(hex: "#FFFFFF"),      // White
        textPrimary: Color(hex: "#000000"),  // Black
        // ... all optimized iOS light colors
    )
    
    public static let darkDefaults = ColorScheme(
        primary: Color(hex: "#0A84FF"),      // iOS Dark Blue
        background: Color(hex: "#000000"),   // Black
        surface: Color(hex: "#1C1C1E"),      // iOS Dark Gray
        textPrimary: Color(hex: "#FFFFFF"),  // White
        // ... all optimized iOS dark colors
    )
}
```

---

## 🎯 **User Benefits**

### **🚀 For Simple Apps:**
```json
{
  "theme": {
    "mode": "automatic",
    "lightColors": { "primary": "#YOUR_BRAND" },
    "darkColors": { "primary": "#YOUR_BRAND_DARK" }
  }
}
```
→ **Perfect iOS experience** with your brand colors

### **🎬 For Streaming Apps:**
```json
{
  "theme": {
    "mode": "automatic",
    "darkColors": {
      "background": "#000000",
      "surface": "#0D0D0F"
    }
  }
}
```
→ **Optimized dark experience** with SDK light defaults

### **🏪 For E-commerce Apps:**
```json
{
  "theme": {
    "mode": "automatic"
    // No custom colors → Pure SDK defaults
  }
}
```
→ **Perfect iOS native** experience

---

## 💡 **Smart Defaults Strategy**

### **🎨 SDK Provides:**
1. **iOS-optimized colors** → Tested contrast ratios
2. **Accessibility compliance** → WCAG guidelines
3. **Platform consistency** → Feels native
4. **Performance optimized** → Efficient color computation

### **👤 User Provides:**
1. **Brand colors** → Primary, secondary
2. **Custom backgrounds** → For specific experiences
3. **Accent overrides** → Success, warning, error
4. **Text customization** → If needed for brand

### **🔄 Result:**
- **Best of both worlds** → SDK quality + brand identity
- **Minimal configuration** → Only specify what you need
- **Automatic optimization** → SDK fills the gaps
- **Theme switching** → Seamless light/dark transitions

**¡Este sistema permite que con mínima configuración tengas máxima personalización, y el SDK se encarga de optimizar todo lo que no especifiques!** 🎨✨

¿Te gusta esta aproximación de defaults inteligentes + overrides selectivos?
