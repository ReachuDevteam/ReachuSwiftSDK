import SwiftUI
import ReachuUI
import ReachuCore

/// Demo view showing how to use the dynamic Offer Banner
struct OfferBannerDemo: View {
    @StateObject private var componentManager = ComponentManager(campaignId: 10)
    @State private var showDemo = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Offer Banner Demo")
                .font(.title)
                .fontWeight(.bold)
            
            // Demo button
            Button("Show Demo Banner") {
                showDemo.toggle()
            }
            .buttonStyle(.borderedProminent)
            
            // Dynamic banner container
            if let bannerConfig = componentManager.activeBanner {
                ROfferBanner(config: bannerConfig)
                    .padding(.horizontal)
            } else if showDemo {
                // Demo banner with hardcoded config
                ROfferBanner(config: demoConfig)
                    .padding(.horizontal)
            } else {
                Text("No active banner")
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .onAppear {
            Task {
                await componentManager.connect()
            }
        }
        .onDisappear {
            componentManager.disconnect()
        }
    }
    
    // Demo configuration for testing
    private var demoConfig: OfferBannerConfig {
        OfferBannerConfig(
            logoUrl: "https://via.placeholder.com/100x30/00FF00/FFFFFF?text=XXL",
            title: "Ukens tilbud",
            subtitle: "Se denne ukes beste tilbud",
            backgroundImageUrl: "https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=800&h=400&fit=crop",
            countdownEndDate: "2025-12-31T23:59:59Z",
            discountBadgeText: "Opp til 30%",
            ctaText: "Se alle tilbud →",
            ctaLink: "https://xxlsports.no/offers",
            overlayOpacity: 0.4
        )
    }
}

/// Alternative: Using the container component (recommended)
struct OfferBannerContainerDemo: View {
    var body: some View {
        VStack {
            Text("Offer Banner Container Demo")
                .font(.title)
                .fontWeight(.bold)
            
            // This automatically handles connection and lifecycle
            ROfferBannerContainer(campaignId: 10)
                .padding(.horizontal)
            
            Spacer()
        }
    }
}

#if DEBUG
struct OfferBannerDemo_Previews: PreviewProvider {
    static var previews: some View {
        OfferBannerDemo()
    }
}
#endif
