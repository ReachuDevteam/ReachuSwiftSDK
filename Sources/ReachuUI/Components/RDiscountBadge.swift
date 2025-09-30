import SwiftUI
import ReachuCore
import ReachuDesignSystem

/// Discount badge component for showing savings and promotions
public struct RDiscountBadge: View {
    
    // MARK: - Configuration
    public struct Configuration {
        public let style: BadgeStyle
        public let size: BadgeSize
        public let animation: AnimationType
        public let position: BadgePosition
        
        public init(
            style: BadgeStyle = .percentage,
            size: BadgeSize = .medium,
            animation: AnimationType = .none,
            position: BadgePosition = .topRight
        ) {
            self.style = style
            self.size = size
            self.animation = animation
            self.position = position
        }
    }
    
    public enum BadgeStyle {
        case percentage     // "25% OFF"
        case amount        // "$10 OFF"
        case text          // "SALE"
        case flashSale     // "FLASH" with special styling
        
        var backgroundColor: Color {
            switch self {
            case .percentage: return .red
            case .amount: return .orange
            case .text: return .blue
            case .flashSale: return .purple
            }
        }
    }
    
    public enum BadgeSize {
        case small
        case medium
        case large
        
        var fontSize: Font {
            switch self {
            case .small: return .system(size: 10, weight: .bold)
            case .medium: return .system(size: 12, weight: .bold)
            case .large: return .system(size: 14, weight: .bold)
            }
        }
        
        var padding: EdgeInsets {
            switch self {
            case .small: return EdgeInsets(top: 2, leading: 6, bottom: 2, trailing: 6)
            case .medium: return EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
            case .large: return EdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 10)
            }
        }
    }
    
    public enum AnimationType {
        case none
        case pulse
        case bounce
        case wiggle
        case glow
    }
    
    public enum BadgePosition {
        case topLeft
        case topRight
        case bottomLeft
        case bottomRight
        case center
        
        var alignment: Alignment {
            switch self {
            case .topLeft: return .topLeading
            case .topRight: return .topTrailing
            case .bottomLeft: return .bottomLeading
            case .bottomRight: return .bottomTrailing
            case .center: return .center
            }
        }
        
        var offset: CGSize {
            switch self {
            case .topLeft: return CGSize(width: 8, height: 8)
            case .topRight: return CGSize(width: -8, height: 8)
            case .bottomLeft: return CGSize(width: 8, height: -8)
            case .bottomRight: return CGSize(width: -8, height: -8)
            case .center: return .zero
            }
        }
    }
    
    // MARK: - Properties
    private let discount: Discount
    private let configuration: Configuration
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var isAnimating = false
    
    // Colors based on theme
    private var adaptiveColors: AdaptiveColors {
        ReachuColors.adaptive(for: colorScheme)
    }
    
    // MARK: - Discount Model
    public struct Discount {
        public let type: DiscountType
        public let value: Double
        public let text: String?
        
        public enum DiscountType {
            case percentage
            case fixedAmount
            case custom
        }
        
        public init(percentage: Double) {
            self.type = .percentage
            self.value = percentage
            self.text = nil
        }
        
        public init(amount: Double) {
            self.type = .fixedAmount
            self.value = amount
            self.text = nil
        }
        
        public init(customText: String) {
            self.type = .custom
            self.value = 0
            self.text = customText
        }
        
        var displayText: String {
            switch type {
            case .percentage:
                return "\(Int(value))% OFF"
            case .fixedAmount:
                return "$\(Int(value)) OFF"
            case .custom:
                return text ?? "SALE"
            }
        }
    }
    
    // MARK: - Initializers
    public init(
        discount: Discount,
        configuration: Configuration = Configuration()
    ) {
        self.discount = discount
        self.configuration = configuration
    }
    
    // Convenience initializers
    public init(
        percentage: Double,
        style: BadgeStyle = .percentage,
        size: BadgeSize = .medium,
        animation: AnimationType = .none
    ) {
        self.init(
            discount: Discount(percentage: percentage),
            configuration: Configuration(style: style, size: size, animation: animation)
        )
    }
    
    public init(
        amount: Double,
        style: BadgeStyle = .amount,
        size: BadgeSize = .medium,
        animation: AnimationType = .none
    ) {
        self.init(
            discount: Discount(amount: amount),
            configuration: Configuration(style: style, size: size, animation: animation)
        )
    }
    
    // MARK: - Body
    public var body: some View {
        badgeContent
            .onAppear {
                startAnimation()
            }
    }
    
    // MARK: - Badge Content
    
    @ViewBuilder
    private var badgeContent: some View {
        Text(discount.displayText)
            .font(configuration.size.fontSize)
            .foregroundColor(.white)
            .padding(configuration.size.padding)
            .background(badgeBackground)
            .cornerRadius(ReachuBorderRadius.small)
            .shadow(
                color: configuration.style.backgroundColor.opacity(0.4),
                radius: 4,
                x: 0,
                y: 2
            )
            .scaleEffect(animationScale)
            .rotationEffect(animationRotation)
            .shadow(
                color: configuration.animation == .glow && isAnimating ? 
                    configuration.style.backgroundColor.opacity(0.8) : Color.clear,
                radius: isAnimating ? 12 : 0,
                x: 0,
                y: 0
            )
    }
    
    @ViewBuilder
    private var badgeBackground: some View {
        if configuration.style == .flashSale {
            // Special gradient for flash sale
            LinearGradient(
                colors: [
                    Color.purple,
                    Color.pink,
                    Color.red
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            // Standard color
            configuration.style.backgroundColor
        }
    }
    
    // MARK: - Animation Properties
    
    private var animationScale: CGFloat {
        switch configuration.animation {
        case .pulse, .bounce:
            return isAnimating ? 1.1 : 1.0
        default:
            return 1.0
        }
    }
    
    private var animationRotation: Angle {
        switch configuration.animation {
        case .wiggle:
            return isAnimating ? .degrees(Double.random(in: -3...3)) : .degrees(0)
        default:
            return .degrees(0)
        }
    }
    
    // MARK: - Animation Control
    
    private func startAnimation() {
        guard configuration.animation != .none else { return }
        
        switch configuration.animation {
        case .pulse:
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
            
        case .bounce:
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
            
        case .wiggle:
            Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
                withAnimation(.easeInOut(duration: 0.2).repeatCount(3, autoreverses: true)) {
                    isAnimating.toggle()
                }
            }
            
        case .glow:
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
            
        case .none:
            break
        }
    }
    
    // MARK: - Helper Properties
    
    // shouldShowAlert removed - this is for discount badges, not stock alerts
}

// MARK: - Convenience Extensions

extension RDiscountBadge {
    /// Create a percentage discount badge
    public static func percentage(
        _ value: Double,
        size: BadgeSize = .medium,
        animation: AnimationType = .pulse
    ) -> RDiscountBadge {
        RDiscountBadge(
            percentage: value,
            size: size,
            animation: animation
        )
    }
    
    /// Create a fixed amount discount badge
    public static func amount(
        _ value: Double,
        size: BadgeSize = .medium,
        animation: AnimationType = .bounce
    ) -> RDiscountBadge {
        RDiscountBadge(
            amount: value,
            size: size,
            animation: animation
        )
    }
    
    /// Create a flash sale badge
    public static func flashSale(
        size: BadgeSize = .large,
        animation: AnimationType = .glow
    ) -> RDiscountBadge {
        RDiscountBadge(
            discount: Discount(customText: "FLASH SALE"),
            configuration: Configuration(
                style: .flashSale,
                size: size,
                animation: animation
            )
        )
    }
}

// MARK: - Preview

#Preview("Discount Badges - Styles") {
    VStack(spacing: ReachuSpacing.lg) {
        HStack(spacing: ReachuSpacing.md) {
            RDiscountBadge.percentage(25)
            RDiscountBadge.amount(10)
            RDiscountBadge.flashSale()
        }
        
        HStack(spacing: ReachuSpacing.md) {
            RDiscountBadge.percentage(50, animation: .pulse)
            RDiscountBadge.amount(15, animation: .bounce)
            RDiscountBadge(
                discount: RDiscountBadge.Discount(customText: "NEW"),
                configuration: RDiscountBadge.Configuration(
                    style: .text,
                    animation: .glow
                )
            )
        }
    }
    .padding()
}

#Preview("Discount Badges - Sizes") {
    VStack(spacing: ReachuSpacing.lg) {
        HStack(spacing: ReachuSpacing.md) {
            RDiscountBadge.percentage(25, size: .small)
            RDiscountBadge.percentage(25, size: .medium)
            RDiscountBadge.percentage(25, size: .large)
        }
        
        Text("Different sizes comparison")
            .font(.caption)
            .foregroundColor(.gray)
    }
    .padding()
}
