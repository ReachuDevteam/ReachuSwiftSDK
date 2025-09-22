# 📋 Reachu SDK Configuration Files

This directory contains template configuration files for the Reachu Swift SDK.

## 📁 Available Files

### 🟢 `reachu-config-starter.json` 
**→ Perfect for beginners**
- Contains only essential configuration options
- Easy to understand and modify
- Good starting point for most apps

### 🔵 `reachu-config-example.json`
**→ Complete configuration reference**
- Contains ALL available configuration options
- Includes advanced features (typography, shadows, animations, etc.)
- Use as reference for advanced customization

## 🚀 How to Use

### Step 1: Choose Your Template
```bash
# For beginners - basic setup
cp reachu-config-starter.json reachu-config.json

# For advanced users - all options
cp reachu-config-example.json reachu-config.json
```

### Step 2: Customize
1. Open `reachu-config.json`
2. Replace `"YOUR_REACHU_API_KEY_HERE"` with your actual API key
3. Modify colors, settings, and preferences as needed
4. Save the file

### Step 3: Add to Xcode Project
1. Drag `reachu-config.json` into your Xcode project
2. Make sure "Add to target" is checked for your main app
3. Verify it appears in "Copy Bundle Resources" build phase

### Step 4: Load in Your App
```swift
import ReachuCore

// In AppDelegate.swift or App.swift
do {
    try ConfigurationLoader.loadFromJSON(fileName: "reachu-config")
    print("✅ Reachu SDK configured successfully")
} catch {
    print("❌ Configuration failed: \(error)")
    // Fallback to manual configuration
    ReachuConfiguration.configure(apiKey: "your-api-key")
}
```

## 🔧 Key Configuration Sections

### 🎨 **Theme & Branding**
```json
"theme": {
    "colors": {
        "primary": "#007AFF",     // Your brand color
        "secondary": "#5856D6"    // Accent color
    }
}
```

### 🛒 **Shopping Cart**
```json
"cart": {
    "floatingCartPosition": "bottomRight",  // Where cart appears
    "showCartNotifications": true,          // Show "Added to cart"
    "enableGuestCheckout": true             // Allow checkout without account
}
```

### 🖼️ **UI Components**
```json
"ui": {
    "enableAnimations": true,        // Enable smooth animations
    "showProductBrands": true,       // Show brand names
    "enableHapticFeedback": true     // Tactile feedback
}
```

## 🎯 Common Use Cases

### E-commerce Store
```json
{
    "theme": { "colors": { "primary": "#FF6B35" } },
    "ui": { "showProductBrands": true, "showProductDescriptions": true }
}
```

### Fashion Brand
```json
{
    "theme": { "colors": { "primary": "#000000", "secondary": "#C4A484" } },
    "ui": { "defaultProductCardVariant": "hero" }
}
```

### Tech Store
```json
{
    "theme": { "colors": { "primary": "#007AFF" } },
    "ui": { "enableProductCardAnimations": true, "showProductDescriptions": true }
}
```

## 🔍 Troubleshooting

### ❌ File Not Found
- Check that `reachu-config.json` is in your app bundle
- Verify it's added to your main app target
- Look for the file in Build Phases → Copy Bundle Resources

### ❌ JSON Syntax Error
- Use a JSON validator to check syntax
- Common issues: missing quotes, trailing commas
- Check console for specific error messages

### ❌ Configuration Not Applied
- Ensure you're calling `ConfigurationLoader.loadFromJSON()` at app startup
- Check for error messages in console
- Verify API key is correct

### ✅ Test Your Configuration
```swift
// Add this code to verify configuration loaded correctly
print("API Key: \(ReachuConfiguration.shared.apiKey)")
print("Environment: \(ReachuConfiguration.shared.environment)")
print("Theme: \(ReachuConfiguration.shared.theme.name)")
```

## 📚 Next Steps

1. **Basic Setup:** Start with `reachu-config-starter.json`
2. **Customize Colors:** Update theme colors to match your brand
3. **Test Components:** Add a product card to see your styling
4. **Advanced Features:** Gradually add more configuration options
5. **Read Documentation:** Check [CONFIGURATION_GUIDE.md](./CONFIGURATION_GUIDE.md) for detailed explanations

## 🆘 Need Help?

- 📖 [Full Configuration Guide](./CONFIGURATION_GUIDE.md)
- 👨‍💻 [Developer Guide](./DEVELOPER_CONFIGURATION_GUIDE.md)
- 🌐 [Online Documentation](https://docs.reachu.io/sdk/swift/configuration)
- 📧 Support: sdk-support@reachu.io

---

🎉 **Happy Configuring!** Your Reachu SDK will be perfectly tailored to your app in no time! ✨
