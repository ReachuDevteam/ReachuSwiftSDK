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
    
    // MARK: - Shipping Options
    public enum ShippingOption: String, CaseIterable {
        case standard = "standard"
        case express = "express"
        case overnight = "overnight"
        case pickup = "pickup"
        
        var displayName: String {
            switch self {
            case .standard: return "Free - Standard"
            case .express: return "Express Shipping"
            case .overnight: return "Overnight Delivery"
            case .pickup: return "Store Pickup"
            }
        }
        
        var description: String {
            switch self {
            case .standard: return "Delivery by Jun 28"
            case .express: return "Delivery by Jun 25"
            case .overnight: return "Delivery by Jun 23"
            case .pickup: return "Available today at store"
            }
        }
        
        var price: Double {
            switch self {
            case .standard: return 0.0
            case .express: return 9.99
            case .overnight: return 19.99
            case .pickup: return 0.0
            }
        }
        
        var icon: String {
            switch self {
            case .standard: return "shippingbox"
            case .express: return "airplane"
            case .overnight: return "clock.badge.checkmark"
            case .pickup: return "building.2"
            }
        }
    }
    
    // MARK: - Payment Methods (Real Reachu Methods)
    public enum PaymentMethod: String, CaseIterable {
        case stripe = "stripe"
        case paypal = "paypal"
        case klarna = "klarna"
        case afterpay = "afterpay"
        case applePay = "apple_pay"
        case googlePay = "google_pay"
        case interestFree = "4x_interest_free"
        case bankTransfer = "bank_transfer"
        
        var displayName: String {
            switch self {
            case .stripe: return "Credit Card"
            case .paypal: return "Pay with PayPal"
            case .klarna: return "Pay with Klarna"
            case .afterpay: return "Pay with Afterpay"
            case .applePay: return "Apple Pay"
            case .googlePay: return "Google Pay"
            case .interestFree: return "Pay with 4x interest-free"
            case .bankTransfer: return "Bank Transfer"
            }
        }
        
        var icon: String {
            switch self {
            case .stripe: return "creditcard.fill"
            case .paypal: return "p.square.fill"
            case .klarna: return "k.square.fill"
            case .afterpay: return "a.square.fill"
            case .applePay: return "apple.logo"
            case .googlePay: return "g.square.fill"
            case .interestFree: return "x.square.fill"
            case .bankTransfer: return "building.columns.fill"
            }
        }
        
        var iconColor: Color {
            switch self {
            case .stripe: return .purple
            case .paypal: return .blue
            case .klarna: return Color(hex: "#FFB3C7")
            case .afterpay: return Color(hex: "#B2FCE4")
            case .applePay: return .black
            case .googlePay: return Color(hex: "#4285F4")
            case .interestFree: return ReachuColors.primary
            case .bankTransfer: return .orange
            }
        }
        
        var supportsInstallments: Bool {
            switch self {
            case .klarna, .afterpay, .interestFree:
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
                    // Shipping Address Header
                    HStack {
                        Text("Shipping Address")
                            .font(ReachuTypography.title2)
                            .foregroundColor(ReachuColors.textPrimary)
                        
                        Spacer()
                        
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isEditingAddress.toggle()
                            }
                        }) {
                            Image(systemName: isEditingAddress ? "checkmark" : "pencil")
                                .foregroundColor(ReachuColors.primary)
                                .font(.title3)
                        }
                    }
                    .padding(.horizontal, ReachuSpacing.lg)
                    .padding(.top, ReachuSpacing.lg)
                    
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
                    
                    // Product Summary with Cart Integration
                    productSummaryView
                    
                    // Quantity Section with Cart Integration
                    quantityControlView
                    
                    // Shipping Options Section
                    shippingOptionsView
                    
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

// MARK: - RCheckoutOverlay Helper Views Extension
extension RCheckoutOverlay {
    
    private var addressDisplayView: some View {
        VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
            Text("\(firstName) \(lastName)")
                .font(ReachuTypography.bodyBold)
                .foregroundColor(ReachuColors.textPrimary)
            
            Text(address1)
                .font(ReachuTypography.body)
                .foregroundColor(ReachuColors.textPrimary)
            
            if !address2.isEmpty {
                Text(address2)
                    .font(ReachuTypography.body)
                    .foregroundColor(ReachuColors.textPrimary)
            }
            
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
    
    private var productSummaryView: some View {
        VStack(alignment: .leading, spacing: ReachuSpacing.md) {
            ForEach(cartManager.items) { item in
                HStack(spacing: ReachuSpacing.md) {
                    // Product Image
                    AsyncImage(url: URL(string: item.imageUrl ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: ReachuBorderRadius.medium)
                            .fill(ReachuColors.surfaceSecondary)
                            .overlay {
                                Image(systemName: "photo")
                                    .foregroundColor(ReachuColors.textSecondary)
                            }
                    }
                    .frame(width: 80, height: 80)
                    .cornerRadius(ReachuBorderRadius.medium)
                    
                    VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
                        Text(item.brand ?? "Adidas Store")
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
                    
                    VStack(alignment: .trailing, spacing: ReachuSpacing.xs) {
                        Text("\(item.currency) \(String(format: "%.2f", item.price * Double(item.quantity)))")
                            .font(ReachuTypography.title3)
                            .foregroundColor(ReachuColors.textPrimary)
                        
                        Text("Qty: \(item.quantity)")
                            .font(ReachuTypography.caption1)
                            .foregroundColor(ReachuColors.textSecondary)
                    }
                }
                .padding(.horizontal, ReachuSpacing.lg)
            }
        }
    }
    
    private var quantityControlView: some View {
        VStack(alignment: .leading, spacing: ReachuSpacing.md) {
            HStack {
                Text("Quantity")
                    .font(ReachuTypography.bodyBold)
                    .foregroundColor(ReachuColors.textPrimary)
                
                Spacer()
                
                HStack(spacing: ReachuSpacing.sm) {
                    Button(action: {
                        if let firstItem = cartManager.items.first, firstItem.quantity > 1 {
                            Task {
                                await cartManager.updateQuantity(for: firstItem, to: firstItem.quantity - 1)
                            }
                        }
                    }) {
                        Image(systemName: "minus")
                            .font(.body)
                            .foregroundColor(ReachuColors.textPrimary)
                            .frame(width: 32, height: 32)
                            .background(ReachuColors.surfaceSecondary)
                            .cornerRadius(ReachuBorderRadius.small)
                    }
                    .disabled(cartManager.items.first?.quantity ?? 0 <= 1)
                    
                    Text("\(cartManager.itemCount)")
                        .font(ReachuTypography.bodyBold)
                        .foregroundColor(ReachuColors.textPrimary)
                        .frame(width: 40)
                        .animation(.spring(), value: cartManager.itemCount)
                    
                    Button(action: {
                        if let firstItem = cartManager.items.first {
                            Task {
                                await cartManager.updateQuantity(for: firstItem, to: firstItem.quantity + 1)
                            }
                        }
                    }) {
                        Image(systemName: "plus")
                            .font(.body)
                            .foregroundColor(ReachuColors.textPrimary)
                            .frame(width: 32, height: 32)
                            .background(ReachuColors.surfaceSecondary)
                            .cornerRadius(ReachuBorderRadius.small)
                    }
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