import SwiftUI
import ReachuCore
import ReachuDesignSystem

/// Floating cart indicator that appears on all screens when cart has items
/// 
/// Displays cart item count and total price, provides quick access to checkout
/// Uses elegant design with animations and haptic feedback
public struct RFloatingCartIndicator: View {
    
    // MARK: - Position Options
    public enum Position {
        case bottomRight
        case bottomLeft
        case bottomCenter
        case topRight
        case topLeft
        case topCenter
        case centerRight
        case centerLeft
    }
    
    // MARK: - Display Mode
    public enum DisplayMode {
        case full        // Icon + count + price + arrow
        case compact     // Icon + count + price
        case minimal     // Icon + count only
        case iconOnly    // Just icon with badge
    }
    
    // MARK: - Size Options
    public enum Size {
        case small
        case medium
        case large
        
        var iconSize: Font {
            switch self {
            case .small: return .title3
            case .medium: return .title2
            case .large: return .title
            }
        }
        
        var horizontalPadding: CGFloat {
            switch self {
            case .small: return ReachuSpacing.md
            case .medium: return ReachuSpacing.lg
            case .large: return ReachuSpacing.xl
            }
        }
        
        var verticalPadding: CGFloat {
            switch self {
            case .small: return ReachuSpacing.md
            case .medium: return ReachuSpacing.md
            case .large: return ReachuSpacing.lg
            }
        }
        
        /// Circle padding for iconOnly mode
        var circlePadding: CGFloat {
            switch self {
            case .small: return 12
            case .medium: return 16
            case .large: return 20
            }
        }
        
        var shadowRadius: CGFloat {
            switch self {
            case .small: return 4
            case .medium: return 8
            case .large: return 12
            }
        }
    }
    
    // MARK: - Properties
    @EnvironmentObject private var cartManager: CartManager
    @SwiftUI.Environment(\.colorScheme) private var colorScheme: SwiftUI.ColorScheme
    
    @State private var isPressed = false
    @State private var bounceAnimation = false
    
    private let position: Position
    private let displayMode: DisplayMode
    private let size: Size
    private let customPadding: EdgeInsets?
    private let onTapAction: (() -> Void)?
    
    // MARK: - Initializer
    public init(
        position: Position? = nil,
        displayMode: DisplayMode? = nil,
        size: Size? = nil,
        customPadding: EdgeInsets? = nil,
        onTap: (() -> Void)? = nil
    ) {
        // Read from configuration if not provided
        let cartConfig = ReachuConfiguration.shared.cartConfiguration
        
        self.position = position ?? Position.from(cartConfig.floatingCartPosition)
        self.displayMode = displayMode ?? DisplayMode.from(cartConfig.floatingCartDisplayMode)
        self.size = size ?? Size.from(cartConfig.floatingCartSize)
        self.customPadding = customPadding
        self.onTapAction = onTap
    }
    
    public var body: some View {
        if cartManager.itemCount > 0 {
            ZStack {
                Color.clear.edgesIgnoringSafeArea(.all)
                
                // Position the cart indicator
                VStack {
                    if position.isTop {
                        cartIndicatorButton
                        Spacer()
                    } else if position.isCenter {
                        Spacer()
                        cartIndicatorButton
                        Spacer()
                    } else {
                        Spacer()
                        cartIndicatorButton
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: position.alignment)
                .padding(customPadding ?? defaultPadding)
            }
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: cartManager.itemCount)
            .onChange(of: cartManager.itemCount) { newCount in
                triggerBounceAnimation()
            }
        }
        
    }
    
    // MARK: - Cart Indicator Button
    private var cartIndicatorButton: some View {
        Button(action: {
            performHapticFeedback()
            // Use custom action if provided, otherwise use default
            if let customAction = onTapAction {
                customAction()
            } else {
                cartManager.showCheckout()
            }
        }) {
            cartContentView
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(
            minimumDuration: 0,
            maximumDistance: .infinity,
            pressing: { pressing in
                isPressed = pressing
            },
            perform: {}
        )
    }
    
    // MARK: - Cart Content View
    @ViewBuilder
    private var cartContentView: some View {
        switch displayMode {
        case .full:
            fullModeContent
        case .compact:
            compactModeContent
        case .minimal:
            minimalModeContent
        case .iconOnly:
            iconOnlyContent
        }
    }
    
    // MARK: - Display Mode Implementations
    
    private var fullModeContent: some View {
        HStack(spacing: ReachuSpacing.sm) {
            cartIconWithBadge
            
            // Price info
            VStack(alignment: .leading, spacing: 2) {
                Text("Cart")
                    .font(ReachuTypography.caption1)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.9))
                
                Text("\(cartManager.currency) \(String(format: "%.0f", cartManager.cartTotal))")
                    .font(ReachuTypography.bodyBold)
                    .foregroundColor(.white)
            }
            
            // Checkout arrow
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.horizontal, size.horizontalPadding)
        .padding(.vertical, size.verticalPadding)
        .background(cartBackground)
        .clipShape(Capsule())
        .shadow(color: ReachuColors.primary.opacity(0.3), radius: size.shadowRadius, x: 0, y: 4)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
    }
    
    private var compactModeContent: some View {
        HStack(spacing: ReachuSpacing.sm) {
            cartIconWithBadge
            
            // Price only
            Text("\(cartManager.currency) \(String(format: "%.0f", cartManager.cartTotal))")
                .font(ReachuTypography.bodyBold)
                .foregroundColor(.white)
        }
        .padding(.horizontal, size.horizontalPadding)
        .padding(.vertical, size.verticalPadding)
        .background(cartBackground)
        .clipShape(Capsule())
        .shadow(color: ReachuColors.primary.opacity(0.3), radius: size.shadowRadius, x: 0, y: 4)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
    }
    
    private var minimalModeContent: some View {
        HStack(spacing: ReachuSpacing.xs) {
            cartIconWithBadge
            
            // Count only
            Text("\(cartManager.itemCount)")
                .font(ReachuTypography.bodyBold)
                .foregroundColor(.white)
        }
        .padding(.horizontal, size.horizontalPadding)
        .padding(.vertical, size.verticalPadding)
        .background(cartBackground)
        .clipShape(Capsule())
        .shadow(color: ReachuColors.primary.opacity(0.3), radius: size.shadowRadius, x: 0, y: 4)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
    }
    
    private var iconOnlyContent: some View {
        cartIconWithBadge
            .padding(size.circlePadding)
            .background(cartBackground)
            .clipShape(Circle())
            .shadow(color: ReachuColors.primary.opacity(0.3), radius: size.shadowRadius, x: 0, y: 4)
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
    }
    
    // MARK: - Cart Icon with Badge
    private var cartIconWithBadge: some View {
        ZStack(alignment: .topTrailing) {
            Image(systemName: "cart.fill")
                .font(size.iconSize)
                .foregroundColor(.white)
                .padding(4) // Add padding to make room for badge
            
            // Item count badge - compact design that scales
            Text("\(cartManager.itemCount)")
                .font(.system(size: size == .small ? 10 : 11, weight: .bold))
                .foregroundColor(ReachuColors.primary)
                .frame(minWidth: size == .small ? 18 : 20)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(.white)
                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                )
                .offset(x: 4, y: -4)
                .scaleEffect(bounceAnimation ? 1.15 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: bounceAnimation)
        }
    }
    
    // MARK: - Background
    private var cartBackground: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                ReachuColors.primary,
                ReachuColors.primary.opacity(0.8)
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    // MARK: - Helper Properties
    
    private var defaultPadding: EdgeInsets {
        switch position {
        case .bottomRight, .bottomLeft:
            return EdgeInsets(top: 0, leading: ReachuSpacing.lg, bottom: ReachuSpacing.xl, trailing: ReachuSpacing.lg)
        case .bottomCenter:
            return EdgeInsets(top: 0, leading: ReachuSpacing.lg, bottom: ReachuSpacing.xl, trailing: ReachuSpacing.lg)
        case .topRight, .topLeft:
            return EdgeInsets(top: ReachuSpacing.xl, leading: ReachuSpacing.lg, bottom: 0, trailing: ReachuSpacing.lg)
        case .topCenter:
            return EdgeInsets(top: ReachuSpacing.xl, leading: ReachuSpacing.lg, bottom: 0, trailing: ReachuSpacing.lg)
        case .centerRight, .centerLeft:
            return EdgeInsets(top: 0, leading: ReachuSpacing.lg, bottom: 0, trailing: ReachuSpacing.lg)
        }
    }
    
    // MARK: - Helper Functions
    
    private func performHapticFeedback() {
        #if os(iOS)
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        #endif
    }
    
    private func triggerBounceAnimation() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            bounceAnimation = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                bounceAnimation = false
            }
        }
    }
}

// MARK: - Position Extensions
extension RFloatingCartIndicator.Position {
    var isTop: Bool {
        switch self {
        case .topLeft, .topRight, .topCenter:
            return true
        default:
            return false
        }
    }
    
    var isCenter: Bool {
        switch self {
        case .centerLeft, .centerRight:
            return true
        default:
            return false
        }
    }
    
    var alignment: Alignment {
        switch self {
        case .bottomRight:
            return .bottomTrailing
        case .bottomLeft:
            return .bottomLeading
        case .bottomCenter:
            return .bottom
        case .topRight:
            return .topTrailing
        case .topLeft:
            return .topLeading
        case .topCenter:
            return .top
        case .centerRight:
            return .trailing
        case .centerLeft:
            return .leading
        }
    }
    
    /// Map from configuration enum to component enum
    static func from(_ configPosition: FloatingCartPosition) -> Self {
        switch configPosition {
        case .bottomRight: return .bottomRight
        case .bottomLeft: return .bottomLeft
        case .bottomCenter: return .bottomCenter
        case .topRight: return .topRight
        case .topLeft: return .topLeft
        case .topCenter: return .topCenter
        case .centerRight: return .centerRight
        case .centerLeft: return .centerLeft
        }
    }
}

// MARK: - DisplayMode Extensions
extension RFloatingCartIndicator.DisplayMode {
    /// Map from configuration enum to component enum
    static func from(_ configMode: FloatingCartDisplayMode) -> Self {
        switch configMode {
        case .full: return .full
        case .compact: return .compact
        case .minimal: return .minimal
        case .iconOnly: return .iconOnly
        }
    }
}

// MARK: - Size Extensions
extension RFloatingCartIndicator.Size {
    /// Map from configuration enum to component enum
    static func from(_ configSize: FloatingCartSize) -> Self {
        switch configSize {
        case .small: return .small
        case .medium: return .medium
        case .large: return .large
        }
    }
}

// MARK: - Preview
#if DEBUG
import ReachuTesting

#Preview("Full Mode - Bottom Right") {
    PreviewContainer {
        RFloatingCartIndicator(
            position: .bottomRight,
            displayMode: .full,
            size: .medium
        )
    }
}

#Preview("Compact Mode - Top Left") {
    PreviewContainer {
        RFloatingCartIndicator(
            position: .topLeft,
            displayMode: .compact,
            size: .medium
        )
    }
}

#Preview("Minimal Mode - Center Right") {
    PreviewContainer {
        RFloatingCartIndicator(
            position: .centerRight,
            displayMode: .minimal,
            size: .small
        )
    }
}

#Preview("Icon Only - Bottom Center") {
    PreviewContainer {
        RFloatingCartIndicator(
            position: .bottomCenter,
            displayMode: .iconOnly,
            size: .large
        )
    }
}

#Preview("All Sizes Comparison") {
    ZStack {
        Color.gray.opacity(0.1).ignoresSafeArea()
        
        VStack(spacing: 50) {
            Text("Size Comparison")
                .font(.title2)
                .fontWeight(.bold)
            
            HStack(spacing: 30) {
                VStack {
                    Text("Small")
                        .font(.caption)
                    RFloatingCartIndicator(
                        position: .bottomCenter,
                        displayMode: .full,
                        size: .small
                    )
                    .frame(height: 100)
                }
                
                VStack {
                    Text("Medium")
                        .font(.caption)
                    RFloatingCartIndicator(
                        position: .bottomCenter,
                        displayMode: .full,
                        size: .medium
                    )
                    .frame(height: 100)
                }
                
                VStack {
                    Text("Large")
                        .font(.caption)
                    RFloatingCartIndicator(
                        position: .bottomCenter,
                        displayMode: .full,
                        size: .large
                    )
                    .frame(height: 100)
                }
            }
        }
    }
    .environmentObject({
        let manager = CartManager()
        Task {
            await manager.addProduct(MockDataProvider.shared.sampleProducts[0])
            await manager.addProduct(MockDataProvider.shared.sampleProducts[1])
        }
        return manager
    }())
}

// MARK: - Preview Helper
private struct PreviewContainer<Content: View>: View {
    @StateObject private var cartManager = CartManager()
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            // Background content
            Color.gray.opacity(0.1)
                .ignoresSafeArea()
            
            VStack {
                Text("Your App Content")
                    .font(.title)
                    .foregroundColor(.gray)
                Spacer()
            }
            
            // Cart indicator
            content
        }
        .environmentObject(cartManager)
        .onAppear {
            Task {
                await cartManager.addProduct(MockDataProvider.shared.sampleProducts[0])
                await cartManager.addProduct(MockDataProvider.shared.sampleProducts[1])
            }
        }
    }
}
#endif
