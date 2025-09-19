/// Reachu Testing Utilities
/// 
/// Provides testing utilities for the Reachu SDK

import Foundation

/// Main entry point for Reachu Testing utilities
public struct ReachuTesting {
    
    /// Initialize testing utilities
    public static func configure() {
        print("🧪 Reachu Testing utilities initialized")
    }
}

// MARK: - Public Exports

// Export MockDataProvider for use in other modules
public typealias ReachuMockDataProvider = MockDataProvider
