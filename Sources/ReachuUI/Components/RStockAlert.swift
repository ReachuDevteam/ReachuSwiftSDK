import SwiftUI
import ReachuCore
import ReachuDesignSystem

/// Stock alert component that shows low stock warnings to create urgency
public struct RStockAlert: View {
    
    // MARK: - Configuration
    public struct Configuration {
        public let threshold: Int
        public let showExactCount: Bool
        public let style: AlertStyle
        public let animation: AnimationType
        
        public init(
            threshold: Int = 10,
            showExactCount: Bool = true,
            style: AlertStyle = .warning,
            animation: AnimationType = .pulse
        ) {
            self.threshold = threshold
            self.showExactCount = showExactCount
            self.style = style
            self.animation = animation
        }
    }
    
    public enum AlertStyle {
        case warning    // Orange/yellow
        case critical   // Red
        case info       // Blue
        case success    // Green (back in stock)
        
        var color: Color {
            switch self {
            case .warning: return .orange
            case .critical: return .red
            case .info: return .blue
            case .success: return .green
            }
        }
        
        var icon: String {
            switch self {
            case .warning: return "exclamationmark.triangle.fill"
            case .critical: return "exclamationmark.circle.fill"
            case .info: return "info.circle.fill"
            case .success: return "checkmark.circle.fill"
            }
        }
    }
    
    public enum AnimationType {
        case none
        case pulse
        case shake
        case glow
    }
    
    // MARK: - Properties
    private let stockCount: Int
    private let configuration: Configuration
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var isAnimating = false
    
    // Colors based on theme
    private var adaptiveColors: AdaptiveColors {
        ReachuColors.adaptive(for: colorScheme)
    }
    
    // MARK: - Initializer
    public init(
        stockCount: Int,
        configuration: Configuration = Configuration()
    ) {
        self.stockCount = stockCount
        self.configuration = configuration
    }
    
    // Convenience initializers
    public init(
        stockCount: Int,
        threshold: Int = 10,
        style: AlertStyle = .warning,
        showExactCount: Bool = true
    ) {
        self.init(
            stockCount: stockCount,
            configuration: Configuration(
                threshold: threshold,
                showExactCount: showExactCount,
                style: style
            )
        )
    }
    
    // MARK: - Body
    public var body: some View {
        if shouldShowAlert {
            alertContent
                .onAppear {
                    startAnimation()
                }
        }
    }
    
    // MARK: - Alert Content
    
    @ViewBuilder
    private var alertContent: some View {
        HStack(spacing: ReachuSpacing.sm) {
            // Alert icon
            Image(systemName: configuration.style.icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(configuration.style.color)
                .scaleEffect(isAnimating && configuration.animation == .pulse ? 1.2 : 1.0)
                .animation(
                    configuration.animation == .pulse ? 
                        .easeInOut(duration: 1.0).repeatForever(autoreverses: true) : .none,
                    value: isAnimating
                )
            
            // Alert text
            Text(alertMessage)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(configuration.style.color)
                .lineLimit(1)
            
            Spacer()
        }
        .padding(.horizontal, ReachuSpacing.sm)
        .padding(.vertical, ReachuSpacing.xs)
        .background(
            RoundedRectangle(cornerRadius: ReachuBorderRadius.small)
                .fill(configuration.style.color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: ReachuBorderRadius.small)
                        .stroke(configuration.style.color.opacity(0.3), lineWidth: 1)
                )
        )
        .offset(x: isAnimating && configuration.animation == .shake ? shakeOffset : 0)
        .animation(
            configuration.animation == .shake ?
                .easeInOut(duration: 0.1).repeatCount(3, autoreverses: true) : .none,
            value: isAnimating
        )
        .shadow(
            color: configuration.animation == .glow && isAnimating ? 
                configuration.style.color.opacity(0.5) : Color.clear,
            radius: 8,
            x: 0,
            y: 0
        )
    }
    
    // MARK: - Computed Properties
    
    private var shouldShowAlert: Bool {
        stockCount <= configuration.threshold && stockCount > 0
    }
    
    private var alertMessage: String {
        if stockCount == 1 {
            return "Only 1 left in stock!"
        } else if configuration.showExactCount {
            return "Only \(stockCount) left in stock!"
        } else {
            return "Low stock - order soon!"
        }
    }
    
    private var shakeOffset: CGFloat {
        CGFloat.random(in: -2...2)
    }
    
    // MARK: - Animation
    
    private func startAnimation() {
        guard configuration.animation != .none else { return }
        
        isAnimating = true
        
        if configuration.animation == .shake {
            // Trigger shake animation every 5 seconds
            Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
                isAnimating = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isAnimating = true
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Stock Alert - Warning") {
    VStack(spacing: ReachuSpacing.lg) {
        RStockAlert(stockCount: 3, style: .warning)
        RStockAlert(stockCount: 1, style: .critical)
        RStockAlert(stockCount: 8, style: .info)
        RStockAlert(stockCount: 0, style: .success) // Won't show
    }
    .padding()
}

#Preview("Stock Alert - Animations") {
    VStack(spacing: ReachuSpacing.lg) {
        RStockAlert(
            stockCount: 2,
            configuration: RStockAlert.Configuration(
                style: .critical,
                animation: .pulse
            )
        )
        
        RStockAlert(
            stockCount: 5,
            configuration: RStockAlert.Configuration(
                style: .warning,
                animation: .shake
            )
        )
        
        RStockAlert(
            stockCount: 3,
            configuration: RStockAlert.Configuration(
                style: .critical,
                animation: .glow
            )
        )
    }
    .padding()
}
