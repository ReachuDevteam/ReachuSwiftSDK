# 📋 Reachu SDK Configuration Guide

This comprehensive guide explains how to configure the Reachu Swift SDK to match your app's branding and requirements. Configure once and use everywhere - no repeated setup needed!

## 🚀 Quick Start

### Option 1: Simple Setup (API Key Only)
```swift
import ReachuCore

// In your AppDelegate or App.swift
ReachuConfiguration.configure(apiKey: "your-api-key-here")

// Now use anywhere in your app without additional setup
RProductCard(product: product) // Automatically configured
RCheckoutOverlay() // Uses global settings
```

### Option 2: Configuration File (Recommended)

**Step 1:** Download the configuration template

**Step 2:** Add it to your Xcode project

**Step 3:** Load in your app startup

```swift
import ReachuCore

// In your AppDelegate or App.swift
do {
    try ConfigurationLoader.loadFromJSON(fileName: "reachu-config")
} catch {
    print("Failed to load configuration: \(error)")
    // Fallback to basic configuration
    ReachuConfiguration.configure(apiKey: "your-api-key")
}
```

## 📁 Configuration File Setup

### 📥 Step 1: Download Template

Copy this complete configuration file to get started:

**File Name:** `reachu-config.json`

```json
{
  "apiKey": "YOUR_REACHU_API_KEY_HERE",
  "environment": "production",
  "theme": {
    "name": "My Store Theme",
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

### 📂 Step 2: Add to Xcode Project

1. **Create the file:**
   - Right-click your project in Xcode
   - Select "New File" → "Other" → "Empty"
   - Name it `reachu-config.json`

2. **Add to bundle:**
   - Make sure "Add to target" is checked for your main app target
   - The file should appear in your project navigator

3. **Verify bundle inclusion:**
   - Select your project → Build Phases → Copy Bundle Resources
   - Ensure `reachu-config.json` is listed

### 📱 Step 3: Load Configuration

Add this code to your app startup (AppDelegate.swift or App.swift):

```swift
import ReachuCore

class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Load Reachu configuration
        do {
            try ConfigurationLoader.loadFromJSON(fileName: "reachu-config")
            print("✅ Reachu SDK configured successfully")
        } catch {
            print("❌ Failed to load Reachu configuration: \(error)")
            
            // Fallback to basic configuration
            ReachuConfiguration.configure(apiKey: "YOUR_API_KEY_HERE")
        }
        
        return true
    }
}
```

**For SwiftUI Apps (App.swift):**
```swift
import SwiftUI
import ReachuCore

@main
struct MyApp: App {
    init() {
        configureReachu()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
    
    private func configureReachu() {
        do {
            try ConfigurationLoader.loadFromJSON(fileName: "reachu-config")
            print("✅ Reachu SDK configured successfully")
        } catch {
            print("❌ Failed to load Reachu configuration: \(error)")
            ReachuConfiguration.configure(apiKey: "YOUR_API_KEY_HERE")
        }
    }
}
```

## 🔧 Configuration Sections Explained

### 🔑 API & Environment
```json
{
  "apiKey": "YOUR_REACHU_API_KEY_HERE",    // ✅ REQUIRED: Your Reachu API key
  "environment": "production"              // production | sandbox
}
```

**Effect:** Determines which Reachu servers to connect to and authenticates your app.

### 🎨 Theme & Colors
```json
{
  "theme": {
    "name": "My Store Theme",
    "colors": {
      "primary": "#007AFF",      // Main brand color (buttons, links, emphasis)
      "secondary": "#5856D6"     // Secondary brand color (accents, highlights)
    }
  }
}
```

**Effect:** All Reachu UI components will use these colors automatically. Changes the appearance of buttons, product cards, checkout flow, etc.

### 🛒 Shopping Cart
```json
{
  "cart": {
    "floatingCartPosition": "bottomRight",           // Where cart appears on screen
    "floatingCartDisplayMode": "full",               // How much info to show
    "floatingCartSize": "medium",                    // Size of floating cart
    "autoSaveCart": true,                           // Save cart between app sessions
    "showCartNotifications": true,                   // Show "Added to cart" messages
    "enableGuestCheckout": true,                     // Allow checkout without account
    "requirePhoneNumber": true,                      // Require phone in checkout
    "defaultShippingCountry": "US",                  // Default country for shipping
    "supportedPaymentMethods": ["stripe", "klarna", "paypal"]  // Available payment options
  }
}
```

**Effect:** Controls how users interact with the shopping cart throughout your app.

#### Cart Position Options:
```
topLeft        topCenter        topRight
centerLeft                      centerRight  
bottomLeft     bottomCenter     bottomRight
```

#### Display Mode Options:
- `full` - Shows cart icon, item count, and total price
- `compact` - Shows cart icon and item count only
- `minimal` - Shows cart icon with small badge
- `iconOnly` - Shows only the cart icon

### 🖼️ UI Components
```json
{
  "ui": {
    "defaultProductCardVariant": "grid",       // Default product card style
    "enableProductCardAnimations": true,       // Enable card animations
    "showProductBrands": true,                 // Show brand names on products
    "showProductDescriptions": false,          // Show product descriptions
    "imageQuality": "medium",                  // Image quality (low/medium/high)
    "enableImageCaching": true,                // Cache images for performance
    
    "typography": {
      "fontFamily": null,                      // Custom font family (null = system)
      "enableCustomFonts": false,              // Enable custom font loading
      "supportDynamicType": true,              // Support iOS Dynamic Type
      "lineHeightMultiplier": 1.2,             // Line height multiplier
      "letterSpacing": 0.0                     // Letter spacing adjustment
    },
    
    "shadows": {
      "cardShadowRadius": 4,                   // Shadow blur radius for cards
      "cardShadowOpacity": 0.1,                // Shadow opacity (0.0 - 1.0)
      "buttonShadowEnabled": true,             // Enable shadows on buttons
      "enableBlurEffects": true,               // Enable blur effects
      "blurIntensity": 0.3                     // Blur intensity (0.0 - 1.0)
    },
    
    "animations": {
      "defaultDuration": 0.3,                  // Default animation duration (seconds)
      "springResponse": 0.4,                   // Spring animation response
      "springDamping": 0.8,                    // Spring animation damping
      "enableSpringAnimations": true,          // Use spring animations
      "enableMicroInteractions": true,         // Small interaction animations
      "respectReduceMotion": true,             // Respect accessibility settings
      "animationQuality": "high"               // Animation quality (low/medium/high)
    },
    
    "layout": {
      "gridColumns": 2,                        // Columns in product grids
      "gridSpacing": 16,                       // Space between grid items
      "respectSafeAreas": true,                // Respect device safe areas
      "enableResponsiveLayout": true,          // Adapt to screen sizes
      "screenMargins": 16,                     // Screen edge margins
      "sectionSpacing": 24                     // Space between sections
    },
    
    "accessibility": {
      "enableVoiceOverOptimizations": true,    // Optimize for VoiceOver
      "enableDynamicTypeSupport": true,        // Support Dynamic Type
      "respectHighContrastMode": true,         // Respect high contrast mode
      "respectReduceMotion": true,             // Respect reduce motion
      "minimumTouchTargetSize": 44,            // Minimum touch target size
      "enableHapticFeedback": true,            // Enable haptic feedback
      "hapticIntensity": "medium"              // Haptic intensity (light/medium/heavy)
    }
  }
}
```

**Effect:** Controls the look, feel, and behavior of all UI components in the SDK.

### 🌐 Network & Performance
```json
{
  "network": {
    "timeout": 30.0,                          // Request timeout (seconds)
    "retryAttempts": 3,                       // Number of retry attempts
    "enableCaching": true,                    // Enable response caching
    "cacheDuration": 300,                     // Cache duration (seconds)
    "enableQueryBatching": true,              // Batch GraphQL queries
    "maxConcurrentRequests": 6,               // Max concurrent requests
    "requestPriority": "normal",              // Request priority (low/normal/high)
    "enableCompression": true,                // Enable request compression
    "enableSSLPinning": false,                // Enable SSL certificate pinning
    "enableCertificateValidation": true,      // Validate SSL certificates
    "enableLogging": false,                   // Enable network logging
    "logLevel": "info",                       // Log level (debug/info/warning/error)
    "enableNetworkInspector": false,          // Enable network debugging
    "enableOfflineMode": false,               // Enable offline functionality
    "offlineCacheDuration": 86400,            // Offline cache duration (seconds)
    "syncStrategy": "automatic"               // Sync strategy (manual/automatic)
  }
}
```

**Effect:** Optimizes network performance and handles connectivity issues.

### 📺 LiveShow Features
```json
{
  "liveShow": {
    "autoJoinChat": true,                     // Auto-join chat when viewing
    "enableChatModeration": true,             // Enable chat moderation
    "maxChatMessageLength": 200,              // Max characters per message
    "enableEmojis": true,                     // Allow emoji reactions
    "enableShoppingDuringStream": true,       // Allow shopping during stream
    "showProductOverlays": true,              // Show product overlays
    "enableQuickBuy": true,                   // Enable quick buy buttons
    "enableStreamNotifications": true,        // Stream event notifications
    "enableProductNotifications": true,       // Product-related notifications
    "enableChatNotifications": false,         // Chat message notifications
    "videoQuality": "auto",                   // Video quality (auto/low/medium/high)
    "enableAutoplay": false,                  // Auto-play live streams
    "enablePictureInPicture": true            // Picture-in-picture support
  }
}
```

**Effect:** Controls livestream functionality and user interaction during live shows.

## 🔄 Updating Configuration

### Method 1: Edit the JSON File
1. Open `reachu-config.json` in Xcode
2. Modify the values you want to change
3. Save the file
4. Restart your app to see changes

### Method 2: Runtime Updates
```swift
// Update theme at runtime
ReachuConfiguration.updateTheme(
    ReachuTheme(
        name: "Dark Theme",
        colors: ColorScheme(
            primary: Color.orange,
            secondary: Color.red
        )
    )
)

// Update cart configuration
ReachuConfiguration.updateCartConfiguration(
    CartConfiguration(
        floatingCartPosition: .topRight,
        showCartNotifications: false
    )
)
```

## 🎯 Common Configuration Examples

### E-commerce Store
```json
{
  "theme": {
    "colors": {
      "primary": "#FF6B35",     // Vibrant orange
      "secondary": "#004E89"     // Deep blue
    }
  },
  "cart": {
    "floatingCartPosition": "bottomRight",
    "showCartNotifications": true,
    "enableGuestCheckout": true
  },
  "ui": {
    "showProductBrands": true,
    "showProductDescriptions": true,
    "enableProductCardAnimations": true
  }
}
```

### Fashion Brand
```json
{
  "theme": {
    "colors": {
      "primary": "#000000",     // Black
      "secondary": "#C4A484"     // Gold
    }
  },
  "ui": {
    "defaultProductCardVariant": "hero",
    "showProductBrands": true,
    "showProductDescriptions": false,
    "shadows": {
      "cardShadowRadius": 8,
      "cardShadowOpacity": 0.15
    }
  }
}
```

### Tech Store
```json
{
  "theme": {
    "colors": {
      "primary": "#007AFF",     // Apple Blue
      "secondary": "#5856D6"     // Purple
    }
  },
  "ui": {
    "enableProductCardAnimations": true,
    "animations": {
      "enableMicroInteractions": true,
      "animationQuality": "high"
    },
    "showProductDescriptions": true
  }
}
```

## 🔍 Troubleshooting

### Configuration Not Loading
1. **Check file location:** Ensure `reachu-config.json` is in your app bundle
2. **Verify JSON syntax:** Use a JSON validator to check for syntax errors
3. **Check target membership:** File must be added to your app target
4. **Review error messages:** Check console for specific error details

### Common JSON Errors
```json
// ❌ WRONG - Missing quotes around keys
{
  apiKey: "your-key"
}

// ✅ CORRECT - Keys must be quoted
{
  "apiKey": "your-key"
}

// ❌ WRONG - Trailing comma
{
  "apiKey": "your-key",
}

// ✅ CORRECT - No trailing comma
{
  "apiKey": "your-key"
}
```

### Testing Configuration
```swift
// Add this to test your configuration
print("Current API Key: \(ReachuConfiguration.shared.apiKey)")
print("Current Environment: \(ReachuConfiguration.shared.environment)")
print("Current Theme: \(ReachuConfiguration.shared.theme.name)")
```

## 🚀 Advanced Usage

### Environment-Specific Configurations
```swift
#if DEBUG
    try ConfigurationLoader.loadFromJSON(fileName: "reachu-config-dev")
#else
    try ConfigurationLoader.loadFromJSON(fileName: "reachu-config-prod")
#endif
```

### Remote Configuration
```swift
try await ConfigurationLoader.loadFromRemoteURL(
    url: URL(string: "https://yourserver.com/reachu-config.json")!
)
```

### Environment Variables (for CI/CD)
```swift
try ConfigurationLoader.loadFromEnvironmentVariables()
```

Set these environment variables:
```bash
export REACHU_API_KEY="your-api-key"
export REACHU_ENVIRONMENT="production"
export REACHU_THEME_PRIMARY_COLOR="#007AFF"
```

## 💡 Best Practices

1. **Start Simple:** Begin with basic configuration and add complexity as needed
2. **Version Control:** Keep configuration files in version control
3. **Environment Separation:** Use different configs for development/production
4. **Error Handling:** Always provide fallback configuration
5. **Testing:** Test configuration changes thoroughly
6. **Documentation:** Document custom configuration choices for your team

## 🎉 Ready to Use!

Once configured, all Reachu components automatically use your settings:

```swift
import ReachuUI

// All of these use your global configuration automatically!
RProductCard(product: product)          // Uses your theme colors and animations
RProductSlider(products: products)      // Uses your layout and UI settings
RCheckoutOverlay()                      // Uses your cart and payment configuration
RFloatingCartIndicator()               // Uses your cart position and display mode
```

Your app is now ready with a fully customized Reachu shopping experience! 🛍️✨

---

📖 **Next Steps:**
- [View Component Documentation](./ui-components.md)
- [Explore Example Implementations](./examples/)
- [Set Up LiveShow Features](./livestream.md)