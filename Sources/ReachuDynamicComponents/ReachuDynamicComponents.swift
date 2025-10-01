import Foundation
import SwiftUI
import ReachuCore

/// Reachu Dynamic Components - punto de entrada público
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public struct ReachuDynamicComponents {
    public static func configure() {
        print("🧩 Reachu Dynamic Components initialized")
    }
}

// Exports
public typealias ReachuDynamicComponentManager = DynamicComponentManager
public typealias ReachuDynamicComponentRegistry = DynamicComponentRegistry

