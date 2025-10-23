import Foundation
import SwiftUI

/// Handles Vipps payment return URLs and status checking
@MainActor
public class VippsPaymentHandler: ObservableObject {
    
    public static let shared = VippsPaymentHandler()
    
    @Published public var isPaymentInProgress = false
    @Published public var currentCheckoutId: String?
    @Published public var paymentStatus: PaymentStatus = .unknown
    
    public enum PaymentStatus {
        case unknown
        case inProgress
        case success
        case failed
        case cancelled
    }
    
    private init() {}
    
    /// Handle URL scheme return from Vipps
    public func handleReturnURL(_ url: URL) {
        print("🔗 [Vipps Handler] Received URL: \(url)")
        
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            print("❌ [Vipps Handler] Invalid URL format")
            return
        }
        
        // Extract parameters from URL
        var checkoutId: String?
        var status: String?
        var paymentMethod: String?
        
        for item in queryItems {
            switch item.name {
            case "checkout_id":
                checkoutId = item.value
            case "status":
                status = item.value
            case "payment_method":
                paymentMethod = item.value
            default:
                break
            }
        }
        
        print("🔗 [Vipps Handler] Extracted parameters:")
        print("   - Checkout ID: \(checkoutId ?? "nil")")
        print("   - Status: \(status ?? "nil")")
        print("   - Payment Method: \(paymentMethod ?? "nil")")
        
        // Only handle Vipps payments
        guard paymentMethod == "vipps" else {
            print("ℹ️ [Vipps Handler] Not a Vipps payment, ignoring")
            return
        }
        
        // Update status based on URL parameters
        if let status = status {
            switch status.lowercased() {
            case "success":
                self.paymentStatus = .success
                print("✅ [Vipps Handler] Payment successful!")
            case "cancelled", "cancel":
                self.paymentStatus = .cancelled
                print("❌ [Vipps Handler] Payment cancelled")
            case "failed", "error":
                self.paymentStatus = .failed
                print("❌ [Vipps Handler] Payment failed")
            default:
                self.paymentStatus = .unknown
                print("⚠️ [Vipps Handler] Unknown status: \(status)")
            }
        }
        
        // Clear in-progress state
        if checkoutId == self.currentCheckoutId {
            self.isPaymentInProgress = false
            self.currentCheckoutId = nil
        }
    }
    
    /// Start tracking a Vipps payment
    public func startPaymentTracking(checkoutId: String) {
        print("🟠 [Vipps Handler] Starting payment tracking for: \(checkoutId)")
        self.isPaymentInProgress = true
        self.currentCheckoutId = checkoutId
        self.paymentStatus = .inProgress
    }
    
    /// Stop tracking and reset state
    public func stopPaymentTracking() {
        print("🟠 [Vipps Handler] Stopping payment tracking")
        self.isPaymentInProgress = false
        self.currentCheckoutId = nil
        self.paymentStatus = .unknown
    }
    
    /// Check if current URL is a Vipps return URL
    public func isVippsReturnURL(_ url: URL) -> Bool {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            return false
        }
        
        // Check if it's a reachu-demo:// URL with payment_method=vipps
        return components.scheme == "reachu-demo" &&
               queryItems.contains { $0.name == "payment_method" && $0.value == "vipps" }
    }
}

/// SwiftUI ViewModifier to handle Vipps payment returns
struct VippsPaymentHandlerModifier: ViewModifier {
    @StateObject private var handler = VippsPaymentHandler.shared
    
    func body(content: Content) -> some View {
        content
            .onOpenURL { url in
                if handler.isVippsReturnURL(url) {
                    handler.handleReturnURL(url)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .vippsPaymentReturn)) { notification in
                if let url = notification.object as? URL {
                    handler.handleReturnURL(url)
                }
            }
    }
}

extension View {
    /// Add Vipps payment handling to any view
    public func handleVippsPayments() -> some View {
        modifier(VippsPaymentHandlerModifier())
    }
}

public extension Notification.Name {
    static let vippsPaymentReturn = Notification.Name("vippsPaymentReturn")
}
