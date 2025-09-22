import SwiftUI
import ReachuCore
import ReachuDesignSystem

/// Complete checkout overlay with real Reachu GraphQL steps
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
    
    // MARK: - Checkout Steps (Based on Reachu GraphQL)
    public enum CheckoutStep: CaseIterable {
        case address      // Shipping/Billing Address
        case payment      // Payment Method Selection
        case review       // Order Review & Confirmation  
        case success      // Purchase Complete
        
        var title: String {
            switch self {
            case .address: return "Address"
            case .payment: return "Payment"
            case .review: return "Review"
            case .success: return "Complete"
            }
        }
        
        var stepNumber: Int {
            switch self {
            case .address: return 1
            case .payment: return 2
            case .review: return 3
            case .success: return 4
            }
        }
    }
    
    // MARK: - Payment Methods (Based on Reachu GraphQL)
    public enum PaymentMethod: String, CaseIterable {
        case stripe = "stripe"
        case klarna = "klarna"
        case paypal = "paypal"
        case bankTransfer = "bank_transfer"
        case interestFree = "4x_interest_free"
        case vipps = "vipps"
        
        var displayName: String {
            switch self {
            case .stripe: return "Credit Card"
            case .klarna: return "Klarna"
            case .paypal: return "PayPal"
            case .bankTransfer: return "Bank Transfer"
            case .interestFree: return "4x Interest-Free"
            case .vipps: return "Vipps"
            }
        }
        
        var icon: String {
            switch self {
            case .stripe: return "creditcard"
            case .klarna: return "k.square"
            case .paypal: return "p.square"
            case .bankTransfer: return "building.columns"
            case .interestFree: return "4.square"
            case .vipps: return "v.square"
            }
        }
        
        var description: String {
            switch self {
            case .stripe: return "Pay with your credit or debit card"
            case .klarna: return "Buy now, pay later with Klarna"
            case .paypal: return "Pay securely with your PayPal account"
            case .bankTransfer: return "Direct bank transfer"
            case .interestFree: return "Split into 4 interest-free payments"
            case .vipps: return "Norwegian mobile payment solution"
            }
        }
    }
    
    // MARK: - Initialization
    public init() {
        // Initialize checkout overlay
    }
    
    // MARK: - Body
    public var body: some View {
        NavigationView {
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    // Progress Indicator
                    if checkoutStep != .success {
                        progressIndicatorView
                            .padding(.vertical, ReachuSpacing.md)
                            .background(ReachuColors.surface)
                    }
                    
                    // Content
                    ScrollView {
                        VStack(spacing: ReachuSpacing.lg) {
                            switch checkoutStep {
                            case .address:
                                addressFormView
                            case .payment:
                                paymentMethodView
                            case .review:
                                reviewOrderView
                            case .success:
                                successView
                            }
                        }
                        .padding(.horizontal, ReachuSpacing.lg)
                        .padding(.vertical, ReachuSpacing.lg)
                    }
                    
                    // Bottom Action Button
                    if checkoutStep != .success {
                        bottomActionView
                            .padding(.horizontal, ReachuSpacing.lg)
                            .padding(.vertical, ReachuSpacing.md)
                            .background(ReachuColors.surface)
                    }
                }
            }
            .navigationTitle(checkoutStep == .success ? "" : "Checkout")
            #if os(iOS) || os(tvOS) || os(watchOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if checkoutStep != .success {
                        Button("Close") {
                            cartManager.hideCheckout()
                        }
                        .foregroundColor(ReachuColors.textSecondary)
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
            // Pre-fill demo data for testing
            fillDemoData()
        }
    }
    
    // MARK: - Progress Indicator
    private var progressIndicatorView: some View {
        VStack(spacing: ReachuSpacing.sm) {
            // Step circles with connecting lines
            HStack(spacing: ReachuSpacing.sm) {
                ForEach(Array(CheckoutStep.allCases.dropLast().enumerated()), id: \.offset) { index, step in
                    HStack(spacing: ReachuSpacing.xs) {
                        // Step Circle
                        ZStack {
                            Circle()
                                .fill(stepColor(for: step))
                                .frame(width: 28, height: 28)
                            
                            if step.stepNumber <= checkoutStep.stepNumber {
                                Image(systemName: step == checkoutStep ? "circle.fill" : "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                            } else {
                                Text("\(step.stepNumber)")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(ReachuColors.textSecondary)
                            }
                        }
                        
                        // Connecting Line
                        if index < CheckoutStep.allCases.count - 2 {
                            Rectangle()
                                .fill(step.stepNumber < checkoutStep.stepNumber ? ReachuColors.primary : ReachuColors.border)
                                .frame(height: 2)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            
            // Current step label only
            Text(checkoutStep.title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(ReachuColors.primary)
        }
        .padding(.horizontal, ReachuSpacing.lg)
    }
    
    // MARK: - Address Form View
    private var addressFormView: some View {
        VStack(alignment: .leading, spacing: ReachuSpacing.lg) {
            // Header
            VStack(alignment: .leading, spacing: ReachuSpacing.sm) {
                Text("Shipping Address")
                    .font(ReachuTypography.title2)
                    .foregroundColor(ReachuColors.textPrimary)
                
                Text("Where should we deliver your order?")
                    .font(ReachuTypography.body)
                    .foregroundColor(ReachuColors.textSecondary)
            }
            
            // Form Fields
            VStack(spacing: ReachuSpacing.md) {
                // Contact Information
                VStack(alignment: .leading, spacing: ReachuSpacing.sm) {
                    Text("Contact Information")
                        .font(ReachuTypography.bodyBold)
                        .foregroundColor(ReachuColors.textPrimary)
                    
                    CustomTextField(title: "Email", text: $email, placeholder: "your@email.com")
                    
                    // Phone with country code selector
                    VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
                        Text("Phone")
                            .font(ReachuTypography.caption1)
                            .foregroundColor(ReachuColors.textSecondary)
                        
                        HStack(spacing: ReachuSpacing.sm) {
                            // Country code picker
                            CountryCodePicker(selectedCode: $phoneCountryCode)
                                .frame(width: 80)
                            
                            // Phone number field
                            TextField("(555) 123-4456", text: $phone)
                                .textFieldStyle(PlainTextFieldStyle())
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
                
                // Name
                HStack(spacing: ReachuSpacing.md) {
                    CustomTextField(title: "First Name", text: $firstName, placeholder: "John")
                    CustomTextField(title: "Last Name", text: $lastName, placeholder: "Doe")
                }
                
                // Address
                VStack(spacing: ReachuSpacing.sm) {
                    CustomTextField(title: "Address", text: $address1, placeholder: "123 Main Street")
                    CustomTextField(title: "Apartment, suite, etc. (optional)", text: $address2, placeholder: "Apt 4B")
                }
                
                // Location
                HStack(spacing: ReachuSpacing.md) {
                    CustomTextField(title: "City", text: $city, placeholder: "New York")
                    CustomTextField(title: "State", text: $province, placeholder: "NY")
                    CustomTextField(title: "ZIP", text: $zip, placeholder: "10001")
                }
                
                // Country selector
                VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
                    Text("Country")
                        .font(ReachuTypography.caption1)
                        .foregroundColor(ReachuColors.textSecondary)
                    
                    CountryPicker(selectedCountry: $country)
                }
            }
        }
    }
    
    // MARK: - Payment Method View
    private var paymentMethodView: some View {
        VStack(alignment: .leading, spacing: ReachuSpacing.lg) {
            // Header
            VStack(alignment: .leading, spacing: ReachuSpacing.sm) {
                Text("Payment Method")
                    .font(ReachuTypography.title2)
                    .foregroundColor(ReachuColors.textPrimary)
                
                Text("Choose how you'd like to pay")
                    .font(ReachuTypography.body)
                    .foregroundColor(ReachuColors.textSecondary)
            }
            
            // Payment Methods
            VStack(spacing: ReachuSpacing.sm) {
                ForEach(PaymentMethod.allCases, id: \.self) { method in
                    PaymentMethodRow(
                        method: method,
                        isSelected: selectedPaymentMethod == method
                    ) {
                        selectedPaymentMethod = method
                    }
                }
            }
            
            // Special handling for 4x interest-free
            if selectedPaymentMethod == .interestFree {
                PaymentScheduleView(total: cartManager.cartTotal, currency: cartManager.currency)
            }
            
            // Terms and Conditions
            VStack(alignment: .leading, spacing: ReachuSpacing.md) {
                CheckboxRow(
                    title: "I accept the terms and conditions",
                    isChecked: $acceptsTerms
                )
                
                CheckboxRow(
                    title: "I accept the purchase conditions",
                    isChecked: $acceptsPurchaseConditions
                )
            }
            .padding(.top, ReachuSpacing.md)
        }
    }
    
    // MARK: - Review Order View
    private var reviewOrderView: some View {
        VStack(alignment: .leading, spacing: ReachuSpacing.lg) {
            // Header
            Text("Order Review")
                .font(ReachuTypography.title2)
                .foregroundColor(ReachuColors.textPrimary)
            
            // Order Summary
            VStack(alignment: .leading, spacing: ReachuSpacing.md) {
                Text("Product Summary")
                    .font(ReachuTypography.bodyBold)
                    .foregroundColor(ReachuColors.textPrimary)
                
                VStack(spacing: ReachuSpacing.sm) {
                    ForEach(cartManager.items) { item in
                        HStack {
                            Text(item.title)
                                .font(ReachuTypography.body)
                                .foregroundColor(ReachuColors.textPrimary)
                            
                            Spacer()
                            
                            Text("\(item.quantity) x \(item.currency) \(String(format: "%.2f", item.price))")
                                .font(ReachuTypography.body)
                                .foregroundColor(ReachuColors.textSecondary)
                        }
                    }
                    
                    Divider()
                    
                    HStack {
                        Text("Total")
                            .font(ReachuTypography.bodyBold)
                            .foregroundColor(ReachuColors.textPrimary)
                        
                        Spacer()
                        
                        Text("\(cartManager.currency) \(String(format: "%.2f", cartManager.cartTotal))")
                            .font(ReachuTypography.bodyBold)
                            .foregroundColor(ReachuColors.primary)
                    }
                }
                .padding(ReachuSpacing.md)
                .background(ReachuColors.surfaceSecondary)
                .cornerRadius(ReachuBorderRadius.medium)
            }
            
            // Shipping Address
            VStack(alignment: .leading, spacing: ReachuSpacing.sm) {
                Text("Shipping Address")
                    .font(ReachuTypography.bodyBold)
                    .foregroundColor(ReachuColors.textPrimary)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(firstName) \(lastName)")
                    Text(address1)
                    if !address2.isEmpty {
                        Text(address2)
                    }
                    Text("\(city), \(province) \(zip)")
                    Text(country)
                    Text("Phone: \(phone)")
                }
                .font(ReachuTypography.body)
                .foregroundColor(ReachuColors.textSecondary)
                .padding(ReachuSpacing.md)
                .background(ReachuColors.surfaceSecondary)
                .cornerRadius(ReachuBorderRadius.medium)
            }
            
            // Payment Method
            VStack(alignment: .leading, spacing: ReachuSpacing.sm) {
                Text("Payment Method")
                    .font(ReachuTypography.bodyBold)
                    .foregroundColor(ReachuColors.textPrimary)
                
                HStack {
                    Image(systemName: selectedPaymentMethod.icon)
                        .foregroundColor(ReachuColors.primary)
                    
                    Text(selectedPaymentMethod.displayName)
                        .font(ReachuTypography.body)
                        .foregroundColor(ReachuColors.textPrimary)
                    
                    Spacer()
                }
                .padding(ReachuSpacing.md)
                .background(ReachuColors.surfaceSecondary)
                .cornerRadius(ReachuBorderRadius.medium)
            }
        }
    }
    
    // MARK: - Success View
    private var successView: some View {
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
            .scaleEffect(1.0)
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: checkoutStep)
            
            // Success Message
            VStack(spacing: ReachuSpacing.sm) {
                Text("Purchase Complete!")
                    .font(ReachuTypography.largeTitle)
                    .foregroundColor(ReachuColors.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text("Your order has been successfully placed. We'll send you a confirmation email shortly.")
                    .font(ReachuTypography.body)
                    .foregroundColor(ReachuColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            // Order ID (Mock)
            VStack(spacing: ReachuSpacing.xs) {
                Text("Order ID")
                    .font(ReachuTypography.caption1)
                    .foregroundColor(ReachuColors.textSecondary)
                
                Text("BD23672983")
                    .font(ReachuTypography.bodyBold)
                    .foregroundColor(ReachuColors.textPrimary)
            }
            .padding(ReachuSpacing.md)
            .background(ReachuColors.surfaceSecondary)
            .cornerRadius(ReachuBorderRadius.medium)
            
            Spacer()
            
            // Back to Home Button
            RButton(
                title: "Back to Home",
                style: .primary,
                size: .medium
            ) {
                cartManager.hideCheckout()
                // Clear cart after successful purchase
                Task {
                    await cartManager.clearCart()
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, ReachuSpacing.lg)
    }
    
    // MARK: - Bottom Action View
    private var bottomActionView: some View {
        VStack(spacing: ReachuSpacing.sm) {
            if let error = errorMessage {
                Text(error)
                    .font(ReachuTypography.caption1)
                    .foregroundColor(ReachuColors.error)
                    .padding(.horizontal, ReachuSpacing.md)
            }
            
            HStack(spacing: ReachuSpacing.md) {
                // Back Button
                if checkoutStep != .address {
                    RButton(
                        title: "Back",
                        style: .tertiary,
                        size: .medium
                    ) {
                        goToPreviousStep()
                    }
                }
                
                // Next/Complete Button
                RButton(
                    title: nextButtonTitle,
                    style: .primary,
                    size: .medium,
                    isLoading: isLoading,
                    isDisabled: !canProceedToNext
                ) {
                    proceedToNext()
                }
            }
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
    
    private func stepColor(for step: CheckoutStep) -> Color {
        if step.stepNumber < checkoutStep.stepNumber {
            return ReachuColors.primary
        } else if step.stepNumber == checkoutStep.stepNumber {
            return ReachuColors.primary
        } else {
            return ReachuColors.border
        }
    }
    
    private var nextButtonTitle: String {
        switch checkoutStep {
        case .address: return "Continue to Payment"
        case .payment: return "Review Order"
        case .review: return "Complete Purchase"
        case .success: return ""
        }
    }
    
    private var canProceedToNext: Bool {
        switch checkoutStep {
        case .address:
            return !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                   !lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                   !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                   email.contains("@") &&
                   !phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                   !address1.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                   !city.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                   !province.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                   !zip.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                   !country.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .payment:
            return acceptsTerms && acceptsPurchaseConditions
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
        errorMessage = nil
        
        // Simulate payment processing
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isLoading = false
            
            // Simulate success
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                checkoutStep = .success
            }
            
            // Trigger haptic feedback
            #if os(iOS)
            let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
            impactFeedback.impactOccurred()
            #endif
        }
    }
    
    private func fillDemoData() {
        // Pre-fill with demo data for easier testing
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

// MARK: - Supporting Views

struct CustomTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
            Text(title)
                .font(ReachuTypography.caption1)
                .foregroundColor(ReachuColors.textSecondary)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(PlainTextFieldStyle())
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

struct PaymentMethodRow: View {
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
                    .font(.title2)
                    .foregroundColor(ReachuColors.primary)
                    .frame(width: 30)
                
                // Payment Method Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(method.displayName)
                        .font(ReachuTypography.bodyBold)
                        .foregroundColor(ReachuColors.textPrimary)
                    
                    Text(method.description)
                        .font(ReachuTypography.caption1)
                        .foregroundColor(ReachuColors.textSecondary)
                }
                
                Spacer()
            }
            .padding(ReachuSpacing.md)
            .background(isSelected ? ReachuColors.primary.opacity(0.05) : ReachuColors.surface)
            .overlay(
                RoundedRectangle(cornerRadius: ReachuBorderRadius.medium)
                    .stroke(isSelected ? ReachuColors.primary : ReachuColors.border, lineWidth: 1)
            )
            .cornerRadius(ReachuBorderRadius.medium)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PaymentScheduleView: View {
    let total: Double
    let currency: String
    
    private var installmentAmount: Double {
        total / 4.0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: ReachuSpacing.sm) {
            Text("Payment Schedule")
                .font(ReachuTypography.bodyBold)
                .foregroundColor(ReachuColors.textPrimary)
            
            VStack(spacing: ReachuSpacing.xs) {
                ForEach(1...4, id: \.self) { installment in
                    HStack {
                        ZStack {
                            Circle()
                                .fill(installment == 1 ? ReachuColors.primary : ReachuColors.border)
                                .frame(width: 24, height: 24)
                            
                            Text("\(installment)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(installment == 1 ? .white : ReachuColors.textSecondary)
                        }
                        
                        VStack(alignment: .leading, spacing: 0) {
                            Text(installment == 1 ? "Due Today" : "In \(installment - 1) month\(installment > 2 ? "s" : "")")
                                .font(ReachuTypography.caption1)
                                .foregroundColor(ReachuColors.textSecondary)
                            
                            Text("\(currency) \(String(format: "%.2f", installmentAmount))")
                                .font(ReachuTypography.bodyBold)
                                .foregroundColor(ReachuColors.textPrimary)
                        }
                        
                        Spacer()
                    }
                }
                
                Divider()
                
                HStack {
                    Text("Down payment due today")
                        .font(ReachuTypography.bodyBold)
                        .foregroundColor(ReachuColors.textPrimary)
                    
                    Spacer()
                    
                    Text("\(currency) \(String(format: "%.2f", installmentAmount))")
                        .font(ReachuTypography.bodyBold)
                        .foregroundColor(ReachuColors.primary)
                }
            }
        }
        .padding(ReachuSpacing.md)
        .background(ReachuColors.surfaceSecondary)
        .cornerRadius(ReachuBorderRadius.medium)
    }
}

struct CheckboxRow: View {
    let title: String
    @Binding var isChecked: Bool
    
    var body: some View {
        Button(action: { isChecked.toggle() }) {
            HStack(spacing: ReachuSpacing.sm) {
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(isChecked ? ReachuColors.primary : ReachuColors.border, lineWidth: 2)
                        .frame(width: 20, height: 20)
                        .background(isChecked ? ReachuColors.primary : Color.clear)
                        .cornerRadius(4)
                    
                    if isChecked {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                
                Text(title)
                    .font(ReachuTypography.body)
                    .foregroundColor(ReachuColors.textPrimary)
                    .multilineTextAlignment(.leading)
                
                Spacer()
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Country and Phone Code Pickers

struct CountryCodePicker: View {
    @Binding var selectedCode: String
    
    private let countryCodes = [
        ("+1", "🇺🇸"),
        ("+44", "🇬🇧"),
        ("+49", "🇩🇪"),
        ("+33", "🇫🇷"),
        ("+39", "🇮🇹"),
        ("+34", "🇪🇸"),
        ("+31", "🇳🇱"),
        ("+46", "🇸🇪"),
        ("+47", "🇳🇴"),
        ("+45", "🇩🇰"),
        ("+41", "🇨🇭"),
        ("+43", "🇦🇹"),
        ("+32", "🇧🇪"),
        ("+351", "🇵🇹"),
        ("+52", "🇲🇽"),
        ("+54", "🇦🇷"),
        ("+55", "🇧🇷"),
        ("+86", "🇨🇳"),
        ("+81", "🇯🇵"),
        ("+82", "🇰🇷"),
        ("+91", "🇮🇳"),
        ("+61", "🇦🇺"),
        ("+64", "🇳🇿")
    ]
    
    var body: some View {
        Menu {
            ForEach(countryCodes, id: \.0) { code, flag in
                Button(action: {
                    selectedCode = code
                }) {
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

struct CountryPicker: View {
    @Binding var selectedCountry: String
    
    private let countries = [
        "United States",
        "Canada",
        "United Kingdom",
        "Germany",
        "France",
        "Italy",
        "Spain",
        "Netherlands",
        "Sweden",
        "Norway",
        "Denmark",
        "Switzerland",
        "Austria",
        "Belgium",
        "Portugal",
        "Mexico",
        "Argentina",
        "Brazil",
        "China",
        "Japan",
        "South Korea",
        "India",
        "Australia",
        "New Zealand"
    ]
    
    var body: some View {
        Menu {
            ForEach(countries, id: \.self) { country in
                Button(action: {
                    selectedCountry = country
                }) {
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

// MARK: - Preview
#if DEBUG
import ReachuTesting

#Preview("Checkout - Address Step") {
    RCheckoutOverlay()
        .environmentObject({
            let manager = CartManager()
            Task {
                await manager.addProduct(MockDataProvider.shared.sampleProducts[0])
                await manager.addProduct(MockDataProvider.shared.sampleProducts[1])
            }
            return manager
        }())
}
#endif