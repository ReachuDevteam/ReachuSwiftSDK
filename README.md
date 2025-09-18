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
