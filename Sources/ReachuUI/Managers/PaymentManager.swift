import Foundation
import ReachuCore

@MainActor
extension CartManager {

    @discardableResult
    public func initKlarna(countryCode: String, href: String, email: String?) async
        -> InitPaymentKlarnaDto?
    {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let id: String?
        if let passed = checkoutId, !passed.isEmpty {
            id = passed
        } else {
            id = await createCheckout()
        }

        guard let checkout = id else {
            print("ℹ️ [Payment] KlarnaInit: missing checkoutId")
            return nil
        }

        print("💳 [Payment] KlarnaInit START checkoutId=\(checkout)")
        do {
            logRequest(
                "sdk.payment.klarnaInit",
                payload: [
                    "checkoutId": checkout,
                    "countryCode": countryCode,
                    "href": href,
                    "email": email as Any
                ]
            )
            let dto = try await sdk.payment.klarnaInit(
                checkoutId: checkout,
                countryCode: countryCode,
                href: href,
                email: email
            )
            logResponse("sdk.payment.klarnaInit")
            print("✅ [Payment] KlarnaInit OK")
            return dto
        } catch {
            let msg = (error as? SdkException)?.description ?? error.localizedDescription
            errorMessage = msg
            logError("sdk.payment.klarnaInit", error: error)
            print("❌ [Payment] KlarnaInit FAIL \(msg)")
            return nil
        }
    }

    @discardableResult
    public func initKlarnaNative(
        input: KlarnaNativeInitInputDto
    ) async -> InitPaymentKlarnaNativeDto? {
        print("🚀🚀🚀 [PaymentManager.initKlarnaNative] MÉTODO LLAMADO")
        print("🚀 Thread: \(Thread.current)")
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let id: String?
        if let passed = checkoutId, !passed.isEmpty {
            id = passed
        } else {
            id = await createCheckout()
        }

        guard let checkout = id, !checkout.isEmpty else {
            print("❌❌❌ [Payment] KlarnaNativeInit: missing checkoutId")
            print("❌❌❌ [Payment] checkoutId actual: \(String(describing: checkoutId))")
            print("❌❌❌ [Payment] id después de createCheckout: \(String(describing: id))")
            return nil
        }

        print("💳💳💳 [Payment] KlarnaNativeInit START")
        print("💳 checkoutId: \(checkout)")
        print("💳 input.countryCode: \(input.countryCode)")
        print("💳 input.currency: \(input.currency)")
        print("💳 input.locale: \(input.locale)")
        print("💳 input.customer.email: \(input.customer?.email ?? "nil")")
        print("💳 input.customer.phone: \(input.customer?.phone ?? "nil")")
        do {
            logRequest(
                "sdk.payment.klarnaNativeInit",
                payload: [
                    "checkoutId": checkout,
                    "autoCapture": input.autoCapture as Any
                ]
            )
            let dto = try await sdk.payment.klarnaNativeInit(
                checkoutId: checkout,
                input: input
            )
            checkoutId = dto.checkoutId
            logResponse(
                "sdk.payment.klarnaNativeInit",
                payload: ["sessionId": dto.sessionId, "checkoutId": dto.checkoutId]
            )
            print("✅ [Payment] KlarnaNativeInit OK sessionId=\(dto.sessionId)")
            return dto
        } catch {
            let msg = (error as? SdkException)?.description ?? error.localizedDescription
            errorMessage = msg
            logError("sdk.payment.klarnaNativeInit", error: error)
            print("❌❌❌ [Payment] KlarnaNativeInit FAIL")
            print("❌ Error type: \(type(of: error))")
            print("❌ Error message: \(msg)")
            print("❌ Full error: \(error)")
            if let sdkError = error as? SdkException {
                print("❌ SdkException description: \(sdkError.description)")
            }
            return nil
        }
    }

    @discardableResult
    public func confirmKlarnaNative(
        authorizationToken: String,
        autoCapture: Bool? = nil,
        customer: KlarnaNativeCustomerInputDto? = nil,
        billingAddress: KlarnaNativeAddressInputDto? = nil,
        shippingAddress: KlarnaNativeAddressInputDto? = nil
    ) async -> ConfirmPaymentKlarnaNativeDto? {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let id: String?
        if let passed = checkoutId, !passed.isEmpty {
            id = passed
        } else {
            id = await createCheckout()
        }

        guard let checkout = id, !checkout.isEmpty else {
            print("ℹ️ [Payment] KlarnaNativeConfirm: missing checkoutId")
            return nil
        }

        let input = KlarnaNativeConfirmInputDto(
            authorizationToken: authorizationToken,
            autoCapture: autoCapture,
            customer: customer,
            billingAddress: billingAddress,
            shippingAddress: shippingAddress
        )

        print("💳 [Payment] KlarnaNativeConfirm START checkoutId=\(checkout)")
        do {
            logRequest(
                "sdk.payment.klarnaNativeConfirm",
                payload: [
                    "checkoutId": checkout,
                    "authorizationToken": authorizationToken
                ]
            )
            let dto = try await sdk.payment.klarnaNativeConfirm(
                checkoutId: checkout,
                input: input
            )
            logResponse(
                "sdk.payment.klarnaNativeConfirm",
                payload: ["orderId": dto.orderId as Any]
            )
            print("✅ [Payment] KlarnaNativeConfirm OK orderId=\(dto.orderId)")
            return dto
        } catch {
            let msg = (error as? SdkException)?.description ?? error.localizedDescription
            errorMessage = msg
            logError("sdk.payment.klarnaNativeConfirm", error: error)
            print("❌ [Payment] KlarnaNativeConfirm FAIL \(msg)")
            return nil
        }
    }

    public func klarnaNativeOrder(
        orderId: String,
        userId: String? = nil
    ) async -> KlarnaNativeOrderDto? {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        print("🔍 [Payment] KlarnaNativeOrder START orderId=\(orderId)")
        do {
            logRequest(
                "sdk.payment.klarnaNativeOrder",
                payload: ["orderId": orderId, "userId": userId as Any]
            )
            let dto = try await sdk.payment.klarnaNativeOrder(
                orderId: orderId,
                userId: userId
            )
            logResponse(
                "sdk.payment.klarnaNativeOrder",
                payload: ["status": dto.status as Any]
            )
            print("✅ [Payment] KlarnaNativeOrder OK status=\(dto.status ?? "-")")
            return dto
        } catch {
            let msg = (error as? SdkException)?.description ?? error.localizedDescription
            errorMessage = msg
            logError("sdk.payment.klarnaNativeOrder", error: error)
            print("❌ [Payment] KlarnaNativeOrder FAIL \(msg)")
            return nil
        }
    }

    @discardableResult
    public func stripeIntent(returnEphemeralKey: Bool? = true) async -> PaymentIntentStripeDto? {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let id: String?
        if let passed = checkoutId, !passed.isEmpty {
            id = passed
        } else {
            id = await createCheckout()
        }

        guard let checkout = id else {
            print("ℹ️ [Payment] StripeIntent: missing checkoutId")
            return nil
        }

        print("💳 [Payment] StripeIntent START checkoutId=\(checkout)")
        do {
            logRequest(
                "sdk.payment.stripeIntent",
                payload: [
                    "checkoutId": checkout,
                    "returnEphemeralKey": returnEphemeralKey as Any
                ]
            )
            let dto = try await sdk.payment.stripeIntent(
                checkoutId: checkout,
                returnEphemeralKey: returnEphemeralKey
            )
            logResponse(
                "sdk.payment.stripeIntent",
                payload: ["clientSecret": dto.clientSecret as Any]
            )
            print("✅ [Payment] StripeIntent OK")
            return dto
        } catch {
            let msg = (error as? SdkException)?.description ?? error.localizedDescription
            errorMessage = msg
            logError("sdk.payment.stripeIntent", error: error)
            print("❌ [Payment] StripeIntent FAIL \(msg)")
            return nil
        }
    }

    @discardableResult
    public func stripeLink(
        successUrl: String,
        paymentMethod: String,
        email: String
    ) async -> InitPaymentStripeDto? {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let id: String?
        if let passed = checkoutId, !passed.isEmpty {
            id = passed
        } else {
            id = await createCheckout()
        }

        guard let checkout = id else {
            print("ℹ️ [Payment] StripeLink: missing checkoutId")
            return nil
        }

        print("💳 [Payment] StripeLink START checkoutId=\(checkout)")
        do {
            logRequest(
                "sdk.payment.stripeLink",
                payload: [
                    "checkoutId": checkout,
                    "successUrl": successUrl,
                    "paymentMethod": paymentMethod,
                    "email": email
                ]
            )
            let dto = try await sdk.payment.stripeLink(
                checkoutId: checkout,
                successUrl: successUrl,
                paymentMethod: paymentMethod,
                email: email
            )
            logResponse("sdk.payment.stripeLink")
            print("✅ [Payment] StripeLink OK")
            return dto
        } catch {
            let msg = (error as? SdkException)?.description ?? error.localizedDescription
            errorMessage = msg
            logError("sdk.payment.stripeLink", error: error)
            print("❌ [Payment] StripeLink FAIL \(msg)")
            return nil
        }
    }

    @discardableResult
    public func vippsInit(
        email: String,
        returnUrl: String
    ) async -> InitPaymentVippsDto? {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let id: String?
        if let passed = checkoutId, !passed.isEmpty {
            id = passed
        } else {
            id = await createCheckout()
        }

        guard let checkout = id else {
            print("ℹ️ [Payment] VippsInit: missing checkoutId")
            return nil
        }

        print("💳 [Payment] VippsInit START checkoutId=\(checkout)")
        do {
            logRequest(
                "sdk.payment.vippsInit",
                payload: [
                    "checkoutId": checkout,
                    "email": email,
                    "returnUrl": returnUrl
                ]
            )
            let dto = try await sdk.payment.vippsInit(
                checkoutId: checkout,
                email: email,
                returnUrl: returnUrl
            )
            logResponse("sdk.payment.vippsInit")
            print("✅ [Payment] VippsInit OK")
            return dto
        } catch {
            let msg = (error as? SdkException)?.description ?? error.localizedDescription
            errorMessage = msg
            logError("sdk.payment.vippsInit", error: error)
            print("❌ [Payment] VippsInit FAIL \(msg)")
            return nil
        }
    }
}
