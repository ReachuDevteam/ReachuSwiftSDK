import SwiftUI
import ReachuDesignSystem

public struct CheckoutDemoView: View {
    @State private var customerInfo = CustomerInfo()
    @State private var paymentInfo = PaymentInfo()
    @State private var currentStep: CheckoutStep = .customerInfo
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // Progress Indicator
            CheckoutProgressView(currentStep: currentStep)
                .padding(.horizontal, ReachuSpacing.lg)
                .padding(.top, ReachuSpacing.md)
            
            ScrollView {
                VStack(spacing: ReachuSpacing.lg) {
                    switch currentStep {
                    case .customerInfo:
                        CustomerInfoStep(customerInfo: $customerInfo)
                    case .payment:
                        PaymentInfoStep(paymentInfo: $paymentInfo)
                    case .review:
                        OrderReviewStep(customerInfo: customerInfo, paymentInfo: paymentInfo)
                    }
                }
                .padding(ReachuSpacing.lg)
            }
            
            // Navigation Buttons
            HStack(spacing: ReachuSpacing.md) {
                if currentStep != .customerInfo {
                    RButton(title: "Back", style: .tertiary) {
                        previousStep()
                    }
                }
                
                Spacer()
                
                RButton(title: nextButtonTitle) {
                    nextStep()
                }
            }
            .padding(ReachuSpacing.lg)
            .background(ReachuColors.surface)
        }
        .navigationTitle("Checkout")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
    
    private var nextButtonTitle: String {
        switch currentStep {
        case .customerInfo: return "Continue to Payment"
        case .payment: return "Review Order"
        case .review: return "Place Order"
        }
    }
    
    private func nextStep() {
        switch currentStep {
        case .customerInfo:
            currentStep = .payment
        case .payment:
            currentStep = .review
        case .review:
            placeOrder()
        }
    }
    
    private func previousStep() {
        switch currentStep {
        case .payment:
            currentStep = .customerInfo
        case .review:
            currentStep = .payment
        default:
            break
        }
    }
    
    private func placeOrder() {
        print("Order placed!")
        print("Customer: \(customerInfo.firstName) \(customerInfo.lastName)")
        print("Email: \(customerInfo.email)")
        print("Payment: **** **** **** \(paymentInfo.cardNumber.suffix(4))")
        // TODO: Integrar con ReachuCore para procesar el pedido
    }
}

enum CheckoutStep: CaseIterable {
    case customerInfo, payment, review
    
    var title: String {
        switch self {
        case .customerInfo: return "Customer Info"
        case .payment: return "Payment"
        case .review: return "Review"
        }
    }
}

struct CustomerInfo {
    var firstName = ""
    var lastName = ""
    var email = ""
    var phone = ""
    var address = ""
    var city = ""
    var zipCode = ""
}

struct PaymentInfo {
    var cardNumber = ""
    var expiryDate = ""
    var cvv = ""
    var cardholderName = ""
}

struct CheckoutProgressView: View {
    let currentStep: CheckoutStep
    
    var body: some View {
        HStack {
            ForEach(Array(CheckoutStep.allCases.enumerated()), id: \.offset) { index, step in
                let isCompleted = step.rawValue < currentStep.rawValue
                let isCurrent = step == currentStep
                
                HStack {
                Circle()
                    .fill(isCompleted || isCurrent ? ReachuColors.primary : ReachuColors.textSecondary.opacity(0.3))
                        .frame(width: 24, height: 24)
                        .overlay(
                            Group {
                                if isCompleted {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.white)
                                        .font(.caption.bold())
                                } else {
                                    Text("\(step.rawValue + 1)")
                                        .foregroundColor(isCurrent ? .white : ReachuColors.textSecondary)
                                        .font(.caption.bold())
                                }
                            }
                        )
                    
                    Text(step.title)
                        .font(ReachuTypography.caption1)
                        .foregroundColor(isCurrent ? ReachuColors.primary : ReachuColors.textSecondary)
                    
                    if step != CheckoutStep.allCases.last {
                        Rectangle()
                            .fill(ReachuColors.textSecondary.opacity(0.3))
                            .frame(height: 1)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .padding(.vertical, ReachuSpacing.md)
    }
}

struct CustomerInfoStep: View {
    @Binding var customerInfo: CustomerInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: ReachuSpacing.md) {
            Text("Customer Information")
                .font(ReachuTypography.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: ReachuSpacing.sm) {
                HStack(spacing: ReachuSpacing.sm) {
                    CustomTextField("First Name", text: $customerInfo.firstName)
                    CustomTextField("Last Name", text: $customerInfo.lastName)
                }
                
                CustomTextField("Email", text: $customerInfo.email)
                CustomTextField("Phone", text: $customerInfo.phone)
                CustomTextField("Address", text: $customerInfo.address)
                
                HStack(spacing: ReachuSpacing.sm) {
                    CustomTextField("City", text: $customerInfo.city)
                    CustomTextField("ZIP Code", text: $customerInfo.zipCode)
                }
            }
        }
    }
}

struct PaymentInfoStep: View {
    @Binding var paymentInfo: PaymentInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: ReachuSpacing.md) {
            Text("Payment Information")
                .font(ReachuTypography.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: ReachuSpacing.sm) {
                CustomTextField("Cardholder Name", text: $paymentInfo.cardholderName)
                CustomTextField("Card Number", text: $paymentInfo.cardNumber)
                
                HStack(spacing: ReachuSpacing.sm) {
                    CustomTextField("MM/YY", text: $paymentInfo.expiryDate)
                    CustomTextField("CVV", text: $paymentInfo.cvv)
                }
            }
        }
    }
}

struct OrderReviewStep: View {
    let customerInfo: CustomerInfo
    let paymentInfo: PaymentInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: ReachuSpacing.lg) {
            Text("Order Review")
                .font(ReachuTypography.headline)
                .fontWeight(.semibold)
            
            // Customer Info Summary
            VStack(alignment: .leading, spacing: ReachuSpacing.sm) {
                Text("Shipping Information")
                    .font(ReachuTypography.body)
                    .fontWeight(.medium)
                
                Text("\(customerInfo.firstName) \(customerInfo.lastName)")
                Text(customerInfo.email)
                Text(customerInfo.address)
                Text("\(customerInfo.city), \(customerInfo.zipCode)")
            }
            .padding(ReachuSpacing.md)
            .background(ReachuColors.surface)
            .cornerRadius(ReachuBorderRadius.medium)
            
            // Payment Info Summary
            VStack(alignment: .leading, spacing: ReachuSpacing.sm) {
                Text("Payment Method")
                    .font(ReachuTypography.body)
                    .fontWeight(.medium)
                
                Text(paymentInfo.cardholderName)
                Text("**** **** **** \(paymentInfo.cardNumber.suffix(4))")
            }
            .padding(ReachuSpacing.md)
            .background(ReachuColors.surface)
            .cornerRadius(ReachuBorderRadius.medium)
            
            // Order Summary
            VStack(alignment: .leading, spacing: ReachuSpacing.sm) {
                Text("Order Summary")
                    .font(ReachuTypography.body)
                    .fontWeight(.medium)
                
                HStack {
                    Text("Subtotal")
                    Spacer()
                    Text("$2,549.97")
                }
                
                HStack {
                    Text("Shipping")
                    Spacer()
                    Text("$9.99")
                }
                
                HStack {
                    Text("Tax")
                    Spacer()
                    Text("$255.00")
                }
                
                Divider()
                
                HStack {
                    Text("Total")
                        .fontWeight(.bold)
                    Spacer()
                    Text("$2,814.96")
                        .fontWeight(.bold)
                        .foregroundColor(ReachuColors.primary)
                }
            }
            .padding(ReachuSpacing.md)
            .background(ReachuColors.surface)
            .cornerRadius(ReachuBorderRadius.medium)
        }
    }
}

struct CustomTextField: View {
    let placeholder: String
    @Binding var text: String
    
    init(_ placeholder: String, text: Binding<String>) {
        self.placeholder = placeholder
        self._text = text
    }
    
    var body: some View {
        TextField(placeholder, text: $text)
            .textFieldStyle(PlainTextFieldStyle())
            .padding(ReachuSpacing.md)
            .background(ReachuColors.surface)
            .cornerRadius(ReachuBorderRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: ReachuBorderRadius.medium)
                    .stroke(ReachuColors.textSecondary.opacity(0.3), lineWidth: 1)
            )
    }
}

extension CheckoutStep: RawRepresentable {
    var rawValue: Int {
        switch self {
        case .customerInfo: return 0
        case .payment: return 1
        case .review: return 2
        }
    }
    
    init?(rawValue: Int) {
        switch rawValue {
        case 0: self = .customerInfo
        case 1: self = .payment
        case 2: self = .review
        default: return nil
        }
    }
}

#Preview {
    NavigationView {
        CheckoutDemoView()
    }
}
