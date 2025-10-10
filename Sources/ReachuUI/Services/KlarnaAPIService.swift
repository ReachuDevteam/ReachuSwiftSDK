import Foundation

/// Service to interact directly with Klarna Payments API.
/// ⚠️ Credentials are hard-coded for demonstration purposes.
final class KlarnaAPIService {

    // MARK: - Credentials

    private let username = "f4db48cb-b9a8-4933-abbe-39a9fadcd12f"
    private let password =
        "klarna_live_api_VWtxaE5QTzBZKlZ6bylnRDZ5SWpyaFZqU1QlKXl0U20sZjRkYjQ4Y2ItYjlhOC00OTMzLWFiYmUtMzlhOWZhZGNkMTJmLDEsQ200S2hxTmNNQXorN0E5bnlWSVpaUWNUbTFRM0l0dDZodUZ2aXlpUDJ2Zz0"

    /// Use `https://api.playground.klarna.com` for sandbox,
    /// `https://api.klarna.com` for production.
    private let baseURL = "https://api.klarna.com"

    // MARK: - Session DTOs

    struct CreateSessionRequest: Codable {
        let intent: String = "buy"
        let purchase_country: String
        let purchase_currency: String
        let locale: String
        let order_amount: Int
        let order_tax_amount: Int
        let order_lines: [OrderLine]
        let merchant_urls: MerchantUrls?

        struct OrderLine: Codable {
            let type: String = "physical"
            let reference: String
            let name: String
            let quantity: Int
            let unit_price: Int
            let tax_rate: Int
            let total_amount: Int
            let total_tax_amount: Int
        }

        struct MerchantUrls: Codable {
            let confirmation: String
            let notification: String?
        }
    }

    struct CreateSessionResponse: Codable {
        let client_token: String
        let session_id: String
        let payment_method_categories: [PaymentMethodCategory]?

        struct PaymentMethodCategory: Codable {
            let identifier: String
            let name: String?
            let asset_urls: AssetUrls?

            struct AssetUrls: Codable {
                let standard: String?
                let descriptive: String?
            }
        }
    }

    // MARK: - Order DTOs

    struct CreateOrderRequest: Codable {
        let purchase_country: String
        let purchase_currency: String
        let locale: String
        let order_amount: Int
        let order_tax_amount: Int
        let order_lines: [OrderLine]
        let merchant_reference1: String?
        let merchant_reference2: String?

        struct OrderLine: Codable {
            let type: String = "physical"
            let reference: String
            let name: String
            let quantity: Int
            let unit_price: Int
            let tax_rate: Int
            let total_amount: Int
            let total_tax_amount: Int
        }
    }

    struct CreateOrderResponse: Codable {
        let order_id: String
        let fraud_status: String
        let authorized_payment_method: AuthorizedPaymentMethod?
        let redirect_url: String?

        struct AuthorizedPaymentMethod: Codable {
            let type: String
            let number_of_installments: Int?
        }
    }

    struct KlarnaError: Codable {
        let error_code: String
        let error_messages: [String]
        let correlation_id: String?
    }

    // MARK: - API Methods

    func createSession(
        country: String = "US",
        currency: String = "USD",
        locale: String = "en-US",
        amount: Int = 5000,
        productName: String = "Test Product"
    ) async throws -> CreateSessionResponse {
        let url = URL(string: "\(baseURL)/payments/v1/sessions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        setAuthHeaders(on: &request)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let sessionRequest = CreateSessionRequest(
            purchase_country: country,
            purchase_currency: currency,
            locale: locale,
            order_amount: amount,
            order_tax_amount: 0,
            order_lines: [
                .init(
                    reference: "PROD-001",
                    name: productName,
                    quantity: 1,
                    unit_price: amount,
                    tax_rate: 0,
                    total_amount: amount,
                    total_tax_amount: 0
                )
            ],
            merchant_urls: .init(
                confirmation: "https://example.com/confirmation",
                notification: nil
            )
        )

        request.httpBody = try JSONEncoder().encode(sessionRequest)

        print("🔵 [Klarna API] Creating session…")
        let data = try await send(request: request)

        return try decode(CreateSessionResponse.self, from: data)
    }

    func createOrder(
        authorizationToken: String,
        country: String = "US",
        currency: String = "USD",
        locale: String = "en-US",
        amount: Int = 5000,
        productName: String = "Test Product"
    ) async throws -> CreateOrderResponse {
        let url = URL(string: "\(baseURL)/payments/v1/authorizations/\(authorizationToken)/order")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        setAuthHeaders(on: &request)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let orderRequest = CreateOrderRequest(
            purchase_country: country,
            purchase_currency: currency,
            locale: locale,
            order_amount: amount,
            order_tax_amount: 0,
            order_lines: [
                .init(
                    reference: "PROD-001",
                    name: productName,
                    quantity: 1,
                    unit_price: amount,
                    tax_rate: 0,
                    total_amount: amount,
                    total_tax_amount: 0
                )
            ],
            merchant_reference1: "ORDER-\(UUID().uuidString.prefix(8))",
            merchant_reference2: nil
        )

        request.httpBody = try JSONEncoder().encode(orderRequest)

        print("🔵 [Klarna API] Creating order…")
        let data = try await send(request: request)

        return try decode(CreateOrderResponse.self, from: data)
    }

    // MARK: - Helpers

    private func setAuthHeaders(on request: inout URLRequest) {
        let credentials = "\(username):\(password)"
        let base64 = Data(credentials.utf8).base64EncodedString()
        request.setValue("Basic \(base64)", forHTTPHeaderField: "Authorization")
    }

    private func send(request: URLRequest) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(
                domain: "KlarnaAPIService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid HTTP response"]
            )
        }

        guard 200 ... 299 ~= httpResponse.statusCode else {
            if let klarnaError = try? JSONDecoder().decode(KlarnaError.self, from: data) {
                throw NSError(
                    domain: "KlarnaAPIService",
                    code: httpResponse.statusCode,
                    userInfo: [
                        NSLocalizedDescriptionKey: klarnaError.error_messages.joined(separator: ", "),
                        "error_code": klarnaError.error_code,
                        "correlation_id": klarnaError.correlation_id ?? ""
                    ]
                )
            }
            let fallback = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(
                domain: "KlarnaAPIService",
                code: httpResponse.statusCode,
                userInfo: [NSLocalizedDescriptionKey: fallback]
            )
        }

        return data
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        try JSONDecoder().decode(T.self, from: data)
    }
}
