import Foundation
import ReachuCore
import ReachuDemoKit

@main
struct CheckoutDemo {
    static func main() async {
        let API_TOKEN = "THVXN06-MGB4D4P-KCPRCKP-RHGT6VJ"
        let BASE_URL = URL(string: "https://graph-ql-dev.reachu.io/graphql")!

        let CURRENCY = "NOK"
        let COUNTRY = "NO"

        let PRODUCT_ID: Int = 397968
        let VARIANT_ID: Int? = nil
        let QUANTITY: Int = 1

        let EMAIL = "demo@acme.test"
        let COUNTRY_NAME = "Norway"
        let PHONE_CODE = "47"

        let DELETE_CHECKOUT_AT_END = false

        let sessionId = "demo-\(UUID().uuidString)"
        let sdk = SdkClient(baseUrl: BASE_URL, apiKey: API_TOKEN)

        func makeAddress(
            first: String, last: String,
            phone: String,
            address1: String, address2: String,
            city: String,
            countryName: String, countryCode: String,
            province: String, provinceCode: String,
            zip: String,
            company: String?,
            email: String,
            phoneCode: String
        ) -> [String: Any] {
            return [
                "address1": address1,
                "address2": address2,
                "city": city,
                "company": company ?? "",
                "country": countryName,
                "country_code": countryCode,
                "email": email,
                "first_name": first,
                "last_name": last,
                "phone": phone,
                "phone_code": phoneCode,
                "province": province,
                "province_code": provinceCode,
                "zip": zip,
            ]
        }

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
                variantId: VARIANT_ID,
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

            Log.section("Apply cheapest shipping per supplier")
            var totalUpdates = 0
            for group in groups {
                var shippings = group.availableShippings ?? []
                shippings.sort {
                    let a = $0.price.amount ?? Double.greatestFiniteMagnitude
                    let b = $1.price.amount ?? Double.greatestFiniteMagnitude
                    return a < b
                }
                guard let cheapestId = shippings.first?.id, !cheapestId.isEmpty else {
                    Log.warn(
                        "No shippings for supplier \(group.supplier?.name ?? "N/A"). Skipping.")
                    continue
                }
                for li in group.lineItems {
                    if li.shipping?.id == cheapestId { continue }  // skip redundant
                    _ = try await sdk.cart.updateItem(
                        cart_id: cartId,
                        cart_item_id: li.id,
                        shipping_id: cheapestId,
                        quantity: nil
                    )
                    totalUpdates += 1
                }
            }
            Log.info("Shipping updated for \(totalUpdates) item(s).")

            Log.section("Checkout.create")
            let (createdCheckout, _) = try await Log.measure("Checkout.create") {
                try await sdk.checkout.create(cart_id: cartId)
            }
            Log.json(createdCheckout, label: "Response (Checkout.create)")

            let checkoutId: String = {
                let data = try? JSONEncoder().encode(createdCheckout)
                let dict =
                    (data.flatMap { try? JSONSerialization.jsonObject(with: $0) }) as? [String: Any]
                return (dict?["checkout_id"] as? String)
                    ?? (dict?["checkoutId"] as? String)
                    ?? (dict?["id"] as? String)
                    ?? ""
            }()
            guard !checkoutId.isEmpty else {
                throw SdkException(
                    "Cannot extract checkout_id from create response", code: "MISSING_ID")
            }

            let billingAddr: [String: Any] = makeAddress(
                first: "Ola", last: "Nordmann",
                phone: "41234567",
                address1: "Karl Johans gate 1", address2: "Suite 2",
                city: "Oslo",
                countryName: COUNTRY_NAME, countryCode: COUNTRY,
                province: "", provinceCode: "",
                zip: "0154",
                company: "ACME AS",
                email: EMAIL,
                phoneCode: PHONE_CODE
            )

            let shippingAddr = billingAddr

            Log.section("Checkout.update")
            let (updatedCheckout, _) = try await Log.measure("Checkout.update") {
                try await sdk.checkout.update(
                    checkout_id: checkoutId,
                    status: nil,
                    email: EMAIL,
                    success_url: "",
                    cancel_url: "",
                    payment_method: "Klarna",
                    shipping_address: shippingAddr,
                    billing_address: billingAddr,
                    buyer_accepts_terms_conditions: true,
                    buyer_accepts_purchase_conditions: true
                )
            }
            Log.json(updatedCheckout, label: "Response (Checkout.update)")

            Log.section("Checkout.getById")
            let (fetchedCheckout, _) = try await Log.measure("Checkout.getById") {
                try await sdk.checkout.getById(checkout_id: checkoutId)
            }
            Log.json(fetchedCheckout, label: "Response (Checkout.getById)")

            if DELETE_CHECKOUT_AT_END {
                Log.section("Checkout.delete")
                let (deleted, _) = try await Log.measure("Checkout.delete") {
                    try await sdk.checkout.delete(checkout_id: checkoutId)
                }
                Log.json(deleted, label: "Response (Checkout.delete)")
            }

            Log.section("Done")
            Log.success("Checkout demo finished successfully (Flutter parity for keys & flow).")

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
