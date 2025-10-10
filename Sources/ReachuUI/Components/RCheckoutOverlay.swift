import ReachuCore
import ReachuDesignSystem
import SwiftUI

#if canImport(KlarnaMobileSDK)
    import KlarnaMobileSDK
#endif

#if os(iOS)
    import UIKit
    import StripePaymentSheet
#endif

/// Complete checkout overlay matching original Reachu design
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public struct RCheckoutOverlay: View {

    // MARK: - Environment
    @EnvironmentObject private var cartManager: CartManager
    @EnvironmentObject private var checkoutDraft: CheckoutDraft  // ⬅️ Exponemos estado al contexto
    @SwiftUI.Environment(\.colorScheme) private var colorScheme: SwiftUI.ColorScheme

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
    @State private var phoneCountryCode = ""
    @State private var address1 = ""
    @State private var address2 = ""
    @State private var city = ""
    @State private var province = ""
    @State private var country = ""
    @State private var zip = ""

    // Payment Information
    @State private var selectedPaymentMethod: PaymentMethod = .stripe
    @State private var acceptsTerms = true
    @State private var acceptsPurchaseConditions = true

    // Discount Code
    @State private var discountCode = ""
    @State private var appliedDiscount: Double = 0.0
    @State private var discountMessage = ""

    #if os(iOS)
        @State private var paymentSheet: PaymentSheet?
        @State private var shouldPresentStripeSheet = false
    #endif

    #if os(iOS) && canImport(KlarnaMobileSDK)
        @State private var showKlarnaNativeSheet = false
        @State private var klarnaNativeInitData: InitPaymentKlarnaNativeDto?
        @State private var klarnaNativeContentHeight: CGFloat = 420
        @State private var klarnaAvailableCategories: [KlarnaNativePaymentMethodCategoryDto] = []
        @State private var klarnaSelectedCategoryIdentifier: String = ""
        private let klarnaSuccessURLString =
            "https://tuapp.com/checkout/klarna-return"
        @State private var isUsingKlarnaDirectFlow = true
        @State private var klarnaDirectService: KlarnaAPIService?
        @State private var klarnaDirectAmount: Int = 0
        @State private var klarnaDirectProductName: String = "iPhone 15 Pro Max"
        @State private var klarnaDirectStatusMessage: String?
        @State private var klarnaAutoAuthorize = false // Para disparar autorización automáticamente
    #endif

    private var draftSyncKey: String {
        [
            firstName, lastName, email, phone, phoneCountryCode,
            address1, address2, city, province, country, zip,
            cartManager.items.compactMap { $0.shippingId }.joined(separator: ","),
            selectedPaymentMethod.rawValue,
            String(acceptsTerms), String(acceptsPurchaseConditions),
            String(appliedDiscount), cartManager.currency,
        ].joined(separator: "|")
    }

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
        .onAppear {
            syncSelectedMarket()
        }
        .onChange(of: cartManager.phoneCode) { newValue in
            syncPhoneCode(newValue)
        }
        .onChange(of: cartManager.selectedMarket) { _ in
            syncSelectedMarket()
        }
        .overlay {
            if isLoading {
                loadingOverlay
            }
        }
        #if os(iOS) && canImport(KlarnaMobileSDK)
            .sheet(
                isPresented: $showKlarnaNativeSheet,
                onDismiss: {
                    klarnaNativeInitData = nil
                    klarnaNativeContentHeight = 420
                    klarnaAvailableCategories = []
                    klarnaSelectedCategoryIdentifier = ""
                    if checkoutStep != .success && checkoutStep != .error {
                        checkoutStep = .orderSummary  // cerrar=cancel
                    }
                }
            ) {
                if let initData = klarnaNativeInitData,
                    let returnURL = URL(string: klarnaSuccessURLString),
                    !klarnaAvailableCategories.isEmpty,
                    !klarnaSelectedCategoryIdentifier.isEmpty
                {
                    KlarnaNativePaymentSheet(
                        initData: initData,
                        categories: klarnaAvailableCategories,
                        selectedCategory: $klarnaSelectedCategoryIdentifier,
                        returnURL: returnURL,
                        contentHeight: $klarnaNativeContentHeight,
                        autoAuthorize: $klarnaAutoAuthorize,
                        onAuthorized: { authToken, finalizeRequired in
                            Task { @MainActor in
                                isLoading = true

                                if isUsingKlarnaDirectFlow {
                                    defer {
                                        isLoading = false
                                        showKlarnaNativeSheet = false
                                    }

                                    guard let service = klarnaDirectService else {
                                        klarnaDirectStatusMessage = "Missing direct service instance"
                                        errorMessage = "Direct Klarna service unavailable"
                                        checkoutStep = .error
                                        return
                                    }

                                    do {
                                        let order = try await service.createOrder(
                                            authorizationToken: authToken,
                                            country: "NO",
                                            currency: "NOK",
                                            locale: "nb-NO",
                                            amount: klarnaDirectAmount,
                                            productName: klarnaDirectProductName
                                        )
                                        klarnaDirectStatusMessage =
                                            "Order created: \(order.order_id) (fraud: \(order.fraud_status))"
                                        klarnaDirectService = nil
                                        checkoutStep = .success
                                        klarnaNativeInitData = nil
                                    } catch {
                                        klarnaDirectStatusMessage =
                                            "Error creating order: \(error.localizedDescription)"
                                        errorMessage = error.localizedDescription
                                        checkoutStep = .error
                                    }

                                    return
                                }

                                let customer = klarnaTestCustomer()
                                let address = klarnaTestAddress()
                                let result = await cartManager.confirmKlarnaNative(
                                    authorizationToken: authToken,
                                    autoCapture: finalizeRequired ? nil : true,
                                    customer: customer,
                                    billingAddress: address,
                                    shippingAddress: address
                                )
                                isLoading = false

                                if let confirmation = result {
                                    checkoutStep = .success
                                    klarnaNativeInitData = nil
                                } else {
                                    checkoutStep = .error
                                }

                                showKlarnaNativeSheet = false
                            }
                        },
                        onFailed: { message in
                            Task { @MainActor in
                                errorMessage = message
                            }
                        },
                        onDismiss: {
                            showKlarnaNativeSheet = false
                        }
                    )
                    .interactiveDismissDisabled(isLoading)
                } else {
                    Text("No Klarna payment methods available.")
                    .padding()
                    .onAppear {
                        showKlarnaNativeSheet = false
                        checkoutStep = .error
                    }
                }
            }
        #endif

        .onAppear {
            fillDemoData()
            syncDraftFromState()
        }
        .onChange(of: draftSyncKey) { _ in
            syncDraftFromState()
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
                                Image(
                                    systemName: isEditingAddress
                                        ? "checkmark" : "pencil"
                                )
                                .foregroundColor(ReachuColors.primary)
                                .font(.system(size: 16))
                            }
                        }
                        .padding(.horizontal, ReachuSpacing.lg)

                        // Address Display or Edit Form
                        Group {
                            if isEditingAddress {
                                addressEditForm
                                    .transition(
                                        AnyTransition.opacity.combined(
                                            with: AnyTransition.move(edge: .top)
                                        )
                                    )
                            } else {
                                addressDisplayView
                                    .transition(
                                        AnyTransition.opacity.combined(
                                            with: AnyTransition.move(edge: .top)
                                        )
                                    )
                            }
                        }
                        .animation(
                            .easeInOut(duration: 0.3),
                            value: isEditingAddress
                        )

                        // Shipping Options Selection
                        shippingOptionsSelectionView

                        // Shipping Summary
                        shippingSummaryView
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
            .task {
                await cartManager.refreshShippingOptions()
            }

            // Bottom Button - Full Width
            VStack {
                RButton(
                    title: "Proceed to Checkout",
                    style: .primary,
                    size: .large,
                    isDisabled: !canProceedToNext
                ) {
                    Task {
                        checkoutDraft.firstName = firstName
                        checkoutDraft.lastName = lastName
                        checkoutDraft.email = email
                        checkoutDraft.phone = phone
                        checkoutDraft.phoneCountryCode =
                            phoneCountryCode.replacingOccurrences(
                                of: "+",
                                with: ""
                            )
                        checkoutDraft.address1 = address1
                        checkoutDraft.address2 = address2
                        checkoutDraft.city = city
                        checkoutDraft.province = province
                        checkoutDraft.countryName = country
                        checkoutDraft.zip = zip
                        checkoutDraft.shippingOptionRaw =
                            cartManager.items.compactMap(\.shippingId)
                            .joined(separator: ",")
                        checkoutDraft.paymentMethodRaw =
                            selectedPaymentMethod.rawValue
                        checkoutDraft.acceptsTerms = acceptsTerms
                        checkoutDraft.acceptsPurchaseConditions =
                            acceptsPurchaseConditions
                        checkoutDraft.appliedDiscount = appliedDiscount

                        _ = await cartManager.applyCheapestShippingPerSupplier()

                        guard let chkId = await cartManager.createCheckout()
                        else {
                            proceedToNext()
                            return
                        }

                        let addr = checkoutDraft.addressPayload(
                            fallbackCountryISO2: cartManager.country
                        )

                        _ = await cartManager.updateCheckout(
                            checkoutId: chkId,
                            email: checkoutDraft.email,
                            successUrl: nil,
                            cancelUrl: nil,
                            paymentMethod: checkoutDraft.paymentMethodRaw
                                .capitalized,
                            shippingAddress: addr,
                            billingAddress: addr,
                            acceptsTerms: checkoutDraft.acceptsTerms,
                            acceptsPurchaseConditions: checkoutDraft
                                .acceptsPurchaseConditions
                        )

                        proceedToNext()

                    }
                }
                .frame(maxWidth: .infinity)  // Full width
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
                            ForEach(PaymentMethod.allCases, id: \.self) {
                                method in
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
                        PaymentScheduleCompact(
                            total: finalTotal,
                            currency: cartManager.currency
                        )
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
                    Task { @MainActor in
                        #if os(iOS)
                            if selectedPaymentMethod == .stripe {
                                isLoading = true
                                let ok = await prepareStripePaymentSheet()
                                isLoading = false
                                if ok {
                                    shouldPresentStripeSheet = true
                                    presentStripePaymentSheet()
                                    return
                                } else {
                                    checkoutStep = .error
                                    return
                                }
                            }
                            if selectedPaymentMethod == .klarna {
                                isLoading = true
                                let ok = await prepareKlarnaNative()
                                isLoading = false
                                if ok {
                                    klarnaNativeContentHeight = 420
                                    showKlarnaNativeSheet = true
                                    return
                                } else {
                                    checkoutStep = .error
                                    return
                                }
                            }
                        #endif
                        proceedToNext()
                    }
                }
                .frame(maxWidth: .infinity)  // Full width
                .padding(.horizontal, ReachuSpacing.lg)
                .padding(.vertical, ReachuSpacing.md)
            }
            .background(ReachuColors.surface)
        }
        .onChange(of: selectedPaymentMethod) { newMethod in
            Task { @MainActor in
                _ = await cartManager.updateCheckout(
                    checkoutId: cartManager.checkoutId,
                    email: nil,
                    successUrl: nil,
                    cancelUrl: nil,
                    paymentMethod: newMethod.rawValue.capitalized,  // "Stripe" | "Klarna"
                    shippingAddress: nil,
                    billingAddress: nil,
                    acceptsTerms: acceptsTerms,
                    acceptsPurchaseConditions: acceptsPurchaseConditions
                )
            }
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

                        Text(
                            "\(cartManager.currency) \(String(format: "%.2f", finalTotal))"
                        )
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(ReachuColors.textPrimary)
                    }
                    .padding(.horizontal, ReachuSpacing.lg)
                    .padding(.top, ReachuSpacing.lg)

                    // Products List - Each product with individual quantity controls
                    VStack(spacing: ReachuSpacing.xl) {
                        ForEach(
                            Array(cartManager.items.enumerated()),
                            id: \.offset
                        ) {
                            index,
                            item in
                            VStack(spacing: ReachuSpacing.md) {
                                // Product header with image and details
                                HStack(spacing: ReachuSpacing.md) {
                                    // Product image
                                    AsyncImage(
                                        url: URL(string: item.imageUrl ?? "")
                                    ) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        Rectangle()
                                            .fill(Color.yellow)  // Placeholder like in image
                                    }
                                    .frame(width: 60, height: 60)
                                    .cornerRadius(8)

                                    VStack(
                                        alignment: .leading,
                                        spacing: ReachuSpacing.xs
                                    ) {
                                        Text(item.brand ?? "Reachu Audio")
                                            .font(
                                                .system(
                                                    size: 14,
                                                    weight: .regular
                                                )
                                            )
                                            .foregroundColor(
                                                ReachuColors.textSecondary
                                            )

                                        Text(item.title)
                                            .font(
                                                .system(
                                                    size: 16,
                                                    weight: .semibold
                                                )
                                            )
                                            .foregroundColor(
                                                ReachuColors.textPrimary
                                            )
                                            .lineLimit(2)
                                    }

                                    Spacer()

                                    Text(
                                        "\(item.currency) \(String(format: "%.2f", item.price))"
                                    )
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(ReachuColors.textPrimary)
                                }

                                // Product details
                                VStack(spacing: ReachuSpacing.xs) {
                                    HStack {
                                        Text("Order ID:")
                                            .font(
                                                .system(
                                                    size: 14,
                                                    weight: .regular
                                                )
                                            )
                                            .foregroundColor(
                                                ReachuColors.textSecondary
                                            )

                                        Spacer()

                                        Text("BD23672983")
                                            .font(
                                                .system(
                                                    size: 14,
                                                    weight: .regular
                                                )
                                            )
                                            .foregroundColor(
                                                ReachuColors.textSecondary
                                            )
                                    }

                                    HStack {
                                        Text("Colors:")
                                            .font(
                                                .system(
                                                    size: 14,
                                                    weight: .regular
                                                )
                                            )
                                            .foregroundColor(
                                                ReachuColors.textSecondary
                                            )

                                        Spacer()

                                        Text("Like Water")
                                            .font(
                                                .system(
                                                    size: 14,
                                                    weight: .regular
                                                )
                                            )
                                            .foregroundColor(
                                                ReachuColors.textSecondary
                                            )
                                    }
                                }

                                // Read-only Quantity Display (NO controls in payment step)
                                HStack {
                                    Text("Quantity")
                                        .font(
                                            .system(size: 16, weight: .semibold)
                                        )
                                        .foregroundColor(
                                            ReachuColors.textPrimary
                                        )

                                    Spacer()

                                    Text("\(item.quantity)")
                                        .font(
                                            .system(size: 18, weight: .semibold)
                                        )
                                        .foregroundColor(
                                            ReachuColors.textPrimary
                                        )
                                }

                                // Show total for this product
                                HStack {
                                    Text("Total for this item:")
                                        .font(
                                            .system(size: 14, weight: .medium)
                                        )
                                        .foregroundColor(
                                            ReachuColors.textSecondary
                                        )

                                    Spacer()

                                    Text(
                                        "\(item.currency) \(String(format: "%.2f", item.price * Double(item.quantity)))"
                                    )
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(ReachuColors.primary)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, ReachuSpacing.lg)

                    completeOrderSummaryView

                    // Payment Schedule (if Klarna installments selected)
                    if selectedPaymentMethod == .klarna {
                        VStack(alignment: .leading, spacing: ReachuSpacing.md) {
                            Text("Payment Schedule")
                                .font(ReachuTypography.bodyBold)
                                .foregroundColor(ReachuColors.textPrimary)
                                .padding(.horizontal, ReachuSpacing.lg)

                            PaymentScheduleDetailed(
                                total: finalTotal,
                                currency: cartManager.currency
                            )
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
        Group {
            #if os(iOS)
                if selectedPaymentMethod == .stripe && shouldPresentStripeSheet {
                    Color.clear
                        .onAppear {
                            presentStripePaymentSheet()
                        }
                } else {
                    VStack(spacing: 0) {
                        ScrollView {
                            VStack(
                                alignment: .leading,
                                spacing: ReachuSpacing.lg
                            ) {
                                Text("Review Order")
                                    .font(ReachuTypography.title2)
                                    .foregroundColor(ReachuColors.textPrimary)
                                    .padding(.horizontal, ReachuSpacing.lg)
                                    .padding(.top, ReachuSpacing.lg)

                                Text("Order review content...")
                                    .padding(.horizontal, ReachuSpacing.lg)

                                Spacer(minLength: 100)
                            }
                        }

                        VStack {
                            RButton(
                                title: "Complete Purchase",
                                style: .primary,
                                size: .large
                            ) {
                                Task {
                                    await prepareStripePaymentSheet()
                                    shouldPresentStripeSheet = true
                                }
                            }
                            .padding(.horizontal, ReachuSpacing.lg)
                            .padding(.vertical, ReachuSpacing.md)
                        }
                        .background(ReachuColors.surface)
                    }
                }
            #else
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: ReachuSpacing.lg) {
                            Text("Review Order")
                                .font(ReachuTypography.title2)
                                .foregroundColor(ReachuColors.textPrimary)
                                .padding(.horizontal, ReachuSpacing.lg)
                                .padding(.top, ReachuSpacing.lg)

                            Text("Order review content...")
                                .padding(.horizontal, ReachuSpacing.lg)

                            Spacer(minLength: 100)
                        }
                    }
                    VStack {
                        RButton(
                            title: "Complete Purchase",
                            style: .primary,
                            size: .large
                        ) {
                            checkoutStep = .review
                        }
                        .padding(.horizontal, ReachuSpacing.lg)
                        .padding(.vertical, ReachuSpacing.md)
                    }
                    .background(ReachuColors.surface)
                }
            #endif
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
                        .animation(
                            .spring(response: 0.6, dampingFraction: 0.6).delay(
                                0.2
                            ),
                            value: checkoutStep
                        )

                    Image(systemName: "checkmark")
                        .font(.system(size: 45, weight: .bold))
                        .foregroundColor(.white)
                        .scaleEffect(checkoutStep == .success ? 1.0 : 0.0)
                        .animation(
                            .spring(response: 0.4, dampingFraction: 0.6).delay(
                                0.4
                            ),
                            value: checkoutStep
                        )
                }

                // Success Message (smaller and more compact)
                VStack(spacing: ReachuSpacing.sm) {
                    Text("Purchase Complete!")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(ReachuColors.textPrimary)
                        .multilineTextAlignment(.center)
                        .opacity(checkoutStep == .success ? 1.0 : 0.0)
                        .animation(
                            .easeInOut(duration: 0.5).delay(0.6),
                            value: checkoutStep
                        )

                    Text(
                        selectedPaymentMethod == .klarna
                            ? "You'll pay in 4x interest-free. We'll send you a reminder a few days before each payment."
                            : "Your order has been confirmed. You'll receive an email confirmation shortly."
                    )
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(ReachuColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, ReachuSpacing.xl)
                    .opacity(checkoutStep == .success ? 1.0 : 0.0)
                    .animation(
                        .easeInOut(duration: 0.5).delay(0.8),
                        value: checkoutStep
                    )
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
                .animation(
                    .easeInOut(duration: 0.5).delay(1.0),
                    value: checkoutStep
                )
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
                        .animation(
                            .spring(response: 0.6, dampingFraction: 0.6).delay(
                                0.2
                            ),
                            value: checkoutStep
                        )

                    Image(systemName: "xmark")
                        .font(.system(size: 45, weight: .bold))
                        .foregroundColor(.white)
                        .scaleEffect(checkoutStep == .error ? 1.0 : 0.0)
                        .animation(
                            .spring(response: 0.4, dampingFraction: 0.6).delay(
                                0.4
                            ),
                            value: checkoutStep
                        )
                }

                // Error Message
                VStack(spacing: ReachuSpacing.sm) {
                    Text("Payment Failed")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(ReachuColors.textPrimary)
                        .multilineTextAlignment(.center)
                        .opacity(checkoutStep == .error ? 1.0 : 0.0)
                        .animation(
                            .easeInOut(duration: 0.5).delay(0.6),
                            value: checkoutStep
                        )

                    Text(
                        "There was an issue processing your payment. Please check your payment information and try again."
                    )
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(ReachuColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, ReachuSpacing.xl)
                    .opacity(checkoutStep == .error ? 1.0 : 0.0)
                    .animation(
                        .easeInOut(duration: 0.5).delay(0.8),
                        value: checkoutStep
                    )
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
                .animation(
                    .easeInOut(duration: 0.5).delay(1.0),
                    value: checkoutStep
                )

                RButton(
                    title: "Go Back",
                    style: .secondary,
                    size: .large
                ) {
                    cartManager.hideCheckout()
                }
                .opacity(checkoutStep == .error ? 1.0 : 0.0)
                .animation(
                    .easeInOut(duration: 0.5).delay(1.1),
                    value: checkoutStep
                )
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
                        .progressViewStyle(
                            CircularProgressViewStyle(tint: .white)
                        )
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
            return !firstName.isEmpty && !lastName.isEmpty && !email.isEmpty
                && !phone.isEmpty
                && !address1.isEmpty && !city.isEmpty && !zip.isEmpty
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
                // Handle Klarna direct flow
                if selectedPaymentMethod == .klarna {
                    #if os(iOS) && canImport(KlarnaMobileSDK)
                        Task {
                            await initiateKlarnaDirectFlow()
                        }
                    #endif
                } else {
                    checkoutStep = .review
                }
            case .review:
                if selectedPaymentMethod == .stripe {
                    #if os(iOS)
                        Task {
                            await prepareStripePaymentSheet()
                            shouldPresentStripeSheet = true
                        }
                    #endif
                } else {
                    checkoutStep = .success
                }
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
                let impactFeedback = UIImpactFeedbackGenerator(
                    style: isSuccess ? .heavy : .rigid
                )
                impactFeedback.impactOccurred()
            #endif
        }
    }

    private func fillDemoData() {
        firstName = "John"
        lastName = "Doe"
        email = "john.doe@example.com"
        phone = "2125551212"
        if let market = cartManager.selectedMarket {
            phoneCountryCode = market.phoneCode
            country = market.name
        } else {
            phoneCountryCode = "+1"
            country = "United States"
        }
        address1 = "82 Melora Street"
        city = "Westbridge"
        province = "California"
        zip = "92841"
        syncPhoneCode(phoneCountryCode)
    }

    private func syncDraftFromState() {
        checkoutDraft.firstName = firstName
        checkoutDraft.lastName = lastName
        checkoutDraft.email = email
        checkoutDraft.phone = phone
        checkoutDraft.phoneCountryCode = phoneCountryCode.replacingOccurrences(
            of: "+",
            with: ""
        )

        checkoutDraft.address1 = address1
        checkoutDraft.address2 = address2
        checkoutDraft.city = city
        checkoutDraft.province = province
        checkoutDraft.countryName = country
        checkoutDraft.zip = zip

        checkoutDraft.shippingOptionRaw =
            cartManager.items.compactMap(\.shippingId).joined(separator: ",")
        checkoutDraft.paymentMethodRaw = selectedPaymentMethod.rawValue
        checkoutDraft.acceptsTerms = acceptsTerms
        checkoutDraft.acceptsPurchaseConditions = acceptsPurchaseConditions
        checkoutDraft.appliedDiscount = appliedDiscount
    }

    #if os(iOS) && canImport(KlarnaMobileSDK)
        private func klarnaTestCustomer() -> KlarnaNativeCustomerInputDto {
            KlarnaNativeCustomerInputDto(
                email: "test.user@example.com",
                phone: "+4798765432"
            )
        }

        private func klarnaTestAddress() -> KlarnaNativeAddressInputDto {
            KlarnaNativeAddressInputDto(
                givenName: "John",
                familyName: "Doe",
                email: "john.doe@example.com",
                phone: "+4798765432",
                streetAddress: "Karl Johans gate 1",
                streetAddress2: nil,
                city: "Oslo",
                region: nil,
                postalCode: "0154",
                country: "NO"
            )
        }

        private func initiateKlarnaDirectFlow() async {
            await MainActor.run {
                isLoading = true
                errorMessage = nil
            }

            // Calculate total amount in minor units (cents/øre)
            let totalAmount = Int(finalTotal * 100)

            // Initialize Klarna service
            let service = KlarnaAPIService()
            await MainActor.run {
                klarnaDirectService = service
                klarnaDirectAmount = totalAmount
                klarnaDirectProductName = cartManager.items.first?.title ?? "Order"
            }

            do {
                // Create Klarna session
                let response = try await service.createSession(
                    country: "NO",
                    currency: "NOK",
                    locale: "nb-NO",
                    amount: totalAmount,
                    productName: klarnaDirectProductName
                )

                await MainActor.run {
                    do {
                        // Map response to DTOs using JSONEncoder/Decoder
                        let encoder = JSONEncoder()
                        encoder.keyEncodingStrategy = .convertToSnakeCase
                        
                        // Create categories array
                        var categoriesArray: [[String: Any]] = []
                        if let categories = response.payment_method_categories {
                            for category in categories {
                                var categoryDict: [String: Any] = [
                                    "identifier": category.identifier,
                                    "name": category.name ?? ""
                                ]
                                
                                if let assetUrls = category.asset_urls {
                                    categoryDict["asset_urls"] = [
                                        "descriptive": assetUrls.descriptive ?? "",
                                        "standard": assetUrls.standard ?? ""
                                    ]
                                }
                                
                                categoriesArray.append(categoryDict)
                            }
                        }
                        
                        // Decode categories
                        let categoriesData = try JSONSerialization.data(withJSONObject: categoriesArray)
                        let mappedCategories = try JSONDecoder().decode([KlarnaNativePaymentMethodCategoryDto].self, from: categoriesData)
                        
                        self.klarnaAvailableCategories = mappedCategories
                        
                        // Select first category automatically
                        if let firstCategory = mappedCategories.first {
                            self.klarnaSelectedCategoryIdentifier = firstCategory.identifier
                        }
                        
                        // Create InitPaymentKlarnaNativeDto
                        let initDict: [String: Any] = [
                            "client_token": response.client_token,
                            "session_id": response.session_id,
                            "purchase_country": "NO",
                            "purchase_currency": "NOK",
                            "cart_id": cartManager.cartId ?? "",
                            "checkout_id": "",
                            "payment_method_categories": categoriesArray
                        ]
                        
                        let initData = try JSONSerialization.data(withJSONObject: initDict)
                        self.klarnaNativeInitData = try JSONDecoder().decode(InitPaymentKlarnaNativeDto.self, from: initData)
                        
                        self.isLoading = false
                        
                        // Activate auto-authorize and show sheet
                        self.klarnaAutoAuthorize = true
                        self.showKlarnaNativeSheet = true
                    } catch {
                        self.isLoading = false
                        self.errorMessage = "Failed to parse Klarna response: \(error.localizedDescription)"
                        self.checkoutStep = .error
                    }
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = "Failed to initialize Klarna: \(error.localizedDescription)"
                    self.checkoutStep = .error
                }
            }
        }
    #endif

    #if os(iOS)
        private func dtoToDict<T: Encodable>(_ dto: T) -> [String: Any]? {
            guard let data = try? JSONEncoder().encode(dto) else { return nil }
            return
                (try? JSONSerialization.jsonObject(with: data) as? [String: Any])
                ?? nil
        }

        private func pick<T>(_ dict: [String: Any], _ keys: [String]) -> T? {
            for k in keys {
                if let v = dict[k] as? T { return v }
                let normalized = k.replacingOccurrences(of: "_", with: "")
                    .lowercased()
                if let hit = dict.first(where: {
                    $0.key.replacingOccurrences(of: "_", with: "").lowercased()
                        == normalized
                }), let cast = hit.value as? T {
                    return cast
                }
            }
            return nil
        }

        private func prepareStripePaymentSheet() async -> Bool {
            guard
                let dto = await cartManager.stripeIntent(
                    returnEphemeralKey: true
                ),
                let dict = dtoToDict(dto)
            else {
                self.errorMessage = "Could not get Stripe Intent from API."
                return false
            }

            let clientSecret: String? = pick(
                dict,
                [
                    "payment_intent_client_secret", "client_secret",
                    "paymentIntentClientSecret",
                ]
            )
            guard let secret = clientSecret, !secret.isEmpty else {
                self.errorMessage = "Missing Payment Intent client_secret."
                return false
            }

            let ephemeralKey: String? = pick(
                dict,
                ["ephemeralKeySecret", "ephemeral_key_secret", "ephemeral_key"]
            )
            let customerId: String? = pick(
                dict,
                ["customer", "customer_id", "customerId"]
            )

            var config = PaymentSheet.Configuration()
            config.merchantDisplayName = "Reachu Demo"
            if let ek = ephemeralKey, let cid = customerId {
                config.customer = .init(id: cid, ephemeralKeySecret: ek)
            }

            self.paymentSheet = PaymentSheet(
                paymentIntentClientSecret: secret,
                configuration: config
            )
            return true
        }

        // Present PaymentSheet from the top-most view controller
        private func presentStripePaymentSheet() {
            guard let sheet = paymentSheet, let root = topMostViewController()
            else { return }
            sheet.present(from: root) { result in
                switch result {
                case .completed:
                    withAnimation { checkoutStep = .success }  // ✅ done
                case .canceled:
                    withAnimation { checkoutStep = .orderSummary }  // ↩️ back to summary
                case .failed(let error):
                    self.errorMessage = error.localizedDescription
                    withAnimation { checkoutStep = .error }  // ❌ error
                }
                shouldPresentStripeSheet = false
            }
        }

        // Find the top-most view controller for presentation
        private func topMostViewController() -> UIViewController? {
            guard
                let scene = UIApplication.shared.connectedScenes
                    .compactMap({ $0 as? UIWindowScene })
                    .first(where: { $0.activationState == .foregroundActive }),
                let root = scene.windows.first(where: { $0.isKeyWindow })?
                    .rootViewController
            else { return nil }

            var vc: UIViewController = root
            while let presented = vc.presentedViewController { vc = presented }
            if let nav = vc as? UINavigationController {
                return nav.visibleViewController ?? nav
            }
            if let tab = vc as? UITabBarController {
                return tab.selectedViewController ?? tab
            }
            return vc
        }

        private func prepareKlarnaNative() async -> Bool {
            guard let returnURL = URL(string: klarnaSuccessURLString) else {
                errorMessage = "Invalid Klarna return URL"
                return false
            }

            klarnaAvailableCategories = []
            klarnaSelectedCategoryIdentifier = ""

            cartManager.checkoutId = "aff8128b-8df1-4d50-9fc8-9114795fe6c7"

            let hardcodedCustomer = KlarnaNativeCustomerInputDto(
                email: "test.user@example.com",
                phone: "+4798765432"
            )

            let hardcodedAddress = KlarnaNativeAddressInputDto(
                givenName: "John",
                familyName: "Doe",
                email: "john.doe@example.com",
                phone: "+4798765432",
                streetAddress: "Karl Johans gate 1",
                streetAddress2: nil,
                city: "Oslo",
                region: nil,
                postalCode: "0154",
                country: "NO"
            )

            let input = KlarnaNativeInitInputDto(
                countryCode: "NO",
                currency: "NOK",
                locale: "nb-NO",
                returnUrl: returnURL.absoluteString,
                intent: "buy",
                autoCapture: true,
                customer: hardcodedCustomer,
                billingAddress: hardcodedAddress,
                shippingAddress: hardcodedAddress
            )

            guard let dto = await cartManager.initKlarnaNative(input: input)
            else {
                return false
            }

            let categories = dto.paymentMethodCategories ?? []
            guard !categories.isEmpty else {
                errorMessage = "No Klarna payment methods available for this checkout."
                klarnaAvailableCategories = []
                klarnaSelectedCategoryIdentifier = ""
                return false
            }

            klarnaAvailableCategories = KlarnaCategoryMapper.sorted(categories)
            klarnaSelectedCategoryIdentifier =
                KlarnaCategoryMapper.preferredIdentifier(from: klarnaAvailableCategories)
                ?? ""

            guard !klarnaSelectedCategoryIdentifier.isEmpty else {
                errorMessage = "Unsupported Klarna payment category."
                return false
            }

            klarnaNativeInitData = dto
            return true
        }

    #endif

}

// MARK: - Supporting Components

struct PaymentMethodRowCompact: View {
    let method: RCheckoutOverlay.PaymentMethod
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: ReachuSpacing.md) {
                ZStack {
                    Circle()
                        .stroke(
                            isSelected
                                ? ReachuColors.primary : ReachuColors.border,
                            lineWidth: 2
                        )
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
                            .fill(
                                installment == 1
                                    ? ReachuColors.primary : ReachuColors.border
                            )
                            .frame(width: 24, height: 24)

                        Text("\(installment)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(
                                installment == 1
                                    ? .white : ReachuColors.textSecondary
                            )
                    }

                    Text(
                        installment == 1
                            ? "Due Today"
                            : "In \(installment - 1) month\(installment > 2 ? "s" : "")"
                    )
                    .font(.system(size: 10))
                    .foregroundColor(ReachuColors.textSecondary)

                    Text(
                        "\(currency) \(String(format: "%.2f", installmentAmount))"
                    )
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
                                .fill(
                                    installment == 1
                                        ? ReachuColors.primary
                                        : ReachuColors.border
                                )
                                .frame(width: 32, height: 32)

                            Text("\(installment)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(
                                    installment == 1
                                        ? .white : ReachuColors.textSecondary
                                )
                        }

                        Text(
                            installment == 1
                                ? "Due Today"
                                : "In \(installment - 1) month\(installment > 2 ? "s" : "")"
                        )
                        .font(.system(size: 11))
                        .foregroundColor(ReachuColors.textSecondary)

                        Text(
                            "\(currency) \(String(format: "%.2f", installmentAmount))"
                        )
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
            ForEach(Array(cartManager.items.enumerated()), id: \.offset) {
                index,
                item in
                VStack(spacing: ReachuSpacing.md) {
                    // Product header with image and details
                    HStack(spacing: ReachuSpacing.md) {
                        // Product image
                        AsyncImage(url: URL(string: item.imageUrl ?? "")) {
                            image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle()
                                .fill(Color.yellow)  // Placeholder like in image
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
                                            await cartManager.updateQuantity(
                                                for: item,
                                                to: item.quantity - 1
                                            )
                                        }
                                    }
                                }) {
                                    Image(systemName: "minus")
                                        .font(
                                            .system(size: 14, weight: .medium)
                                        )
                                        .foregroundColor(
                                            ReachuColors.textPrimary
                                        )
                                        .frame(width: 28, height: 28)
                                        .background(
                                            ReachuColors.surfaceSecondary
                                        )
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
                                        await cartManager.updateQuantity(
                                            for: item,
                                            to: item.quantity + 1
                                        )
                                    }
                                }) {
                                    Image(systemName: "plus")
                                        .font(
                                            .system(size: 14, weight: .medium)
                                        )
                                        .foregroundColor(
                                            ReachuColors.textPrimary
                                        )
                                        .frame(width: 28, height: 28)
                                        .background(
                                            ReachuColors.surfaceSecondary
                                        )
                                        .cornerRadius(4)
                                }
                            }
                        }

                        Spacer()

                        Text(
                            "\(item.currency) \(String(format: "%.2f", item.price))"
                        )
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

                        Text(
                            "\(item.currency) \(String(format: "%.2f", item.price * Double(item.quantity)))"
                        )
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
                                    colors: [
                                        ReachuColors.surfaceSecondary,
                                        ReachuColors.background,
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay {
                                Image(systemName: "photo")
                                    .font(.title2)
                                    .foregroundColor(
                                        ReachuColors.textSecondary.opacity(0.6)
                                    )
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
                .shadow(
                    color: ReachuColors.textPrimary.opacity(0.1),
                    radius: 8,
                    x: 0,
                    y: 4
                )

                // Product Details with Elegant Typography
                VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
                    // Brand with subtle styling
                    Text(item.brand ?? "Adidas Store")
                        .font(
                            .system(size: 13, weight: .medium, design: .rounded)
                        )
                        .foregroundColor(ReachuColors.textSecondary)
                        .textCase(.uppercase)

                    // Product name with emphasis
                    Text(item.title)
                        .font(
                            .system(size: 16, weight: .bold, design: .default)
                        )
                        .foregroundColor(ReachuColors.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    // Order ID with modern styling
                    HStack(spacing: ReachuSpacing.xs) {
                        Image(systemName: "number.circle.fill")
                            .font(.caption2)
                            .foregroundColor(ReachuColors.primary.opacity(0.7))

                        Text("BD23672983")
                            .font(
                                .system(
                                    size: 12,
                                    weight: .medium,
                                    design: .monospaced
                                )
                            )
                            .foregroundColor(ReachuColors.textSecondary)
                    }

                    // Colors with stylish presentation
                    HStack(spacing: ReachuSpacing.xs) {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.blue.opacity(0.8),
                                        Color.purple.opacity(0.6),
                                    ],
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
                    Text(
                        "\(item.currency) \(String(format: "%.2f", item.price * Double(item.quantity)))"
                    )
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(ReachuColors.textPrimary)

                    // Quantity with subtle background
                    HStack(spacing: ReachuSpacing.xs) {
                        Text("×")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(ReachuColors.textSecondary)

                        Text("\(item.quantity)")
                            .font(
                                .system(
                                    size: 14,
                                    weight: .bold,
                                    design: .rounded
                                )
                            )
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
            .shadow(
                color: ReachuColors.textPrimary.opacity(0.05),
                radius: 12,
                x: 0,
                y: 6
            )
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
                        RoundedRectangle(
                            cornerRadius: ReachuBorderRadius.medium
                        )
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
                    Image(
                        systemName: appliedDiscount > 0
                            ? "checkmark.circle.fill"
                            : "exclamationmark.circle.fill"
                    )
                    .font(.body)
                    .foregroundColor(
                        appliedDiscount > 0
                            ? ReachuColors.success : ReachuColors.error
                    )

                    Text(discountMessage)
                        .font(ReachuTypography.caption1)
                        .foregroundColor(
                            appliedDiscount > 0
                                ? ReachuColors.success : ReachuColors.error
                        )
                }
                .transition(
                    AnyTransition.opacity.combined(
                        with: AnyTransition.move(edge: .top)
                    )
                )
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

                    Text(
                        "\(cartManager.currency) \(String(format: "%.2f", cartManager.cartTotal))"
                    )
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(ReachuColors.textPrimary)
                }

                // Shipping
                HStack {
                    Text("Shipping")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(ReachuColors.textSecondary)

                    Spacer()

                    Text(shippingAmountText)
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

                        Text(
                            "-\(cartManager.currency) \(String(format: "%.2f", appliedDiscount))"
                        )
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

                    Text(
                        "\(cartManager.currency) \(String(format: "%.2f", finalTotal))"
                    )
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
                                    await cartManager.updateQuantity(
                                        for: item,
                                        to: item.quantity - 1
                                    )
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
                .disabled(cartManager.itemCount <= cartManager.items.count)  // Can't go below 1 per item

                Text("\(cartManager.itemCount)")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(ReachuColors.textPrimary)
                    .frame(width: 60)
                    .animation(.spring(), value: cartManager.itemCount)

                Button(action: {
                    // Increase entire order quantity
                    Task {
                        for item in cartManager.items {
                            await cartManager.updateQuantity(
                                for: item,
                                to: item.quantity + 1
                            )
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

    // Shipping summary sourced from CartManager
    private var shippingSummaryView: some View {
        VStack(alignment: .leading, spacing: ReachuSpacing.sm) {
            Text("Shipping")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(ReachuColors.textPrimary)
                .padding(.horizontal, ReachuSpacing.lg)

            VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
                HStack {
                    Text("Total shipping")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(ReachuColors.textPrimary)

                    Spacer()

                    Text(shippingAmountText)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(ReachuColors.textPrimary)
                }

                if cartManager.items.contains(where: {
                    ($0.shippingName?.isEmpty == false) || $0.shippingAmount != nil
                }) {
                    ForEach(cartManager.items) { item in
                        if (item.shippingName?.isEmpty == false) || item.shippingAmount != nil {
                            HStack(alignment: .top, spacing: ReachuSpacing.sm) {
                                VStack(alignment: .leading, spacing: 2) {
                                    if let name = item.shippingName, !name.isEmpty {
                                        Text(name)
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(ReachuColors.textPrimary)
                                    }

                                    Text(item.title)
                                        .font(.system(size: 12))
                                        .foregroundColor(ReachuColors.textSecondary)
                                        .lineLimit(1)
                                }

                                Spacer()

                                Text(
                                    formattedShipping(
                                        amount: item.shippingAmount,
                                        currency: item.shippingCurrency
                                    )
                                )
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(ReachuColors.textPrimary)
                            }
                            .padding(.vertical, ReachuSpacing.xs)
                        }
                    }
                } else {
                    Text("Shipping is calculated automatically for this order.")
                        .font(.system(size: 12))
                        .foregroundColor(ReachuColors.textSecondary)
                }
            }
            .padding(.horizontal, ReachuSpacing.lg)
            .padding(.vertical, ReachuSpacing.sm)
            .background(ReachuColors.surfaceSecondary)
            .cornerRadius(ReachuBorderRadius.medium)
            .padding(.horizontal, ReachuSpacing.lg)
        }
    }

    private var shippingOptionsSelectionView: some View {
        VStack(alignment: .leading, spacing: ReachuSpacing.md) {
            if cartManager.items.contains(where: { !$0.availableShippings.isEmpty }) {
                Text("Shipping Options")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(ReachuColors.textPrimary)
                    .padding(.horizontal, ReachuSpacing.lg)

                VStack(spacing: ReachuSpacing.md) {
                    ForEach(cartManager.items) { item in
                        if !item.availableShippings.isEmpty {
                            ItemShippingOptionsView(
                                item: item,
                                onSelect: { option in
                                    cartManager.setShippingOption(for: item.id, optionId: option.id)
                                }
                            )
                        }
                    }
                }
                .padding(.horizontal, ReachuSpacing.lg)
            } else {
                Text("No shipping methods available for this order yet.")
                    .font(.system(size: 12))
                    .foregroundColor(ReachuColors.textSecondary)
                    .padding(.horizontal, ReachuSpacing.lg)
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

                Text(
                    "\(cartManager.currency) \(String(format: "%.2f", cartManager.cartTotal))"
                )
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(ReachuColors.textPrimary)
            }

            // Shipping
            HStack {
                Text("Shipping")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(ReachuColors.textSecondary)

                Spacer()

                Text(shippingAmountText)
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

                Text(
                    "\(cartManager.currency) \(String(format: "%.2f", cartManager.cartTotal + shippingAmount))"
                )
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
                    Text(
                        "\(item.currency) \(String(format: "%.2f", item.price * Double(item.quantity)))"
                    )
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

                    Text(
                        "\(cartManager.currency) \(String(format: "%.2f", cartManager.cartTotal))"
                    )
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(ReachuColors.textPrimary)
                }

                // Shipping
                HStack {
                    Text("Shipping")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(ReachuColors.textSecondary)

                    Spacer()

                    Text(shippingAmountText)
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

                        Text(
                            "-\(cartManager.currency) \(String(format: "%.2f", appliedDiscount))"
                        )
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

                    Text(
                        "\(cartManager.currency) \(String(format: "%.2f", finalTotal))"
                    )
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(ReachuColors.primary)
                }
            }
            .padding(.horizontal, ReachuSpacing.lg)
        }
    }

    // MARK: - Helper Functions

    private var shippingAmount: Double {
        cartManager.shippingTotal
    }

    private var shippingCurrencySymbol: String {
        return cartManager.currencySymbol
    }

    private var shippingAmountText: String {
        shippingAmount > 0
            ? "\(shippingCurrencySymbol) \(String(format: "%.2f", shippingAmount))"
            : "Free"
    }

    private var finalTotal: Double {
        return cartManager.cartTotal + shippingAmount - appliedDiscount
    }

    private func formattedShipping(amount: Double?, currency: String?) -> String {
        guard let amount = amount else { return "Free" }

        let symbol = (currency?.isEmpty == false) ? currency! : shippingCurrencySymbol
        return amount > 0
            ? "\(symbol) \(String(format: "%.2f", amount))"
            : "Free"
    }

    private func syncSelectedMarket() {
        if let market = cartManager.selectedMarket {
            country = market.name
            syncPhoneCode(market.phoneCode)
            checkoutDraft.countryName = market.name
            checkoutDraft.countryCode = market.code
        }
    }

    private func syncPhoneCode(_ code: String) {
        phoneCountryCode = code
        checkoutDraft.phoneCountryCode = code.replacingOccurrences(of: "+", with: "")
    }

    fileprivate struct ItemShippingOptionsView: View {
        let item: CartManager.CartItem
        let onSelect: (CartManager.CartItem.ShippingOption) -> Void

        private var title: String { item.title }
        private var selectedId: String? { item.shippingId }

        var body: some View {
            VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(ReachuColors.textPrimary)

                VStack(spacing: ReachuSpacing.xs) {
                    ForEach(item.availableShippings) { option in
                        Button {
                            onSelect(option)
                        } label: {
                            HStack(spacing: ReachuSpacing.sm) {
                                Image(
                                    systemName: selectedId == option.id
                                        ? "checkmark.circle.fill"
                                        : "circle"
                                )
                                .foregroundColor(
                                    selectedId == option.id
                                        ? ReachuColors.primary
                                        : ReachuColors.textSecondary
                                )

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(option.name)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(ReachuColors.textPrimary)

                                    if let description = option.description, !description.isEmpty {
                                        Text(description)
                                            .font(.system(size: 12))
                                            .foregroundColor(ReachuColors.textSecondary)
                                    }
                                }

                                Spacer()

                                Text(
                                    option.amount > 0
                                        ? "\(option.currency) \(String(format: "%.2f", option.amount))"
                                        : "Free"
                                )
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(ReachuColors.textPrimary)
                            }
                            .padding(.horizontal, ReachuSpacing.md)
                            .padding(.vertical, ReachuSpacing.sm)
                            .background(
                                selectedId == option.id
                                    ? ReachuColors.primary.opacity(0.08)
                                    : ReachuColors.surfaceSecondary
                            )
                            .cornerRadius(ReachuBorderRadius.medium)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
    }

    private func applyDiscountCode() {
        let code = discountCode.trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
        guard !code.isEmpty else { return }

        Task {
            if let last = cartManager.lastDiscountCode {
                if last.caseInsensitiveCompare(code) == .orderedSame {
                    _ = await cartManager.discountRemoveApplied(code: last)
                } else {
                    _ = await cartManager.discountRemoveApplied(code: last)
                }
            }

            switch code {

            case "SAVE10", "SAVE20":
                let percent: Double = (code == "SAVE20") ? 0.20 : 0.10
                let percentInt = Int(percent * 100)

                var applied = await cartManager.discountApply(code: code)
                if !applied {
                    _ = await cartManager.discountCreate(
                        code: code,
                        percentage: percentInt
                    )
                    applied = await cartManager.discountApply(code: code)
                }

                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    appliedDiscount = cartManager.cartTotal * percent
                    discountMessage = "\(percentInt)% discount applied!"
                }
                #if os(iOS)
                    UINotificationFeedbackGenerator().notificationOccurred(
                        .success
                    )
                #endif

            case "FREE10", "WELCOME":
                _ = await cartManager.discountApply(code: code)

                let fixed: Double = (code == "WELCOME") ? 15.0 : 10.0
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    appliedDiscount = fixed
                    discountMessage =
                        (code == "WELCOME")
                        ? "Welcome discount applied!" : "$10 off applied!"
                }
                #if os(iOS)
                    UINotificationFeedbackGenerator().notificationOccurred(
                        .success
                    )
                #endif

            default:
                var applied = await cartManager.discountApply(code: code)
                if !applied {
                    _ = await cartManager.discountCreate(
                        code: code,
                        percentage: 10
                    )
                    applied = await cartManager.discountApply(code: code)
                }

                if applied {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        appliedDiscount = cartManager.cartTotal * 0.10
                        discountMessage = "10% discount applied!"
                    }
                    #if os(iOS)
                        UINotificationFeedbackGenerator().notificationOccurred(
                            .success
                        )
                    #endif
                } else {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        appliedDiscount = 0.0
                        discountMessage = "Invalid discount code"
                    }
                    #if os(iOS)
                        UINotificationFeedbackGenerator().notificationOccurred(
                            .error
                        )
                    #endif
                }
            }

            if !discountMessage.isEmpty && appliedDiscount > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        discountMessage = ""
                    }
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
        ("+91", "🇮🇳"), ("+61", "🇦🇺"), ("+64", "🇳🇿"),
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
                Text(
                    countryCodes.first(where: { $0.0 == selectedCode })?.1
                        ?? "🇺🇸"
                )
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
        "India", "Australia", "New Zealand",
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
                Text(
                    selectedCountry.isEmpty ? "Select Country" : selectedCountry
                )
                .font(ReachuTypography.body)
                .foregroundColor(
                    selectedCountry.isEmpty
                        ? ReachuColors.textSecondary : ReachuColors.textPrimary
                )

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
            .environmentObject(
                {
                    let manager = CartManager()
                    Task {
                        await manager.addProduct(
                            MockDataProvider.shared.sampleProducts[0]
                        )
                    }
                    return manager
                }()
            )
            .environmentObject(CheckoutDraft())
    }
#endif

#if os(iOS)
    struct KlarnaNativePaymentSheet: View {
        let initData: InitPaymentKlarnaNativeDto
        let categories: [KlarnaNativePaymentMethodCategoryDto]
        @Binding var selectedCategory: String
        let returnURL: URL
        @Binding var contentHeight: CGFloat
        @Binding var autoAuthorize: Bool
        let onAuthorized: (_ authToken: String, _ finalizeRequired: Bool) -> Void
        let onFailed: (String) -> Void
        let onDismiss: () -> Void

        @State private var triggerAuthorize = false
        @State private var localError: String?
        @State private var hasTriggeredAutoAuthorize = false

        var body: some View {
            VStack(spacing: ReachuSpacing.lg) {
                // Solo mostrar header y selector si NO es auto-authorize
                if !autoAuthorize {
                    HStack {
                        Text("Klarna Checkout")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(ReachuColors.textPrimary)

                        Spacer()

                        Button(role: .cancel) {
                            onDismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(ReachuColors.textSecondary)
                                .imageScale(.large)
                        }
                        .buttonStyle(.plain)
                    }
                }

                if !autoAuthorize && categories.count > 1 {
                    VStack(alignment: .leading, spacing: ReachuSpacing.sm) {
                        Text("Payment method")
                            .font(ReachuTypography.caption1)
                            .foregroundColor(ReachuColors.textSecondary)

                        if categories.count <= 3 {
                            Picker("Payment method", selection: $selectedCategory) {
                                ForEach(categories, id: \.identifier) { category in
                                    Text(
                                        category.name
                                            ?? KlarnaCategoryMapper.displayName(for: category)
                                    )
                                    .tag(
                                        KlarnaCategoryMapper
                                            .normalizedIdentifier(from: category.identifier)
                                    )
                                }
                            }
                            .pickerStyle(.segmented)
                        } else {
                            Picker("Payment method", selection: $selectedCategory) {
                                ForEach(categories, id: \.identifier) { category in
                                    Text(
                                        category.name
                                            ?? KlarnaCategoryMapper.displayName(for: category)
                                    )
                                    .tag(
                                        KlarnaCategoryMapper
                                            .normalizedIdentifier(from: category.identifier)
                                    )
                                }
                            }
                            .pickerStyle(.menu)
                        }
                    }
                } else if !autoAuthorize, let category = categories.first {
                    HStack {
                        Text("Method:")
                            .font(ReachuTypography.caption1)
                            .foregroundColor(ReachuColors.textSecondary)
                        Text(
                            category.name
                                ?? KlarnaCategoryMapper.displayName(for: category)
                        )
                        .font(ReachuTypography.body)
                        .foregroundColor(ReachuColors.textPrimary)
                        Spacer()
                    }
                }

                if selectedCategory.isEmpty {
                    Text("Select a payment method to continue")
                        .font(ReachuTypography.body)
                        .foregroundColor(ReachuColors.textSecondary)
                        .frame(maxWidth: .infinity, minHeight: 200)
                        .background(ReachuColors.surfaceSecondary)
                        .cornerRadius(ReachuBorderRadius.large)
                } else {
                    KlarnaPaymentViewContainer(
                        initData: initData,
                        categoryIdentifier: selectedCategory,
                        returnURL: returnURL,
                        contentHeight: $contentHeight,
                        triggerAuthorize: $triggerAuthorize,
                        onAuthorized: { token, finalizeRequired in
                            localError = nil
                            onAuthorized(token, finalizeRequired)
                        },
                        onFailed: { message in
                            localError = message
                            onFailed(message)
                        }
                    )
                    .frame(maxWidth: .infinity)
                    .frame(height: contentHeight)
                    .clipShape(RoundedRectangle(cornerRadius: ReachuBorderRadius.large))
                    .id(selectedCategory)
                }

                if let localError {
                    Text(localError)
                        .font(ReachuTypography.caption1)
                        .foregroundColor(ReachuColors.error)
                        .multilineTextAlignment(.center)
                        .transition(.opacity)
                }

                // Solo mostrar botones si NO es auto-authorize
                if !autoAuthorize {
                    RButton(
                        title: "Confirm with Klarna",
                        style: .primary,
                        size: .large
                    ) {
                        triggerAuthorize = true
                    }

                    RButton(
                        title: "Cancel",
                        style: .secondary,
                        size: .large
                    ) {
                        onDismiss()
                    }
                }

                Spacer(minLength: ReachuSpacing.md)
            }
            .padding(.horizontal, autoAuthorize ? 0 : ReachuSpacing.lg)
            .padding(.top, autoAuthorize ? 0 : ReachuSpacing.lg)
            .padding(.bottom, autoAuthorize ? 0 : ReachuSpacing.xl)
            .onAppear {
                if categories.first(where: {
                    KlarnaCategoryMapper.normalizedIdentifier(from: $0.identifier)
                        == selectedCategory
                }) == nil {
                    if let first = categories.first {
                        selectedCategory =
                            KlarnaCategoryMapper
                            .normalizedIdentifier(from: first.identifier)
                    }
                }
                
                // Disparar autorización automáticamente si está activado
                if autoAuthorize && !hasTriggeredAutoAuthorize {
                    hasTriggeredAutoAuthorize = true
                    // Dar un pequeño delay para que el KlarnaPaymentView se inicialice
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        triggerAuthorize = true
                    }
                }
            }
            .onChange(of: selectedCategory) { _ in
                if !autoAuthorize {
                    triggerAuthorize = false
                    localError = nil
                    contentHeight = 420
                }
            }
        }
    }

    struct KlarnaPaymentViewContainer: UIViewRepresentable {
        let initData: InitPaymentKlarnaNativeDto
        let categoryIdentifier: String
        let returnURL: URL
        @Binding var contentHeight: CGFloat
        @Binding var triggerAuthorize: Bool
        let onAuthorized: (_ authToken: String, _ finalizeRequired: Bool) -> Void
        let onFailed: (String) -> Void

        func makeCoordinator() -> Coordinator {
            Coordinator(parent: self)
        }

        func makeUIView(context: Context) -> KlarnaPaymentView {
            let paymentView = KlarnaPaymentView(
                category: categoryIdentifier,
                returnUrl: returnURL,
                eventListener: context.coordinator
            )
            paymentView.environment = .playground
            paymentView.region = region(for: initData.purchaseCountry)
            context.coordinator.attach(paymentView, categoryIdentifier: categoryIdentifier)
            paymentView.initialize(clientToken: initData.clientToken, returnUrl: returnURL)
            paymentView.load()
            DispatchQueue.main.async {
                contentHeight = max(paymentView.contentHeight, 400)
            }
            return paymentView
        }

        func updateUIView(_ uiView: KlarnaPaymentView, context: Context) {
            context.coordinator.update(parent: self)
            if triggerAuthorize {
                context.coordinator.authorize(autoFinalize: true)
                DispatchQueue.main.async {
                    triggerAuthorize = false
                }
            }
        }

        private func region(for purchaseCountry: String) -> KlarnaCore.KlarnaRegion {
            switch purchaseCountry.uppercased() {
            case "US", "CA":
                return .na
            case "AU", "NZ":
                return .oc
            default:
                return .eu
            }
        }

        final class Coordinator: NSObject, KlarnaPaymentEventListener {
            private var parent: KlarnaPaymentViewContainer
            weak var paymentView: KlarnaPaymentView?
            private var categoryIdentifier: String

            init(parent: KlarnaPaymentViewContainer) {
                self.parent = parent
                self.categoryIdentifier = parent.categoryIdentifier
            }

            func update(parent: KlarnaPaymentViewContainer) {
                self.parent = parent
                self.categoryIdentifier = parent.categoryIdentifier
            }

            func attach(_ paymentView: KlarnaPaymentView, categoryIdentifier: String) {
                self.paymentView = paymentView
                self.categoryIdentifier = categoryIdentifier
            }

            func authorize(autoFinalize: Bool) {
                paymentView?.authorize(autoFinalize: autoFinalize, jsonData: nil)
            }

            func klarnaInitialized(paymentView: KlarnaPaymentView) {}

            func klarnaLoaded(paymentView: KlarnaPaymentView) {}

            func klarnaLoadedPaymentReview(paymentView: KlarnaPaymentView) {}

            func klarnaAuthorized(
                paymentView: KlarnaPaymentView,
                approved: Bool,
                authToken: String?,
                finalizeRequired: Bool
            ) {
                guard approved, let token = authToken, !token.isEmpty else {
                    DispatchQueue.main.async {
                        self.parent.onFailed("Klarna authorization was declined.")
                    }
                    return
                }
                DispatchQueue.main.async {
                    self.parent.onAuthorized(token, finalizeRequired)
                }
            }

            func klarnaReauthorized(
                paymentView: KlarnaPaymentView,
                approved: Bool,
                authToken: String?
            ) {
                guard approved, let token = authToken, !token.isEmpty else {
                    DispatchQueue.main.async {
                        self.parent.onFailed("Klarna reauthorization failed.")
                    }
                    return
                }
                DispatchQueue.main.async {
                    self.parent.onAuthorized(token, false)
                }
            }

            func klarnaFinalized(
                paymentView: KlarnaPaymentView,
                approved: Bool,
                authToken: String?
            ) {
                guard approved, let token = authToken, !token.isEmpty else { return }
                DispatchQueue.main.async {
                    self.parent.onAuthorized(token, false)
                }
            }

            func klarnaResized(
                paymentView: KlarnaPaymentView,
                to newHeight: CGFloat
            ) {
                DispatchQueue.main.async {
                    self.parent.contentHeight = max(newHeight, 360)
                }
            }

            func klarnaFailed(
                inPaymentView paymentView: KlarnaPaymentView,
                withError error: KlarnaPaymentError
            ) {
                DispatchQueue.main.async {
                    self.parent.onFailed(error.localizedDescription)
                }
            }
        }
    }

    enum KlarnaCategoryMapper {
        static func normalizedIdentifier(from raw: String) -> String {
            switch raw.lowercased() {
            case "pay_now":
                return String.PayNow
            case "pay_later", "klarna":
                return String.PayLater
            case "slice_it":
                return String.SliceIt
            case "pay_over_time":
                return String.PayInParts
            default:
                return raw
            }
        }

        static func preferredIdentifier(from categories: [KlarnaNativePaymentMethodCategoryDto])
            -> String?
        {
            for key in priorityOrder {
                if let match = categories.first(where: { $0.identifier.lowercased() == key }) {
                    return normalizedIdentifier(from: match.identifier)
                }
            }
            return categories.first.map { normalizedIdentifier(from: $0.identifier) }
        }

        static func sorted(_ categories: [KlarnaNativePaymentMethodCategoryDto])
            -> [KlarnaNativePaymentMethodCategoryDto]
        {
            categories.sorted { lhs, rhs in
                priorityIndex(for: lhs.identifier) < priorityIndex(for: rhs.identifier)
            }
        }

        private static let priorityOrder = [
            "pay_now", "klarna", "pay_later", "pay_over_time", "slice_it",
        ]

        private static func priorityIndex(for identifier: String) -> Int {
            let key = identifier.lowercased()
            if let idx = priorityOrder.firstIndex(of: key) { return idx }
            // keep original order for unknown types by placing them after known ones
            return priorityOrder.count
        }

        static func displayName(for category: KlarnaNativePaymentMethodCategoryDto) -> String {
            if let name = category.name, !name.isEmpty { return name }
            return rawDisplayName(from: category.identifier)
        }

        private static func rawDisplayName(from identifier: String) -> String {
            identifier
                .replacingOccurrences(of: "_", with: " ")
                .capitalized
        }
    }
#endif
