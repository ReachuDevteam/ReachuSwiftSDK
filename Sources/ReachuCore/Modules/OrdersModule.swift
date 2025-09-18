import Foundation

/// Module for managing orders
public class OrdersModule {
    
    /// Get orders for customer
    /// - Parameter customerId: Customer ID
    /// - Returns: Customer's orders
    public func getOrders(customerId: String) async throws -> [Order] {
        throw ReachuError.notImplemented("OrdersModule.getOrders will be implemented in Task 2")
    }
    
    /// Get specific order by ID
    /// - Parameter id: Order ID
    /// - Returns: Order details
    public func getOrder(id: String) async throws -> Order {
        throw ReachuError.notImplemented("OrdersModule.getOrder will be implemented in Task 2")
    }
    
    /// Track order shipment
    /// - Parameter id: Order ID
    /// - Returns: Order tracking information
    public func trackOrder(id: String) async throws -> OrderTracking {
        throw ReachuError.notImplemented("OrdersModule.trackOrder will be implemented in Task 2")
    }
    
    /// Cancel order (if possible)
    /// - Parameter id: Order ID to cancel
    /// - Returns: Updated order
    public func cancelOrder(id: String) async throws -> Order {
        throw ReachuError.notImplemented("OrdersModule.cancelOrder will be implemented in Task 2")
    }
    
    /// Request return for order items
    /// - Parameters:
    ///   - orderId: Order ID
    ///   - lines: Order lines to return
    ///   - reason: Return reason
    /// - Returns: Return request
    public func requestReturn(
        orderId: String,
        lines: [OrderLine],
        reason: ReturnReason
    ) async throws -> ReturnRequest {
        throw ReachuError.notImplemented("OrdersModule.requestReturn will be implemented in Task 2")
    }
    
    /// Get return status
    /// - Parameter returnId: Return request ID
    /// - Returns: Return request details
    public func getReturnStatus(returnId: String) async throws -> ReturnRequest {
        throw ReachuError.notImplemented("OrdersModule.getReturnStatus will be implemented in Task 2")
    }
}
