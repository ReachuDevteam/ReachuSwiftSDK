# Reachu SDK Configuration Guide

This guide explains how to configure the Reachu Swift SDK for seamless integration across all modules (Core, UI, LiveShow) without repeated setup.

## 🚀 Quick Start

### 1. Basic Configuration (API Key Only)

```swift
import ReachuCore

// In your AppDelegate or App.swift
ReachuConfiguration.configure(apiKey: "your-api-key-here")

// Now use anywhere in your app without additional setup
RProductCard(product: product) // Automatically configured
RCheckoutOverlay() // Uses global settings
```

### 2. Advanced Configuration (Programmatic)

```swift
import ReachuCore

ReachuConfiguration.configure(
    apiKey: "your-api-key-here",
    environment: .production,
    theme: .custom(
        primary: Color.blue,
        secondary: Color.purple
    ),
    cartConfig: CartConfiguration(
        floatingCartPosition: .bottomRight,
        showCartNotifications: true,
        enableGuestCheckout: true
    ),
    uiConfig: UIConfiguration(
        enableAnimations: true,
        showProductBrands: true,
        enableHapticFeedback: true
    )
)
```

## 📁 Configuration from File

### JSON Configuration

Create a `reachu-config.json` file in your app bundle:

```json
{
  "apiKey": "your-reachu-api-key-here",
  "environment": "production",
  "theme": {
    "name": "Mi Tienda Theme",
    "colors": {
      "primary": "#007AFF",
      "secondary": "#5856D6"
    }
  },
  "cart": {
    "floatingCartPosition": "bottomRight",
    "floatingCartDisplayMode": "full",
    "floatingCartSize": "medium",
    "autoSaveCart": true,
    "showCartNotifications": true,
    "enableGuestCheckout": true,
    "requirePhoneNumber": true,
    "defaultShippingCountry": "US",
    "supportedPaymentMethods": ["stripe", "klarna", "paypal"]
  },
  "ui": {
    "defaultProductCardVariant": "grid",
    "enableProductCardAnimations": true,
    "showProductBrands": true,
    "showProductDescriptions": false,
    "imageQuality": "medium",
    "enableImageCaching": true,
    "typography": {
      "fontFamily": null,
      "enableCustomFonts": false,
      "supportDynamicType": true,
      "lineHeightMultiplier": 1.2,
      "letterSpacing": 0.0
    },
    "shadows": {
      "cardShadowRadius": 4,
      "cardShadowOpacity": 0.1,
      "buttonShadowEnabled": true,
      "enableBlurEffects": true,
      "blurIntensity": 0.3
    },
    "animations": {
      "defaultDuration": 0.3,
      "springResponse": 0.4,
      "springDamping": 0.8,
      "enableSpringAnimations": true,
      "enableMicroInteractions": true,
      "respectReduceMotion": true,
      "animationQuality": "high"
    },
    "layout": {
      "gridColumns": 2,
      "gridSpacing": 16,
      "respectSafeAreas": true,
      "enableResponsiveLayout": true,
      "screenMargins": 16,
      "sectionSpacing": 24
    },
    "accessibility": {
      "enableVoiceOverOptimizations": true,
      "enableDynamicTypeSupport": true,
      "respectHighContrastMode": true,
      "respectReduceMotion": true,
      "minimumTouchTargetSize": 44,
      "enableHapticFeedback": true,
      "hapticIntensity": "medium"
    },
    "enableAnimations": true,
    "animationDuration": 0.3,
    "enableHapticFeedback": true
  },
  "network": {
    "timeout": 30.0,
    "retryAttempts": 3,
    "enableCaching": true,
    "cacheDuration": 300,
    "enableQueryBatching": true,
    "maxConcurrentRequests": 6,
    "requestPriority": "normal",
    "enableCompression": true,
    "enableSSLPinning": false,
    "enableCertificateValidation": true,
    "enableLogging": false,
    "logLevel": "info",
    "enableNetworkInspector": false,
    "enableOfflineMode": false,
    "offlineCacheDuration": 86400,
    "syncStrategy": "automatic"
  },
  "liveShow": {
    "autoJoinChat": true,
    "enableChatModeration": true,
    "maxChatMessageLength": 200,
    "enableEmojis": true,
    "enableShoppingDuringStream": true,
    "showProductOverlays": true,
    "enableQuickBuy": true,
    "enableStreamNotifications": true,
    "enableProductNotifications": true,
    "enableChatNotifications": false,
    "videoQuality": "auto",
    "enableAutoplay": false,
    "enablePictureInPicture": true
  }
}
```

Load the configuration:

```swift
// In your app startup
do {
    try ConfigurationLoader.loadFromJSON(fileName: "reachu-config")
} catch {
    print("Failed to load configuration: \(error)")
    // Fallback to manual configuration
    ReachuConfiguration.configure(apiKey: "your-api-key")
}
```

### Plist Configuration

Add to your `Info.plist`:

```xml
<key>ReachuAPIKey</key>
<string>your-api-key-here</string>
<key>ReachuEnvironment</key>
<string>production</string>
```

Load the configuration:

```swift
try ConfigurationLoader.loadFromPlist(fileName: "Info")
```

### Environment Variables

Set environment variables for CI/CD:

```bash
export REACHU_API_KEY="your-api-key"
export REACHU_ENVIRONMENT="production"
```

Load in your app:

```swift
ConfigurationLoader.loadFromEnvironment()
```

## 🎨 Theme Customization

### Predefined Themes

```swift
ReachuConfiguration.configure(
    apiKey: "your-key",
    theme: .default  // Reachu brand colors
)

ReachuConfiguration.configure(
    apiKey: "your-key", 
    theme: .light    // Light theme
)

ReachuConfiguration.configure(
    apiKey: "your-key",
    theme: .dark     // Dark theme
)

ReachuConfiguration.configure(
    apiKey: "your-key",
    theme: .minimal  // Minimal theme
)
```

### Custom Theme

```swift
let customTheme = ReachuTheme(
    name: "Brand Theme",
    colors: ColorScheme(
        primary: Color(hex: "#FF6B35"),
        secondary: Color(hex: "#004E89"),
        success: Color(hex: "#2ECC71"),
        error: Color(hex: "#E74C3C")
    )
)

ReachuConfiguration.configure(
    apiKey: "your-key",
    theme: customTheme
)
```

## 🛒 Cart Configuration

```swift
let cartConfig = CartConfiguration(
    floatingCartPosition: .bottomRight,     // Cart position
    floatingCartDisplayMode: .full,         // Display mode
    floatingCartSize: .medium,              // Size
    autoSaveCart: true,                     // Auto-save to device
    maxQuantityPerItem: 99,                 // Max quantity
    showCartNotifications: true,            // Show add notifications
    enableGuestCheckout: true,              // Allow guest checkout
    requirePhoneNumber: true,               // Require phone in checkout
    defaultShippingCountry: "US",           // Default country
    supportedPaymentMethods: [              // Available payment methods
        "stripe", "klarna", "paypal"
    ]
)

ReachuConfiguration.configure(
    apiKey: "your-key",
    cartConfig: cartConfig
)
```

### Cart Position Options

```swift
.topLeft        .topCenter        .topRight
.centerLeft                      .centerRight  
.bottomLeft     .bottomCenter     .bottomRight
```

### Display Modes

- `.full` - Shows icon, count, and total
- `.compact` - Shows icon and count only  
- `.minimal` - Shows icon with small badge
- `.iconOnly` - Shows only cart icon

## 🖼️ UI Configuration

```swift
let uiConfig = UIConfiguration(
    defaultProductCardVariant: .grid,       // Default card style
    enableProductCardAnimations: true,      // Card animations
    showProductBrands: true,                // Show brand names
    showProductDescriptions: false,         // Show descriptions
    defaultSliderLayout: .cards,            // Default slider style
    imageQuality: .medium,                  // Image quality
    enableAnimations: true,                 // Global animations
    enableHapticFeedback: true              // Haptic feedback
)
```

## 📺 LiveShow Configuration

```swift
let liveShowConfig = LiveShowConfiguration(
    autoJoinChat: true,                     // Auto-join chat
    enableChatModeration: true,             // Moderate chat
    maxChatMessageLength: 200,              // Max message length
    enableShoppingDuringStream: true,       // Allow shopping
    showProductOverlays: true,              // Show product overlays
    enableQuickBuy: true,                   // Quick buy buttons
    videoQuality: .auto,                    // Video quality
    enableAutoplay: false,                  // Auto-play videos
    enablePictureInPicture: true            // PiP support
)
```

## 🌐 Network Configuration

```swift
let networkConfig = NetworkConfiguration(
    timeout: 30.0,                          // Request timeout
    retryAttempts: 3,                       // Retry failed requests
    enableCaching: true,                    // Enable caching
    cacheDuration: 300,                     // Cache duration (seconds)
    enableLogging: false,                   // Network logging
    customHeaders: [                        // Custom headers
        "X-App-Version": "1.0.0"
    ]
)
```

## 🔧 Runtime Configuration Updates

```swift
// Update theme after initial configuration
ReachuConfiguration.updateTheme(.dark)

// Update cart configuration
let newCartConfig = CartConfiguration(
    floatingCartPosition: .topRight
)
ReachuConfiguration.updateCartConfiguration(newCartConfig)
```

## ✅ Configuration Validation

```swift
// Check if SDK is properly configured
if ReachuConfiguration.shared.isValidConfiguration {
    // SDK is ready to use
} else {
    // Configuration is incomplete
}

// Validate configuration and handle errors
do {
    try ReachuConfiguration.shared.validateConfiguration()
} catch {
    print("Configuration error: \(error)")
}
```

## 🌍 Multi-Environment Setup

### Development

```swift
#if DEBUG
ReachuConfiguration.configure(
    apiKey: "dev-api-key",
    environment: .sandbox,
    networkConfig: NetworkConfiguration(enableLogging: true)
)
#else
ReachuConfiguration.configure(
    apiKey: "prod-api-key",
    environment: .production
)
#endif
```

### Using Build Configurations

```swift
#if STAGING
let environment = Environment.sandbox
let apiKey = "staging-key"
#else
let environment = Environment.production  
let apiKey = "production-key"
#endif

ReachuConfiguration.configure(
    apiKey: apiKey,
    environment: environment
)
```

## 📱 Complete Integration Example

```swift
import SwiftUI
import ReachuCore
import ReachuUI

@main
struct MyApp: App {
    
    init() {
        configureReachuSDK()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(CartManager())
        }
    }
    
    private func configureReachuSDK() {
        // Option 1: Load from JSON file
        do {
            try ConfigurationLoader.loadFromJSON(fileName: "reachu-config")
        } catch {
            // Option 2: Fallback to manual configuration
            ReachuConfiguration.configure(
                apiKey: "your-api-key",
                environment: .production,
                theme: .default,
                cartConfig: CartConfiguration(
                    floatingCartPosition: .bottomRight,
                    showCartNotifications: true
                ),
                uiConfig: UIConfiguration(
                    enableAnimations: true,
                    enableHapticFeedback: true
                )
            )
        }
    }
}

struct ContentView: View {
    var body: some View {
        VStack {
            // These components automatically use global configuration
            RProductCard(product: sampleProduct)
            RProductSlider(products: sampleProducts)
            
            // Global floating cart (uses configured position/style)
            RFloatingCartIndicator()
        }
        .sheet(isPresented: $showCheckout) {
            // Checkout uses global theme and cart configuration
            RCheckoutOverlay()
        }
    }
}
```

## 🔍 Configuration Reference

### All Available Options

```swift
ReachuConfiguration.configure(
    apiKey: String,                         // Required: Your API key
    environment: Environment,               // .sandbox or .production
    theme: ReachuTheme,                     // Visual theme
    cartConfig: CartConfiguration,          // Cart behavior
    networkConfig: NetworkConfiguration,    // Network settings  
    uiConfig: UIConfiguration,              // UI preferences
    liveShowConfig: LiveShowConfiguration   // LiveShow settings
)
```

### Benefits of Centralized Configuration

✅ **One-time setup** - Configure once, use everywhere  
✅ **Consistent styling** - All components use same theme  
✅ **Easy customization** - Change appearance globally  
✅ **Environment management** - Easy dev/staging/prod switching  
✅ **Type-safe configuration** - Compile-time validation  
✅ **Multiple loading sources** - JSON, Plist, Environment, Remote  
✅ **Runtime updates** - Change settings without restart  
✅ **Validation** - Built-in configuration validation  

This configuration system ensures that once you set up the Reachu SDK, all components (product cards, checkout, livestreaming, etc.) work seamlessly together with consistent styling and behavior.
