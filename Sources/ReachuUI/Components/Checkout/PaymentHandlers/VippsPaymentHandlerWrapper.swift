import Foundation
import ReachuCore

/// Wrapper for Vipps payment processing
/// Note: VippsPaymentHandler is already a separate class in ReachuCore
/// This wrapper provides additional checkout-specific functionality
@MainActor
public class VippsPaymentHandlerWrapper {
    
    // MARK: - Properties
    
    private let cartManager: CartManager
    private let checkoutDraft: CheckoutDraft
    private let vippsHandler = VippsPaymentHandler.shared
    
    private(set) var paymentInProgress = false
    private(set) var checkoutId: String?
    private(set) var retryCount = 0
    
    private let maxRetries = 30
    private var retryTimer: Timer?
    
    // MARK: - Initialization
    
    public init(cartManager: CartManager, checkoutDraft: CheckoutDraft) {
        self.cartManager = cartManager
        self.checkoutDraft = checkoutDraft
    }
    
    // MARK: - Public Methods
    
    /// Initiates the Vipps payment flow
    public func initiateFlow(email: String) async -> Result<VippsInitResult, VippsError> {
        ReachuLogger.debug("Vipps Flow INICIO - Step 1: Preparando datos del checkout", component: "VippsPaymentHandlerWrapper")
        
        let checkoutId = cartManager.checkoutId ?? "unknown"
        let successUrlWithTracking = "\(checkoutDraft.successUrl)?checkout_id=\(checkoutId)&payment_method=vipps&status=success"
        
        ReachuLogger.debug("Datos preparados: Email=\(email), CheckoutId=\(checkoutId)", component: "VippsPaymentHandlerWrapper")
        
        guard let dto = await cartManager.vippsInit(
            email: email,
            returnUrl: successUrlWithTracking
        ) else {
            ReachuLogger.error("vippsInit returned: NIL", component: "VippsPaymentHandlerWrapper")
            return .failure(.initializationFailed)
        }
        
        ReachuLogger.success("Step 3: Backend respondió correctamente - Payment URL: \(dto.paymentUrl)", component: "VippsPaymentHandlerWrapper")
        
        guard let url = URL(string: dto.paymentUrl) else {
            ReachuLogger.error("ERROR: URL inválida", component: "VippsPaymentHandlerWrapper")
            return .failure(.invalidURL)
        }
        
        #if os(iOS)
        UIApplication.shared.open(url)
        #elseif os(macOS)
        NSWorkspace.shared.open(url)
        #endif
        
        paymentInProgress = true
        self.checkoutId = checkoutId
        retryCount = 0
        vippsHandler.startPaymentTracking(checkoutId: checkoutId)
        startRetryTimer()
        
        ReachuLogger.success("Vipps abierto en navegador - Payment marked as in progress", component: "VippsPaymentHandlerWrapper")
        
        return .success(VippsInitResult(paymentUrl: dto.paymentUrl, checkoutId: checkoutId))
    }
    
    /// Handles payment status changes from VippsPaymentHandler
    public func handlePaymentStatusChange(_ status: VippsPaymentHandler.PaymentStatus) -> VippsPaymentResult {
        ReachuLogger.debug("Status changed to: \(status)", component: "VippsPaymentHandlerWrapper")
        
        switch status {
        case .success:
            ReachuLogger.success("Payment successful!", component: "VippsPaymentHandlerWrapper")
            stopRetryTimer()
            paymentInProgress = false
            checkoutId = nil
            retryCount = 0
            return .success
        case .failed:
            ReachuLogger.error("Payment failed", component: "VippsPaymentHandlerWrapper")
            stopRetryTimer()
            paymentInProgress = false
            checkoutId = nil
            retryCount = 0
            return .failure(.paymentFailed)
        case .cancelled:
            ReachuLogger.error("Payment cancelled", component: "VippsPaymentHandlerWrapper")
            stopRetryTimer()
            paymentInProgress = false
            checkoutId = nil
            retryCount = 0
            return .failure(.paymentCancelled)
        case .inProgress, .unknown:
            return .inProgress
        }
    }
    
    /// Starts the retry timer for checking payment status
    public func startRetryTimer() {
        ReachuLogger.debug("Starting retry timer - Max retries: \(maxRetries)", component: "VippsPaymentHandlerWrapper")
        retryTimer?.invalidate()
        retryTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.checkPaymentStatusWithRetry()
            }
        }
    }
    
    /// Stops the retry timer
    public func stopRetryTimer() {
        ReachuLogger.debug("Stopping retry timer", component: "VippsPaymentHandlerWrapper")
        retryTimer?.invalidate()
        retryTimer = nil
    }
    
    /// Resets the handler state
    public func reset() {
        stopRetryTimer()
        paymentInProgress = false
        checkoutId = nil
        retryCount = 0
    }
    
    // MARK: - Private Methods
    
    private func checkPaymentStatusWithRetry() async {
        guard paymentInProgress, let checkoutId = checkoutId else {
            stopRetryTimer()
            return
        }
        
        retryCount += 1
        ReachuLogger.debug("Attempt \(retryCount)/\(maxRetries) - Checking status for checkout: \(checkoutId)", component: "VippsPaymentHandlerWrapper")
        
        if retryCount >= maxRetries {
            ReachuLogger.error("Max retries reached - Stopping timer", component: "VippsPaymentHandlerWrapper")
            stopRetryTimer()
            paymentInProgress = false
            return
        }
        
        // Status is checked by VippsPaymentHandler via deep link callbacks
        // This timer is just a fallback mechanism
    }
}

// MARK: - Supporting Types

public struct VippsInitResult {
    public let paymentUrl: String
    public let checkoutId: String
}

public enum VippsPaymentResult {
    case success
    case inProgress
    case failure(VippsError)
}

public enum VippsError: Error, LocalizedError {
    case initializationFailed
    case invalidURL
    case paymentFailed
    case paymentCancelled
    
    public var errorDescription: String? {
        switch self {
        case .initializationFailed:
            return "Failed to initialize Vipps payment"
        case .invalidURL:
            return "Invalid Vipps payment URL"
        case .paymentFailed:
            return "Payment failed"
        case .paymentCancelled:
            return "Payment was cancelled"
        }
    }
}

