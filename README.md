# Reachu Swift SDK

A modular Swift SDK for the Reachu ecommerce platform. Add shopping cart, checkout, and livestream features to any iOS, macOS, tvOS or watchOS application.

## 🏗️ Modular Architecture

This SDK is designed with a modular architecture that allows you to import only the features you need:

- **ReachuCore** (Required) - Core ecommerce functionality
- **ReachuUI** (Optional) - SwiftUI components
- **ReachuLiveShow** (Optional) - Livestream shopping features
- **ReachuLiveUI** (Optional) - Livestream UI components

## 📦 Installation

Add the Reachu Swift SDK to your project using Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/angelosv/ReachuSwiftSDK.git", from: "1.0.0")
]
```

### Choose Your Modules

Import only what you need:

```swift
// Core functionality only
.product(name: "ReachuCore", package: "ReachuSwiftSDK")

// Core + UI Components
.product(name: "ReachuUI", package: "ReachuSwiftSDK")

// Core + LiveShow
.product(name: "ReachuLiveShow", package: "ReachuSwiftSDK")

// Everything
.product(name: "ReachuComplete", package: "ReachuSwiftSDK")
```

## 🎨 UI Components

### RProductCard
Flexible product card with 4 variants:
- **Grid**: Medium cards for main catalogs
- **List**: Compact cards for search results  
- **Hero**: Large cards for featured products
- **Minimal**: Small cards for recommendations

### RProductSlider
Horizontal scrolling component with 3 layouts:
- **Featured**: Hero cards for promotions (280pt)
- **Cards**: Grid cards for categories (180pt)
- **Compact**: Minimal cards for recommendations (120pt)

## 🚀 Quick Start

```swift
import SwiftUI
import ReachuUI

struct ProductView: View {
    let products: [Product]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Featured products slider
                RProductSlider.featured(
                    title: "Featured Products",
                    products: Array(products.prefix(5)),
                    onProductTap: { product in
                        // Handle product tap
                    }
                )
                
                // Product grid
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ]) {
                    ForEach(products) { product in
                        RProductCard(
                            product: product,
                            variant: .grid,
                            onAddToCart: { 
                                // Handle add to cart
                            }
                        )
                    }
                }
            }
        }
    }
}
```

## 📱 Demo App

Run the demo app to see all components in action:

```bash
cd Demo/ReachuDemoApp
open ReachuDemoApp.xcodeproj
```

The demo app includes:
- Design System showcase
- Product Card variants
- Product Slider layouts
- Interactive examples with real data

## 📚 Documentation

- **[Complete Documentation](https://docs.reachu.io/swift-sdk)** - Full documentation site
- **[PROJECT_STATUS.md](./PROJECT_STATUS.md)** - Current development status and context

## 🔧 Development

### Current Status
- ✅ **ReachuCore**: Core models and business logic
- ✅ **ReachuUI**: 2 main components (RProductCard, RProductSlider)
- ✅ **ReachuDesignSystem**: Complete design tokens and base components
- ✅ **Demo App**: Fully functional iOS app
- ✅ **Documentation**: Professional docs integrated with Docusaurus

### Build and Test

```bash
# Build the SDK
swift build --target ReachuUI

# Test demo app
cd Demo/ReachuDemoApp
xcodebuild -scheme ReachuDemoApp build
```

### Current Branch

Development is happening on `feature/ui-components` branch. See `PROJECT_STATUS.md` for detailed context and next steps.

## 🤝 Contributing

This SDK follows a modular, documentation-first approach:

1. **Develop** components in the SDK
2. **Test** in the demo app  
3. **Document** in the docs site
4. **Commit** with semantic messages

## 📄 License

This project is licensed under the MIT License.