import SwiftUI
import ReachuCore

/// Helper view wrapper that automatically hides Reachu components if market is not available or campaign is not active
/// Use this to wrap any Reachu UI components
public struct ReachuComponentWrapper<Content: View>: View {
    @ViewBuilder let content: () -> Content
    
    public init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    public var body: some View {
        if ReachuConfiguration.shared.shouldUseSDK && CampaignManager.shared.isCampaignActive {
            content()
        } else {
            EmptyView()
        }
    }
}

extension View {
    /// Conditionally show this view only if Reachu SDK market is available and campaign is active
    public func reachuOnly() -> some View {
        Group {
            if ReachuConfiguration.shared.shouldUseSDK && CampaignManager.shared.isCampaignActive {
                self
            } else {
                EmptyView()
            }
        }
    }
}


