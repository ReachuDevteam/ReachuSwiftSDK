import Foundation
import ReachuCore
import ReachuDemoKit

@main
struct PaymentDemo {
    static func checkoutId<T: Encodable>(_ dto: T) -> String? {
        guard
            let data = try? JSONEncoder().encode(dto),
            let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }
        return (dict["checkout_id"] as? String)
            ?? (dict["checkoutId"] as? String)
            ?? (dict["id"] as? String)
    }

    static func main() async {
        let API_TOKEN = "THVXN06-MGB4D4P-KCPRCKP-RHGT6VJ"
        let BASE_URL = URL(string: "https://graph-ql-dev.reachu.io/graphql")!

        let CURRENCY = "NOK"
        let COUNTRY = "NO"
        let EMAIL = "demo@acme.test"
        let COUNTRY_NAME = "Norway"
        let PHONE_CODE = "47"
        let SUCCESS_URL = "https://dev.reachu.io/demo/success"
        let CANCEL_URL = "https://dev.reachu.io/demo/cancel"

        let PRODUCT_ID: Int = 397968
        let QUANTITY: Int = 1

        let STRIPE_LINK_METHOD = "card"

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
            [
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
            let (createdCart, _) = try await Log.measure("CreateCart") {
                try await sdk.cart.create(
                    customer_session_id: sessionId,
                    currency: CURRENCY,
                    shippingCountry: COUNTRY
                )
            }
            Log.json(createdCart, label: "Response (CreateCart)")
            var cartId = createdCart.cartId

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

            Log.section("Apply cheapest shipping per supplier")
            var updated = 0
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
                    if li.shipping?.id == cheapestId { continue }
                    _ = try await sdk.cart.updateItem(
                        cart_id: cartId,
                        cart_item_id: li.id,
                        shipping_id: cheapestId,
                        quantity: nil
                    )
                    updated += 1
                }
            }
            Log.info("Shipping updated for \(updated) item(s).")

            Log.section("Checkout.create")
            let (createdCheckout, _) = try await Log.measure("Checkout.create") {
                try await sdk.checkout.create(cart_id: cartId)
            }
            Log.json(createdCheckout, label: "Response (Checkout.create)")

            guard let checkoutId = checkoutId(createdCheckout), !checkoutId.isEmpty else {
                throw SdkException("Cannot extract checkout_id", code: "MISSING_ID")
            }

            let addr = makeAddress(
                first: "Ola", last: "Nordmann",
                phone: "41234567",
                address1: "Karl Johans gate 1",
                address2: "Suite 2",
                city: "Oslo",
                countryName: COUNTRY_NAME, countryCode: COUNTRY,
                province: "", provinceCode: "",
                zip: "0154",
                company: "ACME AS",
                email: EMAIL,
                phoneCode: PHONE_CODE
            )

            Log.section("Checkout.update")
            let (updatedCheckout, _) = try await Log.measure("Checkout.update") {
                try await sdk.checkout.update(
                    checkout_id: checkoutId,
                    status: nil,
                    email: EMAIL,
                    success_url: SUCCESS_URL,
                    cancel_url: CANCEL_URL,
                    payment_method: nil,
                    shipping_address: addr,
                    billing_address: addr,
                    buyer_accepts_terms_conditions: true,
                    buyer_accepts_purchase_conditions: true
                )
            }
            Log.json(updatedCheckout, label: "Response (Checkout.update)")

            Log.section("Payment.getAvailableMethods")
            let (methods, _) = try await Log.measure("Payment.getAvailableMethods") {
                try await sdk.payment.getAvailableMethods()
            }
            Log.json(methods, label: "Response (Payment.getAvailableMethods)")

            do {
                Log.section("Payment.stripeIntent")
                let (intent, _) = try await Log.measure("Payment.stripeIntent") {
                    try await sdk.payment.stripeIntent(
                        checkoutId: checkoutId, returnEphemeralKey: true)
                }
                Log.json(intent, label: "Response (Payment.stripeIntent)")
            } catch {
                Log.warn(
                    "Stripe Intent failed: \((error as? SdkException)?.description ?? error.localizedDescription)"
                )
            }

            do {
                Log.section("Payment.stripeLink")
                let (stripeInit, _) = try await Log.measure("Payment.stripeLink") {
                    try await sdk.payment.stripeLink(
                        checkoutId: checkoutId,
                        successUrl: SUCCESS_URL,
                        paymentMethod: STRIPE_LINK_METHOD,
                        email: EMAIL
                    )
                }
                Log.json(stripeInit, label: "Response (Payment.stripeLink)")
            } catch {
                Log.warn(
                    "Stripe Link failed: \((error as? SdkException)?.description ?? error.localizedDescription)"
                )
            }

            do {
                Log.section("Payment.klarnaInit")
                let (klarna, _) = try await Log.measure("Payment.klarnaInit") {
                    try await sdk.payment.klarnaInit(
                        checkoutId: checkoutId,
                        countryCode: COUNTRY,
                        href: SUCCESS_URL,
                        email: EMAIL
                    )
                }
                Log.json(klarna, label: "Response (Payment.klarnaInit)")
            } catch {
                Log.warn(
                    "Klarna init failed: \((error as? SdkException)?.description ?? error.localizedDescription)"
                )
            }

            do {
                Log.section("Payment.vippsInit")
                let (vipps, _) = try await Log.measure("Payment.vippsInit") {
                    try await sdk.payment.vippsInit(
                        checkoutId: checkoutId,
                        email: EMAIL,
                        returnUrl: SUCCESS_URL
                    )
                }
                Log.json(vipps, label: "Response (Payment.vippsInit)")
            } catch {
                Log.warn(
                    "Vipps init failed: \((error as? SdkException)?.description ?? error.localizedDescription)"
                )
            }

            Log.section("Done")
            Log.success("Payment demo finished successfully.")

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
