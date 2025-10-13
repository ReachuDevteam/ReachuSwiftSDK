import SwiftUI

/// Offer Banner View (for NavigationLink)
/// Version without internal button for use with NavigationLink
struct OfferBannerView: View {
    let title: String
    let subtitle: String?
    
    init(
        title: String = "Ukens tilbud",
        subtitle: String? = "Se denne ukes beste tilbud"
    ) {
        self.title = title
        self.subtitle = subtitle
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            // Background with vibrant gradient
            ZStack {
                // Vibrant gradient background (TV2 colors)
                LinearGradient(
                    colors: [
                        Color(hex: "7B5FFF"), // TV2 primary purple
                        Color(hex: "E893CF"), // TV2 secondary pink
                        Color(hex: "5E5CE6")  // Deep blue
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // Dark overlay for text readability
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.5),
                        Color.black.opacity(0.2),
                        Color.clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }
            
            // Content
            VStack(alignment: .leading, spacing: TV2Theme.Spacing.sm) {
                Text(title)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(TV2Theme.Typography.body)
                        .foregroundColor(.white.opacity(0.9))
                }
                
                // Arrow indicator
                HStack(spacing: TV2Theme.Spacing.xs) {
                    Text("Se alle tilbud")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, TV2Theme.Spacing.md)
                .padding(.vertical, TV2Theme.Spacing.sm)
                .background(
                    Capsule()
                        .fill(TV2Theme.Colors.primary)
                )
            }
            .padding(.leading, TV2Theme.Spacing.xl)
        }
        .frame(height: 180)
        .cornerRadius(TV2Theme.CornerRadius.medium)
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}

/// Offer Banner Component (with button)
/// Banner promocional con imagen de fondo para ofertas especiales
struct OfferBanner: View {
    let title: String
    let subtitle: String?
    let onTap: () -> Void
    
    init(
        title: String = "Ukens tilbud",
        subtitle: String? = "Se denne ukes beste tilbud",
        onTap: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.onTap = onTap
    }
    
    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .leading) {
                // Background with vibrant gradient
                ZStack {
                    // Vibrant gradient background (TV2 colors)
                    LinearGradient(
                        colors: [
                            Color(hex: "7B5FFF"), // TV2 primary purple
                            Color(hex: "E893CF"), // TV2 secondary pink
                            Color(hex: "5E5CE6")  // Deep blue
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    // Dark overlay for text readability
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.5),
                            Color.black.opacity(0.2),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                }
                
                // Content
                VStack(alignment: .leading, spacing: TV2Theme.Spacing.sm) {
                    Text(title)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(TV2Theme.Typography.body)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    // Arrow indicator
                    HStack(spacing: TV2Theme.Spacing.xs) {
                        Text("Se alle tilbud")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, TV2Theme.Spacing.md)
                    .padding(.vertical, TV2Theme.Spacing.sm)
                    .background(
                        Capsule()
                            .fill(TV2Theme.Colors.primary)
                    )
                }
                .padding(.leading, TV2Theme.Spacing.xl)
            }
            .frame(height: 180)
            .cornerRadius(TV2Theme.CornerRadius.medium)
            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Scale Button Style
/// Adds a subtle scale animation on tap
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

#Preview {
    ZStack {
        TV2Theme.Colors.background
            .ignoresSafeArea()
        
        VStack(spacing: 20) {
            // Version for NavigationLink (without button)
            OfferBannerView()
                .padding(.horizontal, TV2Theme.Spacing.md)
            
            // Version with button
            OfferBanner {
                print("Banner tapped!")
            }
            .padding(.horizontal, TV2Theme.Spacing.md)
        }
    }
    .preferredColorScheme(.dark)
}

