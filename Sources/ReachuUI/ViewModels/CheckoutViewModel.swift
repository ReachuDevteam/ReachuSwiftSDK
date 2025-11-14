import Foundation
import ReachuCore
import SwiftUI

#if canImport(KlarnaMobileSDK)
    import KlarnaMobileSDK
#endif

#if os(iOS)
    import UIKit
    import StripePaymentSheet
#elseif os(macOS)
    import AppKit
#endif

/// ViewModel for RCheckoutOverlay
/// Contains all business logic separated from UI
@MainActor
public class CheckoutViewModel: ObservableObject {
    
    // MARK: - Dependencies
    private let cartManager: CartManager
    private let checkoutDraft: CheckoutDraft
    
    // MARK: - Published State
    @Published public var currentStep: CheckoutStep = .address
    @Published public var isLoading = false
    @Published public var errorMessage: String?
    
    // Address Information
    @Published public var firstName = ""
    @Published public var lastName = ""
    @Published public var email = ""
    @Published public var phone = ""
    @Published public var phoneCountryCode = ""
    @Published public var phoneCountryCodeISO: String? = nil
    @Published public var address1 = ""
    @Published public var address2 = ""
    @Published public var city = ""
    @Published public var province = ""
    @Published public var country = ""
    @Published public var zip = ""
    @Published public var isEditingAddress = false
    
    // Payment Information
    @Published public var selectedPaymentMethod: PaymentMethod = .stripe
    @Published public var availablePaymentMethods: [PaymentMethod] = []
    @Published public var acceptsTerms = true
    @Published public var acceptsPurchaseConditions = true
    
    // Discount Code
    @Published public var discountCode = ""
    @Published public var appliedDiscount: Double = 0.0
    @Published public var discountMessage = ""
    
    // Checkout totals
    @Published public var checkoutTotals: GetCheckoutDto?
    
    // Vipps Payment Tracking
    @Published public var vippsPaymentInProgress = false
    @Published public var vippsCheckoutId: String?
    @Published public var vippsRetryCount = 0
    private let vippsMaxRetries = 30
    private var vippsRetryTimer: Timer?
    private let vippsHandler = VippsPaymentHandler.shared
    
    #if os(iOS)
        @Published public var paymentSheet: PaymentSheet?
        @Published public var shouldPresentStripeSheet = false
    #endif
    
    #if os(iOS) && canImport(KlarnaMobileSDK)
        @Published public var showKlarnaNativeSheet = false
        @Published public var klarnaNativeInitData: InitPaymentKlarnaNativeDto?
        @Published public var klarnaNativeContentHeight: CGFloat = 420
        @Published public var klarnaAvailableCategories: [KlarnaNativePaymentMethodCategoryDto] = []
        @Published public var klarnaSelectedCategoryIdentifier: String = ""
        private let klarnaSuccessURLString = "https://tuapp.com/checkout/klarna-return"
        @Published public var klarnaAutoAuthorize = false
        @Published public var showKlarnaErrorToast = false
        @Published public var klarnaErrorMessage = ""
    #endif
    
    // MARK: - Initialization
    
    public init(
        cartManager: CartManager,
        checkoutDraft: CheckoutDraft,
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
        self.cartManager = cartManager
        self.checkoutDraft = checkoutDraft
        
        // Load initial data
        loadInitialData(
            userFirstName: userFirstName,
            userLastName: userLastName,
            userEmail: userEmail,
            userPhone: userPhone,
            userPhoneCountryCode: userPhoneCountryCode,
            userAddress1: userAddress1,
            userAddress2: userAddress2,
            userCity: userCity,
            userProvince: userProvince,
            userCountry: userCountry,
            userZip: userZip
        )
        
        // Setup observers
        setupObservers()
    }
    
    // MARK: - Public Methods
    
    public func loadAvailablePaymentMethods() async {
        isLoading = true
        defer { isLoading = false }
        
        let methods = await cartManager.getAvailablePaymentMethods()
        availablePaymentMethods = methods.map { PaymentMethod(rawValue: $0.lowercased()) ?? .stripe }
            .filter { $0 != nil }
            .map { $0! }
        
        // Ensure current selection is valid
        if !availablePaymentMethods.contains(selectedPaymentMethod) && !availablePaymentMethods.isEmpty {
            selectedPaymentMethod = availablePaymentMethods[0]
        }
    }
    
    public func loadCheckoutTotals() async {
        guard let checkoutId = cartManager.checkoutId else {
            ReachuLogger.debug("No checkoutId available to load totals", component: "CheckoutViewModel")
            return
        }
        
        ReachuLogger.debug("Loading checkout totals for checkoutId: \(checkoutId)", component: "CheckoutViewModel")
        
        if let checkout = await cartManager.getCheckoutById(checkoutId: checkoutId) {
            checkoutTotals = checkout
            ReachuLogger.debug("Checkout totals loaded - shipping: \(checkout.totals?.shipping ?? 0), taxes: \(checkout.totals?.taxes ?? 0)", component: "CheckoutViewModel")
        } else {
            ReachuLogger.debug("Failed to load checkout totals", component: "CheckoutViewModel")
        }
    }
    
    public func proceedToNextStep() {
        ReachuLogger.debug("proceedToNext - currentStep: \(currentStep), paymentMethod: \(selectedPaymentMethod.rawValue)", component: "CheckoutViewModel")
        
        withAnimation(.easeInOut(duration: 0.3)) {
            switch currentStep {
            case .address:
                currentStep = .orderSummary
            case .orderSummary:
                if selectedPaymentMethod == .klarna {
                    #if os(iOS) && canImport(KlarnaMobileSDK)
                        Task {
                            await initiateKlarnaDirectFlow()
                        }
                    #endif
                } else {
                    currentStep = .review
                }
            case .review:
                if selectedPaymentMethod == .stripe {
                    #if os(iOS)
                        Task {
                            isLoading = true
                            await prepareStripePaymentSheet()
                            isLoading = false
                            shouldPresentStripeSheet = true
                        }
                    #endif
                } else {
                    currentStep = .success
                }
            case .success, .error:
                break
            }
        }
    }
    
    public func goToPreviousStep() {
        withAnimation(.easeInOut(duration: 0.3)) {
            switch currentStep {
            case .orderSummary:
                currentStep = .address
            case .review:
                currentStep = .orderSummary
            default:
                break
            }
        }
    }
    
    public func syncDraftFromState() {
        checkoutDraft.firstName = firstName
        checkoutDraft.lastName = lastName
        checkoutDraft.email = email
        checkoutDraft.phone = phone
        checkoutDraft.phoneCountryCode = phoneCountryCode.replacingOccurrences(of: "+", with: "")
        checkoutDraft.address1 = address1
        checkoutDraft.address2 = address2
        checkoutDraft.city = city
        checkoutDraft.province = province
        checkoutDraft.countryName = country
        checkoutDraft.zip = zip
        checkoutDraft.shippingOptionRaw = cartManager.items.compactMap(\.shippingId).joined(separator: ",")
        checkoutDraft.paymentMethodRaw = selectedPaymentMethod.rawValue
        checkoutDraft.acceptsTerms = acceptsTerms
        checkoutDraft.acceptsPurchaseConditions = acceptsPurchaseConditions
        checkoutDraft.appliedDiscount = appliedDiscount
    }
    
    // MARK: - Validation
    
    public var canProceedToNext: Bool {
        if cartManager.items.isEmpty {
            return false
        }
        
        switch currentStep {
        case .address:
            return !firstName.isEmpty && !lastName.isEmpty && !email.isEmpty && 
                   !phone.isEmpty && !address1.isEmpty && !city.isEmpty && !zip.isEmpty
        case .orderSummary:
            return cartManager.items.allSatisfy { item in
                item.shippingId != nil && !item.shippingId!.isEmpty
            }
        case .review:
            return true
        case .success, .error:
            return false
        }
    }
    
    public var validationMessage: String {
        if cartManager.items.isEmpty {
            return RLocalizedString(ReachuTranslationKey.cartEmptyMessage.rawValue)
        }
        
        if currentStep == .orderSummary {
            let itemsWithoutShipping = cartManager.items.filter { item in
                item.shippingId == nil || item.shippingId!.isEmpty
            }
            
            if !itemsWithoutShipping.isEmpty {
                let itemsWithMultipleOptions = itemsWithoutShipping.filter { item in
                    item.availableShippings.count > 1
                }
                
                if !itemsWithMultipleOptions.isEmpty {
                    return RLocalizedString(ReachuTranslationKey.shippingRequired.rawValue)
                }
            }
        }
        
        switch currentStep {
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
            if city.isEmpty || zip.isEmpty {
                return RLocalizedString(ReachuTranslationKey.required.rawValue)
            }
            return RLocalizedString(ReachuTranslationKey.required.rawValue)
        case .orderSummary:
            return RLocalizedString(ReachuTranslationKey.shippingRequired.rawValue)
        default:
            return ""
        }
    }
    
    // MARK: - Computed Properties
    
    public var checkoutSubtotal: Double {
        cartManager.cartTotal
    }
    
    public var checkoutTotal: Double {
        let subtotal = checkoutSubtotal
        let shipping = cartManager.shippingTotal
        let discount = appliedDiscount
        return max(0, subtotal + shipping - discount)
    }
    
    public var shippingAmountText: String {
        if cartManager.shippingTotal > 0 {
            return "\(cartManager.shippingCurrency) \(String(format: "%.2f", cartManager.shippingTotal))"
        }
        return RLocalizedString(ReachuTranslationKey.shippingCalculated.rawValue)
    }
    
    // MARK: - Private Methods
    
    private func setupObservers() {
        // Observe Vipps payment status changes
        // Note: This would need to be implemented with Combine or similar
        // For now, we'll handle it in the View layer
    }
    
    private func loadInitialData(
        userFirstName: String?,
        userLastName: String?,
        userEmail: String?,
        userPhone: String?,
        userPhoneCountryCode: String?,
        userAddress1: String?,
        userAddress2: String?,
        userCity: String?,
        userProvince: String?,
        userCountry: String?,
        userZip: String?
    ) {
        let config = ReachuConfiguration.shared
        let isDevelopment = config.environment == .development || config.environment == .sandbox
        
        // Priority: User provided data > Demo data (if development) > Empty
        firstName = userFirstName ?? (isDevelopment ? "John" : "")
        lastName = userLastName ?? (isDevelopment ? "Doe" : "")
        email = userEmail ?? (isDevelopment ? "john.doe@example.com" : "")
        phone = userPhone ?? (isDevelopment ? "2125551212" : "")
        
        // Handle phone country code
        if let userPhoneCountryCode = userPhoneCountryCode, !userPhoneCountryCode.isEmpty {
            phoneCountryCode = userPhoneCountryCode
            syncPhoneCountryCodeISO(userPhoneCountryCode)
        } else if let market = cartManager.selectedMarket {
            phoneCountryCode = market.phoneCode ?? "+1"
            phoneCountryCodeISO = market.code
        } else {
            let defaultCountry = config.marketConfiguration.countryCode
            if let apiMarket = config.availableMarkets.first(where: { $0.code == defaultCountry }) {
                phoneCountryCode = apiMarket.phoneCode ?? "+1"
                phoneCountryCodeISO = apiMarket.code
            } else if isDevelopment {
                phoneCountryCode = "+1"
                if let caMarket = config.availableMarkets.first(where: { $0.code == "CA" }) {
                    phoneCountryCodeISO = "CA"
                } else if let usMarket = config.availableMarkets.first(where: { $0.code == "US" }) {
                    phoneCountryCodeISO = "US"
                }
            }
        }
        
        address1 = userAddress1 ?? (isDevelopment ? "82 Melora Street" : "")
        address2 = userAddress2 ?? ""
        city = userCity ?? (isDevelopment ? "Westbridge" : "")
        province = userProvince ?? (isDevelopment ? "California" : "")
        country = userCountry ?? cartManager.selectedMarket?.name ?? (isDevelopment ? "United States" : "")
        zip = userZip ?? (isDevelopment ? "92841" : "")
        
        syncPhoneCode(phoneCountryCode)
    }
    
    private func syncPhoneCode(_ code: String) {
        phoneCountryCode = code
        // Additional sync logic if needed
    }
    
    private func syncPhoneCountryCodeISO(_ code: String) {
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
    
    // MARK: - Payment Methods
    
    #if os(iOS)
    public func prepareStripePaymentSheet() async -> Bool {
        guard
            let dto = await cartManager.stripeIntent(returnEphemeralKey: true),
            let dict = dtoToDict(dto)
        else {
            errorMessage = "Could not get Stripe Intent from API."
            return false
        }
        
        let clientSecret: String? = pick(dict, [
            "payment_intent_client_secret", "client_secret", "paymentIntentClientSecret"
        ])
        guard let secret = clientSecret, !secret.isEmpty else {
            errorMessage = "Missing Payment Intent client_secret."
            return false
        }
        
        let ephemeralKey: String? = pick(dict, ["ephemeralKeySecret", "ephemeral_key_secret", "ephemeral_key"])
        let customerId: String? = pick(dict, ["customer", "customer_id", "customerId"])
        
        var config = PaymentSheet.Configuration()
        config.merchantDisplayName = "Reachu Demo"
        if let ek = ephemeralKey, let cid = customerId {
            config.customer = .init(id: cid, ephemeralKeySecret: ek)
        }
        
        paymentSheet = PaymentSheet(paymentIntentClientSecret: secret, configuration: config)
        return true
    }
    
    public func presentStripePaymentSheet(from viewController: UIViewController) {
        guard let sheet = paymentSheet else { return }
        sheet.present(from: viewController) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .completed:
                withAnimation { self.currentStep = .success }
            case .canceled:
                withAnimation { self.currentStep = .orderSummary }
            case .failed(let error):
                ReachuLogger.error("Stripe payment failed: \(error.localizedDescription)", component: "CheckoutViewModel")
                self.errorMessage = error.localizedDescription
                withAnimation { self.currentStep = .error }
            }
            self.shouldPresentStripeSheet = false
        }
    }
    
    private func dtoToDict<T: Encodable>(_ dto: T) -> [String: Any]? {
        guard let data = try? JSONEncoder().encode(dto) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data) as? [String: Any]) ?? nil
    }
    
    private func pick<T>(_ dict: [String: Any], _ keys: [String]) -> T? {
        for k in keys {
            if let v = dict[k] as? T { return v }
            let normalized = k.replacingOccurrences(of: "_", with: "").lowercased()
            if let hit = dict.first(where: {
                $0.key.replacingOccurrences(of: "_", with: "").lowercased() == normalized
            }), let cast = hit.value as? T {
                return cast
            }
        }
        return nil
    }
    #endif
    
    #if os(iOS) && canImport(KlarnaMobileSDK)
    public func initiateKlarnaDirectFlow() async {
        ReachuLogger.debug("Klarna Flow INICIO - Step 1: Preparando datos del checkout", component: "CheckoutViewModel")
        
        isLoading = true
        errorMessage = nil
        
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
        
        ReachuLogger.debug("Datos preparados: Email=\(email), País=\(country)→\(countryCode), Moneda=\(cartManager.currency), Locale=\(locale), CheckoutId=\(cartManager.checkoutId ?? "nil")", component: "CheckoutViewModel")
        
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
        
        ReachuLogger.debug("Step 2: Llamando a backend Reachu (initKlarnaNative)", component: "CheckoutViewModel")
        
        guard let dto = await cartManager.initKlarnaNative(input: input) else {
            ReachuLogger.error("initKlarnaNative returned: NIL", component: "CheckoutViewModel")
            isLoading = false
            errorMessage = "Failed to initialize Klarna payment"
            currentStep = .error
            return
        }
        
        ReachuLogger.success("Step 3: Backend respondió correctamente - SessionId: \(dto.sessionId), Categorías: \(dto.paymentMethodCategories?.count ?? 0)", component: "CheckoutViewModel")
        
        let categories = dto.paymentMethodCategories ?? []
        guard !categories.isEmpty else {
            ReachuLogger.error("ERROR: No hay métodos de pago disponibles", component: "CheckoutViewModel")
            isLoading = false
            errorMessage = "No Klarna payment methods available for this checkout."
            currentStep = .error
            return
        }
        
        ReachuLogger.debug("Métodos de pago disponibles: \(categories.map { "\($0.identifier): \($0.name ?? "sin nombre")" }.joined(separator: ", "))", component: "CheckoutViewModel")
        
        klarnaAvailableCategories = categories
        if let firstCategory = categories.first {
            klarnaSelectedCategoryIdentifier = firstCategory.identifier
            ReachuLogger.debug("Categoría seleccionada: \(firstCategory.identifier)", component: "CheckoutViewModel")
        }
        
        klarnaNativeInitData = dto
        isLoading = false
        
        ReachuLogger.debug("Step 4: Activando auto-authorize (modal Klarna)", component: "CheckoutViewModel")
        klarnaAutoAuthorize = true
    }
    
    public func confirmKlarnaPayment(authToken: String, finalizeRequired: Bool) async -> Bool {
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
        
        guard let result = await cartManager.confirmKlarnaNative(
            authorizationToken: authToken,
            autoCapture: true,
            customer: customer,
            billingAddress: billingAddress,
            shippingAddress: shippingAddress
        ) else {
            ReachuLogger.error("Backend no pudo confirmar el pago", component: "CheckoutViewModel")
            errorMessage = "Failed to confirm Klarna payment"
            currentStep = .error
            return false
        }
        
        ReachuLogger.success("PAGO EXITOSO - OrderId: \(result.orderId), FraudStatus: \(result.fraudStatus)", component: "CheckoutViewModel")
        klarnaNativeInitData = nil
        currentStep = .success
        return true
    }
    
    private func getCountryCode(from countryName: String) -> String {
        let mapping: [String: String] = [
            "Norway": "NO", "United States": "US", "United Kingdom": "GB",
            "Sweden": "SE", "Denmark": "DK", "Finland": "FI",
            "Germany": "DE", "France": "FR", "Spain": "ES", "Italy": "IT"
        ]
        return mapping[countryName] ?? "NO"
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
    #endif
    
    // MARK: - Vipps Payment
    
    public func initiateVippsFlow() async {
        ReachuLogger.debug("Vipps Flow INICIO - Step 1: Preparando datos del checkout", component: "CheckoutViewModel")
        
        isLoading = true
        errorMessage = nil
        
        let checkoutId = cartManager.checkoutId ?? "unknown"
        let successUrlWithTracking = "\(checkoutDraft.successUrl)?checkout_id=\(checkoutId)&payment_method=vipps&status=success"
        
        ReachuLogger.debug("Datos preparados: Email=\(email), CheckoutId=\(checkoutId)", component: "CheckoutViewModel")
        
        guard let dto = await cartManager.vippsInit(
            email: email,
            returnUrl: successUrlWithTracking
        ) else {
            ReachuLogger.error("vippsInit returned: NIL", component: "CheckoutViewModel")
            isLoading = false
            errorMessage = "Failed to initialize Vipps payment"
            currentStep = .error
            return
        }
        
        ReachuLogger.success("Step 3: Backend respondió correctamente - Payment URL: \(dto.paymentUrl)", component: "CheckoutViewModel")
        
        isLoading = false
        
        if let url = URL(string: dto.paymentUrl) {
            #if os(iOS)
            UIApplication.shared.open(url)
            #elseif os(macOS)
            NSWorkspace.shared.open(url)
            #endif
            
            vippsPaymentInProgress = true
            vippsCheckoutId = checkoutId
            vippsRetryCount = 0
            vippsHandler.startPaymentTracking(checkoutId: checkoutId)
            startVippsRetryTimer()
            
            ReachuLogger.success("Vipps abierto en navegador - Payment marked as in progress", component: "CheckoutViewModel")
        } else {
            ReachuLogger.error("ERROR: URL inválida", component: "CheckoutViewModel")
            errorMessage = "Invalid Vipps payment URL"
            currentStep = .error
        }
    }
    
    public func handleVippsPaymentStatusChange(_ status: VippsPaymentHandler.PaymentStatus) {
        ReachuLogger.debug("Status changed to: \(status)", component: "CheckoutViewModel")
        
        switch status {
        case .success:
            ReachuLogger.success("Payment successful!", component: "CheckoutViewModel")
            stopVippsRetryTimer()
            currentStep = .success
            vippsPaymentInProgress = false
            vippsCheckoutId = nil
            vippsRetryCount = 0
        case .failed, .cancelled:
            ReachuLogger.error("Payment failed or cancelled", component: "CheckoutViewModel")
            stopVippsRetryTimer()
            errorMessage = status == .failed ? "Payment failed" : "Payment was cancelled"
            currentStep = .error
            vippsPaymentInProgress = false
            vippsCheckoutId = nil
            vippsRetryCount = 0
        case .inProgress, .unknown:
            // Keep current state and retry timer running
            break
        }
    }
    
    private func startVippsRetryTimer() {
        ReachuLogger.debug("Starting retry timer - Max retries: \(vippsMaxRetries)", component: "CheckoutViewModel")
        vippsRetryTimer?.invalidate()
        vippsRetryTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.checkVippsPaymentStatusWithRetry()
            }
        }
    }
    
    public func stopVippsRetryTimer() {
        ReachuLogger.debug("Stopping retry timer", component: "CheckoutViewModel")
        vippsRetryTimer?.invalidate()
        vippsRetryTimer = nil
    }
    
    private func checkVippsPaymentStatusWithRetry() async {
        guard vippsPaymentInProgress, let checkoutId = vippsCheckoutId else {
            stopVippsRetryTimer()
            return
        }
        
        vippsRetryCount += 1
        ReachuLogger.debug("Attempt \(vippsRetryCount)/\(vippsMaxRetries) - Checking status for checkout: \(checkoutId)", component: "CheckoutViewModel")
        
        if let checkout = await cartManager.getCheckoutById(checkoutId: checkoutId) {
            if checkout.status.uppercased() == "SUCCESS" {
                ReachuLogger.success("Payment successful!", component: "CheckoutViewModel")
                stopVippsRetryTimer()
                vippsPaymentInProgress = false
                vippsCheckoutId = nil
                vippsRetryCount = 0
                currentStep = .success
                return
            }
            
            if vippsRetryCount >= vippsMaxRetries {
                ReachuLogger.warning("Max retries reached. Payment not successful.", component: "CheckoutViewModel")
                stopVippsRetryTimer()
                vippsPaymentInProgress = false
                vippsCheckoutId = nil
                vippsRetryCount = 0
                errorMessage = "Payment verification failed after multiple attempts. Please check your payment status."
                currentStep = .error
                return
            }
        } else {
            if vippsRetryCount >= vippsMaxRetries {
                stopVippsRetryTimer()
                vippsPaymentInProgress = false
                vippsCheckoutId = nil
                vippsRetryCount = 0
                errorMessage = "Could not verify payment status after multiple attempts."
                currentStep = .error
            }
        }
    }
    
    // MARK: - Discount
    
    public func applyDiscount() async {
        guard !discountCode.isEmpty else { return }
        
        let applied = await cartManager.applyDiscount(code: discountCode)
        if applied {
            appliedDiscount = cartManager.lastDiscountId != nil ? 
                (checkoutTotals?.totals?.discounts ?? 0.0) : 0.0
            discountMessage = "Discount applied: \(discountCode)"
        } else {
            discountMessage = cartManager.errorMessage ?? "Discount not applied"
        }
    }
    
    public func removeDiscount() async {
        await cartManager.removeDiscount()
        appliedDiscount = 0.0
        discountCode = ""
        discountMessage = ""
    }
    
    // MARK: - Address Step Actions
    
    public func proceedFromAddressStep() async {
        syncDraftFromState()
        
        _ = await cartManager.applyCheapestShippingPerSupplier()
        
        guard let chkId = await cartManager.createCheckout() else {
            proceedToNextStep()
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
        
        let addr = checkoutDraft.addressPayload(fallbackCountryISO2: cartManager.country)
        
        _ = await cartManager.updateCheckout(
            checkoutId: chkId,
            email: checkoutDraft.email,
            successUrl: nil,
            cancelUrl: nil,
            paymentMethod: checkoutDraft.paymentMethodRaw.capitalized,
            shippingAddress: addr,
            billingAddress: addr,
            acceptsTerms: checkoutDraft.acceptsTerms,
            acceptsPurchaseConditions: checkoutDraft.acceptsPurchaseConditions
        )
        
        // Load checkout totals after updating
        await loadCheckoutTotals()
        
        proceedToNextStep()
    }
    
    // MARK: - Market Sync
    
    public func syncSelectedMarket() {
        if let market = cartManager.selectedMarket {
            country = market.name
            syncPhoneCode(market.phoneCode ?? "+1")
            phoneCountryCodeISO = market.code
            checkoutDraft.countryName = market.name
            checkoutDraft.countryCode = market.code
        }
    }
    
    public func syncPhoneCode(_ code: String) {
        phoneCountryCode = code
        checkoutDraft.phoneCountryCode = code.replacingOccurrences(of: "+", with: "")
        
        // If we have a selected country code ISO, keep it
        // Otherwise, try to find it from available markets (from API)
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
}

// MARK: - Supporting Types

public enum CheckoutStep: CaseIterable {
    case address
    case orderSummary
    case review
    case success
    case error
    
    public var title: String {
        switch self {
        case .address: return "Address"
        case .orderSummary: return "Order Summary"
        case .review: return "Review"
        case .success: return "Complete"
        case .error: return "Error"
        }
    }
}

public enum PaymentMethod: String, CaseIterable {
    case stripe = "stripe"
    case klarna = "klarna"
    case vipps = "vipps"
    
    public var displayName: String {
        switch self {
        case .stripe: return "Credit Card"
        case .klarna: return "Pay with Klarna"
        case .vipps: return "Vipps"
        }
    }
    
    public var icon: String {
        switch self {
        case .stripe: return "creditcard.fill"
        case .klarna: return "k.square.fill"
        case .vipps: return "v.square.fill"
        }
    }
    
    public var imageName: String? {
        switch self {
        case .stripe: return "stripe"
        case .klarna: return "klarna"
        case .vipps: return "vipps"
        }
    }
    
    public var iconColor: Color {
        switch self {
        case .stripe: return .purple
        case .klarna: return Color(hex: "#FFB3C7")
        case .vipps: return Color(hex: "#FF5B24")
        }
    }
    
    public var supportsInstallments: Bool {
        switch self {
        case .klarna: return true
        default: return false
        }
    }
}

