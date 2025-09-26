import Foundation
import ReachuCore
import ReachuDemoKit

@main
struct CartDemo {
    static func main() async {
        let API_TOKEN = "THVXN06-MGB4D4P-KCPRCKP-RHGT6VJ"
        let BASE_URL = URL(string: "https://graph-ql-dev.reachu.io/graphql")!

        let CURRENCY = "NOK"
        let COUNTRY = "NO"

        let PRODUCT_ID: Int = 397968
        let QUANTITY: Int = 1

        let DELETE_ITEM_AT_END = false
        let DELETE_CART_AT_END = true

        let sessionId = "demo-\(UUID().uuidString)"
        let sdk = SdkClient(baseUrl: BASE_URL, apiKey: API_TOKEN)

        do {
            Log.section("CreateCart (\(sessionId))")
            let (created, _) = try await Log.measure("CreateCart") {
                try await sdk.cart.create(
                    customer_session_id: sessionId,
                    currency: CURRENCY,
                    shippingCountry: COUNTRY
                )
            }
            Log.json(created, label: "Response (CreateCart)")
            var cartId = created.cartId

            Log.section("AddItem")
            let line = LineItemInput(
                productId: PRODUCT_ID,
                quantity: QUANTITY,
                priceData: nil
            )
            let (afterAdd, _) = try await Log.measure("AddItem") {
                try await sdk.cart.addItem(cart_id: cartId, line_items: [line])
            }
            Log.json(afterAdd, label: "Response (AddItem)")
            cartId = afterAdd.cartId

            Log.section("GetLineItemsBySupplier")
            let (groups, _) = try await Log.measure("GetLineItemsBySupplier") {
                try await sdk.cart.getLineItemsBySupplier(cart_id: cartId)
            }
            Log.json(groups, label: "Response (GetLineItemsBySupplier)")

            Log.section("Apply cheapest shipping per supplier to all line items")
            var totalUpdates = 0
            var failures: [(String, String)] = []

            for group in groups {
                var shippings = group.availableShippings ?? []
                shippings.sort {
                    let a = $0.price.amount ?? Double.greatestFiniteMagnitude
                    let b = $1.price.amount ?? Double.greatestFiniteMagnitude
                    return a < b
                }

                guard let cheapestId = shippings.first?.id, !cheapestId.isEmpty else {
                    Log.warn(
                        "No available shippings for supplier \(group.supplier?.name ?? "N/A"). Skipping."
                    )
                    continue
                }

                for li in group.lineItems {
                    do {
                        _ = try await sdk.cart.updateItem(
                            cart_id: cartId,
                            cart_item_id: li.id,
                            shipping_id: cheapestId,
                            quantity: nil
                        )
                        totalUpdates += 1
                    } catch {
                        let msg =
                            (error as? SdkException)?.description ?? error.localizedDescription
                        failures.append((li.id, msg))
                    }
                }
            }

            Log.info("Applied shipping to \(totalUpdates) item(s).")
            if !failures.isEmpty {
                Log.warn("Failed updates:")
                for (itemId, msg) in failures {
                    Log.warn(" - \(itemId): \(msg)")
                }
            }

            Log.section("GetCart (final)")
            let (finalCart, _) = try await Log.measure("GetCart") {
                try await sdk.cart.getById(cart_id: cartId)
            }
            Log.json(finalCart, label: "Response (GetCart final)")

            if DELETE_ITEM_AT_END, let first = finalCart.lineItems.first {
                Log.section("DeleteItem")
                let (afterDeleteItem, _) = try await Log.measure("DeleteItem") {
                    try await sdk.cart.deleteItem(cart_id: cartId, cart_item_id: first.id)
                }
                Log.json(afterDeleteItem, label: "Response (DeleteItem)")
            }

            if DELETE_CART_AT_END {
                Log.section("DeleteCart")
                let (deleted, _) = try await Log.measure("DeleteCart") {
                    try await sdk.cart.delete(cart_id: cartId)
                }
                Log.json(deleted, label: "Response (DeleteCart)")
            }

            Log.section("Done")
            Log.success("Cart flow aligned with Flutter selection & update behavior.")

        } catch {
            Log.section("Error")
            if let e = error as? SdkException {
                Log.error(e.description)
            } else {
                Log.error(error.localizedDescription)
            }
        }
    }
}
