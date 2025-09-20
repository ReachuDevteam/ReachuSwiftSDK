import Foundation

public protocol PaymentRepository {
    func getAvailableMethods() async throws -> [GetAvailablePaymentMethodsDto]

    func stripeIntent(
        checkoutId: String,
        returnEphemeralKey: Bool?
    ) async throws -> PaymentIntentStripeDto

    func stripeLink(
        checkoutId: String,
        successUrl: String,
        paymentMethod: String,
        email: String
    ) async throws -> InitPaymentStripeDto

    func klarnaInit(
        checkoutId: String,
        countryCode: String,
        href: String,
        email: String?
    ) async throws -> InitPaymentKlarnaDto

    func vippsInit(
        checkoutId: String,
        email: String,
        returnUrl: String
    ) async throws -> InitPaymentVippsDto
}
