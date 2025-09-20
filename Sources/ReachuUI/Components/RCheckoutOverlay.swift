import SwiftUI
import ReachuCore
import ReachuDesignSystem

/// Global checkout overlay that appears as a modal sheet
public struct RCheckoutOverlay: View {
    
    // MARK: - Environment
    @EnvironmentObject private var cartManager: CartManager
    
    // MARK: - State
    @State private var checkoutStep: CheckoutStep = .cart
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var currentCheckout: CreateCheckoutDto?
    
    // MARK: - Private Properties
    private let sdkClient: SdkClient
    
    // MARK: - Checkout Steps
    public enum CheckoutStep {
        case cart
        case shipping
        case payment
        case confirmation
    }
    
    // MARK: - Initialization
    public init(sdkClient: SdkClient) {
        self.sdkClient = sdkClient
    }
    
    // MARK: - Body
    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress Indicator
                checkoutProgressView
                
                // Content
                ScrollView {
                    switch checkoutStep {
                    case .cart:
                        cartReviewView
                    case .shipping:
                        shippingView
                    case .payment:
                        paymentView
                    case .confirmation:
                        confirmationView
                    }
                }
                
                // Bottom Action Button
                bottomActionButton
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        cartManager.hideCheckout()
                    }
                }
            }
        }
        .overlay {
            if isLoading {
                Color.black.opacity(0.3)
                    .overlay {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                    }
                    .ignoresSafeArea()
            }
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "")
        }
    }
    
    // MARK: - Views
    
    private var checkoutProgressView: some View {
        HStack {
            ForEach(CheckoutStep.allCases, id: \.self) { step in
                HStack {
                    Circle()
                        .fill(step.isCompleted(current: checkoutStep) ? ReachuColors.primary : ReachuColors.border)
                        .frame(width: 12, height: 12)
                    
                    if step != CheckoutStep.allCases.last {
                        Rectangle()
                            .fill(ReachuColors.border)
                            .frame(height: 1)
                    }
                }
            }
        }
        .padding(.horizontal, ReachuSpacing.lg)
        .padding(.vertical, ReachuSpacing.md)
        .background(ReachuColors.surfaceSecondary)
    }
    
    private var cartReviewView: some View {
        VStack(alignment: .leading, spacing: ReachuSpacing.lg) {
            Text("Review Your Items")
                .font(ReachuTypography.title2)
                .padding(.horizontal, ReachuSpacing.lg)
            
            if cartManager.items.isEmpty {
                emptyCartView
            } else {
                LazyVStack(spacing: ReachuSpacing.md) {
                    ForEach(cartManager.items) { item in
                        CartItemRow(item: item, cartManager: cartManager)
                    }
                }
                .padding(.horizontal, ReachuSpacing.lg)
                
                // Cart Summary
                cartSummaryView
            }
        }
        .padding(.vertical, ReachuSpacing.lg)
    }
    
    private var emptyCartView: some View {
        VStack(spacing: ReachuSpacing.lg) {
            Image(systemName: "cart")
                .font(.system(size: 48))
                .foregroundColor(ReachuColors.textSecondary)
            
            Text("Your cart is empty")
                .font(ReachuTypography.headline)
                .foregroundColor(ReachuColors.textSecondary)
            
            Text("Add some products to get started")
                .font(ReachuTypography.body)
                .foregroundColor(ReachuColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, ReachuSpacing.xl)
    }
    
    private var cartSummaryView: some View {
        VStack(spacing: ReachuSpacing.sm) {
            Divider()
            
            VStack(spacing: ReachuSpacing.xs) {
                HStack {
                    Text("Subtotal")
                        .font(ReachuTypography.body)
                    Spacer()
                    Text("\(cartManager.currency) \(String(format: "%.2f", cartManager.cartTotal))")
                        .font(ReachuTypography.bodyBold)
                }
                
                HStack {
                    Text("Shipping")
                        .font(ReachuTypography.body)
                    Spacer()
                    Text("Calculated at next step")
                        .font(ReachuTypography.body)
                        .foregroundColor(ReachuColors.textSecondary)
                }
                
                Divider()
                
                HStack {
                    Text("Total")
                        .font(ReachuTypography.headline)
                    Spacer()
                    Text("\(cartManager.currency) \(String(format: "%.2f", cartManager.cartTotal))")
                        .font(ReachuTypography.headline)
                        .foregroundColor(ReachuColors.primary)
                }
            }
        }
        .padding(.horizontal, ReachuSpacing.lg)
        .padding(.vertical, ReachuSpacing.md)
        .background(ReachuColors.surfaceSecondary)
        .cornerRadius(ReachuBorderRadius.medium)
        .padding(.horizontal, ReachuSpacing.lg)
    }
    
    private var shippingView: some View {
        VStack(alignment: .leading, spacing: ReachuSpacing.lg) {
            Text("Shipping Information")
                .font(ReachuTypography.title2)
            
            Text("Coming soon...")
                .font(ReachuTypography.body)
                .foregroundColor(ReachuColors.textSecondary)
        }
        .padding(.horizontal, ReachuSpacing.lg)
        .padding(.vertical, ReachuSpacing.lg)
    }
    
    private var paymentView: some View {
        VStack(alignment: .leading, spacing: ReachuSpacing.lg) {
            Text("Payment")
                .font(ReachuTypography.title2)
            
            Text("Payment integration coming soon...")
                .font(ReachuTypography.body)
                .foregroundColor(ReachuColors.textSecondary)
        }
        .padding(.horizontal, ReachuSpacing.lg)
        .padding(.vertical, ReachuSpacing.lg)
    }
    
    private var confirmationView: some View {
        VStack(alignment: .leading, spacing: ReachuSpacing.lg) {
            Text("Order Confirmation")
                .font(ReachuTypography.title2)
            
            Text("Order confirmation flow coming soon...")
                .font(ReachuTypography.body)
                .foregroundColor(ReachuColors.textSecondary)
        }
        .padding(.horizontal, ReachuSpacing.lg)
        .padding(.vertical, ReachuSpacing.lg)
    }
    
    private var bottomActionButton: some View {
        VStack(spacing: 0) {
            Divider()
            
            RButton(
                title: actionButtonTitle,
                style: .primary,
                size: .large,
                isLoading: isLoading,
                isDisabled: actionButtonDisabled
            ) {
                handleActionButton()
            }
            .padding(.horizontal, ReachuSpacing.lg)
            .padding(.vertical, ReachuSpacing.md)
        }
        .background(ReachuColors.surface)
    }
    
    // MARK: - Computed Properties
    
    private var navigationTitle: String {
        switch checkoutStep {
        case .cart:
            return "Cart (\(cartManager.itemCount))"
        case .shipping:
            return "Shipping"
        case .payment:
            return "Payment"
        case .confirmation:
            return "Confirmation"
        }
    }
    
    private var actionButtonTitle: String {
        switch checkoutStep {
        case .cart:
            return cartManager.items.isEmpty ? "Continue Shopping" : "Continue to Shipping"
        case .shipping:
            return "Continue to Payment"
        case .payment:
            return "Place Order"
        case .confirmation:
            return "Done"
        }
    }
    
    private var actionButtonDisabled: Bool {
        switch checkoutStep {
        case .cart:
            return false
        case .shipping, .payment:
            return true // Disabled until implemented
        case .confirmation:
            return false
        }
    }
    
    // MARK: - Actions
    
    private func handleActionButton() {
        switch checkoutStep {
        case .cart:
            if cartManager.items.isEmpty {
                cartManager.hideCheckout()
            } else {
                checkoutStep = .shipping
            }
        case .shipping:
            checkoutStep = .payment
        case .payment:
            checkoutStep = .confirmation
        case .confirmation:
            cartManager.hideCheckout()
        }
    }
}

// MARK: - Supporting Views

struct CartItemRow: View {
    let item: CartManager.CartItem
    let cartManager: CartManager
    
    var body: some View {
        HStack(spacing: ReachuSpacing.md) {
            // Product Image
            AsyncImage(url: URL(string: item.imageUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(ReachuColors.background)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundColor(ReachuColors.textSecondary)
                    }
            }
            .frame(width: 60, height: 60)
            .cornerRadius(ReachuBorderRadius.medium)
            
            // Product Info
            VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
                Text(item.title)
                    .font(ReachuTypography.bodyBold)
                    .lineLimit(2)
                
                if let brand = item.brand {
                    Text(brand)
                        .font(ReachuTypography.caption1)
                        .foregroundColor(ReachuColors.textSecondary)
                }
                
                Text("\(item.currency) \(String(format: "%.2f", item.price))")
                    .font(ReachuTypography.body)
                    .foregroundColor(ReachuColors.primary)
            }
            
            Spacer()
            
            // Quantity Controls
            VStack(spacing: ReachuSpacing.xs) {
                HStack(spacing: ReachuSpacing.xs) {
                    Button("-") {
                        if item.quantity > 1 {
                            Task {
                                await cartManager.updateQuantity(for: item, to: item.quantity - 1)
                            }
                        }
                    }
                    .frame(width: 32, height: 32)
                    .background(ReachuColors.background)
                    .cornerRadius(ReachuBorderRadius.small)
                    
                    Text("\(item.quantity)")
                        .font(ReachuTypography.bodyBold)
                        .frame(minWidth: 24)
                    
                    Button("+") {
                        Task {
                            await cartManager.updateQuantity(for: item, to: item.quantity + 1)
                        }
                    }
                    .frame(width: 32, height: 32)
                    .background(ReachuColors.background)
                    .cornerRadius(ReachuBorderRadius.small)
                }
                
                Button("Remove") {
                    Task {
                        await cartManager.removeItem(item)
                    }
                }
                .font(ReachuTypography.caption1)
                .foregroundColor(ReachuColors.error)
            }
        }
        .padding(ReachuSpacing.md)
        .background(ReachuColors.surface)
        .cornerRadius(ReachuBorderRadius.medium)
        .shadow(color: ReachuColors.textPrimary.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Checkout Step Extensions

extension RCheckoutOverlay.CheckoutStep: CaseIterable {
    public static var allCases: [RCheckoutOverlay.CheckoutStep] {
        return [.cart, .shipping, .payment, .confirmation]
    }
    
    func isCompleted(current: RCheckoutOverlay.CheckoutStep) -> Bool {
        let allCases = RCheckoutOverlay.CheckoutStep.allCases
        guard let selfIndex = allCases.firstIndex(of: self),
              let currentIndex = allCases.firstIndex(of: current) else {
            return false
        }
        return selfIndex <= currentIndex
    }
}
