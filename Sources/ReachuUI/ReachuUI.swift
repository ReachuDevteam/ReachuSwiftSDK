import SwiftUI
import ReachuCore
import ReachuDesignSystem

/// Reachu UI Components
/// 
/// Optional target for pre-built SwiftUI components
/// Import this target to get ready-to-use UI components for Reachu functionality

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public struct ReachuUI {
    
    public static func initialize() {
        print("✨ ReachuUI components initialized")
    }
}

// MARK: - Component Exports

// Export product components
public typealias ReachuProductCard = RProductCard
