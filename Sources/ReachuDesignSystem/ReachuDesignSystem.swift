/// Reachu Design System
/// 
/// Provides design tokens, base components, and utilities for building
/// consistent UI experiences across Reachu applications.

import Foundation
import SwiftUI

/// Main entry point for Reachu Design System
public struct ReachuDesignSystem {
    
    /// Initialize design system
    public static func configure() {
        // Future: Load custom fonts, configure themes, etc.
        print("🎨 Reachu Design System initialized")
    }
}

// MARK: - Public Exports

// Export base components
public typealias ReachuButton = RButton
public typealias ReachuToastNotification = RToastNotification
public typealias ReachuToastOverlay = RToastOverlay
public typealias ReachuToastManager = ToastManager
public typealias ReachuCustomLoader = RCustomLoader

// Export image components
public typealias ReachuCachedAsyncImage = CachedAsyncImage
public typealias ReachuImageLoader = ImageLoader
public typealias ReachuCampaignSponsorBadge = CampaignSponsorBadge
