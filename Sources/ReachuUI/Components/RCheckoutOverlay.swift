import SwiftUI
import ReachuCore
import ReachuDesignSystem

/// Complete checkout overlay matching original Reachu design
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public struct RCheckoutOverlay: View {
    
    // MARK: - Environment
    @EnvironmentObject private var cartManager: CartManager
    
    // MARK: - State
    @State private var checkoutStep: CheckoutStep = .address
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isEditingAddress = false
    
    // Address Information
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var phoneCountryCode = "+1"
    @State private var address1 = ""
    @State private var address2 = ""
    @State private var city = ""
    @State private var province = ""
    @State private var country = "United States"
    @State private var zip = ""
    
    // Shipping Information
    @State private var selectedShippingOption: ShippingOption = .standard
    
    // Payment Information
    @State private var selectedPaymentMethod: PaymentMethod = .stripe
    @State private var acceptsTerms = false
    @State private var acceptsPurchaseConditions = false
    
    // Discount Code
    @State private var discountCode = ""
    @State private var appliedDiscount: Double = 0.0
    @State private var discountMessage = ""
    
    // MARK: - Checkout Steps
    public enum CheckoutStep: CaseIterable {
        case address
        case orderSummary
        case review
        case success
        case error
        
        var title: String {
            switch self {
            case .address: return "Address"
            case .orderSummary: return "Order Summary"
            case .review: return "Review"
            case .success: return "Complete"
            case .error: return "Error"
            }
        }
    }
    
    // MARK: - Shipping Options
           public enum ShippingOption: String, CaseIterable {
               case standard = "standard"
               case express = "express"
        
                var displayName: String {
                    switch self {
                    case .standard: return "Free - Standard"
                    case .express: return "Express Shipping"
                    }
                }
                
                var description: String {
                    switch self {
                    case .standard: return "Delivery by Jun 28"
                    case .express: return "Delivery by Jun 25"
                    }
                }
                
                var price: Double {
                    switch self {
                    case .standard: return 0.0
                    case .express: return 9.99
                    }
                }
                
                var icon: String {
                    switch self {
                    case .standard: return "shippingbox"
                    case .express: return "airplane"
                    }
                }
    }
    
    // MARK: - Payment Methods (Real Reachu Methods)
           public enum PaymentMethod: String, CaseIterable {
               case stripe = "stripe"
               case klarna = "klarna"
        
                var displayName: String {
                    switch self {
                    case .stripe: return "Credit Card"
                    case .klarna: return "Pay with Klarna"
                    }
                }
                
                var icon: String {
                    switch self {
                    case .stripe: return "creditcard.fill"
                    case .klarna: return "k.square.fill"
                    }
                }
                
                var iconColor: Color {
                    switch self {
                    case .stripe: return .purple
                    case .klarna: return Color(hex: "#FFB3C7")
                    }
                }
                
                var supportsInstallments: Bool {
                    switch self {
                    case .klarna:
                        return true
                    default:
                        return false
                    }
                }
    }
    
    // MARK: - Initialization
    public init() {}
    
    // MARK: - Body
    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Content based on step
                switch checkoutStep {
                case .address:
                    addressStepView
                case .orderSummary:
                    orderSummaryStepView
                case .review:
                    reviewStepView
                case .success:
                    successStepView
                case .error:
                    errorStepView
                }
            }
            .navigationTitle("Checkout")
            #if os(iOS) || os(tvOS) || os(watchOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if checkoutStep != .success {
                        Button("", systemImage: "arrow.left") {
                            if checkoutStep == .address {
                                cartManager.hideCheckout()
                            } else {
                                goToPreviousStep()
                            }
                        }
                        .foregroundColor(ReachuColors.textPrimary)
                    } else {
                        EmptyView()
                    }
                }
            }
        }
        .overlay {
            if isLoading {
                loadingOverlay
            }
        }
        .onAppear {
            fillDemoData()
        }
    }
    
    // MARK: - Address Step View
    private var addressStepView: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: ReachuSpacing.xl) {
                    // 1. CART SECTION (Products first)
                    VStack(alignment: .leading, spacing: ReachuSpacing.md) {
                        Text("Cart")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(ReachuColors.textPrimary)
                            .padding(.horizontal, ReachuSpacing.lg)
                        
                        // Individual Products with Quantity
                        individualProductsWithQuantityView
                    }
                    .padding(.top, ReachuSpacing.lg)
                    
                    // 2. SHIPPING ADDRESS SECTION (consistent sizing)
                    VStack(alignment: .leading, spacing: ReachuSpacing.md) {
                        HStack {
                            Text("Shipping Address")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(ReachuColors.textPrimary)
                            
                            Spacer()
                            
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    isEditingAddress.toggle()
                                }
                            }) {
                                Image(systemName: isEditingAddress ? "checkmark" : "pencil")
                                    .foregroundColor(ReachuColors.primary)
                                    .font(.system(size: 16))
                            }
                        }
                        .padding(.horizontal, ReachuSpacing.lg)
                        
                        // Address Display or Edit Form
                        Group {
                            if isEditingAddress {
                                addressEditForm
                                    .transition(AnyTransition.opacity.combined(with: AnyTransition.move(edge: .top)))
                            } else {
                                addressDisplayView
                                    .transition(AnyTransition.opacity.combined(with: AnyTransition.move(edge: .top)))
                            }
                        }
                        .animation(.easeInOut(duration: 0.3), value: isEditingAddress)
                        
                        // Shipping Options (smaller)
                        compactShippingOptionsView
                    }
                    
                    // 3. ORDER SUMMARY SECTION (at bottom)
                    VStack(alignment: .leading, spacing: ReachuSpacing.md) {
                        Text("Order Summary")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(ReachuColors.textPrimary)
                            .padding(.horizontal, ReachuSpacing.lg)
                        
                        // Order totals with shipping
                        addressOrderSummaryView
                    }
                    
                    Spacer(minLength: 100)
                }
            }
            
            // Bottom Button - Full Width
            VStack {
                RButton(
                    title: "Proceed to Checkout",
                    style: .primary,
                    size: .large,
                    isDisabled: !canProceedToNext
                ) {
                    proceedToNext()
                }
                .frame(maxWidth: .infinity) // Full width
                .padding(.horizontal, ReachuSpacing.lg)
                .padding(.vertical, ReachuSpacing.md)
            }
            .background(ReachuColors.surface)
        }
    }
    
    // MARK: - Order Summary Step View (Payment + Discount + Summary)
    private var orderSummaryStepView: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: ReachuSpacing.xl) {
                    // Cart Section (smaller, readonly)
                    VStack(alignment: .leading, spacing: ReachuSpacing.md) {
                        Text("Cart")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(ReachuColors.textPrimary)
                            .padding(.horizontal, ReachuSpacing.lg)
                        
                        // Compact readonly products
                        compactReadonlyCartView
                    }
                    
                    // Payment Method Selection
                    VStack(alignment: .leading, spacing: ReachuSpacing.md) {
                        Text("Payment Method")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(ReachuColors.textPrimary)
                        
                        VStack(spacing: ReachuSpacing.sm) {
                            ForEach(PaymentMethod.allCases, id: \.self) { method in
                                PaymentMethodRowCompact(
                                    method: method,
                                    isSelected: selectedPaymentMethod == method
                                ) {
                                    selectedPaymentMethod = method
                                }
                            }
                        }
                    }
                    .padding(.horizontal, ReachuSpacing.lg)
                    
                    // Klarna installments Details
                    if selectedPaymentMethod == .klarna {
                        PaymentScheduleCompact(total: finalTotal, currency: cartManager.currency)
                            .padding(.horizontal, ReachuSpacing.lg)
                    }
                    
                    // Discount Code Section
                    discountCodeSection
                    
                    // Order Summary
                    orderSummarySection
                    
                    Spacer(minLength: 100)
                }
                .padding(.top, ReachuSpacing.lg)
            }
            
            // Bottom Button - Full Width
            VStack {
                RButton(
                    title: "Initiate Payment",
                    style: .primary,
                    size: .large,
                    isDisabled: !canProceedToNext
                ) {
                    proceedToNext()
                }
                .frame(maxWidth: .infinity) // Full width
                .padding(.horizontal, ReachuSpacing.lg)
                .padding(.vertical, ReachuSpacing.md)
            }
            .background(ReachuColors.surface)
        }
    }
    
    // MARK: - Payment Step View (now Review Step)
    private var paymentStepView: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: ReachuSpacing.lg) {
                    // Product Summary Header - EXACTLY like the image
                    HStack {
                        Text("Product Summary")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(ReachuColors.textPrimary)
                        
                        Spacer()
                        
                        Text("\(cartManager.currency) \(String(format: "%.2f", finalTotal))")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(ReachuColors.textPrimary)
                    }
                    .padding(.horizontal, ReachuSpacing.lg)
                    .padding(.top, ReachuSpacing.lg)
                    
                    // Products List - Each product with individual quantity controls
                    VStack(spacing: ReachuSpacing.xl) {
                        ForEach(Array(cartManager.items.enumerated()), id: \.offset) { index, item in
                            VStack(spacing: ReachuSpacing.md) {
                                // Product header with image and details
                                HStack(spacing: ReachuSpacing.md) {
                                    // Product image
                                    AsyncImage(url: URL(string: item.imageUrl ?? "")) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        Rectangle()
                                            .fill(Color.yellow) // Placeholder like in image
                                    }
                                    .frame(width: 60, height: 60)
                                    .cornerRadius(8)
                                    
                                    VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
                                        Text(item.brand ?? "Reachu Audio")
                                            .font(.system(size: 14, weight: .regular))
                                            .foregroundColor(ReachuColors.textSecondary)
                                        
                                        Text(item.title)
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(ReachuColors.textPrimary)
                                            .lineLimit(2)
                                    }
                                    
                                    Spacer()
                                    
                                    Text("\(item.currency) \(String(format: "%.2f", item.price))")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(ReachuColors.textPrimary)
                                }
                                
                                // Product details
                                VStack(spacing: ReachuSpacing.xs) {
                                    HStack {
                                        Text("Order ID:")
                                            .font(.system(size: 14, weight: .regular))
                                            .foregroundColor(ReachuColors.textSecondary)
                                        
                                        Spacer()
                                        
                                        Text("BD23672983")
                                            .font(.system(size: 14, weight: .regular))
                                            .foregroundColor(ReachuColors.textSecondary)
                                    }
                                    
                                    HStack {
                                        Text("Colors:")
                                            .font(.system(size: 14, weight: .regular))
                                            .foregroundColor(ReachuColors.textSecondary)
                                        
                                        Spacer()
                                        
                                        Text("Like Water")
                                            .font(.system(size: 14, weight: .regular))
                                            .foregroundColor(ReachuColors.textSecondary)
                                    }
                                }
                                
                                // Read-only Quantity Display (NO controls in payment step)
                                HStack {
                                    Text("Quantity")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(ReachuColors.textPrimary)
                                    
                                    Spacer()
                                    
                                    Text("\(item.quantity)")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(ReachuColors.textPrimary)
                                }
                                
                                // Show total for this product
                                HStack {
                                    Text("Total for this item:")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(ReachuColors.textSecondary)
                                    
                                    Spacer()
                                    
                                    Text("\(item.currency) \(String(format: "%.2f", item.price * Double(item.quantity)))")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(ReachuColors.primary)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, ReachuSpacing.lg)
                    
                    // Complete Order Summary (totals, taxes, etc.)
                    completeOrderSummaryView
                    
                    // Payment Schedule (if Klarna installments selected)
                    if selectedPaymentMethod == .klarna {
                        VStack(alignment: .leading, spacing: ReachuSpacing.md) {
                            Text("Payment Schedule")
                                .font(ReachuTypography.bodyBold)
                                .foregroundColor(ReachuColors.textPrimary)
                                .padding(.horizontal, ReachuSpacing.lg)
                            
                            PaymentScheduleDetailed(total: finalTotal, currency: cartManager.currency)
                                .padding(.horizontal, ReachuSpacing.lg)
                        }
                    }
                    
                    Spacer(minLength: 100)
                }
            }
            
            // Bottom Button
            VStack {
                RButton(
                    title: "Payment",
                    style: .primary,
                    size: .large
                ) {
                    proceedToNext()
                }
                .padding(.horizontal, ReachuSpacing.lg)
                .padding(.vertical, ReachuSpacing.md)
            }
            .background(ReachuColors.surface)
        }
    }
    
    // Helper function for the simple summary rows
    private func summaryDetailRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(ReachuColors.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(ReachuColors.textPrimary)
        }
    }
    
    // MARK: - Review Step View
    private var reviewStepView: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: ReachuSpacing.lg) {
                    Text("Review Order")
                        .font(ReachuTypography.title2)
                        .foregroundColor(ReachuColors.textPrimary)
                        .padding(.horizontal, ReachuSpacing.lg)
                        .padding(.top, ReachuSpacing.lg)
                    
                    // Complete order summary would go here
                    Text("Order review content...")
                        .padding(.horizontal, ReachuSpacing.lg)
                    
                    Spacer(minLength: 100)
                }
            }
            
            // Bottom Button
            VStack {
                RButton(
                    title: "Complete Purchase",
                    style: .primary,
                    size: .large
                ) {
                    simulatePayment()
                }
                .padding(.horizontal, ReachuSpacing.lg)
                .padding(.vertical, ReachuSpacing.md)
            }
            .background(ReachuColors.surface)
        }
    }
    
    // MARK: - Success Step View
    private var successStepView: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: ReachuSpacing.lg) {
                // Animated Success Icon
                ZStack {
                    Circle()
                        .fill(ReachuColors.success)
                        .frame(width: 100, height: 100)
                        .scaleEffect(checkoutStep == .success ? 1.0 : 0.5)
                        .animation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.2), value: checkoutStep)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 45, weight: .bold))
                        .foregroundColor(.white)
                        .scaleEffect(checkoutStep == .success ? 1.0 : 0.0)
                        .animation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.4), value: checkoutStep)
                }
                
                // Success Message (smaller and more compact)
                VStack(spacing: ReachuSpacing.sm) {
                    Text("Purchase Complete!")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(ReachuColors.textPrimary)
                        .multilineTextAlignment(.center)
                        .opacity(checkoutStep == .success ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 0.5).delay(0.6), value: checkoutStep)
                    
                    Text(selectedPaymentMethod == .klarna ? 
                         "You'll pay in 4x interest-free. We'll send you a reminder a few days before each payment." :
                         "Your order has been confirmed. You'll receive an email confirmation shortly.")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(ReachuColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, ReachuSpacing.xl)
                        .opacity(checkoutStep == .success ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 0.5).delay(0.8), value: checkoutStep)
                }
            }
            
            Spacer()
            
            // Bottom Close Button
            VStack {
                RButton(
                    title: "Close",
                    style: .primary,
                    size: .large
                ) {
                    cartManager.hideCheckout()
                    Task {
                        await cartManager.clearCart()
                    }
                }
                .padding(.horizontal, ReachuSpacing.lg)
                .padding(.bottom, ReachuSpacing.xl)
                .opacity(checkoutStep == .success ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.5).delay(1.0), value: checkoutStep)
            }
        }
    }
    
    // MARK: - Error Step View
    private var errorStepView: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: ReachuSpacing.lg) {
                // Animated Error Icon
                ZStack {
                    Circle()
                        .fill(ReachuColors.error)
                        .frame(width: 100, height: 100)
                        .scaleEffect(checkoutStep == .error ? 1.0 : 0.5)
                        .animation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.2), value: checkoutStep)
                    
                    Image(systemName: "xmark")
                        .font(.system(size: 45, weight: .bold))
                        .foregroundColor(.white)
                        .scaleEffect(checkoutStep == .error ? 1.0 : 0.0)
                        .animation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.4), value: checkoutStep)
                }
                
                // Error Message
                VStack(spacing: ReachuSpacing.sm) {
                    Text("Payment Failed")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(ReachuColors.textPrimary)
                        .multilineTextAlignment(.center)
                        .opacity(checkoutStep == .error ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 0.5).delay(0.6), value: checkoutStep)
                    
                    Text("There was an issue processing your payment. Please check your payment information and try again.")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(ReachuColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, ReachuSpacing.xl)
                        .opacity(checkoutStep == .error ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 0.5).delay(0.8), value: checkoutStep)
                }
            }
            
            Spacer()
            
            // Bottom Action Buttons
            VStack(spacing: ReachuSpacing.md) {
                RButton(
                    title: "Try Again",
                    style: .primary,
                    size: .large
                ) {
                    // Go back to order summary to retry
                    checkoutStep = .orderSummary
                }
                .opacity(checkoutStep == .error ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.5).delay(1.0), value: checkoutStep)
                
                RButton(
                    title: "Go Back",
                    style: .secondary,
                    size: .large
                ) {
                    cartManager.hideCheckout()
                }
                .opacity(checkoutStep == .error ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.5).delay(1.1), value: checkoutStep)
            }
            .padding(.horizontal, ReachuSpacing.lg)
            .padding(.bottom, ReachuSpacing.xl)
        }
    }
    
    // MARK: - Helper Views
    
    private var loadingOverlay: some View {
        Color.black.opacity(0.3)
            .overlay {
                VStack(spacing: ReachuSpacing.md) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                    
                    Text("Processing...")
                        .font(ReachuTypography.body)
                        .foregroundColor(.white)
                }
            }
            .ignoresSafeArea()
    }
    
    // MARK: - Helper Functions
    
    private var canProceedToNext: Bool {
        switch checkoutStep {
        case .address:
            return !firstName.isEmpty && !lastName.isEmpty && !email.isEmpty && !phone.isEmpty && !address1.isEmpty && !city.isEmpty && !zip.isEmpty
        case .orderSummary:
            return true
        case .review:
            return true
        case .success, .error:
            return false
        }
    }
    
    private func goToPreviousStep() {
        withAnimation(.easeInOut(duration: 0.3)) {
            switch checkoutStep {
            case .orderSummary:
                checkoutStep = .address
            case .review:
                checkoutStep = .orderSummary
            default:
                break
            }
        }
    }
    
    private func proceedToNext() {
        withAnimation(.easeInOut(duration: 0.3)) {
            switch checkoutStep {
            case .address:
                checkoutStep = .orderSummary
            case .orderSummary:
                checkoutStep = .review
            case .review:
                simulatePayment()
            case .success, .error:
                break
            }
        }
    }
    
    private func simulatePayment() {
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isLoading = false
            
            // Simulate payment success/failure (90% success rate for demo)
            let isSuccess = Double.random(in: 0...1) > 0.1
            
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                checkoutStep = isSuccess ? .success : .error
            }
            
            #if os(iOS)
            let impactFeedback = UIImpactFeedbackGenerator(style: isSuccess ? .heavy : .rigid)
            impactFeedback.impactOccurred()
            #endif
        }
    }
    
    private func fillDemoData() {
        firstName = "John"
        lastName = "Doe"
        email = "john.doe@example.com"
        phone = "(555) 123-4456"
        phoneCountryCode = "+1"
        address1 = "82 Melora Street"
        city = "Westbridge"
        province = "CA"
        country = "United States"
        zip = "92841"
    }
}

// MARK: - Supporting Components

struct PaymentMethodRowCompact: View {
    let method: RCheckoutOverlay.PaymentMethod
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: ReachuSpacing.md) {
                // Selection Circle
                ZStack {
                    Circle()
                        .stroke(isSelected ? ReachuColors.primary : ReachuColors.border, lineWidth: 2)
                        .frame(width: 20, height: 20)
                    
                    if isSelected {
                        Circle()
                            .fill(ReachuColors.primary)
                            .frame(width: 12, height: 12)
                    }
                }
                
                // Payment Method Icon
                Image(systemName: method.icon)
                    .font(.title3)
                    .foregroundColor(method.iconColor)
                    .frame(width: 25)
                
                // Payment Method Name
                Text(method.displayName)
                    .font(ReachuTypography.body)
                    .foregroundColor(ReachuColors.textPrimary)
                
                Spacer()
            }
            .padding(.vertical, ReachuSpacing.sm)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PaymentScheduleCompact: View {
    let total: Double
    let currency: String
    
    private var installmentAmount: Double {
        total / 4.0
    }
    
    var body: some View {
        HStack(spacing: ReachuSpacing.lg) {
            ForEach(1...4, id: \.self) { installment in
                VStack(spacing: ReachuSpacing.xs) {
                    ZStack {
                        Circle()
                            .fill(installment == 1 ? ReachuColors.primary : ReachuColors.border)
                            .frame(width: 24, height: 24)
                        
                        Text("\(installment)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(installment == 1 ? .white : ReachuColors.textSecondary)
                    }
                    
                    Text(installment == 1 ? "Due Today" : "In \(installment - 1) month\(installment > 2 ? "s" : "")")
                        .font(.system(size: 10))
                        .foregroundColor(ReachuColors.textSecondary)
                    
                    Text("\(currency) \(String(format: "%.2f", installmentAmount))")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(ReachuColors.textPrimary)
                }
            }
        }
        .padding(ReachuSpacing.md)
        .background(ReachuColors.surfaceSecondary)
        .cornerRadius(ReachuBorderRadius.medium)
    }
}

struct PaymentScheduleDetailed: View {
    let total: Double
    let currency: String
    
    private var installmentAmount: Double {
        total / 4.0
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Paynex account info
            HStack {
                Image(systemName: "x.square.fill")
                    .foregroundColor(ReachuColors.primary)
                    .font(.title2)
                
                VStack(alignment: .leading) {
                    Text("Paynex account")
                        .font(ReachuTypography.bodyBold)
                        .foregroundColor(ReachuColors.textPrimary)
                    
                    Text("028*********240")
                        .font(ReachuTypography.caption1)
                        .foregroundColor(ReachuColors.textSecondary)
                }
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "ellipsis")
                        .foregroundColor(ReachuColors.textSecondary)
                }
            }
            .padding(.bottom, ReachuSpacing.md)
            
            // Payment schedule circles
            HStack(spacing: 0) {
                ForEach(1...4, id: \.self) { installment in
                    VStack(spacing: ReachuSpacing.xs) {
                        ZStack {
                            Circle()
                                .fill(installment == 1 ? ReachuColors.primary : ReachuColors.border)
                                .frame(width: 32, height: 32)
                            
                            Text("\(installment)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(installment == 1 ? .white : ReachuColors.textSecondary)
                        }
                        
                        Text(installment == 1 ? "Due Today" : "In \(installment - 1) month\(installment > 2 ? "s" : "")")
                            .font(.system(size: 11))
                            .foregroundColor(ReachuColors.textSecondary)
                        
                        Text("\(currency) \(String(format: "%.2f", installmentAmount))")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(ReachuColors.textPrimary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, ReachuSpacing.lg)
            
            // Down payment summary
            HStack {
                Text("Down payment due today")
                    .font(ReachuTypography.bodyBold)
                    .foregroundColor(ReachuColors.textPrimary)
                
                Spacer()
                
                Text("\(currency) \(String(format: "%.2f", installmentAmount))")
                    .font(ReachuTypography.title3)
                    .foregroundColor(ReachuColors.textPrimary)
            }
        }
        .padding(ReachuSpacing.lg)
        .background(ReachuColors.surfaceSecondary)
        .cornerRadius(ReachuBorderRadius.medium)
    }
}

// MARK: - RCheckoutOverlay Helper Views Extension
extension RCheckoutOverlay {
    
    private var addressDisplayView: some View {
        VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
            Text("\(firstName) \(lastName)")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(ReachuColors.textPrimary)
            
            Text(address1)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(ReachuColors.textPrimary)
            
            if !address2.isEmpty {
                Text(address2)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(ReachuColors.textPrimary)
            }
            
            Text("\(city), \(province), \(country)")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(ReachuColors.textPrimary)
            
            Text(zip)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(ReachuColors.textPrimary)
            
            HStack {
                Text("Phone :")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(ReachuColors.textPrimary)
                
                Text("\(phoneCountryCode) \(phone)")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(ReachuColors.textPrimary)
            }
        }
        .padding(.horizontal, ReachuSpacing.lg)
    }
    
    private var addressEditForm: some View {
        VStack(spacing: ReachuSpacing.md) {
            // Name fields
            HStack(spacing: ReachuSpacing.md) {
                VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
                    Text("First Name")
                        .font(ReachuTypography.caption1)
                        .foregroundColor(ReachuColors.textSecondary)
                    TextField("John", text: $firstName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
                    Text("Last Name")
                        .font(ReachuTypography.caption1)
                        .foregroundColor(ReachuColors.textSecondary)
                    TextField("Doe", text: $lastName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }
            
            // Email
            VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
                Text("Email")
                    .font(ReachuTypography.caption1)
                    .foregroundColor(ReachuColors.textSecondary)
                TextField("your@email.com", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    #if os(iOS) || os(tvOS) || os(watchOS)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    #endif
            }
            
            // Phone with country code
            VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
                Text("Phone")
                    .font(ReachuTypography.caption1)
                    .foregroundColor(ReachuColors.textSecondary)
                
                HStack(spacing: ReachuSpacing.sm) {
                    CountryCodePicker(selectedCode: $phoneCountryCode)
                        .frame(width: 80)
                    
                    TextField("(555) 123-4456", text: $phone)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }
            
            // Address
            VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
                Text("Address")
                    .font(ReachuTypography.caption1)
                    .foregroundColor(ReachuColors.textSecondary)
                TextField("Street address", text: $address1)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                TextField("Apt, suite, etc. (optional)", text: $address2)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            // City, State, ZIP
            HStack(spacing: ReachuSpacing.md) {
                VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
                    Text("City")
                        .font(ReachuTypography.caption1)
                        .foregroundColor(ReachuColors.textSecondary)
                    TextField("City", text: $city)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
                    Text("State")
                        .font(ReachuTypography.caption1)
                        .foregroundColor(ReachuColors.textSecondary)
                    TextField("State", text: $province)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
                    Text("ZIP")
                        .font(ReachuTypography.caption1)
                        .foregroundColor(ReachuColors.textSecondary)
                    TextField("ZIP", text: $zip)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        #if os(iOS) || os(tvOS) || os(watchOS)
                        .keyboardType(.numberPad)
                        #endif
                }
            }
            
            // Country
            VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
                Text("Country")
                    .font(ReachuTypography.caption1)
                    .foregroundColor(ReachuColors.textSecondary)
                CountryPicker(selectedCountry: $country)
            }
        }
        .padding(.horizontal, ReachuSpacing.lg)
    }
    
    // Individual products with quantity controls for address step (like the image)
    private var individualProductsWithQuantityView: some View {
        VStack(spacing: ReachuSpacing.xl) {
            ForEach(Array(cartManager.items.enumerated()), id: \.offset) { index, item in
                VStack(spacing: ReachuSpacing.md) {
                    // Product header with image and details
                    HStack(spacing: ReachuSpacing.md) {
                        // Product image
                        AsyncImage(url: URL(string: item.imageUrl ?? "")) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle()
                                .fill(Color.yellow) // Placeholder like in image
                        }
                        .frame(width: 60, height: 60)
                        .cornerRadius(8)
                        
                        VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
                            Text(item.brand ?? "Reachu Audio")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(ReachuColors.textSecondary)
                            
                            Text(item.title)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(ReachuColors.textPrimary)
                                .lineLimit(2)
                            
                            // Quantity controls below title (more compact)
                            HStack(spacing: ReachuSpacing.sm) {
                                Button(action: {
                                    if item.quantity > 1 {
                                        Task {
                                            await cartManager.updateQuantity(for: item, to: item.quantity - 1)
                                        }
                                    }
                                }) {
                                    Image(systemName: "minus")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(ReachuColors.textPrimary)
                                        .frame(width: 28, height: 28)
                                        .background(ReachuColors.surfaceSecondary)
                                        .cornerRadius(4)
                                }
                                .disabled(item.quantity <= 1)
                                
                                Text("\(item.quantity)")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(ReachuColors.textPrimary)
                                    .frame(width: 30)
                                    .animation(.spring(), value: item.quantity)
                                
                                Button(action: {
                                    Task {
                                        await cartManager.updateQuantity(for: item, to: item.quantity + 1)
                                    }
                                }) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(ReachuColors.textPrimary)
                                        .frame(width: 28, height: 28)
                                        .background(ReachuColors.surfaceSecondary)
                                        .cornerRadius(4)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        Text("\(item.currency) \(String(format: "%.2f", item.price))")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(ReachuColors.textPrimary)
                    }
                    
                    // Product details
                    VStack(spacing: ReachuSpacing.xs) {
                        HStack {
                            Text("Order ID:")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(ReachuColors.textSecondary)
                            
                            Spacer()
                            
                            Text("BD23672983")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(ReachuColors.textSecondary)
                        }
                        
                        HStack {
                            Text("Colors:")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(ReachuColors.textSecondary)
                            
                            Spacer()
                            
                            Text("Like Water")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(ReachuColors.textSecondary)
                        }
                    }
                    
                    // Show total for this product
                    HStack {
                        Text("Total for this item:")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(ReachuColors.textSecondary)
                        
                        Spacer()
                        
                        Text("\(item.currency) \(String(format: "%.2f", item.price * Double(item.quantity)))")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(ReachuColors.primary)
                    }
                }
            }
        }
        .padding(.horizontal, ReachuSpacing.lg)
    }
    
    private func sexyProductCard(for item: CartManager.CartItem) -> some View {
        VStack(spacing: 0) {
            // Product Card with Shadow and Modern Design
            HStack(spacing: ReachuSpacing.md) {
                // Sexy Product Image with Gradient Overlay
                ZStack {
                    AsyncImage(url: URL(string: item.imageUrl ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 90, height: 90)
                            .clipped()
                    } placeholder: {
                        RoundedRectangle(cornerRadius: ReachuBorderRadius.large)
                            .fill(
                                LinearGradient(
                                    colors: [ReachuColors.surfaceSecondary, ReachuColors.background],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay {
                                Image(systemName: "photo")
                                    .font(.title2)
                                    .foregroundColor(ReachuColors.textSecondary.opacity(0.6))
                            }
                    }
                    
                    // Subtle gradient overlay for depth
                    LinearGradient(
                        colors: [Color.clear, Color.black.opacity(0.1)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
                .frame(width: 90, height: 90)
                .cornerRadius(ReachuBorderRadius.large)
                .shadow(color: ReachuColors.textPrimary.opacity(0.1), radius: 8, x: 0, y: 4)
                
                // Product Details with Elegant Typography
                VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
                    // Brand with subtle styling
                    Text(item.brand ?? "Adidas Store")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(ReachuColors.textSecondary)
                        .textCase(.uppercase)
                    
                    // Product name with emphasis
                    Text(item.title)
                        .font(.system(size: 16, weight: .bold, design: .default))
                        .foregroundColor(ReachuColors.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    // Order ID with modern styling
                    HStack(spacing: ReachuSpacing.xs) {
                        Image(systemName: "number.circle.fill")
                            .font(.caption2)
                            .foregroundColor(ReachuColors.primary.opacity(0.7))
                        
                        Text("BD23672983")
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(ReachuColors.textSecondary)
                    }
                    
                    // Colors with stylish presentation
                    HStack(spacing: ReachuSpacing.xs) {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 12, height: 12)
                        
                        Text("Like Water")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(ReachuColors.textSecondary)
                    }
                }
                
                Spacer()
                
                // Price Section with Modern Layout
                VStack(alignment: .trailing, spacing: ReachuSpacing.xs) {
                    // Main price with bold styling
                    Text("\(item.currency) \(String(format: "%.2f", item.price * Double(item.quantity)))")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(ReachuColors.textPrimary)
                    
                    // Quantity with subtle background
                    HStack(spacing: ReachuSpacing.xs) {
                        Text("×")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(ReachuColors.textSecondary)
                        
                        Text("\(item.quantity)")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(ReachuColors.primary)
                    }
                    .padding(.horizontal, ReachuSpacing.sm)
                    .padding(.vertical, ReachuSpacing.xs)
                    .background(ReachuColors.primary.opacity(0.1))
                    .cornerRadius(ReachuBorderRadius.small)
                }
            }
            .padding(ReachuSpacing.lg)
            .background(ReachuColors.surface)
            .cornerRadius(ReachuBorderRadius.large)
            .shadow(color: ReachuColors.textPrimary.opacity(0.05), radius: 12, x: 0, y: 6)
        }
        .padding(.horizontal, ReachuSpacing.lg)
    }
    
    private var discountCodeSection: some View {
        VStack(alignment: .leading, spacing: ReachuSpacing.md) {
            Text("Discount Code")
                .font(ReachuTypography.bodyBold)
                .foregroundColor(ReachuColors.textPrimary)
            
            HStack(spacing: ReachuSpacing.md) {
                TextField("Enter discount code", text: $discountCode)
                    .font(ReachuTypography.body)
                    .foregroundColor(ReachuColors.textPrimary)
                    .padding(.horizontal, ReachuSpacing.md)
                    .padding(.vertical, ReachuSpacing.sm)
                    .background(ReachuColors.surfaceSecondary)
                    .cornerRadius(ReachuBorderRadius.medium)
                    .overlay(
                        RoundedRectangle(cornerRadius: ReachuBorderRadius.medium)
                            .stroke(ReachuColors.border, lineWidth: 1)
                    )
                
                RButton(
                    title: "Apply",
                    style: .primary,
                    size: .medium
                ) {
                    applyDiscountCode()
                }
            }
            
            // Discount message
            if !discountMessage.isEmpty {
                HStack {
                    Image(systemName: appliedDiscount > 0 ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                        .font(.body)
                        .foregroundColor(appliedDiscount > 0 ? ReachuColors.success : ReachuColors.error)
                    
                    Text(discountMessage)
                        .font(ReachuTypography.caption1)
                        .foregroundColor(appliedDiscount > 0 ? ReachuColors.success : ReachuColors.error)
                }
                .transition(AnyTransition.opacity.combined(with: AnyTransition.move(edge: .top)))
            }
        }
        .padding(.horizontal, ReachuSpacing.lg)
    }
    
    private var orderSummarySection: some View {
        VStack(spacing: ReachuSpacing.md) {
            Text("Order Summary")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(ReachuColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: ReachuSpacing.sm) {
                // Subtotal
                HStack {
                    Text("Subtotal")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(ReachuColors.textSecondary)
                    
                    Spacer()
                    
                    Text("\(cartManager.currency) \(String(format: "%.2f", cartManager.cartTotal))")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(ReachuColors.textPrimary)
                }
                
                // Shipping
                HStack {
                    Text("Shipping")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(ReachuColors.textSecondary)
                    
                    Spacer()
                    
                    Text(selectedShippingOption.price > 0 ? "\(cartManager.currency) \(String(format: "%.2f", selectedShippingOption.price))" : "Free")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(ReachuColors.textPrimary)
                }
                
                // Show discount if applied
                if appliedDiscount > 0 {
                    HStack {
                        Text("Discount")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(ReachuColors.success)
                        
                        Spacer()
                        
                        Text("-\(cartManager.currency) \(String(format: "%.2f", appliedDiscount))")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(ReachuColors.success)
                    }
                }
                
                // Tax
                HStack {
                    Text("Tax")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(ReachuColors.textSecondary)
                    
                    Spacer()
                    
                    Text("\(cartManager.currency) 0.00")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(ReachuColors.textPrimary)
                }
                
                // Divider
                Rectangle()
                    .fill(ReachuColors.border)
                    .frame(height: 1)
                
                // Total
                HStack {
                    Text("Total")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(ReachuColors.textPrimary)
                    
                    Spacer()
                    
                    Text("\(cartManager.currency) \(String(format: "%.2f", finalTotal))")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(ReachuColors.primary)
                }
            }
        }
        .padding(.horizontal, ReachuSpacing.lg)
    }
    
    private func summaryRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(ReachuColors.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(ReachuColors.textPrimary)
        }
    }
    
    // Global quantity control for address step (like image 1)
    private var globalQuantityControlView: some View {
        HStack {
            Text("Quantity")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(ReachuColors.textPrimary)
            
            Spacer()
            
            HStack(spacing: ReachuSpacing.lg) {
                Button(action: {
                    // Decrease entire order quantity
                    if cartManager.itemCount > 1 {
                        Task {
                            for item in cartManager.items {
                                if item.quantity > 1 {
                                    await cartManager.updateQuantity(for: item, to: item.quantity - 1)
                                }
                            }
                        }
                    }
                }) {
                    Image(systemName: "minus")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(ReachuColors.textPrimary)
                        .frame(width: 44, height: 44)
                        .background(ReachuColors.surfaceSecondary)
                        .cornerRadius(8)
                }
                .disabled(cartManager.itemCount <= cartManager.items.count) // Can't go below 1 per item
                
                Text("\(cartManager.itemCount)")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(ReachuColors.textPrimary)
                    .frame(width: 60)
                    .animation(.spring(), value: cartManager.itemCount)
                
                Button(action: {
                    // Increase entire order quantity
                    Task {
                        for item in cartManager.items {
                            await cartManager.updateQuantity(for: item, to: item.quantity + 1)
                        }
                    }
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(ReachuColors.textPrimary)
                        .frame(width: 44, height: 44)
                        .background(ReachuColors.surfaceSecondary)
                        .cornerRadius(8)
                }
            }
        }
        .padding(.horizontal, ReachuSpacing.lg)
    }
    
    private var shippingOptionsView: some View {
        VStack(alignment: .leading, spacing: ReachuSpacing.md) {
            Text("Shipping")
                .font(ReachuTypography.bodyBold)
                .foregroundColor(ReachuColors.textPrimary)
            
            ForEach(ShippingOption.allCases, id: \.self) { option in
                ShippingOptionRow(
                    option: option,
                    isSelected: selectedShippingOption == option
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedShippingOption = option
                    }
                }
            }
        }
        .padding(.horizontal, ReachuSpacing.lg)
    }
    
    // Compact shipping options for address step
    private var compactShippingOptionsView: some View {
        VStack(alignment: .leading, spacing: ReachuSpacing.sm) {
            Text("Shipping")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(ReachuColors.textPrimary)
                .padding(.horizontal, ReachuSpacing.lg)
            
            VStack(spacing: ReachuSpacing.xs) {
                ForEach(ShippingOption.allCases, id: \.self) { option in
                    Button(action: {
                        selectedShippingOption = option
                    }) {
                        HStack(spacing: ReachuSpacing.sm) {
                            // Selection indicator
                            Image(systemName: selectedShippingOption == option ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(selectedShippingOption == option ? ReachuColors.primary : ReachuColors.textSecondary)
                                .font(.system(size: 16))
                            
                            // Shipping icon (smaller)
                            Image(systemName: option.icon)
                                .foregroundColor(ReachuColors.primary)
                                .font(.system(size: 14))
                                .frame(width: 20)
                            
                            // Shipping details
                            VStack(alignment: .leading, spacing: 2) {
                                Text(option.displayName)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(ReachuColors.textPrimary)
                                
                                Text(option.description)
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(ReachuColors.textSecondary)
                            }
                            
                            Spacer()
                            
                            // Price
                            Text(option.price > 0 ? "$\(String(format: "%.2f", option.price))" : "")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(ReachuColors.textPrimary)
                        }
                        .padding(.horizontal, ReachuSpacing.lg)
                        .padding(.vertical, ReachuSpacing.sm)
                        .background(selectedShippingOption == option ? ReachuColors.primary.opacity(0.1) : Color.clear)
                        .cornerRadius(ReachuBorderRadius.small)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    // Order summary for address step (with shipping)
    private var addressOrderSummaryView: some View {
        VStack(spacing: ReachuSpacing.sm) {
            // Subtotal
            HStack {
                Text("Subtotal")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(ReachuColors.textSecondary)
                
                Spacer()
                
                Text("\(cartManager.currency) \(String(format: "%.2f", cartManager.cartTotal))")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(ReachuColors.textPrimary)
            }
            
            // Shipping
            HStack {
                Text("Shipping")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(ReachuColors.textSecondary)
                
                Spacer()
                
                Text(selectedShippingOption.price > 0 ? "\(cartManager.currency) \(String(format: "%.2f", selectedShippingOption.price))" : "Free")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(ReachuColors.textPrimary)
            }
            
            // Divider
            Rectangle()
                .fill(ReachuColors.border)
                .frame(height: 1)
            
            // Total
            HStack {
                Text("Total")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(ReachuColors.textPrimary)
                
                Spacer()
                
                Text("\(cartManager.currency) \(String(format: "%.2f", cartManager.cartTotal + selectedShippingOption.price))")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(ReachuColors.primary)
            }
        }
        .padding(.horizontal, ReachuSpacing.lg)
    }
    
    // Compact readonly cart for order summary step
    private var compactReadonlyCartView: some View {
        VStack(spacing: ReachuSpacing.md) {
            ForEach(cartManager.items) { item in
                HStack(spacing: ReachuSpacing.sm) {
                    // Small product image
                    AsyncImage(url: URL(string: item.imageUrl ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.yellow)
                    }
                    .frame(width: 40, height: 40)
                    .cornerRadius(6)
                    
                    // Product info (compact)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.title)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(ReachuColors.textPrimary)
                            .lineLimit(1)
                        
                        Text("Qty: \(item.quantity)")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(ReachuColors.textSecondary)
                    }
                    
                    Spacer()
                    
                    // Price
                    Text("\(item.currency) \(String(format: "%.2f", item.price * Double(item.quantity)))")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(ReachuColors.textPrimary)
                }
                .padding(.horizontal, ReachuSpacing.lg)
            }
        }
    }
    
    // Complete order summary for payment step
    private var completeOrderSummaryView: some View {
        VStack(spacing: ReachuSpacing.lg) {
            // Divider
            Rectangle()
                .fill(ReachuColors.border)
                .frame(height: 1)
                .padding(.horizontal, ReachuSpacing.lg)
            
            // Order Summary Section
            VStack(spacing: ReachuSpacing.md) {
                // Subtotal
                HStack {
                    Text("Subtotal")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(ReachuColors.textSecondary)
                    
                    Spacer()
                    
                    Text("\(cartManager.currency) \(String(format: "%.2f", cartManager.cartTotal))")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(ReachuColors.textPrimary)
                }
                
                // Shipping
                HStack {
                    Text("Shipping")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(ReachuColors.textSecondary)
                    
                    Spacer()
                    
                    Text(selectedShippingOption.price > 0 ? "\(cartManager.currency) \(String(format: "%.2f", selectedShippingOption.price))" : "Free")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(ReachuColors.textPrimary)
                }
                
                // Discount (if applied)
                if appliedDiscount > 0 {
                    HStack {
                        Text("Discount")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(ReachuColors.success)
                        
                        Spacer()
                        
                        Text("-\(cartManager.currency) \(String(format: "%.2f", appliedDiscount))")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(ReachuColors.success)
                    }
                }
                
                // Tax
                HStack {
                    Text("Tax")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(ReachuColors.textSecondary)
                    
                    Spacer()
                    
                    Text("\(cartManager.currency) 0.00")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(ReachuColors.textPrimary)
                }
                
                // Divider
                Rectangle()
                    .fill(ReachuColors.border)
                    .frame(height: 1)
                
                // Total
                HStack {
                    Text("Total")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(ReachuColors.textPrimary)
                    
                    Spacer()
                    
                    Text("\(cartManager.currency) \(String(format: "%.2f", finalTotal))")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(ReachuColors.primary)
                }
            }
            .padding(.horizontal, ReachuSpacing.lg)
        }
    }
    
    // MARK: - Helper Functions
    
    private var finalTotal: Double {
        return cartManager.cartTotal + selectedShippingOption.price - appliedDiscount
    }
    
    private func applyDiscountCode() {
        let trimmedCode = discountCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            switch trimmedCode {
            case "SAVE10":
                appliedDiscount = cartManager.cartTotal * 0.10
                discountMessage = "10% discount applied!"
                
                // Haptic feedback for success
                #if os(iOS)
                let successFeedback = UINotificationFeedbackGenerator()
                successFeedback.notificationOccurred(.success)
                #endif
                
            case "SAVE20":
                appliedDiscount = cartManager.cartTotal * 0.20
                discountMessage = "20% discount applied!"
                
                #if os(iOS)
                let successFeedback = UINotificationFeedbackGenerator()
                successFeedback.notificationOccurred(.success)
                #endif
                
            case "FREE10":
                appliedDiscount = 10.0
                discountMessage = "$10 off applied!"
                
                #if os(iOS)
                let successFeedback = UINotificationFeedbackGenerator()
                successFeedback.notificationOccurred(.success)
                #endif
                
            case "WELCOME":
                appliedDiscount = 15.0
                discountMessage = "Welcome discount applied!"
                
                #if os(iOS)
                let successFeedback = UINotificationFeedbackGenerator()
                successFeedback.notificationOccurred(.success)
                #endif
                
            default:
                appliedDiscount = 0.0
                discountMessage = "Invalid discount code"
                
                #if os(iOS)
                let errorFeedback = UINotificationFeedbackGenerator()
                errorFeedback.notificationOccurred(.error)
                #endif
            }
        }
        
        // Clear message after 3 seconds
        if !discountMessage.isEmpty && appliedDiscount > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation(.easeOut(duration: 0.3)) {
                    discountMessage = ""
                }
            }
        }
    }
}

// MARK: - Supporting Components

struct CountryCodePicker: View {
    @Binding var selectedCode: String
    
    private let countryCodes = [
        ("+1", "🇺🇸"), ("+44", "🇬🇧"), ("+49", "🇩🇪"), ("+33", "🇫🇷"),
        ("+39", "🇮🇹"), ("+34", "🇪🇸"), ("+31", "🇳🇱"), ("+46", "🇸🇪"),
        ("+47", "🇳🇴"), ("+45", "🇩🇰"), ("+41", "🇨🇭"), ("+43", "🇦🇹"),
        ("+32", "🇧🇪"), ("+351", "🇵🇹"), ("+52", "🇲🇽"), ("+54", "🇦🇷"),
        ("+55", "🇧🇷"), ("+86", "🇨🇳"), ("+81", "🇯🇵"), ("+82", "🇰🇷"),
        ("+91", "🇮🇳"), ("+61", "🇦🇺"), ("+64", "🇳🇿")
    ]
    
    var body: some View {
        Menu {
            ForEach(countryCodes, id: \.0) { code, flag in
                Button(action: { selectedCode = code }) {
                    HStack {
                        Text(flag)
                        Text(code)
                        Spacer()
                        if selectedCode == code {
                            Image(systemName: "checkmark")
                                .foregroundColor(ReachuColors.primary)
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: ReachuSpacing.xs) {
                Text(countryCodes.first(where: { $0.0 == selectedCode })?.1 ?? "🇺🇸")
                Text(selectedCode)
                    .font(ReachuTypography.body)
                    .foregroundColor(ReachuColors.textPrimary)
                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundColor(ReachuColors.textSecondary)
            }
            .padding(ReachuSpacing.sm)
            .background(ReachuColors.surfaceSecondary)
            .cornerRadius(ReachuBorderRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: ReachuBorderRadius.medium)
                    .stroke(ReachuColors.border, lineWidth: 1)
            )
        }
    }
}

struct CountryPicker: View {
    @Binding var selectedCountry: String
    
    private let countries = [
        "United States", "Canada", "United Kingdom", "Germany", "France",
        "Italy", "Spain", "Netherlands", "Sweden", "Norway", "Denmark",
        "Switzerland", "Austria", "Belgium", "Portugal", "Mexico",
        "Argentina", "Brazil", "China", "Japan", "South Korea",
        "India", "Australia", "New Zealand"
    ]
    
    var body: some View {
        Menu {
            ForEach(countries, id: \.self) { country in
                Button(action: { selectedCountry = country }) {
                    HStack {
                        Text(country)
                        Spacer()
                        if selectedCountry == country {
                            Image(systemName: "checkmark")
                                .foregroundColor(ReachuColors.primary)
                        }
                    }
                }
            }
        } label: {
            HStack {
                Text(selectedCountry.isEmpty ? "Select Country" : selectedCountry)
                    .font(ReachuTypography.body)
                    .foregroundColor(selectedCountry.isEmpty ? ReachuColors.textSecondary : ReachuColors.textPrimary)
                
                Spacer()
                
                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundColor(ReachuColors.textSecondary)
            }
            .padding(ReachuSpacing.md)
            .background(ReachuColors.surfaceSecondary)
            .cornerRadius(ReachuBorderRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: ReachuBorderRadius.medium)
                    .stroke(ReachuColors.border, lineWidth: 1)
            )
        }
    }
}

struct ShippingOptionRow: View {
    let option: RCheckoutOverlay.ShippingOption
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: ReachuSpacing.md) {
                // Selection Circle
                ZStack {
                    Circle()
                        .stroke(isSelected ? ReachuColors.primary : ReachuColors.border, lineWidth: 2)
                        .frame(width: 20, height: 20)
                    
                    if isSelected {
                        Circle()
                            .fill(ReachuColors.primary)
                            .frame(width: 12, height: 12)
                    }
                }
                
                // Shipping Icon
                Image(systemName: option.icon)
                    .font(.title3)
                    .foregroundColor(ReachuColors.primary)
                    .frame(width: 25)
                
                // Shipping Details
                VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
                    HStack {
                        Text(option.displayName)
                            .font(ReachuTypography.body)
                            .foregroundColor(ReachuColors.textPrimary)
                        
                        Spacer()
                        
                        if option.price > 0 {
                            Text("$\(String(format: "%.2f", option.price))")
                                .font(ReachuTypography.bodyBold)
                                .foregroundColor(ReachuColors.textPrimary)
                        }
                    }
                    
                    Text(option.description)
                        .font(ReachuTypography.caption1)
                        .foregroundColor(ReachuColors.textSecondary)
                }
            }
            .padding(.vertical, ReachuSpacing.sm)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Preview
#if DEBUG
import ReachuTesting

#Preview("Checkout - Address Step") {
    RCheckoutOverlay()
        .environmentObject({
            let manager = CartManager()
            Task {
                await manager.addProduct(MockDataProvider.shared.sampleProducts[0])
            }
            return manager
        }())
}
#endif