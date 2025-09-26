# 🎬 LiveShow Component Usage Examples

## 🚀 **Simple Implementation**

### **Basic Usage**
```swift
import ReachuLiveUI

struct MyLiveStreamView: View {
    @State private var showLiveStream = false
    
    var body: some View {
        Button("Watch Live") {
            showLiveStream = true
        }
        .sheet(isPresented: $showLiveStream) {
            // ✅ Super simple - uses all defaults
            if let stream = LiveShowManager.shared.activeStreams.first {
                RLiveShowOverlay(stream: stream) {
                    showLiveStream = false
                }
                .environmentObject(CartManager())
            }
        }
    }
}
```

---

## 🎨 **Custom Styling**

### **Custom Colors**
```swift
let customColors = RLiveShowConfiguration.Colors(
    liveBadgeColor: .green,
    controlsBackground: Color.blue.opacity(0.6),
    controlsTint: .yellow,
    chatBackground: Color.purple.opacity(0.8)
)

RLiveShowOverlay.custom(
    stream: stream,
    colors: customColors
) {
    // Close action
}
```

### **Custom Typography**
```swift
let customTypography = RLiveShowConfiguration.Typography(
    streamTitleSize: 20,      // Larger title
    streamSubtitleSize: 14,   // Larger subtitle
    chatMessageSize: 16,      // Larger chat
    productTitleSize: 16,     // Larger product titles
    productPriceSize: 18      // Larger prices
)

RLiveShowOverlay.custom(
    stream: stream,
    typography: customTypography
) {
    // Close action
}
```

### **Custom Spacing**
```swift
let compactSpacing = RLiveShowConfiguration.Spacing(
    controlsSpacing: 8,       // Tighter controls
    contentPadding: 8,        // Less padding
    productSpacing: 6,        // Closer products
    chatPadding: 8           // Compact chat
)

RLiveShowOverlay.custom(
    stream: stream,
    spacing: compactSpacing
) {
    // Close action
}
```

---

## 🎯 **Layout Presets**

### **Minimal Layout**
```swift
// Only video + close button
RLiveShowOverlay.minimal(stream: stream) {
    // Close action
}

// Equivalent to:
let minimalLayout = RLiveShowConfiguration.Layout(
    showCloseButton: true,
    showLiveBadge: true,
    showControls: false,    // No side controls
    showChat: false,        // No chat
    showProducts: false,    // No products
    showLikes: false        // No likes
)
```

### **Chat Only**
```swift
let chatOnlyLayout = RLiveShowConfiguration.Layout(
    showCloseButton: true,
    showLiveBadge: true,
    showControls: true,
    showChat: true,         // ✅ Chat enabled
    showProducts: false,    // ❌ No products
    showLikes: true
)

RLiveShowOverlay(
    stream: stream,
    configuration: RLiveShowConfiguration(layout: chatOnlyLayout)
)
```

### **Products Only**
```swift
let productsOnlyLayout = RLiveShowConfiguration.Layout(
    showCloseButton: true,
    showLiveBadge: true,
    showControls: true,
    showChat: false,        // ❌ No chat
    showProducts: true,     // ✅ Products enabled
    showLikes: true
)
```

---

## 🌙 **Theme Integration**

### **Automatic Theme Adaptation**
```swift
// Adapts to iOS light/dark mode + SDK configuration
RLiveShowOverlay(
    stream: stream,
    configuration: .adaptive(for: colorScheme)
)
```

### **Force Dark Theme**
```swift
RLiveShowOverlay.darkTheme(stream: stream)

// Equivalent to:
RLiveShowOverlay(
    stream: stream,
    configuration: .adaptive(for: .dark)
)
```

### **SDK Configuration Integration**
```swift
// Uses colors from reachu-config.json automatically
let sdkColors = RLiveShowConfiguration.Colors.adaptive(for: colorScheme)

RLiveShowOverlay(
    stream: stream,
    configuration: RLiveShowConfiguration(colors: sdkColors)
)
```

---

## 🧩 **Component Independence**

### **Chat Component Standalone**
```swift
// Use chat anywhere
RLiveChatComponent()
    .environmentObject(cartManager)
    .frame(height: 200)
```

### **Products Grid Standalone**
```swift
// Use products grid anywhere
RLiveProductsGridOverlay(products: liveProducts)
    .environmentObject(cartManager)
```

### **Likes Component Standalone**
```swift
// Use likes anywhere
RLiveLikesComponent()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
```

---

## ⚙️ **Advanced Configuration**

### **Complete Custom Configuration**
```swift
let fullCustomConfig = RLiveShowConfiguration(
    layout: RLiveShowConfiguration.Layout(
        showCloseButton: true,
        showLiveBadge: true,
        showControls: true,
        showChat: true,
        showProducts: true,
        showLikes: true
    ),
    colors: RLiveShowConfiguration.Colors(
        liveBadgeColor: .orange,
        controlsBackground: Color.black.opacity(0.7),
        controlsStroke: Color.white.opacity(0.3),
        controlsTint: .white,
        chatBackground: Color.blue.opacity(0.8),
        productsBackground: Color.green.opacity(0.8)
    ),
    typography: RLiveShowConfiguration.Typography(
        streamTitleSize: 18,
        streamSubtitleSize: 12,
        chatMessageSize: 14,
        productTitleSize: 14,
        productPriceSize: 16
    ),
    spacing: RLiveShowConfiguration.Spacing(
        controlsSpacing: 12,
        contentPadding: 16,
        productSpacing: 10,
        chatPadding: 14
    )
)

RLiveShowOverlay(
    stream: stream,
    configuration: fullCustomConfig
) {
    // Close action
}
```

### **Brand-Specific Themes**
```swift
// Streaming brand theme
let streamingTheme = RLiveShowConfiguration(
    colors: RLiveShowConfiguration.Colors(
        liveBadgeColor: .red,
        controlsBackground: Color.black.opacity(0.8),
        controlsTint: .white,
        chatBackground: Color.black.opacity(0.9)
    )
)

// E-commerce brand theme  
let ecommerceTheme = RLiveShowConfiguration(
    colors: RLiveShowConfiguration.Colors(
        liveBadgeColor: .blue,
        controlsBackground: Color.white.opacity(0.9),
        controlsTint: .black,
        chatBackground: Color.white.opacity(0.95)
    )
)
```

---

## 🎯 **Migration from Old Component**

### **Before (Monolithic)**
```swift
RLiveShowFullScreenOverlay()
    .environmentObject(cartManager)
```

### **After (Modular)**
```swift
// ✅ Same functionality, more control
RLiveShowOverlay(stream: stream)
    .environmentObject(cartManager)

// ✅ Or with custom configuration
RLiveShowOverlay.custom(
    stream: stream,
    colors: myColors,
    typography: myTypography
)
```

---

## 💡 **Best Practices**

1. **Start Simple**: Use default configuration first
2. **Customize Gradually**: Add custom colors/typography as needed
3. **Use Presets**: `.minimal`, `.darkTheme` for common cases
4. **Theme Integration**: Use `.adaptive(for: colorScheme)` for SDK consistency
5. **Component Independence**: Use individual components when needed

**¡The new modular system makes LiveShow implementation super easy while providing complete customization control!** 🎉📺✨
