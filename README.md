# Reachu Swift SDK

A Swift SDK for the Reachu platform - add ecommerce to any iOS, macOS, tvOS or watchOS application.

## Features

- **API Integration** (REST & GraphQL)
- **Products & Channels** management
- **Cart** functionality
- **Checkout** process
- **Payments** processing
- **Orders** management
- **Multi Currency** support
- **LiveShow** (coming in Phase 3)
- **UI Components** (optional)

## Installation

### Swift Package Manager

Add the Reachu Swift SDK to your project using Xcode or by adding it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/ReachuDevteam/swift-sdk.git", from: "1.0.0")
]
```

### Modular Installation

Choose only the modules you need:

#### Core Only (Required)
```swift
.product(name: "ReachuCore", package: "swift-sdk")
```

#### Core + UI Components
```swift
.product(name: "ReachuUI", package: "swift-sdk")
```

#### Core + LiveShow
```swift
.product(name: "ReachuLiveShow", package: "swift-sdk")
```

#### Everything
```swift
.product(name: "ReachuComplete", package: "swift-sdk")
```

## Quick Start

### 1. Configure the SDK

```swift
import ReachuCore

// In your AppDelegate or App struct
Reachu.configure(
    apiKey: "your-reachu-api-key",
    environment: .production
)
```

### 2. Basic Usage

```swift
// Get products
let products = try await Reachu.shared.products.getProducts()

// Get channels
let channels = try await Reachu.shared.products.getChannels()

// Cart operations
let cart = try await Reachu.shared.cart.createCart()
let updatedCart = try await Reachu.shared.cart.addToCart(
    productId: "product-123",
    quantity: 1,
    cartId: cart.id
)

// Checkout
let checkout = try await Reachu.shared.checkout.createCheckout(cartId: cart.id)

// Process payment
let payment = try await Reachu.shared.payments.initiatePayment(
    checkoutId: checkout.id,
    paymentMethod: paymentMethod
)
```

### 3. With UI Components (Optional)

```swift
import ReachuUI

struct ShopView: View {
    var body: some View {
        // Ready-to-use UI components
        ProductListView()
        CartView()
        CheckoutView()
    }
}
```

## Development Status

This SDK is under active development in phases:

- ✅ **Phase 1**: Core Reachu functionality (Products, Cart, Checkout, Payments, Orders)
- 🚧 **Phase 2**: UI Components (SwiftUI components)  
- 📋 **Phase 3**: LiveShow functionality

## Documentation

- [API Reference](docs/api-reference.md)
- [Examples](docs/examples/)
- [Migration Guide](docs/migration.md)

## Requirements

- iOS 15.0+ / macOS 12.0+ / tvOS 15.0+ / watchOS 8.0+
- Xcode 14.0+
- Swift 5.9+

## License

MIT License - see [LICENSE](LICENSE) for details.
