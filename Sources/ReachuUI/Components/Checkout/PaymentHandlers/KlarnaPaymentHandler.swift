import Foundation
import ReachuCore

#if canImport(KlarnaMobileSDK)
import KlarnaMobileSDK
#endif

/// Handler for Klarna payment processing
@MainActor
public class KlarnaPaymentHandler {
    
    // MARK: - Properties
    
    private let cartManager: CartManager
    public let successURLString = "https://tuapp.com/checkout/klarna-return"
    
    #if os(iOS) && canImport(KlarnaMobileSDK)
    private(set) var initData: InitPaymentKlarnaNativeDto?
    private(set) var availableCategories: [KlarnaNativePaymentMethodCategoryDto] = []
    private(set) var selectedCategoryIdentifier: String = ""
    #endif
    
    // MARK: - Initialization
    
    public init(cartManager: CartManager) {
        self.cartManager = cartManager
    }
    
    // MARK: - Public Methods
    
    #if os(iOS) && canImport(KlarnaMobileSDK)
    /// Initiates the Klarna direct payment flow
    public func initiateDirectFlow(
        customer: KlarnaNativeCustomerInputDto,
        shippingAddress: KlarnaNativeAddressInputDto,
        billingAddress: KlarnaNativeAddressInputDto,
        countryCode: String,
        currency: String,
        locale: String
    ) async -> Result<KlarnaInitResult, KlarnaError> {
        ReachuLogger.debug("Klarna Flow INICIO - Step 1: Preparando datos del checkout", component: "KlarnaPaymentHandler")
        
        let input = KlarnaNativeInitInputDto(
            countryCode: countryCode,
            currency: currency,
            locale: locale,
            returnUrl: successURLString,
            intent: "buy",
            autoCapture: true,
            customer: customer,
            billingAddress: billingAddress,
            shippingAddress: shippingAddress
        )
        
        ReachuLogger.debug("Step 2: Llamando a backend Reachu (initKlarnaNative)", component: "KlarnaPaymentHandler")
        
        guard let dto = await cartManager.initKlarnaNative(input: input) else {
            ReachuLogger.error("initKlarnaNative returned: NIL", component: "KlarnaPaymentHandler")
            return .failure(.initializationFailed)
        }
        
        ReachuLogger.success("Step 3: Backend respondió correctamente - SessionId: \(dto.sessionId), Categorías: \(dto.paymentMethodCategories?.count ?? 0)", component: "KlarnaPaymentHandler")
        
        let categories = dto.paymentMethodCategories ?? []
        guard !categories.isEmpty else {
            ReachuLogger.error("ERROR: No hay métodos de pago disponibles", component: "KlarnaPaymentHandler")
            return .failure(.noPaymentMethods)
        }
        
        ReachuLogger.debug("Métodos de pago disponibles: \(categories.map { "\($0.identifier): \($0.name ?? "sin nombre")" }.joined(separator: ", "))", component: "KlarnaPaymentHandler")
        
        self.initData = dto
        self.availableCategories = categories
        
        if let firstCategory = categories.first {
            self.selectedCategoryIdentifier = firstCategory.identifier
            ReachuLogger.debug("Categoría seleccionada: \(firstCategory.identifier)", component: "KlarnaPaymentHandler")
        }
        
        return .success(KlarnaInitResult(
            initData: dto,
            categories: categories,
            selectedCategoryIdentifier: selectedCategoryIdentifier
        ))
    }
    
    /// Confirms the Klarna payment with authorization token
    public func confirmPayment(
        authToken: String,
        customer: KlarnaNativeCustomerInputDto,
        shippingAddress: KlarnaNativeAddressInputDto,
        billingAddress: KlarnaNativeAddressInputDto
    ) async -> Result<ConfirmKlarnaNativeDto, KlarnaError> {
        guard let result = await cartManager.confirmKlarnaNative(
            authorizationToken: authToken,
            autoCapture: true,
            customer: customer,
            billingAddress: billingAddress,
            shippingAddress: shippingAddress
        ) else {
            ReachuLogger.error("Backend no pudo confirmar el pago", component: "KlarnaPaymentHandler")
            return .failure(.confirmationFailed)
        }
        
        ReachuLogger.success("PAGO EXITOSO - OrderId: \(result.orderId), FraudStatus: \(result.fraudStatus)", component: "KlarnaPaymentHandler")
        
        // Clear state
        self.initData = nil
        self.availableCategories = []
        self.selectedCategoryIdentifier = ""
        
        return .success(result)
    }
    
    /// Updates the selected category identifier
    public func selectCategory(_ identifier: String) {
        self.selectedCategoryIdentifier = identifier
    }
    
    /// Clears the handler state
    public func reset() {
        self.initData = nil
        self.availableCategories = []
        self.selectedCategoryIdentifier = ""
    }
    #endif
}

// MARK: - Supporting Types

#if os(iOS) && canImport(KlarnaMobileSDK)
public struct KlarnaInitResult {
    public let initData: InitPaymentKlarnaNativeDto
    public let categories: [KlarnaNativePaymentMethodCategoryDto]
    public let selectedCategoryIdentifier: String
}

public enum KlarnaError: Error, LocalizedError {
    case initializationFailed
    case noPaymentMethods
    case confirmationFailed
    case invalidState
    
    public var errorDescription: String? {
        switch self {
        case .initializationFailed:
            return "Failed to initialize Klarna payment"
        case .noPaymentMethods:
            return "No Klarna payment methods available for this checkout."
        case .confirmationFailed:
            return "Failed to confirm Klarna payment"
        case .invalidState:
            return "Invalid Klarna handler state"
        }
    }
}
#endif

