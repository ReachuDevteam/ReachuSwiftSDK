# 🌓 Dark/Light Mode Guide - Reachu Swift SDK

## 📱 Overview

Reachu Swift SDK provides **complete dark/light mode support** that automatically adapts to iOS system settings or can be manually controlled. All UI components respond to color scheme changes dynamically, providing a professional, polished user experience.

## ✨ Key Features

- 🔄 **Automatic system following** - Respects iOS dark/light mode settings
- 🎛️ **Manual override** - Force light or dark mode when needed
- 🎨 **Complete color customization** - Define separate colors for light and dark modes
- 🧩 **Component adaptation** - All UI components adapt automatically
- 📱 **iOS-standard appearance** - Professional dark mode that matches system apps

---

## 🚀 Quick Start

### 1. Basic Configuration

Add theme configuration to your `reachu-config.json`:

```json
{
  "theme": {
    "mode": "automatic",
    "lightColors": {
      "primary": "#007AFF",
      "surface": "#FFFFFF",
      "textPrimary": "#000000"
    },
    "darkColors": {
      "primary": "#0A84FF", 
      "surface": "#1C1C1E",
      "textPrimary": "#FFFFFF"
    }
  }
}
```

### 2. Load Configuration

```swift
// In your App.swift
import ReachuCore

@main
struct MyApp: App {
    init() {
        ConfigurationLoader.loadFromJSON("reachu-config")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### 3. That's it! 

All Reachu UI components will now automatically adapt to light/dark mode! 🎉

---

## 🎯 Theme Mode Options

| Mode | Description | When to Use |
|------|-------------|-------------|
| `"automatic"` | Follows iOS system settings | **Recommended** - Best user experience |
| `"light"` | Always light mode | Brand requirements, accessibility needs |
| `"dark"` | Always dark mode | Gaming apps, developer tools |

---

## 🎨 Complete Color Configuration

### Available Color Properties

```json
{
  "lightColors": {
    // Brand Colors
    "primary": "#007AFF",
    "secondary": "#5856D6",
    
    // Semantic Colors
    "success": "#34C759",
    "warning": "#FF9500", 
    "error": "#FF3B30",
    "info": "#007AFF",
    
    // Background Colors
    "background": "#F2F2F7",
    "surface": "#FFFFFF",
    "surfaceSecondary": "#F9F9F9",
    
    // Text Colors
    "textPrimary": "#000000",
    "textSecondary": "#8E8E93",
    "textTertiary": "#C7C7CC",
    
    // Border Colors
    "border": "#E5E5EA",
    "borderSecondary": "#D1D1D6"
  },
  "darkColors": {
    // Same properties with dark mode values
    "primary": "#0A84FF",
    "secondary": "#5E5CE6",
    "success": "#32D74B",
    "warning": "#FF9F0A",
    "error": "#FF453A", 
    "info": "#0A84FF",
    "background": "#000000",
    "surface": "#1C1C1E",
    "surfaceSecondary": "#2C2C2E",
    "textPrimary": "#FFFFFF",
    "textSecondary": "#8E8E93",
    "textTertiary": "#48484A",
    "border": "#38383A",
    "borderSecondary": "#48484A"
  }
}
```

---

## 🛠️ Implementation Examples

### Basic Theme Configuration

```json
{
  "theme": {
    "name": "My App Theme",
    "mode": "automatic",
    "lightColors": {
      "primary": "#007AFF",
      "surface": "#FFFFFF",
      "textPrimary": "#000000"
    },
    "darkColors": {
      "primary": "#0A84FF",
      "surface": "#1C1C1E", 
      "textPrimary": "#FFFFFF"
    }
  }
}
```

### Force Light Mode

```json
{
  "theme": {
    "mode": "light",
    "lightColors": {
      "primary": "#FF6B6B",
      "surface": "#FFFFFF"
    }
  }
}
```

### Force Dark Mode

```json
{
  "theme": {
    "mode": "dark",
    "darkColors": {
      "primary": "#00D4AA",
      "surface": "#1A1A1A"
    }
  }
}
```

---

## 🎨 Theme Examples

### Professional Blue Theme

Perfect for business and productivity apps:

```json
{
  "theme": {
    "name": "Professional Blue",
    "mode": "automatic",
    "lightColors": {
      "primary": "#0066CC",
      "secondary": "#4A90E2",
      "surface": "#FFFFFF",
      "background": "#F8F9FA"
    },
    "darkColors": {
      "primary": "#4A9EFF",
      "secondary": "#6BB6FF", 
      "surface": "#1E1E1E",
      "background": "#121212"
    }
  }
}
```

### Green E-commerce Theme

Great for shopping and e-commerce apps:

```json
{
  "theme": {
    "name": "Green Commerce",
    "mode": "automatic",
    "lightColors": {
      "primary": "#00A86B",
      "secondary": "#FF6B35",
      "success": "#28A745"
    },
    "darkColors": {
      "primary": "#00D084",
      "secondary": "#FF8A5B",
      "success": "#34CE57"
    }
  }
}
```

### Minimal Monochrome Theme

Clean and minimalist design:

```json
{
  "theme": {
    "name": "Minimal",
    "mode": "automatic", 
    "lightColors": {
      "primary": "#333333",
      "secondary": "#666666",
      "surface": "#FFFFFF"
    },
    "darkColors": {
      "primary": "#CCCCCC",
      "secondary": "#999999",
      "surface": "#222222"
    }
  }
}
```

---

## 💻 Custom Component Implementation

### SwiftUI Components with Dark/Light Mode

```swift
import SwiftUI
import ReachuDesignSystem

struct MyCustomComponent: View {
    @Environment(\.colorScheme) private var colorScheme
    
    // Get adaptive colors based on current scheme
    private var adaptiveColors: AdaptiveColors {
        ReachuColors.adaptive(for: colorScheme)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Hello World")
                .foregroundColor(adaptiveColors.textPrimary)
                .font(.title)
            
            Button("Action") {
                // Button action
            }
            .foregroundColor(.white)
            .background(adaptiveColors.primary)
            .cornerRadius(8)
        }
        .padding()
        .background(adaptiveColors.surface)
        .cornerRadius(12)
    }
}
```

### Static Color Usage

```swift
// For non-SwiftUI contexts or when you need static colors
Text("Static Example")
    .foregroundColor(ReachuColors.textPrimary)
    .background(ReachuColors.surface)

// Get colors for specific schemes
let lightColors = ReachuColors.colors(for: .light)
let darkColors = ReachuColors.colors(for: .dark)
```

---

## 🧪 Testing Your Dark/Light Mode Implementation

### iOS Simulator Testing

1. **Settings App** → Developer → Dark Appearance (toggle)
2. **Settings App** → Display & Brightness → Appearance (Light/Dark)
3. **Control Center** → Long press brightness → Appearance toggle

### Xcode Previews Testing

```swift
import SwiftUI

struct MyComponent_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MyComponent()
                .preferredColorScheme(.light)
                .previewDisplayName("Light Mode")
            
            MyComponent()
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
        }
    }
}
```

---

## ✅ Best Practices

### ✅ DO

- **Use `"automatic"` mode** for the best user experience
- **Provide both light and dark colors** for complete themes
- **Test your app thoroughly** in both light and dark modes
- **Follow iOS Human Interface Guidelines** for dark mode design
- **Use semantic colors** (success, warning, error) consistently
- **Ensure sufficient contrast** in both modes

### ❌ DON'T

- **Force light mode** unless brand requirements absolutely demand it
- **Use low contrast colors** in dark mode
- **Ignore system preferences** without a good reason
- **Hardcode colors** in components - always use the theme system
- **Forget to test** your implementation in both modes

---

## 🔧 Advanced Configuration

### Programmatic Theme Override

```swift
import ReachuCore

// Force dark mode programmatically
ReachuConfiguration.shared.updateTheme(
    ReachuTheme(
        name: "Forced Dark",
        mode: .dark,
        lightColors: .reachu,
        darkColors: .reachuDark
    )
)
```

### Custom Theme Creation

```swift
let customTheme = ReachuTheme(
    name: "My Custom Theme",
    mode: .automatic,
    lightColors: ColorScheme(
        primary: Color(.sRGB, red: 1.0, green: 0.4, blue: 0.4),
        secondary: Color(.sRGB, red: 0.2, green: 0.6, blue: 1.0)
        // ... other colors
    ),
    darkColors: .autoDark(from: lightColors) // Auto-generate dark colors
)
```

---

## 📊 Component Support

All Reachu UI components automatically support dark/light mode:

| Component | Dark/Light Support | Auto-Adaptive |
|-----------|-------------------|----------------|
| `RProductCard` | ✅ | ✅ |
| `RProductSlider` | ✅ | ✅ |
| `RCheckoutOverlay` | ✅ | ✅ |
| `RFloatingCartIndicator` | ✅ | ✅ |
| `RProductDetailOverlay` | ✅ | ✅ |

---

## 🎉 Result

With Reachu's dark/light mode system, your app will have:

- ✅ **Professional appearance** that matches iOS system apps
- ✅ **Automatic adaptation** to user preferences  
- ✅ **Complete customization** of all colors and themes
- ✅ **Consistent experience** across all components
- ✅ **Easy maintenance** with centralized configuration

**Your users will love the polished, professional look and feel! 🌟**

---

## 🆘 Troubleshooting

### Colors Not Changing in Dark Mode

1. **Check configuration** - Ensure both `lightColors` and `darkColors` are defined
2. **Verify mode** - Make sure `mode` is set to `"automatic"`
3. **Component implementation** - Use `adaptiveColors` in custom components
4. **Restart app** - Configuration changes require app restart

### Components Still Using Old Colors

1. **Clear build cache** - Clean and rebuild your project
2. **Check imports** - Ensure you're importing `ReachuDesignSystem`
3. **Update components** - Use the new `AdaptiveColors` system

### Testing Issues

1. **Simulator settings** - Check simulator appearance settings
2. **Preview environment** - Use `.preferredColorScheme()` in previews
3. **Device vs simulator** - Test on both for best results

Need help? Check our [Developer Documentation](DEVELOPER_CONFIGURATION_GUIDE.md) for more details! 📚
