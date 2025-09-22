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
    
    // Payment Information
    @State private var selectedPaymentMethod: PaymentMethod = .stripe
    @State private var acceptsTerms = false
    @State private var acceptsPurchaseConditions = false
    
    // MARK: - Checkout Steps
    public enum CheckoutStep: CaseIterable {
        case address
        case payment
        case review
        case success
        
        var title: String {
            switch self {
            case .address: return "Address"
            case .payment: return "Payment"
            case .review: return "Review"
            case .success: return "Complete"
            }
        }
    }
    
    // MARK: - Payment Methods
    public enum PaymentMethod: String, CaseIterable {
        case paypal = "paypal"
        case bankTransfer = "bank_transfer"
        case interestFree = "4x_interest_free"
        case stripe = "stripe"
        case klarna = "klarna"
        case vipps = "vipps"
        
        var displayName: String {
            switch self {
            case .paypal: return "Pay with Paypal"
            case .bankTransfer: return "Pay with Bank Transfer"
            case .interestFree: return "Pay with 4x interest- free"
            case .stripe: return "Credit Card"
            case .klarna: return "Klarna"
            case .vipps: return "Vipps"
            }
        }
        
        var icon: String {
            switch self {
            case .paypal: return "p.square.fill"
            case .bankTransfer: return "building.columns.fill"
            case .interestFree: return "x.square.fill"
            case .stripe: return "creditcard.fill"
            case .klarna: return "k.square.fill"
            case .vipps: return "v.square.fill"
            }
        }
        
        var iconColor: Color {
            switch self {
            case .paypal: return .blue
            case .bankTransfer: return .orange
            case .interestFree: return ReachuColors.primary
            case .stripe: return .black
            case .klarna: return .pink
            case .vipps: return .orange
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
                case .payment:
                    paymentStepView
                case .review:
                    reviewStepView
                case .success:
                    successStepView
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
                VStack(alignment: .leading, spacing: ReachuSpacing.lg) {
                    // Address Header
                    HStack {
                        Text("Address")
                            .font(ReachuTypography.title2)
                            .foregroundColor(ReachuColors.textPrimary)
                        
                        Spacer()
                        
                        Button(action: {}) {
                            Image(systemName: "pencil")
                                .foregroundColor(ReachuColors.textSecondary)
                        }
                    }
                    .padding(.horizontal, ReachuSpacing.lg)
                    .padding(.top, ReachuSpacing.lg)
                    
                    // Pre-filled Address Display
                    VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
                        Text("\(firstName) \(lastName)")
                            .font(ReachuTypography.bodyBold)
                            .foregroundColor(ReachuColors.textPrimary)
                        
                        Text(address1)
                            .font(ReachuTypography.body)
                            .foregroundColor(ReachuColors.textPrimary)
                        
                        Text("\(city), \(province), \(country)")
                            .font(ReachuTypography.body)
                            .foregroundColor(ReachuColors.textPrimary)
                        
                        Text(zip)
                            .font(ReachuTypography.body)
                            .foregroundColor(ReachuColors.textPrimary)
                        
                        HStack {
                            Text("Phone :")
                                .font(ReachuTypography.body)
                                .foregroundColor(ReachuColors.textPrimary)
                            
                            Text("\(phoneCountryCode) \(phone)")
                                .font(ReachuTypography.body)
                                .foregroundColor(ReachuColors.textPrimary)
                        }
                    }
                    .padding(.horizontal, ReachuSpacing.lg)
                    
                    // Product Summary
                    VStack(alignment: .leading, spacing: ReachuSpacing.md) {
                        ForEach(cartManager.items.prefix(1)) { item in
                            HStack(spacing: ReachuSpacing.md) {
                                // Product Image Placeholder
                                RoundedRectangle(cornerRadius: ReachuBorderRadius.medium)
                                    .fill(ReachuColors.surfaceSecondary)
                                    .frame(width: 80, height: 80)
                                    .overlay {
                                        AsyncImage(url: URL(string: item.imageUrl ?? "")) { image in
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                        } placeholder: {
                                            Image(systemName: "photo")
                                                .foregroundColor(ReachuColors.textSecondary)
                                        }
                                    }
                                    .cornerRadius(ReachuBorderRadius.medium)
                                
                                VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
                                    Text(item.brand ?? "")
                                        .font(ReachuTypography.caption1)
                                        .foregroundColor(ReachuColors.textSecondary)
                                    
                                    Text(item.title)
                                        .font(ReachuTypography.bodyBold)
                                        .foregroundColor(ReachuColors.textPrimary)
                                        .lineLimit(2)
                                    
                                    Text("Order ID: BD23672983")
                                        .font(ReachuTypography.caption1)
                                        .foregroundColor(ReachuColors.textSecondary)
                                    
                                    Text("Colors: Like Water")
                                        .font(ReachuTypography.caption1)
                                        .foregroundColor(ReachuColors.textSecondary)
                                }
                                
                                Spacer()
                                
                                Text("\(item.currency) \(String(format: "%.2f", item.price))")
                                    .font(ReachuTypography.title3)
                                    .foregroundColor(ReachuColors.textPrimary)
                            }
                        }
                    }
                    .padding(.horizontal, ReachuSpacing.lg)
                    
                    // Quantity Section
                    HStack {
                        Text("Quantity")
                            .font(ReachuTypography.bodyBold)
                            .foregroundColor(ReachuColors.textPrimary)
                        
                        Spacer()
                        
                        HStack(spacing: ReachuSpacing.sm) {
                            Button(action: {}) {
                                Image(systemName: "minus")
                                    .font(.body)
                                    .foregroundColor(ReachuColors.textSecondary)
                                    .frame(width: 30, height: 30)
                                    .background(ReachuColors.surfaceSecondary)
                                    .cornerRadius(ReachuBorderRadius.small)
                            }
                            
                            Text("\(cartManager.itemCount)")
                                .font(ReachuTypography.bodyBold)
                                .foregroundColor(ReachuColors.textPrimary)
                                .frame(width: 30)
                            
                            Button(action: {}) {
                                Image(systemName: "plus")
                                    .font(.body)
                                    .foregroundColor(ReachuColors.textSecondary)
                                    .frame(width: 30, height: 30)
                                    .background(ReachuColors.surfaceSecondary)
                                    .cornerRadius(ReachuBorderRadius.small)
                            }
                        }
                    }
                    .padding(.horizontal, ReachuSpacing.lg)
                    
                    // Shipping Section
                    VStack(alignment: .leading, spacing: ReachuSpacing.sm) {
                        HStack {
                            Text("Shipping")
                                .font(ReachuTypography.bodyBold)
                                .foregroundColor(ReachuColors.textPrimary)
                            
                            Spacer()
                            
                            Button(action: {}) {
                                Image(systemName: "pencil")
                                    .foregroundColor(ReachuColors.textSecondary)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
                            Text("Free - Standard")
                                .font(ReachuTypography.body)
                                .foregroundColor(ReachuColors.textPrimary)
                            
                            Text("Delivery by Jun 28")
                                .font(ReachuTypography.caption1)
                                .foregroundColor(ReachuColors.textSecondary)
                        }
                    }
                    .padding(.horizontal, ReachuSpacing.lg)
                    
                    // Payment Method Section
                    VStack(alignment: .leading, spacing: ReachuSpacing.md) {
                        Text("Payment Method")
                            .font(ReachuTypography.bodyBold)
                            .foregroundColor(ReachuColors.textPrimary)
                        
                        ForEach(PaymentMethod.allCases, id: \.self) { method in
                            PaymentMethodRowCompact(
                                method: method,
                                isSelected: selectedPaymentMethod == method
                            ) {
                                selectedPaymentMethod = method
                            }
                        }
                    }
                    .padding(.horizontal, ReachuSpacing.lg)
                    
                    // 4x Interest-Free Details
                    if selectedPaymentMethod == .interestFree {
                        PaymentScheduleCompact(total: cartManager.cartTotal, currency: cartManager.currency)
                            .padding(.horizontal, ReachuSpacing.lg)
                    }
                    
                    Spacer(minLength: 100)
                }
            }
            
            // Bottom Button
            VStack {
                RButton(
                    title: "Checkout",
                    style: .primary,
                    size: .large,
                    isDisabled: !canProceedToNext
                ) {
                    proceedToNext()
                }
                .padding(.horizontal, ReachuSpacing.lg)
                .padding(.vertical, ReachuSpacing.md)
            }
            .background(ReachuColors.surface)
        }
    }
    
    // MARK: - Payment Step View
    private var paymentStepView: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: ReachuSpacing.lg) {
                    // Product Summary Header
                    HStack {
                        Text("Product Summary")
                            .font(ReachuTypography.title2)
                            .foregroundColor(ReachuColors.textPrimary)
                        
                        Spacer()
                        
                        Text("\(cartManager.currency) \(String(format: "%.2f", cartManager.cartTotal))")
                            .font(ReachuTypography.title2)
                            .foregroundColor(ReachuColors.textPrimary)
                    }
                    .padding(.horizontal, ReachuSpacing.lg)
                    .padding(.top, ReachuSpacing.lg)
                    
                    // Order Details
                    VStack(alignment: .leading, spacing: ReachuSpacing.sm) {
                        HStack {
                            Text("Order ID")
                                .font(ReachuTypography.body)
                                .foregroundColor(ReachuColors.textSecondary)
                            Spacer()
                            Text("BD23672983")
                                .font(ReachuTypography.body)
                                .foregroundColor(ReachuColors.textPrimary)
                        }
                        
                        HStack {
                            Text("Store")
                                .font(ReachuTypography.body)
                                .foregroundColor(ReachuColors.textSecondary)
                            Spacer()
                            Text("Adidas")
                                .font(ReachuTypography.body)
                                .foregroundColor(ReachuColors.textPrimary)
                        }
                        
                        HStack {
                            Text("Category")
                                .font(ReachuTypography.body)
                                .foregroundColor(ReachuColors.textSecondary)
                            Spacer()
                            Text("Basketball")
                                .font(ReachuTypography.body)
                                .foregroundColor(ReachuColors.textPrimary)
                        }
                        
                        HStack {
                            Text("Product")
                                .font(ReachuTypography.body)
                                .foregroundColor(ReachuColors.textSecondary)
                            Spacer()
                            Text("D.O.N ISSUE #6")
                                .font(ReachuTypography.body)
                                .foregroundColor(ReachuColors.textPrimary)
                        }
                        
                        HStack {
                            Text("Colors")
                                .font(ReachuTypography.body)
                                .foregroundColor(ReachuColors.textSecondary)
                            Spacer()
                            Text("Like Water")
                                .font(ReachuTypography.body)
                                .foregroundColor(ReachuColors.textPrimary)
                        }
                        
                        HStack {
                            Text("Quantity")
                                .font(ReachuTypography.body)
                                .foregroundColor(ReachuColors.textSecondary)
                            Spacer()
                            Text("1 item")
                                .font(ReachuTypography.body)
                                .foregroundColor(ReachuColors.textPrimary)
                        }
                        
                        HStack {
                            Text("Price")
                                .font(ReachuTypography.body)
                                .foregroundColor(ReachuColors.textSecondary)
                            Spacer()
                            Text("\(cartManager.currency) \(String(format: "%.2f", cartManager.cartTotal))")
                                .font(ReachuTypography.body)
                                .foregroundColor(ReachuColors.textPrimary)
                        }
                        
                        HStack {
                            Text("Shipping")
                                .font(ReachuTypography.body)
                                .foregroundColor(ReachuColors.textSecondary)
                            Spacer()
                            Text("Free")
                                .font(ReachuTypography.body)
                                .foregroundColor(ReachuColors.textPrimary)
                        }
                    }
                    .padding(.horizontal, ReachuSpacing.lg)
                    
                    // Payment Schedule (if 4x selected)
                    if selectedPaymentMethod == .interestFree {
                        VStack(alignment: .leading, spacing: ReachuSpacing.md) {
                            Text("Payment Schedule")
                                .font(ReachuTypography.bodyBold)
                                .foregroundColor(ReachuColors.textPrimary)
                                .padding(.horizontal, ReachuSpacing.lg)
                            
                            PaymentScheduleDetailed(total: cartManager.cartTotal, currency: cartManager.currency)
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
        VStack(spacing: ReachuSpacing.xl) {
            Spacer()
            
            // Success Icon
            ZStack {
                Circle()
                    .fill(ReachuColors.success)
                    .frame(width: 80, height: 80)
                
                Image(systemName: "checkmark")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.white)
            }
            
            // Success Message
            VStack(spacing: ReachuSpacing.sm) {
                Text("Purchase Complete!")
                    .font(ReachuTypography.largeTitle)
                    .foregroundColor(ReachuColors.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text("You'll pay in 4x interest-free. We'll send you a reminder a few days before each payment.")
                    .font(ReachuTypography.body)
                    .foregroundColor(ReachuColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, ReachuSpacing.lg)
            }
            
            Spacer()
            
            // Back to Home Button
            RButton(
                title: "Back to home",
                style: .primary,
                size: .large
            ) {
                cartManager.hideCheckout()
                Task {
                    await cartManager.clearCart()
                }
            }
            .padding(.horizontal, ReachuSpacing.lg)
            
            Spacer()
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
        case .payment:
            return true
        case .review:
            return true
        case .success:
            return false
        }
    }
    
    private func goToPreviousStep() {
        withAnimation(.easeInOut(duration: 0.3)) {
            switch checkoutStep {
            case .payment:
                checkoutStep = .address
            case .review:
                checkoutStep = .payment
            default:
                break
            }
        }
    }
    
    private func proceedToNext() {
        withAnimation(.easeInOut(duration: 0.3)) {
            switch checkoutStep {
            case .address:
                checkoutStep = .payment
            case .payment:
                checkoutStep = .review
            case .review:
                simulatePayment()
            case .success:
                break
            }
        }
    }
    
    private func simulatePayment() {
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isLoading = false
            
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                checkoutStep = .success
            }
            
            #if os(iOS)
            let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
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