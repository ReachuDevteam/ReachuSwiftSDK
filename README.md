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

## 🚀 Quick Start

```swift
import ReachuCore

// Configure the SDK
Reachu.configure(
    apiKey: "your-reachu-api-key",
    environment: .production
)

// Use the modules
let products = try await Reachu.shared.products.getProducts()
let cart = try await Reachu.shared.cart.createCart(
    customerSessionId: "session-123",
    currency: "USD"
)
```

## 📋 Development Status

🚧 **This SDK is currently under active development**

See [PLAN_DESARROLLO_MODULAR.md](PLAN_DESARROLLO_MODULAR.md) for the complete development roadmap and task breakdown.

### Current Phase
- **Phase 1**: Core module development (In Progress)
- **Phase 2**: UI Components (Planned)
- **Phase 3**: LiveShow features (Planned)

## 📚 Documentation

- [Development Plan](PLAN_DESARROLLO_MODULAR.md) - Complete roadmap and architecture
- [Package Configuration](Package.swift) - Swift Package Manager setup

## ⚡ Requirements

- iOS 15.0+ / macOS 12.0+ / tvOS 15.0+ / watchOS 8.0+
- Xcode 14.0+
- Swift 5.9+

## 🤝 Contributing

This project follows a structured development plan. Please check the [development plan](PLAN_DESARROLLO_MODULAR.md) for current tasks and contribution guidelines.

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.
