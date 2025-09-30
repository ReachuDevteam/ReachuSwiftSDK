import SwiftUI
import ReachuCore
import ReachuDesignSystem

/// Flash sale banner component for promoting limited-time offers in live shows
public struct RFlashSaleBanner: View {
    
    // MARK: - Configuration
    public struct Configuration {
        public let style: BannerStyle
        public let size: BannerSize
        public let animation: AnimationType
        public let showCountdown: Bool
        public let isDismissible: Bool
        
        public init(
            style: BannerStyle = .gradient,
            size: BannerSize = .medium,
            animation: AnimationType = .pulse,
            showCountdown: Bool = true,
            isDismissible: Bool = true
        ) {
            self.style = style
            self.size = size
            self.animation = animation
            self.showCountdown = showCountdown
            self.isDismissible = isDismissible
        }
    }
    
    public enum BannerStyle {
        case gradient      // Gradient background
        case solid         // Solid color
        case outlined      // Border only
        case glassmorphic  // Blur effect
        
        var hasBackground: Bool {
            switch self {
            case .gradient, .solid, .glassmorphic: return true
            case .outlined: return false
            }
        }
    }
    
    public enum BannerSize {
        case compact
        case medium
        case large
        
        var height: CGFloat {
            switch self {
            case .compact: return 60
            case .medium: return 80
            case .large: return 100
            }
        }
        
        var titleFont: Font {
            switch self {
            case .compact: return .system(size: 16, weight: .bold)
            case .medium: return .system(size: 20, weight: .bold)
            case .large: return .system(size: 24, weight: .bold)
            }
        }
        
        var subtitleFont: Font {
            switch self {
            case .compact: return .system(size: 12, weight: .medium)
            case .medium: return .system(size: 14, weight: .medium)
            case .large: return .system(size: 16, weight: .medium)
            }
        }
    }
    
    public enum AnimationType {
        case none
        case pulse
        case glow
        case shimmer
        case bounce
    }
    
    // MARK: - Flash Sale Model
    public struct FlashSale {
        public let title: String
        public let subtitle: String?
        public let discount: String
        public let endDate: Date
        public let products: [String] // Product IDs
        public let backgroundColor: Color?
        
        public init(
            title: String,
            subtitle: String? = nil,
            discount: String,
            endDate: Date,
            products: [String] = [],
            backgroundColor: Color? = nil
        ) {
            self.title = title
            self.subtitle = subtitle
            self.discount = discount
            self.endDate = endDate
            self.products = products
            self.backgroundColor = backgroundColor
        }
    }
    
    // MARK: - Properties
    private let flashSale: FlashSale
    private let configuration: Configuration
    private let onTap: (() -> Void)?
    private let onDismiss: (() -> Void)?
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var isAnimating = false
    @State private var isDismissed = false
    @State private var shimmerOffset: CGFloat = -200
    
    // Colors based on theme
    private var adaptiveColors: AdaptiveColors {
        ReachuColors.adaptive(for: colorScheme)
    }
    
    // MARK: - Initializer
    public init(
        flashSale: FlashSale,
        configuration: Configuration = Configuration(),
        onTap: (() -> Void)? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        self.flashSale = flashSale
        self.configuration = configuration
        self.onTap = onTap
        self.onDismiss = onDismiss
    }
    
    // Convenience initializer
    public init(
        title: String,
        discount: String,
        duration: TimeInterval,
        style: BannerStyle = .gradient,
        onTap: (() -> Void)? = nil
    ) {
        self.init(
            flashSale: FlashSale(
                title: title,
                subtitle: "Limited time offer",
                discount: discount,
                endDate: Date().addingTimeInterval(duration)
            ),
            configuration: Configuration(style: style),
            onTap: onTap
        )
    }
    
    // MARK: - Body
    public var body: some View {
        if !isDismissed {
            bannerContent
                .onAppear {
                    startAnimations()
                }
        }
    }
    
    // MARK: - Banner Content
    
    @ViewBuilder
    private var bannerContent: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: ReachuSpacing.md) {
                // Flash sale icon
                flashSaleIcon
                
                // Content
                VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
                    // Title and discount
                    HStack(spacing: ReachuSpacing.sm) {
                        Text(flashSale.title.uppercased())
                            .font(configuration.size.titleFont)
                            .foregroundColor(.white)
                        
                        Text(flashSale.discount)
                            .font(configuration.size.titleFont)
                            .foregroundColor(.yellow)
                    }
                    
                    // Subtitle
                    if let subtitle = flashSale.subtitle {
                        Text(subtitle)
                            .font(configuration.size.subtitleFont)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    // Countdown if enabled
                    if configuration.showCountdown {
                        RCountdownTimer(
                            endDate: flashSale.endDate,
                            configuration: RCountdownTimer.Configuration(
                                style: .minimal,
                                size: .small,
                                showLabels: false
                            )
                        )
                    }
                }
                
                Spacer()
                
                // Arrow or dismiss button
                if configuration.isDismissible {
                    dismissButton
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(.horizontal, ReachuSpacing.lg)
            .padding(.vertical, ReachuSpacing.md)
        }
        .buttonStyle(PlainButtonStyle())
        .frame(height: configuration.size.height)
        .background(bannerBackground)
        .cornerRadius(ReachuBorderRadius.medium)
        .overlay(shimmerOverlay)
        .scaleEffect(animationScale)
        .shadow(
            color: bannerShadowColor,
            radius: 8,
            x: 0,
            y: 4
        )
        .animation(bounceAnimation, value: isAnimating)
    }
    
    // MARK: - Background Views
    
    @ViewBuilder
    private var bannerBackground: some View {
        switch configuration.style {
        case .gradient:
            LinearGradient(
                colors: [
                    flashSale.backgroundColor ?? .red,
                    (flashSale.backgroundColor ?? .red).opacity(0.8),
                    .purple.opacity(0.6)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
        case .solid:
            (flashSale.backgroundColor ?? .red)
            
        case .outlined:
            adaptiveColors.surface
                .overlay(
                    RoundedRectangle(cornerRadius: ReachuBorderRadius.medium)
                        .stroke(flashSale.backgroundColor ?? .red, lineWidth: 2)
                )
            
        case .glassmorphic:
            Color.black.opacity(0.3)
                .background(.ultraThinMaterial)
        }
    }
    
    @ViewBuilder
    private var shimmerOverlay: some View {
        if configuration.animation == .shimmer {
            RoundedRectangle(cornerRadius: ReachuBorderRadius.medium)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.white.opacity(0.3),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .offset(x: shimmerOffset)
                .animation(
                    .linear(duration: 2.0).repeatForever(autoreverses: false),
                    value: shimmerOffset
                )
        }
    }
    
    // MARK: - Helper Views
    
    private var flashSaleIcon: some View {
        ZStack {
            Circle()
                .fill(Color.yellow)
                .frame(width: 32, height: 32)
                .scaleEffect(isAnimating ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isAnimating)
            
            Image(systemName: "bolt.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.red)
        }
    }
    
    private var dismissButton: some View {
        Button(action: {
            withAnimation(.easeOut(duration: 0.3)) {
                isDismissed = true
            }
            onDismiss?()
        }) {
            Image(systemName: "xmark")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 24, height: 24)
                .background(Color.black.opacity(0.3))
                .clipShape(Circle())
        }
    }
    
    // MARK: - Animation Properties
    
    private var animationScale: CGFloat {
        switch configuration.animation {
        case .bounce:
            return isAnimating ? 1.02 : 1.0
        case .pulse:
            return isAnimating ? 1.01 : 1.0
        default:
            return 1.0
        }
    }
    
    private var bannerShadowColor: Color {
        switch configuration.animation {
        case .glow:
            return isAnimating ? (flashSale.backgroundColor ?? .red).opacity(0.6) : Color.black.opacity(0.2)
        default:
            return Color.black.opacity(0.2)
        }
    }
    
    private var bounceAnimation: Animation? {
        switch configuration.animation {
        case .bounce:
            return .easeInOut(duration: 1.0).repeatForever(autoreverses: true)
        case .pulse:
            return .easeInOut(duration: 1.5).repeatForever(autoreverses: true)
        case .glow:
            return .easeInOut(duration: 2.0).repeatForever(autoreverses: true)
        default:
            return nil
        }
    }
    
    // MARK: - Animation Control
    
    private func startAnimations() {
        isAnimating = true
        
        if configuration.animation == .shimmer {
            shimmerOffset = 200
        }
    }
}

// MARK: - Convenience Extensions

extension RFlashSaleBanner {
    /// Create a flash sale banner with countdown
    public static func withCountdown(
        title: String,
        discount: String,
        duration: TimeInterval,
        onTap: (() -> Void)? = nil
    ) -> RFlashSaleBanner {
        RFlashSaleBanner(
            title: title,
            discount: discount,
            duration: duration,
            style: .gradient,
            onTap: onTap
        )
    }
    
    /// Create a minimal flash sale banner
    public static func minimal(
        title: String,
        discount: String,
        onTap: (() -> Void)? = nil
    ) -> RFlashSaleBanner {
        RFlashSaleBanner(
            flashSale: FlashSale(
                title: title,
                discount: discount,
                endDate: Date().addingTimeInterval(3600)
            ),
            configuration: Configuration(
                style: .outlined,
                size: .compact,
                animation: .none,
                showCountdown: false
            ),
            onTap: onTap
        )
    }
}

// MARK: - Preview

#Preview("Flash Sale Banner - Styles") {
    VStack(spacing: ReachuSpacing.lg) {
        RFlashSaleBanner.withCountdown(
            title: "FLASH SALE",
            discount: "50% OFF",
            duration: 3600
        )
        
        RFlashSaleBanner(
            flashSale: RFlashSaleBanner.FlashSale(
                title: "MEGA SALE",
                subtitle: "Everything must go!",
                discount: "UP TO 70% OFF",
                endDate: Date().addingTimeInterval(1800),
                backgroundColor: .purple
            ),
            configuration: RFlashSaleBanner.Configuration(
                style: .gradient,
                size: .large,
                animation: .glow
            )
        )
        
        RFlashSaleBanner.minimal(
            title: "WEEKEND SPECIAL",
            discount: "25% OFF"
        )
    }
    .padding()
}

#Preview("Flash Sale Banner - Animations") {
    VStack(spacing: ReachuSpacing.lg) {
        RFlashSaleBanner(
            title: "FLASH SALE",
            discount: "50% OFF",
            duration: 900,
            style: .gradient
        )
        
        RFlashSaleBanner(
            flashSale: RFlashSaleBanner.FlashSale(
                title: "LIMITED TIME",
                discount: "40% OFF",
                endDate: Date().addingTimeInterval(600)
            ),
            configuration: RFlashSaleBanner.Configuration(
                style: .glassmorphic,
                animation: .shimmer
            )
        )
    }
    .padding()
    .background(Color.black.opacity(0.1))
}
