import Foundation
import ReachuCore

#if os(iOS)
import UIKit
import StripePaymentSheet
#endif

/// Handler for Stripe payment processing
@MainActor
public class StripePaymentHandler {
    
    // MARK: - Properties
    
    private let cartManager: CartManager
    
    #if os(iOS)
    private(set) var paymentSheet: PaymentSheet?
    #endif
    
    // MARK: - Initialization
    
    public init(cartManager: CartManager) {
        self.cartManager = cartManager
    }
    
    // MARK: - Public Methods
    
    #if os(iOS)
    /// Prepares the Stripe payment sheet with payment intent from backend
    public func preparePaymentSheet() async -> Result<PaymentSheet, StripeError> {
        guard let dto = await cartManager.stripeIntent(returnEphemeralKey: true) else {
            return .failure(.couldNotGetIntent)
        }
        
        guard let dict = dtoToDict(dto) else {
            return .failure(.invalidResponse)
        }
        
        let clientSecret: String? = pick(dict, [
            "payment_intent_client_secret", "client_secret", "paymentIntentClientSecret"
        ])
        
        guard let secret = clientSecret, !secret.isEmpty else {
            return .failure(.missingClientSecret)
        }
        
        let ephemeralKey: String? = pick(dict, ["ephemeralKeySecret", "ephemeral_key_secret", "ephemeral_key"])
        let customerId: String? = pick(dict, ["customer", "customer_id", "customerId"])
        
        var config = PaymentSheet.Configuration()
        config.merchantDisplayName = "Reachu Demo"
        
        if let ek = ephemeralKey, let cid = customerId {
            config.customer = .init(id: cid, ephemeralKeySecret: ek)
        }
        
        let sheet = PaymentSheet(paymentIntentClientSecret: secret, configuration: config)
        self.paymentSheet = sheet
        
        return .success(sheet)
    }
    
    /// Presents the Stripe payment sheet from a view controller
    public func presentPaymentSheet(
        from viewController: UIViewController,
        onCompletion: @escaping (StripePaymentResult) -> Void
    ) {
        guard let sheet = paymentSheet else {
            onCompletion(.failure(.sheetNotPrepared))
            return
        }
        
        sheet.present(from: viewController) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .completed:
                self.paymentSheet = nil
                onCompletion(.success)
            case .canceled:
                onCompletion(.cancelled)
            case .failed(let error):
                ReachuLogger.error("Stripe payment failed: \(error.localizedDescription)", component: "StripePaymentHandler")
                onCompletion(.failure(.paymentFailed(error.localizedDescription)))
            }
        }
    }
    #endif
    
    // MARK: - Helper Methods
    
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
}

// MARK: - Supporting Types

public enum StripePaymentResult {
    case success
    case cancelled
    case failure(StripeError)
}

public enum StripeError: Error, LocalizedError {
    case couldNotGetIntent
    case invalidResponse
    case missingClientSecret
    case sheetNotPrepared
    case paymentFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .couldNotGetIntent:
            return "Could not get Stripe Intent from API."
        case .invalidResponse:
            return "Invalid response from server."
        case .missingClientSecret:
            return "Missing Payment Intent client_secret."
        case .sheetNotPrepared:
            return "Payment sheet not prepared. Call preparePaymentSheet() first."
        case .paymentFailed(let message):
            return message
        }
    }
}

