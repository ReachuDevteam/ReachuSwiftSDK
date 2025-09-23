import Foundation
import ReachuCore

/// Abstraction used by LiveShow to interact with a host app cart
/// This avoids taking a hard dependency on ReachuUI from the LiveShow module.
public protocol LiveShowCartManaging: AnyObject {
    func showCheckout()
    func addProduct(_ product: Product, quantity: Int) async
}


