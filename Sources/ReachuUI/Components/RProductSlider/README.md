# RProductSlider - Smart Product Slider Component

## Overview

`RProductSlider` is an intelligent SwiftUI component that automatically loads and displays products from the Reachu API. It handles loading states, error handling, and retry logic internally, providing a seamless plug-and-play experience.

## Features

✅ **Automatic API Loading** - Loads products automatically on appear  
✅ **Smart States** - Built-in loading, success, and error states  
✅ **Flexible** - Can use API data or manual products  
✅ **Category Filtering** - Optional category filter  
✅ **Retry Logic** - Automatic retry button on errors  
✅ **Themed** - Adapts to light/dark mode automatically  
✅ **Customizable Layouts** - 6 different layout styles  

## Usage

### Basic Usage (Automatic Loading)

```swift
import SwiftUI
import ReachuUI

struct HomeView: View {
    var body: some View {
        ScrollView {
            // Automatically loads products from API
            RProductSlider(
                title: "Featured Products",
                layout: .cards
            )
        }
    }
}
```

That's it! The component will:
1. Load products from the API automatically
2. Show a loading indicator while loading
3. Display products when loaded
4. Show an error message with retry button if it fails

### With Category Filter

```swift
RProductSlider(
    title: "Electronics",
    categoryId: 123,  // Filter by category
    layout: .featured
)
```

### With Manual Products

```swift
let myProducts: [Product] = [...]

RProductSlider(
    title: "Custom Selection",
    products: myProducts,  // Bypass auto-loading
    layout: .cards
)
```

### With Max Items Limit

```swift
RProductSlider(
    title: "Top 6 Products",
    layout: .cards,
    maxItems: 6  // Show only first 6 products
)
```

## Layout Styles

```swift
public enum Layout {
    case compact    // Minimal cards, 120pt width
    case cards      // Grid-style cards, 180pt width (default)
    case featured   // Hero-style cards, 280pt width
    case wide       // Wide list-style, 320pt width
    case showcase   // Extra large premium, 360pt width
    case micro      // Tiny cards, 80pt width
}
```

### Example with Different Layouts

```swift
ScrollView {
    // Compact for quick browsing
    RProductSlider(
        title: "Quick Picks",
        layout: .compact
    )
    
    // Featured for highlights
    RProductSlider(
        title: "Featured",
        layout: .featured
    )
    
    // Showcase for premium items
    RProductSlider(
        title: "Premium Collection",
        layout: .showcase
    )
}
```

## Advanced Usage

### With Custom Actions

```swift
RProductSlider(
    title: "Products",
    layout: .cards,
    onProductTap: { product in
        print("Tapped: \(product.title)")
        // Navigate to detail view
    },
    onAddToCart: { product in
        print("Added to cart: \(product.title)")
        // Custom cart logic
    },
    onSeeAllTap: {
        print("See all tapped")
        // Navigate to full catalog
    }
)
```

### With See All Button

```swift
RProductSlider(
    title: "New Arrivals",
    layout: .cards,
    showSeeAll: true,
    onSeeAllTap: {
        // Navigate to full catalog
    }
)
```

## Configuration

The component uses `ReachuConfiguration` for API settings. Make sure you've configured the SDK:

```swift
// In App.swift
import ReachuCore

@main
struct MyApp: App {
    init() {
        ConfigurationLoader.loadConfiguration()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

And have a `reachu-config.json` file:

```json
{
  "apiKey": "your-api-key",
  "environment": "production"
}
```

## States

The component automatically handles three states:

### 1. Loading State
Shows a progress indicator with "Loading products..." text.

### 2. Success State
Displays the horizontal scrolling product slider.

### 3. Error State
Shows an error icon, message, and a "Retry" button.

## Internal Architecture

```
RProductSlider (UI Component)
    ↓
RProductSliderViewModel (Business Logic)
    ↓
SdkClient → Reachu API
```

The ViewModel is internal and handles:
- API calls
- State management
- Error handling
- Caching logic

## Performance

- **Smart Loading**: Only loads once, uses `loadProductsIfNeeded()`
- **Caching**: Respects API cache settings
- **Lazy Loading**: Products load on `onAppear`
- **Memory Efficient**: Uses `@StateObject` for ViewModel

## Customization

### Styling
The component uses `ReachuDesignSystem` tokens:
- Colors: Adapts to light/dark mode via `adaptiveColors`
- Typography: Uses `ReachuTypography`
- Spacing: Uses `ReachuSpacing`
- Border Radius: Uses `ReachuBorderRadius`

### Theming
Customize via `reachu-config.json`:

```json
{
  "theme": {
    "mode": "automatic",
    "lightColors": {
      "primary": "#007AFF",
      ...
    },
    "darkColors": {
      "primary": "#0A84FF",
      ...
    }
  }
}
```

## Examples

### E-commerce Home Screen

```swift
struct HomeView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                RProductSlider(
                    title: "🔥 Hot Deals",
                    layout: .featured,
                    maxItems: 5
                )
                
                RProductSlider(
                    title: "New Arrivals",
                    layout: .cards
                )
                
                RProductSlider(
                    title: "Electronics",
                    categoryId: 123,
                    layout: .cards
                )
            }
        }
    }
}
```

### Category Screen

```swift
struct CategoryView: View {
    let categoryId: Int
    
    var body: some View {
        ScrollView {
            RProductSlider(
                title: "All Products",
                categoryId: categoryId,
                layout: .wide,
                showSeeAll: true
            )
        }
    }
}
```

## Troubleshooting

### Products not loading?
1. Check `reachu-config.json` has valid `apiKey`
2. Verify `ConfigurationLoader.loadConfiguration()` is called
3. Check network connectivity
4. Look for error messages in console

### Showing mock data instead of API data?
- Make sure you're NOT passing `products` parameter
- The component only auto-loads when `products` is `nil`

### Want to force reload?
```swift
// Currently not exposed, but you can pass new products
RProductSlider(products: updatedProducts, ...)
```

## Migration from Old Version

### Before (Manual Loading)
```swift
@EnvironmentObject var cartManager: CartManager

var body: some View {
    if cartManager.isProductsLoading {
        ProgressView()
    } else if !cartManager.products.isEmpty {
        RProductSlider(
            products: cartManager.products,
            title: "Products"
        )
    } else if let error = cartManager.productsErrorMessage {
        Text(error)
    }
}
.onAppear {
    Task {
        await cartManager.loadProducts()
    }
}
```

### After (Automatic Loading)
```swift
var body: some View {
    RProductSlider(
        title: "Products",
        layout: .cards
    )
}
```

**30+ lines → 3 lines!** 🎉

## Requirements

- iOS 15.0+
- macOS 12.0+
- ReachuCore module
- ReachuDesignSystem module

## See Also

- `RProductCard` - Individual product card component
- `RFloatingCartIndicator` - Floating cart button
- `CartManager` - Cart state management
