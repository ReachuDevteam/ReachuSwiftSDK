import SwiftUI
import ReachuCore

/// Reachu UI Components
/// 
/// Optional target for pre-built SwiftUI components
/// Import this target to get ready-to-use UI components for Reachu functionality

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public struct ReachuUI {
    
    public static func placeholder() {
        print("ReachuUI components available")
    }
}

// MARK: - Public Exports

// Export cart management
public typealias ReachuCartManager = CartManager

// Export UI components
public typealias ReachuProductCard = RProductCard
public typealias ReachuProductSlider = RProductSlider
public typealias ReachuCheckoutOverlay = RCheckoutOverlay
