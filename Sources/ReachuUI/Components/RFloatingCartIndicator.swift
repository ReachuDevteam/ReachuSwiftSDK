import SwiftUI
import ReachuDesignSystem

/// Floating cart indicator that appears on all screens when cart has items
/// 
/// Displays cart item count and total price, provides quick access to checkout
/// Uses elegant design with animations and haptic feedback
public struct RFloatingCartIndicator: View {
    
    @EnvironmentObject private var cartManager: CartManager
    @State private var isPressed = false
    @State private var bounceAnimation = false
    
    public init() {}
    
    public var body: some View {
        if cartManager.itemCount > 0 {
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    
                    Button(action: {
                        // Haptic feedback
                        #if os(iOS)
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                        #endif
                        
                        cartManager.showCheckout()
                    }) {
                        HStack(spacing: ReachuSpacing.sm) {
                            // Cart icon with badge
                            ZStack {
                                Image(systemName: "cart.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                
                                // Item count badge
                                Text("\(cartManager.itemCount)")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(ReachuColors.primary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(.white)
                                    .clipShape(Capsule())
                                    .offset(x: 12, y: -8)
                                    .scaleEffect(bounceAnimation ? 1.2 : 1.0)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: bounceAnimation)
                            }
                            
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
                        .padding(.horizontal, ReachuSpacing.lg)
                        .padding(.vertical, ReachuSpacing.md)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    ReachuColors.primary,
                                    ReachuColors.primary.opacity(0.8)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: ReachuColors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                        .scaleEffect(isPressed ? 0.95 : 1.0)
                        .animation(.easeInOut(duration: 0.1), value: isPressed)
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
                    
                    Spacer()
                }
                .padding(.bottom, ReachuSpacing.xl)
                .padding(.horizontal, ReachuSpacing.lg)
            }
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: cartManager.itemCount)
            .onChange(of: cartManager.itemCount) { newCount in
                // Trigger bounce animation when items are added
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    bounceAnimation = true
                }
                
                // Reset bounce animation after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        bounceAnimation = false
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#if DEBUG
import ReachuTesting

#Preview("Floating Cart - With Items") {
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
        
        // Floating cart indicator
        RFloatingCartIndicator()
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

#Preview("Floating Cart - Empty") {
    ZStack {
        Color.gray.opacity(0.1)
            .ignoresSafeArea()
        
        VStack {
            Text("Your App Content")
                .font(.title)
                .foregroundColor(.gray)
            Spacer()
        }
        
        RFloatingCartIndicator()
    }
    .environmentObject(CartManager())
}
#endif
