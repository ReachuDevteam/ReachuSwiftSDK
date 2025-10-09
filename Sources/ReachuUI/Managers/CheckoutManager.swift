import Foundation
import ReachuCore

@MainActor
extension CartManager {

    @discardableResult
    public func createCheckout() async -> String? {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        guard let cid = await ensureCartIDForCheckout() else {
            print("ℹ️ [Checkout] Create: missing cartId")
            return nil
        }

        print("🧾 [Checkout] Create START cartId=\(cid)")
        do {
            logRequest("sdk.checkout.create", payload: ["cart_id": cid])
            let dto = try await sdk.checkout.create(cart_id: cid)
            let chkId = extractCheckoutId(dto)
            checkoutId = chkId
            logResponse(
                "sdk.checkout.create",
                payload: ["checkoutId": chkId as Any]
            )
            print("✅ [Checkout] Create OK checkoutId=\(chkId ?? "nil")")
            return chkId
        } catch {
            let msg = (error as? SdkException)?.description ?? error.localizedDescription
            errorMessage = msg
            logError("sdk.checkout.create", error: error)
            print("❌ [Checkout] Create FAIL \(msg)")
            return nil
        }
    }

    @discardableResult
    public func updateCheckout(
        checkoutId: String? = nil,
        email: String? = nil,
        successUrl: String? = nil,
        cancelUrl: String? = nil,
        paymentMethod: String? = nil,
        shippingAddress: [String: Any]? = nil,
        billingAddress: [String: Any]? = nil,
        acceptsTerms: Bool = true,
        acceptsPurchaseConditions: Bool = true
    ) async -> UpdateCheckoutDto? {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let chkId: String?
        if let passed = checkoutId, !passed.isEmpty {
            chkId = passed
        } else {
            chkId = await createCheckout()
        }

        guard let id = chkId, !id.isEmpty else {
            print("ℹ️ [Checkout] Update: missing checkoutId")
            return nil
        }

        print("🧾 [Checkout] Update START checkoutId=\(id)")
        do {
            logRequest(
                "sdk.checkout.update",
                payload: [
                    "checkout_id": id,
                    "email": email as Any,
                    "success_url": successUrl as Any,
                    "cancel_url": cancelUrl as Any,
                    "payment_method": paymentMethod as Any
                ]
            )
            let dto = try await sdk.checkout.update(
                checkout_id: id,
                status: nil,
                email: email,
                success_url: successUrl,
                cancel_url: cancelUrl,
                payment_method: paymentMethod,
                shipping_address: shippingAddress,
                billing_address: billingAddress,
                buyer_accepts_terms_conditions: acceptsTerms,
                buyer_accepts_purchase_conditions: acceptsPurchaseConditions
            )
            logResponse("sdk.checkout.update", payload: ["checkoutId": id])
            print("✅ [Checkout] Update OK")
            return dto
        } catch {
            let msg = (error as? SdkException)?.description ?? error.localizedDescription
            errorMessage = msg
            logError("sdk.checkout.update", error: error)
            print("❌ [Checkout] Update FAIL \(msg)")
            return nil
        }
    }

    internal func extractCheckoutId<T: Encodable>(_ dto: T) -> String? {
        guard
            let data = try? JSONEncoder().encode(dto),
            let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }
        return (dict["checkout_id"] as? String)
            ?? (dict["checkoutId"] as? String)
            ?? (dict["id"] as? String)
    }
}
