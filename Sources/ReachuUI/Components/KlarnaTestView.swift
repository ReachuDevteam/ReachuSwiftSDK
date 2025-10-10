#if os(iOS) && canImport(KlarnaMobileSDK)
import SwiftUI
import Combine
import KlarnaMobileSDK

/// Standalone Klarna test view that mirrors the working example exactly.
@available(iOS 15.0, *)
public struct KlarnaTestView: View {
    @StateObject private var viewModel = KlarnaTestViewModel()

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                header
                productDetails
                if let message = viewModel.statusMessage {
                    statusBanner(message, isError: viewModel.isError)
                }
                actionButton
                if let clientToken = viewModel.clientToken {
                    KlarnaPaymentViewWrapper(
                        category: "pay_later",
                        clientToken: clientToken,
                        returnUrl: viewModel.returnUrlScheme,
                        eventListener: viewModel,
                        viewModel: viewModel
                    )
                    .frame(width: 0, height: 0)
                    .opacity(0)
                }
                Spacer()
            }
            .padding(.vertical, 24)
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text("Klarna Payment Test")
                .font(.title)
                .fontWeight(.bold)
                .padding(.top, 40)

            Text("Native View Integration")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Divider()
                .padding(.horizontal)
        }
    }

    private var productDetails: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Product Details")
                .font(.headline)

            detailRow(label: "Product:", value: viewModel.productName)
            detailRow(label: "Price:", value: "\(viewModel.formattedAmount) NOK")
            detailRow(label: "Quantity:", value: "1")
            detailRow(label: "Environment:", value: "Production", color: .red)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    private func detailRow(label: String, value: String, color: Color = .primary) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }

    private func statusBanner(_ message: String, isError: Bool) -> some View {
        Text(message)
            .font(.caption)
            .foregroundColor(isError ? .red : .blue)
            .padding()
            .frame(maxWidth: .infinity)
            .background((isError ? Color.red : Color.blue).opacity(0.1))
            .cornerRadius(8)
            .padding(.horizontal)
    }

    private var actionButton: some View {
        Button {
            Task { await viewModel.initializeAndAuthorizePayment() }
        } label: {
            HStack {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "creditcard")
                }
                Text(viewModel.isLoading ? "Processing..." : "Pay with Klarna")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(viewModel.isLoading ? Color.gray : Color.pink)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(viewModel.isLoading)
        .padding(.horizontal)
    }
}

// MARK: - View Model

@available(iOS 15.0, *)
final class KlarnaTestViewModel: NSObject, ObservableObject {

    // UI state
    @Published var isLoading = false
    @Published var statusMessage: String?
    @Published var isError = false
    @Published var showPaymentView = false
    @Published var isPaymentViewReady = false

    var paymentView: KlarnaPaymentView?
    var clientToken: String?
    private var sessionId: String?
    private var authToken: String?
    private let apiService = KlarnaAPIService()

    // Test product configuration
    let productName = "iPhone 15 Pro Max"
    let productAmountMinor = 50_000 // 500 NOK
    let currency = "NOK"
    let country = "NO"
    let locale = "en-NO"
    let returnUrlScheme = "klarnatest://"

    var formattedAmount: String {
        String(format: "%.2f", Double(productAmountMinor) / 100.0)
    }

    // MARK: - Payment flow

    func initializePayment() async {
        isLoading = true
        isError = false
        statusMessage = "🔄 Creating Klarna payment session..."

        do {
            let response = try await apiService.createSession(
                country: country,
                currency: currency,
                locale: locale,
                amount: productAmountMinor,
                productName: productName
            )

            await MainActor.run {
                self.sessionId = response.session_id
                self.clientToken = response.client_token
                self.statusMessage = "✅ Payment session created. Loading payment view..."
                self.showPaymentView = true
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.statusMessage = "❌ Failed to initialize: \(error.localizedDescription)"
                self.isError = true
                self.isLoading = false
            }
        }
    }

    func authorizePayment() {
        guard clientToken != nil else {
            statusMessage = "❌ No client token available"
            isError = true
            return
        }

        guard let paymentView else {
            statusMessage = "❌ Payment view not initialized"
            isError = true
            return
        }

        isLoading = true
        isError = false
        statusMessage = "🔄 Authorizing payment with Klarna..."
        paymentView.authorize(autoFinalize: true, jsonData: nil)
    }

    func initializeAndAuthorizePayment() async {
        await initializePayment()

        guard !isError else { return }

        try? await Task.sleep(nanoseconds: 500_000_000)

        guard let paymentView else {
            statusMessage = "❌ Payment view not ready"
            isError = true
            return
        }

        isLoading = true
        statusMessage = "🔄 Opening Klarna checkout..."
        paymentView.authorize(autoFinalize: true, jsonData: nil)
    }

    func reset() {
        showPaymentView = false
        isPaymentViewReady = false
        clientToken = nil
        authToken = nil
        statusMessage = nil
        isError = false
    }
}

// MARK: - KlarnaPaymentEventListener

@available(iOS 15.0, *)
extension KlarnaTestViewModel: KlarnaPaymentEventListener {

    func klarnaInitialized(paymentView: KlarnaPaymentView) {
        Task { @MainActor in
            statusMessage = "✅ Klarna initialized"
        }
    }

    func klarnaLoaded(paymentView: KlarnaPaymentView) {
        Task { @MainActor in
            isPaymentViewReady = true
            statusMessage = "✅ Ready to authorize payment"
        }
    }

    func klarnaLoadedPaymentReview(paymentView: KlarnaPaymentView) {
        Task { @MainActor in
            statusMessage = "✅ Payment review loaded"
        }
    }

    func klarnaAuthorized(
        paymentView: KlarnaPaymentView,
        approved: Bool,
        authToken: String?,
        finalizeRequired: Bool
    ) {
        Task {
            await MainActor.run {
                self.isLoading = false
            }

            guard approved, let token = authToken else {
                await MainActor.run {
                    self.isError = true
                    self.statusMessage = "❌ Payment not approved"
                }
                return
            }

            await MainActor.run {
                self.authToken = token
                self.statusMessage = "✅ Payment authorized! Creating order..."
            }

            do {
                let order = try await apiService.createOrder(
                    authorizationToken: token,
                    country: country,
                    currency: currency,
                    locale: locale,
                    amount: productAmountMinor,
                    productName: productName
                )
                await MainActor.run {
                    self.statusMessage =
                        "✅ Order created! ID: \(order.order_id) | Fraud: \(order.fraud_status)"
                    self.isError = false
                }
            } catch {
                await MainActor.run {
                    self.isError = true
                    self.statusMessage =
                        "❌ Failed to create order: \(error.localizedDescription)"
                }
            }
        }
    }

    func klarnaReauthorized(paymentView: KlarnaPaymentView, approved: Bool, authToken: String?) {
        Task { @MainActor in
            statusMessage = "✅ Payment reauthorized"
        }
    }

    func klarnaFinalized(paymentView: KlarnaPaymentView, approved: Bool, authToken: String?) {
        Task { @MainActor in
            statusMessage = "✅ Payment finalised"
        }
    }

    func klarnaResized(paymentView: KlarnaPaymentView, to newHeight: CGFloat) {
        // No-op for this test view.
    }

    func klarnaFailed(inPaymentView paymentView: KlarnaPaymentView, withError error: KlarnaPaymentError) {
        Task { @MainActor in
            isError = true
            isLoading = false
            statusMessage = "❌ Error: \(error.message)"
        }
    }
}

// MARK: - UIViewRepresentable Wrapper

@available(iOS 15.0, *)
private struct KlarnaPaymentViewWrapper: UIViewRepresentable {
    let category: String
    let clientToken: String
    let returnUrl: String
    let eventListener: KlarnaPaymentEventListener
    @ObservedObject var viewModel: KlarnaTestViewModel

    func makeUIView(context: Context) -> KlarnaPaymentView {
        let paymentView = KlarnaPaymentView(category: category, eventListener: eventListener)
        paymentView.loggingLevel = .verbose

        if let url = URL(string: returnUrl) {
            paymentView.initialize(clientToken: clientToken, returnUrl: url)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                paymentView.load()
            }
        }

        DispatchQueue.main.async {
            viewModel.paymentView = paymentView
        }

        return paymentView
    }

    func updateUIView(_ uiView: KlarnaPaymentView, context: Context) {
        // No updates needed
    }
}

#if DEBUG
    @available(iOS 15.0, *)
    #Preview {
        KlarnaTestView()
    }
#endif

#endif
