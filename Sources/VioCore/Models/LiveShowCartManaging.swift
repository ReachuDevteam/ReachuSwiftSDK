import Foundation

/// Abstraction used by LiveShow to interact with a host app cart
/// This protocol is defined in ReachuCore to avoid circular dependencies.
/// Apps that use ReachuLiveShow should implement this protocol in their CartManager.
public protocol LiveShowCartManaging: AnyObject {
    /// Show the checkout overlay
    func showCheckout()
    
    /// Add a product to the cart
    /// - Parameters:
    ///   - product: The product to add
    ///   - quantity: The quantity to add
    func addProduct(_ product: Product, quantity: Int) async
}

