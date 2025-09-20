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
}
