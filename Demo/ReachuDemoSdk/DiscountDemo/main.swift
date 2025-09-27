import Foundation
import ReachuCore
import ReachuDemoKit

@main
struct DiscountDemo {
    static func main() async {
        let API_TOKEN = "THVXN06-MGB4D4P-KCPRCKP-RHGT6VJ"
        let BASE_URL = URL(string: "https://graph-ql-dev.reachu.io/graphql")!

        let CURRENCY = "NOK"
        let COUNTRY = "NO"

        let PRODUCT_ID: Int = 397968
        let QUANTITY: Int = 10

        let DISCOUNT_TYPE_ID = 2

        let iso = ISO8601DateFormatter()
        let startDate = iso.string(from: Date())
        let endDate = iso.string(from: Calendar.current.date(byAdding: .day, value: 7, to: Date())!)

        let code = "DEMO-\(UUID().uuidString.prefix(6))"

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
            let cartId = created.cartId

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

            Log.section("Discounts.get")
            let (allDiscounts, _) = try await Log.measure("Discounts.get") {
                try await sdk.discount.get()
            }
            Log.json(allDiscounts, label: "Response (Discounts.get)")

            Log.section("Discounts.getByChannel")
            let (channelDiscounts, _) = try await Log.measure("Discounts.getByChannel") {
                try await sdk.discount.getByChannel()
            }
            Log.json(channelDiscounts, label: "Response (Discounts.getByChannel)")

            Log.section("Discounts.add")
            let (addResp, _) = try await Log.measure("Discounts.add") {
                try await sdk.discount.add(
                    code: code,
                    percentage: 10,
                    startDate: startDate,
                    endDate: endDate,
                    typeId: DISCOUNT_TYPE_ID
                )
            }
            Log.json(addResp, label: "Response (Discounts.add)")

            Log.section("Discounts.getById")
            let (byId, _) = try await Log.measure("Discounts.getById") {
                try await sdk.discount.getById(discountId: addResp.id)
            }
            Log.json(byId, label: "Response (Discounts.getById)")

            Log.section("Cart.get (before apply)")
            let (cartBefore, _) = try await Log.measure("Cart.get (before apply)") {
                try await sdk.cart.getById(cart_id: cartId)
            }
            Log.json(cartBefore, label: "Response (Cart before apply)")

            Log.section("Discounts.apply")
            let (applyResp, _) = try await Log.measure("Discounts.apply") {
                try await sdk.discount.apply(code: code, cartId: cartId)
            }
            Log.json(applyResp, label: "Response (Discounts.apply)")

            Log.section("Cart.get (after apply)")
            let (cartAfter, _) = try await Log.measure("Cart.get (after apply)") {
                try await sdk.cart.getById(cart_id: cartId)
            }
            Log.json(cartAfter, label: "Response (Cart after apply)")

            Log.section("Discounts.deleteApplied")
            let (delAppliedResp, _) = try await Log.measure("Discounts.deleteApplied") {
                try await sdk.discount.deleteApplied(code: code, cartId: cartId)
            }
            Log.json(delAppliedResp, label: "Response (Discounts.deleteApplied)")

            Log.section("Discounts.delete (created)")
            let (deletedDiscount, _) = try await Log.measure("Discounts.delete") {
                try await sdk.discount.delete(discountId: addResp.id)
            }
            Log.json(deletedDiscount, label: "Response (Discounts.delete)")

            Log.section("Done")
            Log.success("Discount demo finished successfully.")

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
