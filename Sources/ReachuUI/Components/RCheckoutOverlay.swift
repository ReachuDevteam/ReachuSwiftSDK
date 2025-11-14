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
    @StateObject private var vippsHandler = VippsPaymentHandler.shared
    
    private var adaptiveColors: AdaptiveColors {
        ReachuColors.adaptive(for: colorScheme)
    }
    
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
    @State private var phoneCountryCodeISO: String? = nil
    @State private var address1 = ""
    @State private var address2 = ""
    @State private var city = ""
    @State private var province = ""
    @State private var country = ""
    @State private var zip = ""

    // Payment Information
    @State private var selectedPaymentMethod: PaymentMethod = .stripe
    @State private var availablePaymentMethods: [PaymentMethod] = []
    @State private var acceptsTerms = true
    @State private var acceptsPurchaseConditions = true

    // Discount Code
    @State private var discountCode = ""
    @State private var appliedDiscount: Double = 0.0
    @State private var discountMessage = ""

    // Checkout totals
    @State private var checkoutTotals: GetCheckoutDto?

    // Vipps Payment Tracking
    @State private var vippsPaymentInProgress = false
    @State private var vippsCheckoutId: String?
    @State private var vippsRetryCount = 0
    @State private var vippsMaxRetries = 30 // 5 minutos
    @State private var vippsRetryTimer: Timer?

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
        @State private var klarnaAutoAuthorize = false // To trigger authorization automatically
        @State private var showKlarnaErrorToast = false
        @State private var klarnaErrorMessage = ""
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
        case vipps = "vipps"

        var displayName: String {
            switch self {
            case .stripe: return "Credit Card"
            case .klarna: return "Pay with Klarna"
            case .vipps: return "Vipps"
            }
        }

        var icon: String {
            switch self {
            case .stripe: return "creditcard.fill"
            case .klarna: return "k.square.fill"
            case .vipps: return "v.square.fill"
            }
        }
        
        var imageName: String? {
            switch self {
            case .stripe: return "stripe"
            case .klarna: return "klarna"
            case .vipps: return "vipps"
            }
        }

        var iconColor: Color {
            switch self {
            case .stripe: return .purple
            case .klarna: return Color(hex: "#FFB3C7")
            case .vipps: return Color(hex: "#FF5B24")
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
    
    // Optional user data parameters
    public let userFirstName: String?
    public let userLastName: String?
    public let userEmail: String?
    public let userPhone: String?
    public let userPhoneCountryCode: String?
    public let userAddress1: String?
    public let userAddress2: String?
    public let userCity: String?
    public let userProvince: String?
    public let userCountry: String?
    public let userZip: String?
    
    public init(
        userFirstName: String? = nil,
        userLastName: String? = nil,
        userEmail: String? = nil,
        userPhone: String? = nil,
        userPhoneCountryCode: String? = nil,
        userAddress1: String? = nil,
        userAddress2: String? = nil,
        userCity: String? = nil,
        userProvince: String? = nil,
        userCountry: String? = nil,
        userZip: String? = nil
    ) {
        self.userFirstName = userFirstName
        self.userLastName = userLastName
        self.userEmail = userEmail
        self.userPhone = userPhone
        self.userPhoneCountryCode = userPhoneCountryCode
        self.userAddress1 = userAddress1
        self.userAddress2 = userAddress2
        self.userCity = userCity
        self.userProvince = userProvince
        self.userCountry = userCountry
        self.userZip = userZip
    }

    // MARK: - Main Content
    private var mainContent: some View {
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
            .onChange(of: checkoutStep) { newStep in
                if newStep == .orderSummary {
                    Task {
                        await loadCheckoutTotals()
                    }
                } else if newStep == .success {
                    // Track transaction completed
                    if let checkoutId = cartManager.checkoutId, 
                       let checkoutDto = checkoutTotals,
                       let totals = checkoutDto.totals {
                        let products = cartManager.items.map { item -> [String: Any] in
                            [
                                "product_id": String(item.productId),
                                "product_name": item.title,
                                "quantity": item.quantity,
                                "price": item.price
                            ]
                        }
                        
                        AnalyticsManager.shared.trackTransaction(
                            checkoutId: checkoutId,
                            revenue: totals.total,
                            currency: totals.currencyCode,
                            paymentMethod: selectedPaymentMethod.rawValue,
                            products: products,
                            discount: totals.discounts,
                            shipping: totals.shipping,
                            tax: totals.taxes
                        )
                    }
                    
                    // Reset cart and create new one after successful payment
                    Task {
                        ReachuLogger.debug("Payment successful - resetting cart and creating new one", component: "RCheckoutOverlay")
                        await cartManager.resetCartAndCreateNew()
                    }
                }
            }
            .onChange(of: cartManager.checkoutId) { checkoutId in
                if let checkoutId = checkoutId, checkoutStep == .orderSummary {
                    Task {
                        await loadCheckoutTotals()
                    }
                }
            }
            .navigationTitle(RLocalizedString(ReachuTranslationKey.checkout.rawValue))
            #if os(iOS) || os(tvOS) || os(watchOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if checkoutStep != .success {
                        Button(action: {
                            if cartManager.items.isEmpty || checkoutStep == .address {
                                cartManager.hideCheckout()
                            } else {
                                goToPreviousStep()
                            }
                        }) {
                            Image(systemName: cartManager.items.isEmpty ? "xmark" : "arrow.left")
                                .foregroundColor(ReachuColors.textPrimary)
                                .frame(width: 44, height: 44)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Body
    public var body: some View {
        // Hide if SDK should not be used (market not available) or campaign not active
        if !ReachuConfiguration.shared.shouldUseSDK || !CampaignManager.shared.isCampaignActive {
            EmptyView()
        } else {
            mainContent
            .onAppear {
                ReachuLogger.debug("onAppear triggered", component: "RCheckoutOverlay")
                syncSelectedMarket()
                Task {
                    await loadAvailablePaymentMethods()
                }
            }
            .onChange(of: cartManager.phoneCode) { newValue in
                syncPhoneCode(newValue)
            }
            .onChange(of: cartManager.selectedMarket) { newMarket in
                syncSelectedMarket()
                // When market changes from API, update phone country code ISO
                if let market = newMarket {
                    phoneCountryCodeISO = market.code
                }
            }
            .onChange(of: vippsHandler.paymentStatus) { newStatus in
                handleVippsPaymentStatusChange(newStatus)
            }
            .onDisappear {
                // Clean up timer when view disappears
                stopVippsRetryTimer()
            }
            .overlay {
            if isLoading {
                loadingOverlay
            }
            
            // Vipps Payment in Progress Overlay
            if vippsPaymentInProgress {
                VStack {
                    Spacer()
                    HStack(spacing: 12) {
                        RCustomLoader(style: .rotate, size: 20, color: adaptiveColors.surface, speed: 1.5)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(RLocalizedString(ReachuTranslationKey.processingPayment.rawValue))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(adaptiveColors.surface)
                            
                            Text(RLocalizedString(ReachuTranslationKey.processingPaymentMessage.rawValue))
                                .font(.system(size: 12))
                                .foregroundColor(adaptiveColors.surface.opacity(0.9))
                                .lineLimit(2)
                            
                            if vippsRetryCount > 0 {
                                Text(RLocalizedString(ReachuTranslationKey.verifyingPayment.rawValue) + " (\(vippsRetryCount)/\(vippsMaxRetries))")
                                    .font(.system(size: 10))
                                    .foregroundColor(adaptiveColors.surface.opacity(0.7))
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: ReachuBorderRadius.large)
                            .fill(Color.orange)
                            .reachuCardShadow(for: colorScheme)
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: vippsPaymentInProgress)
            }
            
            // Toast de error de Klarna
            #if os(iOS) && canImport(KlarnaMobileSDK)
            if showKlarnaErrorToast {
                VStack {
                    Spacer()
                    HStack(spacing: 12) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(RLocalizedString(ReachuTranslationKey.paymentFailed.rawValue))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text(klarnaErrorMessage)
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.9))
                                .lineLimit(2)
                        }
                        
                        Spacer()
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.red)
                            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showKlarnaErrorToast)
            }
            #endif
            
            // Invisible overlay for Klarna auto-authorization
            #if os(iOS) && canImport(KlarnaMobileSDK)
            if klarnaAutoAuthorize,
               let initData = klarnaNativeInitData,
               let returnURL = URL(string: klarnaSuccessURLString),
               !klarnaSelectedCategoryIdentifier.isEmpty {
                HiddenKlarnaAutoAuthorize(
                    initData: initData,
                    categoryIdentifier: klarnaSelectedCategoryIdentifier,
                    returnURL: returnURL,
                    onAuthorized: { authToken, finalizeRequired in
                        Task { @MainActor in
                            ReachuLogger.debug("Step 5: Usuario autorizó el pago en Klarna", component: "RCheckoutOverlay")
                            ReachuLogger.debug("AuthToken (primeros 20): \(authToken.prefix(20))...", component: "RCheckoutOverlay")
                            ReachuLogger.debug("FinalizeRequired: \(finalizeRequired)", component: "RCheckoutOverlay")
                            ReachuLogger.debug("Step 6: Llamando a backend para confirmar pago", component: "RCheckoutOverlay")
                            
                            isLoading = true
                            klarnaAutoAuthorize = false
                            
                            // Build input for confirm
                            let customer = KlarnaNativeCustomerInputDto(
                                email: email,
                                phone: phoneCountryCode + phone
                            )
                            
                            let shippingAddress = KlarnaNativeAddressInputDto(
                                givenName: firstName,
                                familyName: lastName,
                                email: email,
                                phone: phoneCountryCode + phone,
                                streetAddress: address1,
                                streetAddress2: address2.isEmpty ? nil : address2,
                                city: city,
                                region: province.isEmpty ? nil : province,
                                postalCode: zip,
                                country: getCountryCode(from: country)
                            )
                            
                            let billingAddress = shippingAddress
                            
                            ReachuLogger.debug("CheckoutId: \(cartManager.checkoutId ?? "nil"), Email: \(email)", component: "RCheckoutOverlay")
                            
                            // Call backend to confirm payment
                            guard let result = await cartManager.confirmKlarnaNative(
                                authorizationToken: authToken,
                                autoCapture: true,
                                customer: customer,
                                billingAddress: billingAddress,
                                shippingAddress: shippingAddress
                            ) else {
                                ReachuLogger.error("Backend no pudo confirmar el pago", component: "RCheckoutOverlay")
                                ReachuLogger.error("Verificar: AuthToken válido, Backend respondió, Klarna API respondió", component: "RCheckoutOverlay")
                                ReachuLogger.error("Setting checkoutStep to .error (Klarna confirm failed)", component: "RCheckoutOverlay")
                                errorMessage = "Failed to confirm Klarna payment"
                                checkoutStep = .error
                                isLoading = false
                                return
                            }
                            
                            ReachuLogger.success("Step 7: PAGO EXITOSO - OrderId: \(result.orderId), FraudStatus: \(result.fraudStatus)", component: "RCheckoutOverlay")
                            
                            klarnaNativeInitData = nil
                            checkoutStep = .success
                            isLoading = false
                        }
                    },
                    onFailed: { message in
                        Task { @MainActor in
                            ReachuLogger.error("Pago falló o fue cancelado - Mensaje: \(message)", component: "RCheckoutOverlay")
                            ReachuLogger.error("Razones posibles: Usuario canceló, Klarna rechazó, Error de red, Token expiró", component: "RCheckoutOverlay")
                            
                            klarnaAutoAuthorize = false
                            klarnaNativeInitData = nil
                            // Return to orderSummary and show toast
                            checkoutStep = .orderSummary
                            klarnaErrorMessage = message.isEmpty ? "Payment was cancelled or failed. Please try again." : message
                            showKlarnaErrorToast = true
                            // Auto-hide toast after 4 seconds
                            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                                showKlarnaErrorToast = false
                            }
                        }
                    }
                )
            }
            #endif
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
                                // Este callback ya no se usa (flujo antiguo con sheet)
                                // El flujo actual usa HiddenKlarnaAutoAuthorize con su propio callback
                                isLoading = false
                                return

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
                                    ReachuLogger.error("Setting checkoutStep to .error (proceedToNext failed)", component: "RCheckoutOverlay")
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
                        ReachuLogger.error("Setting checkoutStep to .error (KlarnaNativePaymentSheet onAppear)", component: "RCheckoutOverlay")
                        showKlarnaNativeSheet = false
                        checkoutStep = .error
                    }
                }
            }
        #endif

        .onAppear {
            loadInitialData()
            syncDraftFromState()
        }
        .onChange(of: draftSyncKey) { _ in
            syncDraftFromState()
        }
        }
    }

    // MARK: - Address Step View
    private var addressStepView: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: ReachuSpacing.xl) {
                    // 1. CART SECTION (Products first)
                    VStack(alignment: .leading, spacing: ReachuSpacing.md) {
                        Text(RLocalizedString(ReachuTranslationKey.cart.rawValue))
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(ReachuColors.textPrimary)
                            .padding(.horizontal, ReachuSpacing.lg)

                        // Individual Products with Quantity
                        individualProductsWithQuantityView
                    }
                    .padding(.top, ReachuSpacing.lg)

                    // 2. SHIPPING ADDRESS SECTION (consistent sizing)
                    VStack(alignment: .leading, spacing: ReachuSpacing.md) {
                        HStack {
                            Text(RLocalizedString(ReachuTranslationKey.shippingAddress.rawValue))
                                .font(.system(size: 17, weight: .bold))
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
                        Text(RLocalizedString(ReachuTranslationKey.orderSummary.rawValue))
                            .font(.system(size: 17, weight: .bold))
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
            VStack(spacing: ReachuSpacing.sm) {
                // Validation message
                if !canProceedToNext {
                    HStack(spacing: 10) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(ReachuColors.primary)
                        
                        Text(validationMessage)
                            .font(.system(size: 13))
                            .foregroundColor(ReachuColors.textSecondary)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: ReachuBorderRadius.medium)
                            .fill(ReachuColors.primary.opacity(0.1))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: ReachuBorderRadius.medium)
                            .stroke(ReachuColors.primary.opacity(0.3), lineWidth: 1)
                    )
                    .padding(.horizontal, ReachuSpacing.lg)
                }
                
                RButton(
                    title: RLocalizedString(ReachuTranslationKey.proceedToCheckout.rawValue),
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
                        
                        // Track checkout started with user identification
                        let cartValue = cartManager.cartTotal
                        let productCount = cartManager.items.count
                        AnalyticsManager.shared.trackCheckoutStarted(
                            checkoutId: chkId,
                            cartValue: cartValue,
                            currency: cartManager.currency,
                            productCount: productCount,
                            userEmail: email.isEmpty ? nil : email,
                            userFirstName: firstName.isEmpty ? nil : firstName,
                            userLastName: lastName.isEmpty ? nil : lastName
                        )

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

                        // Load checkout totals after updating
                        await loadCheckoutTotals()

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
                        Text(RLocalizedString(ReachuTranslationKey.cart.rawValue))
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(ReachuColors.textPrimary)
                            .padding(.horizontal, ReachuSpacing.lg)

                        // Compact readonly products
                        compactReadonlyCartView
                    }

                    // Payment Method Selection
                    VStack(alignment: .leading, spacing: ReachuSpacing.md) {
                        Text(RLocalizedString(ReachuTranslationKey.paymentMethod.rawValue))
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(ReachuColors.textPrimary)

                        VStack(spacing: ReachuSpacing.sm) {
                            ForEach(availablePaymentMethods, id: \.self) { method in
                                PaymentMethodRowCompact(
                                    method: method,
                                    isSelected: selectedPaymentMethod == method
                                ) {
                                    selectedPaymentMethod = method
                                }
                            }
                            
                            if availablePaymentMethods.isEmpty {
                                Text(RLocalizedString(ReachuTranslationKey.noPaymentMethods.rawValue))
                                    .font(ReachuTypography.body)
                                    .foregroundColor(ReachuColors.textSecondary)
                                    .padding()
                            }
                        }
                    }
                    .padding(.horizontal, ReachuSpacing.lg)

                    // Klarna installments Details - REMOVED
                    // No mostrar opciones de cuotas en el checkout
                    // if selectedPaymentMethod == .klarna {
                    //     PaymentScheduleCompact(
                    //         total: finalTotal,
                    //         currency: cartManager.currency
                    //     )
                    //     .padding(.horizontal, ReachuSpacing.lg)
                    // }

                    // Discount Code Section
                    discountCodeSection

                    // Order Summary
                    orderSummarySection

                    Spacer(minLength: 100)
                }
                .padding(.top, ReachuSpacing.lg)
            }

            // Bottom Button - Full Width
            VStack(spacing: ReachuSpacing.sm) {
                // Validation messages
                if !canProceedToNext {
                    HStack(spacing: 10) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(ReachuColors.primary)
                        
                        Text(validationMessage)
                            .font(.system(size: 13))
                            .foregroundColor(ReachuColors.textSecondary)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: ReachuBorderRadius.medium)
                            .fill(ReachuColors.primary.opacity(0.1))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: ReachuBorderRadius.medium)
                            .stroke(ReachuColors.primary.opacity(0.3), lineWidth: 1)
                    )
                    .padding(.horizontal, ReachuSpacing.lg)
                }
                
                RButton(
                    title: RLocalizedString(ReachuTranslationKey.initiatePayment.rawValue),
                    style: .primary,
                    size: .large,
                    isDisabled: !canProceedToNext
                ) {
                    Task { @MainActor in
                        ReachuLogger.debug("Botón 'Initiate Payment' presionado - selectedPaymentMethod: \(selectedPaymentMethod.rawValue)", component: "RCheckoutOverlay")
                        
                        #if os(iOS)
                            ReachuLogger.debug("Platform: iOS detected", component: "RCheckoutOverlay")
                            if selectedPaymentMethod == .stripe {
                                isLoading = true
                                let ok = await prepareStripePaymentSheet()
                                isLoading = false
                                if ok {
                                    shouldPresentStripeSheet = true
                                    presentStripePaymentSheet()
                                    return
                                } else {
                                    ReachuLogger.error("Setting checkoutStep to .error (Stripe prepareStripePaymentSheet failed)", component: "RCheckoutOverlay")
                                    checkoutStep = .error
                                    return
                                }
                            }
                            if selectedPaymentMethod == .klarna {
                                ReachuLogger.debug("Botón 'Initiate Payment' presionado con Klarna seleccionado - Llamando a initiateKlarnaDirectFlow()", component: "RCheckoutOverlay")
                                // Usar flujo directo de Klarna sin UI intermedia
                                await initiateKlarnaDirectFlow()
                                return
                            }
                            if selectedPaymentMethod == .vipps {
                                ReachuLogger.debug("Botón 'Initiate Payment' presionado con Vipps seleccionado - Llamando a initiateVippsFlow()", component: "RCheckoutOverlay")
                                // Usar flujo directo de Vipps
                                await initiateVippsFlow()
                                return
                            }
                        #else
                            ReachuLogger.warning("Platform: NO ES iOS - saltando lógica de pago", component: "RCheckoutOverlay")
                        #endif
                        ReachuLogger.debug("Llamando a proceedToNext()", component: "RCheckoutOverlay")
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
                        Text(RLocalizedString(ReachuTranslationKey.productSummary.rawValue))
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
                                    LoadedImage(
                                        url: URL(string: item.imageUrl ?? ""),
                                        placeholder: AnyView(Rectangle().fill(Color.yellow)),
                                        errorView: AnyView(Rectangle().fill(ReachuColors.surfaceSecondary))
                                    )
                                    .aspectRatio(contentMode: .fill)
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
                                    .foregroundColor(adaptiveColors.priceColor)
                                }

                                // Product details
                                VStack(spacing: ReachuSpacing.xs) {
                                    HStack {
                                    Text(RLocalizedString(ReachuTranslationKey.orderId.rawValue))
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
                                    Text(RLocalizedString(ReachuTranslationKey.colors.rawValue))
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
                                    Text(RLocalizedString(ReachuTranslationKey.quantity.rawValue))
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
                                    Text(RLocalizedString(ReachuTranslationKey.totalForItem.rawValue))
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
                                    .foregroundColor(adaptiveColors.priceColor)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, ReachuSpacing.lg)

                    completeOrderSummaryView

                    // Payment Schedule (if Klarna installments selected)
                    if selectedPaymentMethod == .klarna {
                        VStack(alignment: .leading, spacing: ReachuSpacing.md) {
                            Text(RLocalizedString(ReachuTranslationKey.paymentSchedule.rawValue))
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
                                Text(RLocalizedString(ReachuTranslationKey.reviewOrder.rawValue))
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
                                title: RLocalizedString(ReachuTranslationKey.completePurchase.rawValue),
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
                    Text(RLocalizedString(ReachuTranslationKey.purchaseComplete.rawValue))
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
                            ? RLocalizedString(ReachuTranslationKey.purchaseCompleteMessageKlarna.rawValue)
                            : RLocalizedString(ReachuTranslationKey.purchaseCompleteMessage.rawValue)
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
                    title: RLocalizedString(ReachuTranslationKey.close.rawValue),
                    style: .primary,
                    size: .large
                ) {
                    cartManager.hideCheckout()
                    Task {
                        // Reset cart and create new one after successful payment
                        await cartManager.resetCartAndCreateNew()
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
                    RCustomLoader(style: .rotate, size: 48, color: .white, speed: 1.2)

                    Text("Processing...")
                        .font(ReachuTypography.body)
                        .foregroundColor(.white)
                }
            }
            .ignoresSafeArea()
    }

    // MARK: - Helper Functions

    private var canProceedToNext: Bool {
        // Always check if cart is empty
        guard !cartManager.items.isEmpty else { return false }
        
        switch checkoutStep {
        case .address:
            return !firstName.isEmpty && !lastName.isEmpty && !email.isEmpty
                && !phone.isEmpty
                && !address1.isEmpty && !city.isEmpty && !zip.isEmpty
        case .orderSummary:
            // Validate that all items have shipping method selected
            let allItemsHaveShipping = cartManager.items.allSatisfy { item in
                item.shippingId != nil && !item.shippingId!.isEmpty
            }
            return allItemsHaveShipping
        case .review:
            return true
        case .success, .error:
            return false
        }
    }
    
    private var validationMessage: String {
        // Check cart first
        if cartManager.items.isEmpty {
            return RLocalizedString(ReachuTranslationKey.cartEmptyMessage.rawValue)
        }
        
        switch checkoutStep {
        case .address:
            if firstName.isEmpty || lastName.isEmpty { 
                return RLocalizedString(ReachuTranslationKey.required.rawValue)
            }
            if email.isEmpty { 
                return RLocalizedString(ReachuTranslationKey.invalidEmail.rawValue)
            }
            if phone.isEmpty { 
                return RLocalizedString(ReachuTranslationKey.invalidPhone.rawValue)
            }
            if address1.isEmpty { 
                return RLocalizedString(ReachuTranslationKey.invalidAddress.rawValue)
            }
            if city.isEmpty { 
                return RLocalizedString(ReachuTranslationKey.required.rawValue)
            }
            if zip.isEmpty { 
                return RLocalizedString(ReachuTranslationKey.required.rawValue)
            }
            return RLocalizedString(ReachuTranslationKey.required.rawValue)
        case .orderSummary:
            return RLocalizedString(ReachuTranslationKey.shippingRequired.rawValue)
        default:
            return ""
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
        ReachuLogger.debug("proceedToNext FUNCIÓN LLAMADA - checkoutStep actual: \(checkoutStep), selectedPaymentMethod: \(selectedPaymentMethod.rawValue)", component: "RCheckoutOverlay")
        withAnimation(.easeInOut(duration: 0.3)) {
            switch checkoutStep {
            case .address:
                checkoutStep = .orderSummary
            case .orderSummary:
                // Handle Klarna direct flow
                if selectedPaymentMethod == .klarna {
                    #if os(iOS) && canImport(KlarnaMobileSDK)
                        ReachuLogger.debug("Klarna detectado en orderSummary - Llamando a initiateKlarnaDirectFlow()", component: "RCheckoutOverlay")
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

    private func loadInitialData() {
        let config = ReachuConfiguration.shared
        let isDevelopment = config.environment == .development || config.environment == .sandbox
        
        // Priority: User provided data > Demo data (if development) > Empty
        if let userFirstName = userFirstName, !userFirstName.isEmpty {
            firstName = userFirstName
        } else if isDevelopment {
            firstName = "John"
        }
        
        if let userLastName = userLastName, !userLastName.isEmpty {
            lastName = userLastName
        } else if isDevelopment {
            lastName = "Doe"
        }
        
        if let userEmail = userEmail, !userEmail.isEmpty {
            email = userEmail
        } else if isDevelopment {
            email = "john.doe@example.com"
        }
        
        if let userPhone = userPhone, !userPhone.isEmpty {
            phone = userPhone
        } else if isDevelopment {
            phone = "2125551212"
        }
        
        if let userPhoneCountryCode = userPhoneCountryCode, !userPhoneCountryCode.isEmpty {
            phoneCountryCode = userPhoneCountryCode
            // Try to find the country code from available markets (from API)
            // If multiple countries share the same phone code, prefer the one matching selectedMarket or defaultShippingCountry
            if let selectedMarket = cartManager.selectedMarket, 
               let matchingMarket = ReachuConfiguration.shared.availableMarkets.first(where: { 
                   $0.phoneCode == userPhoneCountryCode && $0.code == selectedMarket.code 
               }) {
                phoneCountryCodeISO = matchingMarket.code
            } else {
                let defaultCountry = ReachuConfiguration.shared.marketConfiguration.countryCode
                if let matchingMarket = ReachuConfiguration.shared.availableMarkets.first(where: { 
                    $0.phoneCode == userPhoneCountryCode && $0.code == defaultCountry 
                }) {
                    phoneCountryCodeISO = matchingMarket.code
                } else if let market = ReachuConfiguration.shared.availableMarkets.first(where: { $0.phoneCode == userPhoneCountryCode }) {
                    phoneCountryCodeISO = market.code
                }
            }
        } else if let market = cartManager.selectedMarket {
            phoneCountryCode = market.phoneCode ?? "+1"
            phoneCountryCodeISO = market.code
        } else {
            // Try to get from availableMarkets (from API) first, then fallback
            let defaultCountry = ReachuConfiguration.shared.marketConfiguration.countryCode
            if let apiMarket = ReachuConfiguration.shared.availableMarkets.first(where: { $0.code == defaultCountry }) {
                phoneCountryCode = apiMarket.phoneCode ?? "+1"
                phoneCountryCodeISO = apiMarket.code
            } else if isDevelopment {
                phoneCountryCode = "+1"
                // Default to CA if available in API markets, otherwise US, otherwise fallback
                if let caMarket = ReachuConfiguration.shared.availableMarkets.first(where: { $0.code == "CA" }) {
                    phoneCountryCodeISO = "CA"
                } else if let usMarket = ReachuConfiguration.shared.availableMarkets.first(where: { $0.code == "US" }) {
                    phoneCountryCodeISO = "US"
                }
            }
        }
        
        if let userAddress1 = userAddress1, !userAddress1.isEmpty {
            address1 = userAddress1
        } else if isDevelopment {
            address1 = "82 Melora Street"
        }
        
        if let userAddress2 = userAddress2, !userAddress2.isEmpty {
            address2 = userAddress2
        }
        
        if let userCity = userCity, !userCity.isEmpty {
            city = userCity
        } else if isDevelopment {
            city = "Westbridge"
        }
        
        if let userProvince = userProvince, !userProvince.isEmpty {
            province = userProvince
        } else if isDevelopment {
            province = "California"
        }
        
        if let userCountry = userCountry, !userCountry.isEmpty {
            country = userCountry
        } else if let market = cartManager.selectedMarket {
            country = market.name
        } else if isDevelopment {
            country = "United States"
        }
        
        if let userZip = userZip, !userZip.isEmpty {
            zip = userZip
        } else if isDevelopment {
            zip = "92841"
        }
        
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

    // MARK: - Variant Helpers

    private func optionDetails(for item: CartManager.CartItem) -> [(name: String, value: String)] {
        guard let variantTitle = item.variantTitle, !variantTitle.isEmpty else {
            return []
        }

        var sortedOptions: [Option] = []
        if let product = cartManager.products.first(where: { $0.id == item.productId }),
           let productOptions = product.options,
           !productOptions.isEmpty {

            sortedOptions = productOptions.sorted { $0.order < $1.order }
            let components = parseVariantTitle(variantTitle)

            var details: [(name: String, value: String)] = []
            for (index, option) in sortedOptions.enumerated() {
                guard index < components.count else { break }
                let value = components[index].trimmingCharacters(in: .whitespacesAndNewlines)
                guard !value.isEmpty else { continue }
                details.append((name: formattedOptionName(option.name), value: value))
            }

            if !details.isEmpty {
                return details
            }
        }

        let components = parseVariantTitle(variantTitle).filter { !$0.isEmpty }

        return components.enumerated().map { index, value in
            let optionName = index < sortedOptions.count ? sortedOptions[index].name : "Option \(index + 1)"
            return (name: optionName, value: value)
        }
    }

    private func parseVariantTitle(_ title: String) -> [String] {
        let dashSeparated = title.components(separatedBy: "-")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if dashSeparated.count > 1 {
            return dashSeparated
        }

        return title
            .components(separatedBy: " - ")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func formattedOptionName(_ name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "Option" }
        return trimmed.prefix(1).uppercased() + trimmed.dropFirst()
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
        
        private func getCountryCode(from countryName: String) -> String {
            // Map common country names to ISO codes
            let mapping: [String: String] = [
                "Norway": "NO",
                "United States": "US",
                "United Kingdom": "GB",
                "Sweden": "SE",
                "Denmark": "DK",
                "Finland": "FI",
                "Germany": "DE",
                "France": "FR",
                "Spain": "ES",
                "Italy": "IT"
            ]
            return mapping[countryName] ?? "NO" // Default to Norway
        }
        
        private func getLocale(for countryCode: String) -> String {
            switch countryCode {
            case "NO": return "nb-NO"
            case "US": return "en-US"
            case "GB": return "en-GB"
            case "SE": return "sv-SE"
            case "DK": return "da-DK"
            case "FI": return "fi-FI"
            case "DE": return "de-DE"
            case "FR": return "fr-FR"
            case "ES": return "es-ES"
            case "IT": return "it-IT"
            default: return "en-US"
            }
        }

        private func initiateKlarnaDirectFlow() async {
            ReachuLogger.debug("Klarna Flow INICIO - Step 1: Preparando datos del checkout", component: "RCheckoutOverlay")
            
            await MainActor.run {
                isLoading = true
                errorMessage = nil
            }

            // Build input data from checkout form
            let customer = KlarnaNativeCustomerInputDto(
                email: email,
                phone: phoneCountryCode + phone
            )
            
            let shippingAddress = KlarnaNativeAddressInputDto(
                givenName: firstName,
                familyName: lastName,
                email: email,
                phone: phoneCountryCode + phone,
                streetAddress: address1,
                streetAddress2: address2.isEmpty ? nil : address2,
                city: city,
                region: province.isEmpty ? nil : province,
                postalCode: zip,
                country: getCountryCode(from: country)
            )
            
            let billingAddress = shippingAddress
            
            let countryCode = getCountryCode(from: country)
            let locale = getLocale(for: countryCode)
            
            ReachuLogger.debug("Datos preparados: Email=\(email), País=\(country)→\(countryCode), Moneda=\(cartManager.currency), Locale=\(locale), CheckoutId=\(cartManager.checkoutId ?? "nil")", component: "RCheckoutOverlay")
            
            let input = KlarnaNativeInitInputDto(
                countryCode: countryCode,
                currency: cartManager.currency,
                locale: locale,
                returnUrl: klarnaSuccessURLString,
                intent: "buy",
                autoCapture: true,
                customer: customer,
                billingAddress: billingAddress,
                shippingAddress: shippingAddress
            )

            ReachuLogger.debug("Step 2: Llamando a backend Reachu (initKlarnaNative)", component: "RCheckoutOverlay")
            
            // Call backend to initialize Klarna session
            guard let dto = await cartManager.initKlarnaNative(input: input) else {
                ReachuLogger.error("initKlarnaNative returned: NIL - Backend retornó nil. Verificar: CheckoutId existe, Backend respondió, Credenciales configuradas", component: "RCheckoutOverlay")
                await MainActor.run {
                    ReachuLogger.error("Setting checkoutStep to .error (initKlarnaNative returned nil)", component: "RCheckoutOverlay")
                    self.isLoading = false
                    self.errorMessage = "Failed to initialize Klarna payment"
                    self.checkoutStep = .error
                }
                return
            }
            
            ReachuLogger.success("Step 3: Backend respondió correctamente - SessionId: \(dto.sessionId), ClientToken: \(dto.clientToken.prefix(20))..., Categorías: \(dto.paymentMethodCategories?.count ?? 0)", component: "RCheckoutOverlay")

            await MainActor.run {
                // Backend already returns the correct DTO structure
                let categories = dto.paymentMethodCategories ?? []
                guard !categories.isEmpty else {
                    ReachuLogger.error("ERROR: No hay métodos de pago disponibles - Setting checkoutStep to .error", component: "RCheckoutOverlay")
                    self.isLoading = false
                    self.errorMessage = "No Klarna payment methods available for this checkout."
                    self.checkoutStep = .error
                    return
                }
                
                ReachuLogger.debug("Métodos de pago disponibles: \(categories.map { "\($0.identifier): \($0.name ?? "sin nombre")" }.joined(separator: ", "))", component: "RCheckoutOverlay")
                
                // Store categories and select first one
                self.klarnaAvailableCategories = categories
                if let firstCategory = categories.first {
                    self.klarnaSelectedCategoryIdentifier = firstCategory.identifier
                    ReachuLogger.debug("Categoría seleccionada: \(firstCategory.identifier)", component: "RCheckoutOverlay")
                }
                
                // Store init data (ya viene del backend correctamente)
                self.klarnaNativeInitData = dto
                self.isLoading = false
                
                ReachuLogger.debug("Step 4: Activando auto-authorize (modal Klarna)", component: "RCheckoutOverlay")
                // Activar auto-authorize flow
                self.klarnaAutoAuthorize = true
            }
        }
    #endif

    private func initiateVippsFlow() async {
        ReachuLogger.debug("Vipps Flow INICIO - Step 1: Preparando datos del checkout", component: "RCheckoutOverlay")
        
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        // Create custom return URLs with checkout tracking
        let checkoutId = cartManager.checkoutId ?? "unknown"
        let successUrlWithTracking = "\(checkoutDraft.successUrl)?checkout_id=\(checkoutId)&payment_method=vipps&status=success"
        let cancelUrlWithTracking = "\(checkoutDraft.cancelUrl)?checkout_id=\(checkoutId)&payment_method=vipps&status=cancelled"
        
        ReachuLogger.debug("Datos preparados: Email=\(email), CheckoutId=\(checkoutId), Success URL=\(successUrlWithTracking), Cancel URL=\(cancelUrlWithTracking)", component: "RCheckoutOverlay")
        
        ReachuLogger.debug("Step 2: Llamando a backend Reachu (vippsInit)", component: "RCheckoutOverlay")
        
        // Call backend to initialize Vipps payment
        guard let dto = await cartManager.vippsInit(
            email: email,
            returnUrl: successUrlWithTracking
        ) else {
                ReachuLogger.error("vippsInit returned: NIL - Backend retornó nil. Verificar: CheckoutId existe, Backend respondió, Credenciales configuradas", component: "RCheckoutOverlay")
                await MainActor.run {
                    ReachuLogger.error("Setting checkoutStep to .error (vippsInit returned nil)", component: "RCheckoutOverlay")
                self.isLoading = false
                self.errorMessage = "Failed to initialize Vipps payment"
                self.checkoutStep = .error
            }
            return
        }
        
        ReachuLogger.success("Step 3: Backend respondió correctamente - Payment URL: \(dto.paymentUrl)", component: "RCheckoutOverlay")
        
        await MainActor.run {
            self.isLoading = false
            
            ReachuLogger.debug("Step 4: Abriendo Vipps en navegador", component: "RCheckoutOverlay")
            // Open Vipps payment URL in browser
            if let url = URL(string: dto.paymentUrl) {
                #if os(iOS)
                UIApplication.shared.open(url)
                #elseif os(macOS)
                NSWorkspace.shared.open(url)
                #endif
                
                // Mark Vipps payment as in progress
                self.vippsPaymentInProgress = true
                self.vippsCheckoutId = checkoutId
                self.vippsRetryCount = 0
                self.vippsHandler.startPaymentTracking(checkoutId: checkoutId)
                
                // Start retry timer for webhook delay
                self.startVippsRetryTimer()
                
                ReachuLogger.success("Vipps abierto en navegador - Payment marked as in progress", component: "RCheckoutOverlay")
            } else {
                ReachuLogger.error("ERROR: URL inválida", component: "RCheckoutOverlay")
                self.errorMessage = "Invalid Vipps payment URL"
                self.checkoutStep = .error
            }
        }
    }

    // MARK: - Vipps Retry System
    private func startVippsRetryTimer() {
        ReachuLogger.debug("Starting retry timer - Max retries: \(vippsMaxRetries)", component: "RCheckoutOverlay")
        
        // Cancel any existing timer
        vippsRetryTimer?.invalidate()
        
        // Start new timer
        vippsRetryTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { _ in
            Task {
                await self.checkVippsPaymentStatusWithRetry()
            }
        }
    }
    
    private func stopVippsRetryTimer() {
        ReachuLogger.debug("Stopping retry timer", component: "RCheckoutOverlay")
        vippsRetryTimer?.invalidate()
        vippsRetryTimer = nil
    }
    
    private func checkVippsPaymentStatusWithRetry() async {
        guard vippsPaymentInProgress, let checkoutId = vippsCheckoutId else {
            stopVippsRetryTimer()
            return
        }
        
        vippsRetryCount += 1
        ReachuLogger.debug("Attempt \(vippsRetryCount)/\(vippsMaxRetries) - Checking status for checkout: \(checkoutId)", component: "RCheckoutOverlay")
        
        // Check checkout status from backend
        if let checkout = await cartManager.getCheckoutById(checkoutId: checkoutId) {
            ReachuLogger.debug("Checkout status: \(checkout.status ?? "unknown")", component: "RCheckoutOverlay")
            
            if checkout.status.uppercased() == "SUCCESS" {
                ReachuLogger.success("Payment successful!", component: "RCheckoutOverlay")
                await MainActor.run {
                    self.stopVippsRetryTimer()
                    self.vippsPaymentInProgress = false
                    self.vippsCheckoutId = nil
                    self.vippsRetryCount = 0
                    self.checkoutStep = .success
                }
                return
            }
            
            // If not SUCCESS and we've reached max retries, show error
            if vippsRetryCount >= vippsMaxRetries {
                ReachuLogger.warning("Max retries reached. Payment not successful.", component: "RCheckoutOverlay")
                await MainActor.run {
                    self.stopVippsRetryTimer()
                    self.vippsPaymentInProgress = false
                    self.vippsCheckoutId = nil
                    self.vippsRetryCount = 0
                    self.errorMessage = "Payment verification failed after multiple attempts. Please check your payment status."
                    self.checkoutStep = .error
                }
                return
            }
            
            // If not SUCCESS but still have retries, continue waiting
            ReachuLogger.debug("Status not SUCCESS yet. Waiting for webhook... (\(vippsRetryCount)/\(vippsMaxRetries))", component: "RCheckoutOverlay")
            
        } else {
            ReachuLogger.error("Could not retrieve checkout status", component: "RCheckoutOverlay")
            
            // If we can't retrieve status and reached max retries, show error
            if vippsRetryCount >= vippsMaxRetries {
                await MainActor.run {
                    self.stopVippsRetryTimer()
                    self.vippsPaymentInProgress = false
                    self.vippsCheckoutId = nil
                    self.vippsRetryCount = 0
                    self.errorMessage = "Could not verify payment status after multiple attempts."
                    self.checkoutStep = .error
                }
            }
        }
    }

    // MARK: - Vipps Payment Status Handler
    private func handleVippsPaymentStatusChange(_ status: VippsPaymentHandler.PaymentStatus) {
        ReachuLogger.debug("Status changed to: \(status)", component: "RCheckoutOverlay")
        
        switch status {
        case .success:
            ReachuLogger.success("Payment successful!", component: "RCheckoutOverlay")
            stopVippsRetryTimer()
            checkoutStep = .success
            vippsPaymentInProgress = false
            vippsCheckoutId = nil
            vippsRetryCount = 0
            
        case .failed, .cancelled:
            ReachuLogger.error("Payment failed or cancelled", component: "RCheckoutOverlay")
            stopVippsRetryTimer()
            errorMessage = status == .failed ? "Payment failed" : "Payment was cancelled"
            checkoutStep = .error
            vippsPaymentInProgress = false
            vippsCheckoutId = nil
            vippsRetryCount = 0
            
        case .inProgress:
            ReachuLogger.debug("Payment in progress", component: "RCheckoutOverlay")
            // Keep current state and retry timer running
            
        case .unknown:
            ReachuLogger.warning("Unknown status", component: "RCheckoutOverlay")
            // Don't change state, let retry timer continue
        }
    }

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
                    ReachuLogger.error("Setting checkoutStep to .error (Stripe payment failed: \(error.localizedDescription))", component: "RCheckoutOverlay")
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
                // Radio button
                ZStack {
                    Circle()
                        .stroke(
                            isSelected ? ReachuColors.primary : ReachuColors.border,
                            lineWidth: 2
                        )
                        .frame(width: 20, height: 20)

                    if isSelected {
                        Circle()
                            .fill(ReachuColors.primary)
                            .frame(width: 12, height: 12)
                    }
                }

                // Payment Method Logo Card
                if let imageName = method.imageName {
                    ZStack {
                        RoundedRectangle(cornerRadius: ReachuBorderRadius.small)
                            .fill(Color.white)

                        #if os(iOS)
                        // Load image from module bundle using UIImage (supports PNG files)
                        if let uiImage = UIImage(named: imageName, in: .module, compatibleWith: nil) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .padding(3)
                        } else if let uiImage = UIImage(named: "PaymentIcons/\(imageName)", in: .module, compatibleWith: nil) {
                            // Try with PaymentIcons/ prefix if direct name fails
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .padding(3)
                        } else {
                            // Fallback to SF Symbol if image not found
                            Image(systemName: method.icon)
                                .font(.system(size: 18))
                                .foregroundColor(method.iconColor)
                                .padding(3)
                        }
                        #else
                        // Fallback to SF Symbol on non-iOS platforms
                        Image(systemName: method.icon)
                            .font(.system(size: 18))
                            .foregroundColor(method.iconColor)
                            .padding(3)
                        #endif
                    }
                    .frame(width: 50, height: 30)
                    .overlay(
                        RoundedRectangle(cornerRadius: ReachuBorderRadius.small)
                            .stroke(ReachuColors.border, lineWidth: 1)
                    )
                } else {
                    // Fallback to SF Symbol
                    Image(systemName: method.icon)
                        .font(.system(size: 18))
                        .foregroundColor(method.iconColor)
                        .frame(width: 50, height: 30)
                }

                // Payment Method Name
                Text(method.displayName)
                    .font(.system(size: 15))
                    .foregroundColor(ReachuColors.textPrimary)

                Spacer()
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: ReachuBorderRadius.medium)
                    .fill(isSelected ? ReachuColors.primary.opacity(0.08) : ReachuColors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: ReachuBorderRadius.medium)
                    .stroke(isSelected ? ReachuColors.primary : ReachuColors.border, lineWidth: isSelected ? 2 : 1)
            )
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
                Text(RLocalizedString(ReachuTranslationKey.phoneColon.rawValue))
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
                    Text(RLocalizedString(ReachuTranslationKey.firstName.rawValue))
                        .font(ReachuTypography.caption1)
                        .foregroundColor(ReachuColors.textSecondary)
                    TextField("John", text: $firstName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .overlay(
                            RoundedRectangle(cornerRadius: ReachuBorderRadius.small)
                                .stroke(firstName.isEmpty ? ReachuColors.primary.opacity(0.4) : Color.clear, lineWidth: 2)
                        )
                }

                VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
                    Text(RLocalizedString(ReachuTranslationKey.lastName.rawValue))
                        .font(ReachuTypography.caption1)
                        .foregroundColor(ReachuColors.textSecondary)
                    TextField("Doe", text: $lastName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .overlay(
                            RoundedRectangle(cornerRadius: ReachuBorderRadius.small)
                                .stroke(lastName.isEmpty ? ReachuColors.primary.opacity(0.4) : Color.clear, lineWidth: 2)
                        )
                }
            }

            // Email
            VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
                Text(RLocalizedString(ReachuTranslationKey.email.rawValue))
                    .font(ReachuTypography.caption1)
                    .foregroundColor(ReachuColors.textSecondary)
                TextField("your@email.com", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .overlay(
                        RoundedRectangle(cornerRadius: ReachuBorderRadius.small)
                            .stroke(email.isEmpty ? ReachuColors.primary.opacity(0.4) : Color.clear, lineWidth: 2)
                    )
                    #if os(iOS) || os(tvOS) || os(watchOS)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    #endif
            }

            // Phone with country code
            VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
                Text(RLocalizedString(ReachuTranslationKey.phone.rawValue))
                    .font(ReachuTypography.caption1)
                    .foregroundColor(ReachuColors.textSecondary)

                HStack(spacing: ReachuSpacing.sm) {
                    CountryCodePicker(
                        selectedCode: $phoneCountryCode,
                        selectedCountryCode: $phoneCountryCodeISO,
                        availableMarkets: ReachuConfiguration.shared.availableMarkets
                    )
                        .frame(width: 100)

                    TextField("555 123 4456", text: $phone)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .overlay(
                            RoundedRectangle(cornerRadius: ReachuBorderRadius.small)
                                .stroke(phone.isEmpty ? ReachuColors.primary.opacity(0.4) : Color.clear, lineWidth: 2)
                        )
                }
            }

            // Address
            VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
                Text(RLocalizedString(ReachuTranslationKey.address.rawValue))
                    .font(ReachuTypography.caption1)
                    .foregroundColor(ReachuColors.textSecondary)
                TextField("Street address", text: $address1)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .overlay(
                        RoundedRectangle(cornerRadius: ReachuBorderRadius.small)
                            .stroke(address1.isEmpty ? ReachuColors.primary.opacity(0.4) : Color.clear, lineWidth: 2)
                    )
                TextField("Apt, suite, etc. (optional)", text: $address2)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }

            // City, State, ZIP
            HStack(spacing: ReachuSpacing.md) {
                VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
                    Text(RLocalizedString(ReachuTranslationKey.city.rawValue))
                        .font(ReachuTypography.caption1)
                        .foregroundColor(ReachuColors.textSecondary)
                    TextField("City", text: $city)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .overlay(
                            RoundedRectangle(cornerRadius: ReachuBorderRadius.small)
                                .stroke(city.isEmpty ? ReachuColors.primary.opacity(0.4) : Color.clear, lineWidth: 2)
                        )
                }

                VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
                    Text("State")
                        .font(ReachuTypography.caption1)
                        .foregroundColor(ReachuColors.textSecondary)
                    TextField("State", text: $province)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }

                VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
                    Text(RLocalizedString(ReachuTranslationKey.zip.rawValue))
                        .font(ReachuTypography.caption1)
                        .foregroundColor(ReachuColors.textSecondary)
                    TextField("ZIP", text: $zip)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .overlay(
                            RoundedRectangle(cornerRadius: ReachuBorderRadius.small)
                                .stroke(zip.isEmpty ? ReachuColors.primary.opacity(0.4) : Color.clear, lineWidth: 2)
                        )
                        #if os(iOS) || os(tvOS) || os(watchOS)
                            .keyboardType(.numberPad)
                        #endif
                }
            }

            // Country
            VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
                Text(RLocalizedString(ReachuTranslationKey.country.rawValue))
                    .font(ReachuTypography.caption1)
                    .foregroundColor(ReachuColors.textSecondary)
                CountryPicker(
                    selectedCountry: $country,
                    availableMarkets: ReachuConfiguration.shared.availableMarkets
                )
            }
        }
        .padding(.horizontal, ReachuSpacing.lg)
    }

    // Individual products with quantity controls for address step (like the image)
    private var individualProductsWithQuantityView: some View {
        VStack(spacing: ReachuSpacing.xl) {
            if cartManager.items.isEmpty {
                VStack(spacing: ReachuSpacing.md) {
                    Image(systemName: "cart")
                        .font(.system(size: 48))
                        .foregroundColor(ReachuColors.textSecondary.opacity(0.5))
                    
                    Text(RLocalizedString(ReachuTranslationKey.cartEmpty.rawValue))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(ReachuColors.textPrimary)
                    
                    Text("Add products to continue with checkout")
                        .font(.system(size: 14))
                        .foregroundColor(ReachuColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            }
            
            ForEach(cartManager.items, id: \.id) { item in
                VStack(spacing: ReachuSpacing.md) {
                    // Product header with image and details
                    HStack(spacing: ReachuSpacing.md) {
                        // Product image
                        LoadedImage(
                            url: URL(string: item.imageUrl ?? ""),
                            placeholder: AnyView(RCustomLoader(style: .rotate, size: 30)),
                            errorView: AnyView(Rectangle().fill(ReachuColors.surfaceSecondary))
                        )
                        .aspectRatio(contentMode: .fill)
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
                                    Task {
                                        if item.quantity > 1 {
                                            await cartManager.updateQuantity(
                                                for: item,
                                                to: item.quantity - 1
                                            )
                                        } else {
                                            // Remove item when quantity is 1
                                            await cartManager.removeItem(item)
                                        }
                                    }
                                }) {
                                    Image(systemName: item.quantity == 1 ? "trash" : "minus")
                                        .font(
                                            .system(size: 14, weight: .medium)
                                        )
                                        .foregroundColor(
                                            item.quantity == 1 ? ReachuColors.error : ReachuColors.textPrimary
                                        )
                                        .frame(width: 28, height: 28)
                                        .background(
                                            ReachuColors.surfaceSecondary
                                        )
                                        .cornerRadius(4)
                                }

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
                        .foregroundColor(adaptiveColors.priceColor)
                    }

                    // Product details
                    let optionDetailsList = optionDetails(for: item)
                    if !optionDetailsList.isEmpty {
                        VStack(spacing: ReachuSpacing.xs) {
                            ForEach(Array(optionDetailsList.enumerated()), id: \.offset) { _, detail in
                                HStack {
                                    Text("\(detail.name):")
                                        .font(.system(size: 14, weight: .regular))
                                        .foregroundColor(ReachuColors.textSecondary)

                                    Spacer()

                                    Text(detail.value)
                                        .font(.system(size: 14, weight: .regular))
                                        .foregroundColor(ReachuColors.textSecondary)
                                }
                            }
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
                        .foregroundColor(adaptiveColors.priceColor)
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
                    LoadedImage(
                        url: URL(string: item.imageUrl ?? ""),
                        placeholder: AnyView(RoundedRectangle(cornerRadius: ReachuBorderRadius.large)
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
                            }),
                        errorView: AnyView(RoundedRectangle(cornerRadius: ReachuBorderRadius.large)
                            .fill(ReachuColors.surfaceSecondary)
                            .overlay {
                                Image(systemName: "photo")
                                    .font(.title2)
                                    .foregroundColor(ReachuColors.textSecondary.opacity(0.6))
                            })
                    )
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 90, height: 90)
                    .clipped()

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
                    .foregroundColor(adaptiveColors.priceColor)

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
                // Subtotal - from checkout
                HStack {
                    Text("Subtotal")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(ReachuColors.textSecondary)

                    Spacer()

                    Text(
                        "\(cartManager.currency) \(String(format: "%.2f", checkoutSubtotal))"
                    )
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(ReachuColors.textPrimary)
                }

                // Shipping - from checkout
                HStack {
                    Text(RLocalizedString(ReachuTranslationKey.shipping.rawValue))
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(ReachuColors.textSecondary)

                    Spacer()

                    Text(shippingAmountText)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(ReachuColors.textPrimary)
                }

                // Show discount if applied - from checkout
                if checkoutDiscount > 0 {
                    HStack {
                        Text(RLocalizedString(ReachuTranslationKey.discount.rawValue))
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(ReachuColors.success)

                        Spacer()

                        Text(
                            "-\(cartManager.currency) \(String(format: "%.2f", checkoutDiscount))"
                        )
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(ReachuColors.success)
                    }
                }

                // Tax - from checkout
                HStack {
                    Text("Tax")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(ReachuColors.textSecondary)

                    Spacer()

                    Text("\(cartManager.currency) \(String(format: "%.2f", taxAmount))")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(ReachuColors.textPrimary)
                }

                // Divider
                Rectangle()
                    .fill(ReachuColors.border)
                    .frame(height: 1)

                // Total - from checkout
                HStack {
                    Text("Total")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(ReachuColors.textPrimary)

                    Spacer()

                    Text(
                        "\(cartManager.currency) \(String(format: "%.2f", checkoutTotal))"
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
                    Text(RLocalizedString(ReachuTranslationKey.shippingCalculated.rawValue))
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
        let hasItemsWithoutShipping = cartManager.items.contains { $0.shippingId == nil || $0.shippingId!.isEmpty }
        
        return VStack(alignment: .leading, spacing: ReachuSpacing.md) {
            if cartManager.items.contains(where: { !$0.availableShippings.isEmpty }) {
                HStack(spacing: 8) {
                    Text(RLocalizedString(ReachuTranslationKey.shippingOptions.rawValue))
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(ReachuColors.textPrimary)
                    
                    if hasItemsWithoutShipping {
                        Text(RLocalizedString(ReachuTranslationKey.shippingRequired.rawValue))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(ReachuColors.primary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(ReachuColors.primary.opacity(0.15))
                            )
                    }
                }
                .padding(.horizontal, ReachuSpacing.lg)

                VStack(spacing: ReachuSpacing.md) {
                    ForEach(cartManager.items) { item in
                        if !item.availableShippings.isEmpty {
                            let itemNeedsShipping = item.shippingId == nil || item.shippingId!.isEmpty
                            ItemShippingOptionsView(
                                item: item,
                                onSelect: { option in
                                    cartManager.setShippingOption(for: item.id, optionId: option.id)
                                }
                            )
                            .padding(itemNeedsShipping ? 8 : 0)
                            .background(
                                RoundedRectangle(cornerRadius: ReachuBorderRadius.medium)
                                    .fill(itemNeedsShipping ? ReachuColors.primary.opacity(0.05) : Color.clear)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: ReachuBorderRadius.medium)
                                    .stroke(ReachuColors.primary.opacity(itemNeedsShipping ? 0.4 : 0), lineWidth: 2)
                            )
                        }
                    }
                }
                .padding(.horizontal, ReachuSpacing.lg)
            } else {
                Text(RLocalizedString(ReachuTranslationKey.noShippingMethods.rawValue))
                    .font(.system(size: 12))
                    .foregroundColor(ReachuColors.textSecondary)
                    .padding(.horizontal, ReachuSpacing.lg)
            }
        }
    }

    // Order summary for address step (with shipping)
    // Note: This is shown before checkout is created, so we use cart values
    private var addressOrderSummaryView: some View {
        VStack(spacing: ReachuSpacing.sm) {
            // Subtotal
            HStack {
                Text(RLocalizedString(ReachuTranslationKey.subtotal.rawValue))
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(ReachuColors.textSecondary)

                Spacer()

                Text(
                    "\(cartManager.currency) \(String(format: "%.2f", checkoutSubtotal))"
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
                Text(RLocalizedString(ReachuTranslationKey.total.rawValue))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(ReachuColors.textPrimary)

                Spacer()

                Text(
                    "\(cartManager.currency) \(String(format: "%.2f", checkoutTotal))"
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
            if cartManager.items.isEmpty {
                VStack(spacing: ReachuSpacing.md) {
                    Image(systemName: "cart")
                        .font(.system(size: 40))
                        .foregroundColor(ReachuColors.textSecondary.opacity(0.5))
                    
                    Text(RLocalizedString(ReachuTranslationKey.cartEmpty.rawValue))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(ReachuColors.textPrimary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            }
            
            ForEach(cartManager.items) { item in
                HStack(spacing: ReachuSpacing.sm) {
                    // Small product image
                    LoadedImage(
                        url: URL(string: item.imageUrl ?? ""),
                        placeholder: AnyView(Rectangle().fill(Color.yellow)),
                        errorView: AnyView(Rectangle().fill(ReachuColors.surfaceSecondary))
                    )
                    .aspectRatio(contentMode: .fill)
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
                    .foregroundColor(adaptiveColors.priceColor)
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

            // Order Summary Section - All values from checkout
            VStack(spacing: ReachuSpacing.md) {
                // Subtotal - from checkout
                HStack {
                    Text("Subtotal")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(ReachuColors.textSecondary)

                    Spacer()

                    Text(
                        "\(cartManager.currency) \(String(format: "%.2f", checkoutSubtotal))"
                    )
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(ReachuColors.textPrimary)
                }

                // Shipping - from checkout
                HStack {
                    Text(RLocalizedString(ReachuTranslationKey.shipping.rawValue))
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(ReachuColors.textSecondary)

                    Spacer()

                    Text(shippingAmountText)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(ReachuColors.textPrimary)
                }

                // Discount (if applied) - from checkout
                if checkoutDiscount > 0 {
                    HStack {
                        Text(RLocalizedString(ReachuTranslationKey.discount.rawValue))
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(ReachuColors.success)

                        Spacer()

                        Text(
                            "-\(cartManager.currency) \(String(format: "%.2f", checkoutDiscount))"
                        )
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(ReachuColors.success)
                    }
                }

                // Tax - from checkout
                HStack {
                    Text("Tax")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(ReachuColors.textSecondary)

                    Spacer()

                    Text("\(cartManager.currency) \(String(format: "%.2f", taxAmount))")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(ReachuColors.textPrimary)
                }

                // Divider
                Rectangle()
                    .fill(ReachuColors.border)
                    .frame(height: 1)

                // Total - from checkout
                HStack {
                    Text("Total")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(ReachuColors.textPrimary)

                    Spacer()

                    Text(
                        "\(cartManager.currency) \(String(format: "%.2f", checkoutTotal))"
                    )
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(ReachuColors.primary)
                }
            }
            .padding(.horizontal, ReachuSpacing.lg)
        }
    }

    // MARK: - Helper Functions

    // Use checkout totals directly when available, otherwise fall back to cart manager
    private var checkoutSubtotal: Double {
        if let subtotal = checkoutTotals?.totals?.subtotal {
            return subtotal
        }
        return cartManager.cartTotal
    }
    
    private var shippingAmount: Double {
        if let checkoutShipping = checkoutTotals?.totals?.shipping {
            return checkoutShipping
        }
        return cartManager.shippingTotal
    }
    
    private var taxAmount: Double {
        if let checkoutTaxes = checkoutTotals?.totals?.taxes {
            return checkoutTaxes
        }
        return 0.0
    }
    
    private var checkoutDiscount: Double {
        if let discount = checkoutTotals?.totals?.discounts {
            return discount
        }
        return appliedDiscount
    }
    
    private var checkoutTotal: Double {
        if let total = checkoutTotals?.totals?.total {
            return total
        }
        // Fallback calculation only if checkout totals not available
        return checkoutSubtotal + shippingAmount + taxAmount - checkoutDiscount
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
        return checkoutTotal
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
            syncPhoneCode(market.phoneCode ?? "+1")
            phoneCountryCodeISO = market.code
            checkoutDraft.countryName = market.name
            checkoutDraft.countryCode = market.code
        }
    }

    private func syncPhoneCode(_ code: String) {
        phoneCountryCode = code
        checkoutDraft.phoneCountryCode = code.replacingOccurrences(of: "+", with: "")
        
        // If we have a selected country code ISO, keep it
        // Otherwise, try to find it from available markets (from API)
        // If multiple countries share the same phone code, prefer the one matching selectedMarket or defaultShippingCountry
        if phoneCountryCodeISO == nil {
            if let selectedMarket = cartManager.selectedMarket,
               let matchingMarket = ReachuConfiguration.shared.availableMarkets.first(where: { 
                   $0.phoneCode == code && $0.code == selectedMarket.code 
               }) {
                phoneCountryCodeISO = matchingMarket.code
            } else {
                let defaultCountry = ReachuConfiguration.shared.marketConfiguration.countryCode
                if let matchingMarket = ReachuConfiguration.shared.availableMarkets.first(where: { 
                    $0.phoneCode == code && $0.code == defaultCountry 
                }) {
                    phoneCountryCodeISO = matchingMarket.code
                } else if let market = ReachuConfiguration.shared.availableMarkets.first(where: { $0.phoneCode == code }) {
                    phoneCountryCodeISO = market.code
                }
            }
        }
    }
    
    private func loadCheckoutTotals() async {
        guard let checkoutId = cartManager.checkoutId else {
            ReachuLogger.debug("No checkoutId available to load totals", component: "RCheckoutOverlay")
            return
        }
        
        ReachuLogger.debug("Loading checkout totals for checkoutId: \(checkoutId)", component: "RCheckoutOverlay")
        
        if let checkout = await cartManager.getCheckoutById(checkoutId: checkoutId) {
            await MainActor.run {
                checkoutTotals = checkout
                ReachuLogger.debug("Checkout totals loaded - shipping: \(checkout.totals?.shipping ?? 0), taxes: \(checkout.totals?.taxes ?? 0)", component: "RCheckoutOverlay")
            }
        } else {
            ReachuLogger.debug("Failed to load checkout totals", component: "RCheckoutOverlay")
        }
    }
    
    private func loadAvailablePaymentMethods() async {
        ReachuLogger.debug("Loading available payment methods...", component: "RCheckoutOverlay")
        
        // 1. Get supported methods from config
        let configMethods = ReachuConfiguration.shared.cartConfiguration.supportedPaymentMethods
        ReachuLogger.debug("Config supported methods: \(configMethods)", component: "RCheckoutOverlay")
        
        // 2. Create SDK client to fetch available methods from Reachu API
        let config = ReachuConfiguration.shared
        guard let baseURL = URL(string: config.environment.graphQLURL) else {
            ReachuLogger.error("Invalid GraphQL URL", component: "RCheckoutOverlay")
            await setFallbackPaymentMethods(configMethods)
            return
        }
        
        let sdk = SdkClient(baseUrl: baseURL, apiKey: config.apiKey)
        
        // 3. Fetch available methods from Reachu API (API is the source of truth)
        do {
            let apiMethods = try await sdk.payment.getAvailableMethods()
            ReachuLogger.info("API returned \(apiMethods.count) payment methods", component: "RCheckoutOverlay")
            
            // Use whatever the API returns (API is the authority)
            var available: [PaymentMethod] = []
            
            for apiMethod in apiMethods {
                let methodName = apiMethod.name.lowercased()
                ReachuLogger.debug("API method: \(apiMethod.name) (normalized: \(methodName))", component: "RCheckoutOverlay")
                
                // Try to map API method to PaymentMethod enum
                if let paymentMethod = PaymentMethod(rawValue: methodName) {
                    available.append(paymentMethod)
                    ReachuLogger.debug("Added: \(methodName)", component: "RCheckoutOverlay")
                } else {
                    ReachuLogger.warning("Unknown payment method (no enum case): \(methodName)", component: "RCheckoutOverlay")
                }
            }
            
            await MainActor.run {
                self.availablePaymentMethods = available
                
                // Auto-select first available method
                if let first = available.first {
                    self.selectedPaymentMethod = first
                    ReachuLogger.debug("Auto-selected: \(first.rawValue)", component: "RCheckoutOverlay")
                }
                
                ReachuLogger.debug("Final available methods: \(available.map { $0.rawValue })", component: "RCheckoutOverlay")
            }
            
        } catch {
            ReachuLogger.error("Failed to fetch payment methods: \(error)", component: "RCheckoutOverlay")
            await setFallbackPaymentMethods(configMethods)
        }
    }
    
    private func setFallbackPaymentMethods(_ configMethods: [String]) async {
        await MainActor.run {
            let fallbackMethods = configMethods.compactMap { PaymentMethod(rawValue: $0.lowercased()) }
            self.availablePaymentMethods = fallbackMethods
            
            if let first = fallbackMethods.first {
                self.selectedPaymentMethod = first
            }
            
            ReachuLogger.debug("Using config fallback: \(fallbackMethods.map { $0.rawValue })", component: "RCheckoutOverlay")
        }
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
    @Binding var selectedCountryCode: String?
    let availableMarkets: [GetAvailableMarketsDto]
    
    // Fallback list if no markets available - includes both CA and US with +1
    private let fallbackCountryCodes: [(String, String, String, String?)] = [
        ("+1", "🇨🇦", "CA", nil), ("+1", "🇺🇸", "US", nil), ("+44", "🇬🇧", "GB", nil), ("+49", "🇩🇪", "DE", nil), ("+33", "🇫🇷", "FR", nil),
        ("+39", "🇮🇹", "IT", nil), ("+34", "🇪🇸", "ES", nil), ("+31", "🇳🇱", "NL", nil), ("+46", "🇸🇪", "SE", nil),
        ("+47", "🇳🇴", "NO", nil), ("+45", "🇩🇰", "DK", nil), ("+41", "🇨🇭", "CH", nil), ("+43", "🇦🇹", "AT", nil),
        ("+32", "🇧🇪", "BE", nil), ("+351", "🇵🇹", "PT", nil), ("+52", "🇲🇽", "MX", nil), ("+54", "🇦🇷", "AR", nil),
        ("+55", "🇧🇷", "BR", nil), ("+86", "🇨🇳", "CN", nil), ("+81", "🇯🇵", "JP", nil), ("+82", "🇰🇷", "KR", nil),
        ("+91", "🇮🇳", "IN", nil), ("+61", "🇦🇺", "AU", nil), ("+64", "🇳🇿", "NZ", nil),
    ]
    
    private var countryCodes: [(String, String, String, String?)] {
        if availableMarkets.isEmpty {
            return fallbackCountryCodes
        }
        
        // Build list from available markets - keep all countries even if they share phone code
        return availableMarkets.compactMap { market in
            guard let code = market.phoneCode,
                  let countryCode = market.code else {
                return nil
            }
            
            let flag = market.flag ?? "🌍"
            let name = market.name ?? countryCode
            // Check if flag is a URL
            let flagURL = flag.hasPrefix("http") ? flag : nil
            let flagEmoji = flagURL == nil ? flag : "🌍"
            return (code, flagEmoji, countryCode, flagURL)
        }.sorted { first, second in
            // Sort by phone code first, then by country code
            if first.0 != second.0 {
                return first.0 < second.0
            }
            return first.2 < second.2
        }
    }
    
    private var currentSelection: (String, String, String, String?)? {
        // If we have a specific countryCode selected, use that to find the exact match
        if let countryCode = selectedCountryCode {
            return countryCodes.first(where: { $0.2 == countryCode && $0.0 == selectedCode })
        }
        // Otherwise, find first match by phone code
        return countryCodes.first(where: { $0.0 == selectedCode })
    }

    var body: some View {
        Menu {
            ForEach(countryCodes, id: \.2) { code, flagEmoji, countryCode, flagURL in
                Button(action: { 
                    selectedCode = code
                    selectedCountryCode = countryCode
                }) {
                    HStack {
                        // Show image from URL or emoji
                        if let flagURL = flagURL, let url = URL(string: flagURL) {
                            #if os(iOS)
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 20, height: 14)
                                case .failure(_), .empty:
                                    Text(flagEmoji)
                                        .font(.system(size: 16))
                                @unknown default:
                                    Text(flagEmoji)
                                        .font(.system(size: 16))
                                }
                            }
                            #else
                            Text(flagEmoji)
                                .font(.system(size: 16))
                            #endif
                        } else {
                            Text(flagEmoji)
                                .font(.system(size: 16))
                        }
                        // Show country name or code
                        if let market = availableMarkets.first(where: { $0.code == countryCode }) {
                            Text(market.name ?? countryCode)
                                .font(.system(size: 14))
                        } else {
                            Text(countryCode)
                                .font(.system(size: 14))
                        }
                        Text(code)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(ReachuColors.textSecondary)
                        Spacer()
                        if selectedCode == code && selectedCountryCode == countryCode {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(ReachuColors.primary)
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                // Show current selection flag (URL or emoji)
                if let selection = currentSelection, let flagURL = selection.3, let url = URL(string: flagURL) {
                    #if os(iOS)
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 16, height: 12)
                        case .failure(_), .empty:
                            Text(selection.1)
                                .font(.system(size: 16))
                        @unknown default:
                            Text(selection.1)
                                .font(.system(size: 16))
                        }
                    }
                    #else
                    Text(selection.1)
                        .font(.system(size: 16))
                    #endif
                } else {
                    Text(currentSelection?.1 ?? "🌍")
                        .font(.system(size: 16))
                }
                
                Text(selectedCode.isEmpty ? "+1" : selectedCode)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(ReachuColors.textPrimary)
                
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 12))
                    .foregroundColor(ReachuColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(ReachuColors.surfaceSecondary)
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: ReachuBorderRadius.small)
                    .stroke(ReachuColors.border, lineWidth: 1)
            )
        }
    }
}

struct CountryPicker: View {
    @Binding var selectedCountry: String
    let availableMarkets: [GetAvailableMarketsDto]
    
    // Fallback list if no markets available
    private let fallbackCountries = [
        "United States", "Canada", "United Kingdom", "Germany", "France",
        "Italy", "Spain", "Netherlands", "Sweden", "Norway", "Denmark",
        "Switzerland", "Austria", "Belgium", "Portugal", "Mexico",
        "Argentina", "Brazil", "China", "Japan", "South Korea",
        "India", "Australia", "New Zealand",
    ]
    
    private var countries: [String] {
        if availableMarkets.isEmpty {
            return fallbackCountries
        }
        
        // Build list from available markets
        return availableMarkets.compactMap { market in
            market.name
        }.sorted()
    }

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
                    ZStack {
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
                        .opacity(autoAuthorize && !triggerAuthorize ? 0 : 1) // Ocultar mientras inicializa
                        
                        // Mostrar loading mientras se inicializa en modo auto
                        if autoAuthorize && !triggerAuthorize {
                            VStack(spacing: ReachuSpacing.md) {
                                RCustomLoader(style: .rotate, size: 48, speed: 1.2)
                                Text("Conectando con Klarna...")
                                    .font(ReachuTypography.body)
                                    .foregroundColor(ReachuColors.textSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                        }
                    }
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
                
                // Trigger authorization automatically if enabled
                if autoAuthorize && !hasTriggeredAutoAuthorize {
                    hasTriggeredAutoAuthorize = true
                    // Give a VERY short delay for KlarnaPaymentView to initialize
                    // but trigger authorize() before its UI renders
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
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

    // MARK: - Hidden Klarna Auto-Authorize
    /// Invisible component that creates a KlarnaPaymentView and calls authorize() automatically
    struct HiddenKlarnaAutoAuthorize: UIViewRepresentable {
        let initData: InitPaymentKlarnaNativeDto
        let categoryIdentifier: String
        let returnURL: URL
        let onAuthorized: (_ authToken: String, _ finalizeRequired: Bool) -> Void
        let onFailed: (String) -> Void
        
        func makeCoordinator() -> Coordinator {
            Coordinator(parent: self)
        }
        
        func makeUIView(context: Context) -> UIView {
            let containerView = UIView()
            containerView.isHidden = true // Completamente invisible
            containerView.frame = .zero
            
            let paymentView = KlarnaPaymentView(
                category: categoryIdentifier,
                returnUrl: returnURL,
                eventListener: context.coordinator
            )
            paymentView.environment = .production
            paymentView.region = .eu // Europa para Noruega
            paymentView.frame = .zero
            paymentView.isHidden = true
            
            context.coordinator.paymentView = paymentView
            containerView.addSubview(paymentView)
            
            // Initialize and authorize immediately
            paymentView.initialize(clientToken: initData.clientToken, returnUrl: returnURL)
            
            // Wait a minimum moment and authorize
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                paymentView.authorize(autoFinalize: true, jsonData: nil)
            }
            
            return containerView
        }
        
        func updateUIView(_ uiView: UIView, context: Context) {
            // No updates needed
        }
        
        class Coordinator: NSObject, KlarnaPaymentEventListener {
            let parent: HiddenKlarnaAutoAuthorize
            var paymentView: KlarnaPaymentView?
            
            init(parent: HiddenKlarnaAutoAuthorize) {
                self.parent = parent
            }
            
            func klarnaInitialized(paymentView: KlarnaPaymentView) {
                ReachuLogger.debug("Initialized", component: "RCheckoutOverlay")
            }
            
            func klarnaLoaded(paymentView: KlarnaPaymentView) {
                ReachuLogger.debug("Loaded", component: "RCheckoutOverlay")
            }
            
            func klarnaLoadedPaymentReview(paymentView: KlarnaPaymentView) {
                ReachuLogger.debug("Loaded payment review", component: "RCheckoutOverlay")
            }
            
            func klarnaAuthorized(
                paymentView: KlarnaPaymentView,
                approved: Bool,
                authToken: String?,
                finalizeRequired: Bool
            ) {
                ReachuLogger.debug("Authorized - approved: \(approved), token: \(authToken != nil)", component: "RCheckoutOverlay")
                guard approved, let token = authToken, !token.isEmpty else {
                    DispatchQueue.main.async {
                        self.parent.onFailed("Authorization not approved")
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
                ReachuLogger.debug("Reauthorized", component: "RCheckoutOverlay")
            }
            
            func klarnaFinalized(
                paymentView: KlarnaPaymentView,
                approved: Bool,
                authToken: String?
            ) {
                ReachuLogger.debug("Finalized", component: "RCheckoutOverlay")
            }
            
            func klarnaResized(paymentView: KlarnaPaymentView, to newHeight: CGFloat) {
                // No-op for hidden view
            }
            
            func klarnaFailed(
                inPaymentView paymentView: KlarnaPaymentView,
                withError error: KlarnaPaymentError
            ) {
                ReachuLogger.error("Failed: \(error.localizedDescription)", component: "RCheckoutOverlay")
                DispatchQueue.main.async {
                    self.parent.onFailed(error.localizedDescription)
                }
            }
        }
    }
#endif
