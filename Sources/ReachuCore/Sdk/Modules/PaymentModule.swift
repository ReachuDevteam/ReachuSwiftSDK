import Foundation

public final class PaymentRepositoryGQL: PaymentRepository {
    private let client: GraphQLHTTPClient
    public init(client: GraphQLHTTPClient) { self.client = client }

    public func getAvailableMethods() async throws -> [GetAvailablePaymentMethodsDto] {
        let res = try await client.runQuerySafe(
            query: PaymentGraphQL.GET_AVAILABLE_METHODS_PAYMENT_QUERY,
            variables: [:]
        )
        guard
            let list: [Any] = GraphQLPick.pickPath(
                res.data, path: ["Payment", "GetAvailablePaymentMethods"])
        else {
            throw SdkException(
                "Empty response in Payment.getAvailableMethods", code: "EMPTY_RESPONSE")
        }
        let data = try JSONSerialization.data(withJSONObject: list, options: [])
        return try JSONDecoder().decode([GetAvailablePaymentMethodsDto].self, from: data)
    }

    public func stripeIntent(checkoutId: String, returnEphemeralKey: Bool?) async throws
        -> PaymentIntentStripeDto
    {
        try Validation.requireNonEmpty(checkoutId, field: "checkoutId")

        var vars: [String: Any?] = [
            "checkoutId": checkoutId,
            "returnEphemeralKey": returnEphemeralKey,
        ]

        let res = try await client.runMutationSafe(
            query: PaymentGraphQL.STRIPE_INTENT_PAYMENT_MUTATION,
            variables: vars.compactMapValues { $0 }
        )
        guard
            let obj: [String: Any] = GraphQLPick.pickPath(
                res.data, path: ["Payment", "CreatePaymentIntentStripe"])
        else {
            throw SdkException("Empty response in Payment.stripeIntent", code: "EMPTY_RESPONSE")
        }
        return try GraphQLPick.decodeJSON(obj, as: PaymentIntentStripeDto.self)
    }

    public func stripeLink(
        checkoutId: String, successUrl: String, paymentMethod: String, email: String
    ) async throws -> InitPaymentStripeDto {
        try Validation.requireNonEmpty(checkoutId, field: "checkoutId")
        try Validation.requireNonEmpty(successUrl, field: "successUrl")
        try Validation.requireNonEmpty(paymentMethod, field: "paymentMethod")
        try Validation.requireNonEmpty(email, field: "email")

        let vars: [String: Any] = [
            "checkoutId": checkoutId,
            "successUrl": successUrl,
            "paymentMethod": paymentMethod,
            "email": email,
        ]
        let res = try await client.runMutationSafe(
            query: PaymentGraphQL.STRIPE_PLATFORM_BUILDER_PAYMENT_MUTATION,
            variables: vars
        )
        guard
            let obj: [String: Any] = GraphQLPick.pickPath(
                res.data, path: ["Payment", "CreatePaymentStripe"])
        else {
            throw SdkException("Empty response in Payment.stripeLink", code: "EMPTY_RESPONSE")
        }
        return try GraphQLPick.decodeJSON(obj, as: InitPaymentStripeDto.self)
    }

    public func klarnaInit(checkoutId: String, countryCode: String, href: String, email: String?)
        async throws -> InitPaymentKlarnaDto
    {
        try Validation.requireNonEmpty(checkoutId, field: "checkoutId")
        try Validation.requireCountry(countryCode)
        try Validation.requireNonEmpty(href, field: "href")
        if let e = email, e.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw ValidationException(
                "email cannot be empty when provided", details: ["field": "email"])
        }

        let vars: [String: Any] = [
            "checkoutId": checkoutId,
            "countryCode": countryCode,
            "href": href,
            "email": email ?? "",
        ]
        let res = try await client.runMutationSafe(
            query: PaymentGraphQL.KLARNA_PLATFORM_BUILDER_PAYMENT_MUTATION,
            variables: vars
        )
        guard
            let obj: [String: Any] = GraphQLPick.pickPath(
                res.data, path: ["Payment", "CreatePaymentKlarna"])
        else {
            throw SdkException("Empty response in Payment.klarnaInit", code: "EMPTY_RESPONSE")
        }
        return try GraphQLPick.decodeJSON(obj, as: InitPaymentKlarnaDto.self)
    }

    public func vippsInit(checkoutId: String, email: String, returnUrl: String) async throws
        -> InitPaymentVippsDto
    {
        try Validation.requireNonEmpty(checkoutId, field: "checkoutId")
        try Validation.requireNonEmpty(email, field: "email")
        try Validation.requireNonEmpty(returnUrl, field: "returnUrl")

        let vars: [String: Any] = [
            "checkoutId": checkoutId,
            "email": email,
            "returnUrl": returnUrl,
        ]
        let res = try await client.runMutationSafe(
            query: PaymentGraphQL.VIPPS_PAYMENT,
            variables: vars
        )
        guard
            let obj: [String: Any] = GraphQLPick.pickPath(
                res.data, path: ["Payment", "CreatePaymentVipps"])
        else {
            throw SdkException("Empty response in Payment.vippsInit", code: "EMPTY_RESPONSE")
        }
        return try GraphQLPick.decodeJSON(obj, as: InitPaymentVippsDto.self)
    }

    public func klarnaNativeInit(
        checkoutId: String,
        input: KlarnaNativeInitInputDto
    ) async throws -> InitPaymentKlarnaNativeDto {
        print("🌐🌐🌐 [ReachuCore.PaymentModule] klarnaNativeInit LLAMADO")
        print("🌐 checkoutId: \(checkoutId)")
        print("🌐 countryCode: \(input.countryCode ?? "nil")")
        print("🌐 currency: \(input.currency ?? "nil")")
        print("🌐 locale: \(input.locale ?? "nil")")
        print("🌐 returnUrl: \(input.returnUrl ?? "nil")")
        print("🌐 customer.email: \(input.customer?.email ?? "nil")")
        
        try Validation.requireNonEmpty(checkoutId, field: "checkoutId")
        if let country = input.countryCode { try Validation.requireCountry(country) }
        if let currency = input.currency { try Validation.requireCurrency(currency) }
        if let url = input.returnUrl,
            url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        {
            throw ValidationException(
                "returnUrl cannot be empty when provided", details: ["field": "returnUrl"])
        }

        var vars: [String: Any?] = [
            "checkoutId": checkoutId,
            "countryCode": input.countryCode,
            "currency": input.currency,
            "locale": input.locale,
            "returnUrl": input.returnUrl,
            "intent": input.intent,
            "autoCapture": input.autoCapture,
        ]
        if let customer = input.customer {
            vars["customer"] = try encodeToDictionary(customer)
        }
        if let billing = input.billingAddress {
            vars["billingAddress"] = try encodeToDictionary(billing)
        }
        if let shipping = input.shippingAddress {
            vars["shippingAddress"] = try encodeToDictionary(shipping)
        }

        print("🌐 [ReachuCore] Enviando mutation a backend Reachu...")
        print("🌐 Variables: \(vars.compactMapValues { $0 })")
        
        let res = try await client.runMutationSafe(
            query: PaymentGraphQL.KLARNA_NATIVE_INIT_PAYMENT_MUTATION,
            variables: vars.compactMapValues { $0 }
        )
        
        print("🌐 [ReachuCore] Backend respondió")
        if let dataKeys = res.data?.keys {
            print("🌐 Response data keys: \(dataKeys)")
        } else {
            print("🌐 Response data es nil")
        }
        
        guard
            let obj: [String: Any] = GraphQLPick.pickPath(
                res.data, path: ["Payment", "CreatePaymentKlarnaNative"])
        else {
            print("❌❌❌ [ReachuCore] ERROR: Empty response from backend")
            print("❌ res.data: \(res.data)")
            throw SdkException("Empty response in Payment.klarnaNativeInit", code: "EMPTY_RESPONSE")
        }
        
        print("✅ [ReachuCore] Decodificando respuesta...")
        let dto = try GraphQLPick.decodeJSON(obj, as: InitPaymentKlarnaNativeDto.self)
        print("✅✅✅ [ReachuCore] DTO decodificado correctamente")
        print("✅ sessionId: \(dto.sessionId)")
        print("✅ checkoutId: \(dto.checkoutId)")
        return dto
    }

    public func klarnaNativeConfirm(
        checkoutId: String,
        input: KlarnaNativeConfirmInputDto
    ) async throws -> ConfirmPaymentKlarnaNativeDto {
        try Validation.requireNonEmpty(checkoutId, field: "checkoutId")
        try Validation.requireNonEmpty(input.authorizationToken, field: "authorizationToken")

        var vars: [String: Any?] = [
            "checkoutId": checkoutId,
            "authorizationToken": input.authorizationToken,
            "autoCapture": input.autoCapture,
        ]
        if let customer = input.customer {
            vars["customer"] = try encodeToDictionary(customer)
        }
        if let billing = input.billingAddress {
            vars["billingAddress"] = try encodeToDictionary(billing)
        }
        if let shipping = input.shippingAddress {
            vars["shippingAddress"] = try encodeToDictionary(shipping)
        }

        let res = try await client.runMutationSafe(
            query: PaymentGraphQL.KLARNA_NATIVE_CONFIRM_PAYMENT_MUTATION,
            variables: vars.compactMapValues { $0 }
        )
        guard
            let obj: [String: Any] = GraphQLPick.pickPath(
                res.data, path: ["Payment", "ConfirmPaymentKlarnaNative"])
        else {
            throw SdkException("Empty response in Payment.klarnaNativeConfirm", code: "EMPTY_RESPONSE")
        }
        return try GraphQLPick.decodeJSON(obj, as: ConfirmPaymentKlarnaNativeDto.self)
    }

    public func klarnaNativeOrder(orderId: String, userId: String?) async throws -> KlarnaNativeOrderDto {
        try Validation.requireNonEmpty(orderId, field: "orderId")
        if let uid = userId, uid.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw ValidationException(
                "userId cannot be empty when provided", details: ["field": "userId"])
        }

        let res = try await client.runQuerySafe(
            query: PaymentGraphQL.KLARNA_NATIVE_ORDER_QUERY,
            variables: [
                "orderId": orderId,
                "userId": userId?.trimmingCharacters(in: .whitespacesAndNewlines),
            ].compactMapValues { $0 }
        )
        guard
            let obj: [String: Any] = GraphQLPick.pickPath(
                res.data, path: ["Payment", "GetKlarnaOrderNative"])
        else {
            throw SdkException("Empty response in Payment.klarnaNativeOrder", code: "EMPTY_RESPONSE")
        }
        return try GraphQLPick.decodeJSON(obj, as: KlarnaNativeOrderDto.self)
    }

    private func encodeToDictionary<T: Encodable>(_ value: T) throws -> [String: Any] {
        let encoder = JSONEncoder()
        let data = try encoder.encode(value)
        guard
            let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            throw SdkException("Failed to encode input as dictionary", code: "ENCODING_ERROR")
        }
        return dict
    }
}
