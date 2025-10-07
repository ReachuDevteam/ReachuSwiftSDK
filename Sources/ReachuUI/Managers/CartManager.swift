import Foundation
import ReachuCore
import ReachuDesignSystem
import ReachuLiveShow
import SwiftUI

#if os(iOS)
    import UIKit
#endif

@MainActor
public class CartManager: ObservableObject, LiveShowCartManaging {

    @Published public var items: [CartItem] = []
    @Published public var isCheckoutPresented = false
    @Published public var isLoading = false
    @Published public var cartTotal: Double = 0.0
    @Published public var currency: String = "USD"
    @Published public var country: String = "US"
    @Published public var errorMessage: String?
    @Published public var cartId: String?
    @Published public var checkoutId: String?
    @Published public var lastDiscountCode: String?
    @Published public var lastDiscountId: Int?
    @Published public var products: [Product] = []
    @Published public var isProductsLoading = false
    @Published public var productsErrorMessage: String?
    @Published public var shippingTotal: Double = 0.0
    @Published public var shippingCurrency: String = "USD"

    private var currentCartId: String?
    private var pendingShippingSelections: [String: CartItem.ShippingOption] = [:]
    private let sdk: SdkClient = {
        let baseURL = URL(string: "https://graph-ql-dev.reachu.io/graphql")!
        let apiKey = "DKCSRFE-1HA439V-GPK24GY-6CT93HB"
        return SdkClient(baseUrl: baseURL, apiKey: apiKey)
    }()

    private struct ShippingSyncData {
        let shippingId: String?
        let shippingName: String?
        let shippingDescription: String?
        let shippingAmount: Double?
        let shippingCurrency: String?
        let options: [CartItem.ShippingOption]
    }

    public init() {
        Task { [currency, country] in
            print(
                "🛒 [Cart] init → scheduling createCart(currency:\(currency), country:\(country))"
            )
            await createCart(currency: currency, country: country)
        }
    }

    public func createCart(currency: String = "USD", country: String = "US")
        async
    {
        if currentCartId != nil {
            print(
                "🛒 [Cart] createCart skipped — existing cartId=\(currentCartId)"
            )
            return
        }
        isLoading = true
        errorMessage = nil

        let session = "ios-\(UUID().uuidString)"
        print(
            "🛒 [Cart] createCart START  session=\(session) currency=\(currency) country=\(country)"
        )

        do {
            let dto = try await sdk.cart.create(
                customer_session_id: session,
                currency: currency,
                shippingCountry: country
            )
            print(
                "✅ [Cart] createCart OK     cartId=\(dto.cartId) items=\(dto.lineItems.count) currency=\(dto.currency)"
            )
            sync(from: dto)
        } catch let e as SdkException {
            self.errorMessage = e.description
            print("❌ [Cart] createCart FAIL  \(e.description)")
        } catch {
            self.errorMessage = error.localizedDescription
            print("❌ [Cart] createCart FAIL  \(error.localizedDescription)")
        }

        isLoading = false
    }

    public func loadProductsIfNeeded() async {
        if !products.isEmpty { return }
        await loadProducts()
    }

    public func reloadProducts() async {
        await loadProducts()
    }

    private func loadProducts(
        currency: String? = nil,
        shippingCountryCode: String? = nil,
        imageSize: String = "large"
    ) async {
        if isProductsLoading { return }
        isProductsLoading = true
        productsErrorMessage = nil

        defer {
            isProductsLoading = false
        }

        do {
            let dtoProducts = try await sdk.channel.product.get(
                currency: currency ?? self.currency,
                imageSize: imageSize,
                barcodeList: nil,
                categoryIds: nil,
                productIds: nil,
                skuList: nil,
                useCache: true,
                shippingCountryCode: shippingCountryCode ?? self.country
            )
            products = dtoProducts.map { $0.toDomainProduct() }
        } catch let sdkError as SdkException {
            productsErrorMessage = sdkError.description
            products = []
        } catch {
            productsErrorMessage = error.localizedDescription
            products = []
        }
    }

    @discardableResult
    public func refreshShippingOptions() async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        guard let cid = await ensureCartIDForCheckout() else {
            print("ℹ️ [Cart] refreshShippingOptions: missing cartId")
            return false
        }

        do {
            let groups = try await sdk.cart.getLineItemsBySupplier(cart_id: cid)
            var shippingData: [String: ShippingSyncData] = [:]

            for group in groups {
                let options: [CartItem.ShippingOption] = (group.availableShippings ?? [])
                    .compactMap { option in
                        guard let id = option.id, !id.isEmpty else { return nil }
                        let amount = option.price.amount ?? 0.0
                        let currency = option.price.currencyCode ?? self.currency
                        return CartItem.ShippingOption(
                            id: id,
                            name: option.name ?? "Shipping",
                            description: option.description,
                            amount: amount,
                            currency: currency
                        )
                    }

                for li in group.lineItems {
                    guard items.contains(where: { $0.id == li.id }) else { continue }

                    let shipping = li.shipping
                    let shippingCurrency = shipping?.price.currencyCode ?? self.currency

                    shippingData[li.id] = ShippingSyncData(
                        shippingId: shipping?.id,
                        shippingName: shipping?.name,
                        shippingDescription: shipping?.description,
                        shippingAmount: shipping?.price.amount,
                        shippingCurrency: shippingCurrency,
                        options: options
                    )
                }
            }

            if !shippingData.isEmpty {
                applyShippingMetadata(shippingData)
            }

            return true

        } catch {
            let msg =
                (error as? SdkException)?.description
                ?? error.localizedDescription
            errorMessage = msg
            print("❌ [Cart] refreshShippingOptions FAIL \(msg)")
            return false
        }
    }

    private func sync(from cart: CartDto) {
        self.currentCartId = cart.cartId
        self.currency = cart.currency
        self.country = cart.shippingCountry ?? self.country

        let mappedItems: [CartItem] = cart.lineItems.map { line in
            let sortedImages = (line.image ?? []).sorted { lhs, rhs in
                let lOrder = lhs.order ?? 0
                let rOrder = rhs.order ?? 0
                return lOrder < rOrder
            }
            let imageUrl = sortedImages.first?.url

            let shipping = line.shipping
            let shippingCurrency = shipping?.price.currencyCode ?? cart.currency
            let availableShippings = (line.availableShippings ?? []).compactMap {
                option -> CartItem.ShippingOption? in
                guard let id = option.id, !id.isEmpty else { return nil }
                let amount = option.price.amount ?? 0.0
                let currency = option.price.currencyCode ?? cart.currency
                return CartItem.ShippingOption(
                    id: id,
                    name: option.name ?? "Shipping",
                    description: option.description,
                    amount: amount,
                    currency: currency
                )
            }

            return CartItem(
                id: line.id,
                productId: line.productId,
                variantId: line.variantId.map { String($0) },
                title: line.title ?? "",
                brand: line.brand,
                imageUrl: imageUrl,
                price: line.price.amount,
                currency: line.price.currencyCode,
                quantity: line.quantity,
                sku: line.sku,
                supplier: line.supplier,
                shippingId: shipping?.id,
                shippingName: shipping?.name,
                shippingDescription: shipping?.description,
                shippingAmount: shipping?.price.amount,
                shippingCurrency: shippingCurrency,
                availableShippings: availableShippings
            )
        }

        self.items = mappedItems
        self.cartTotal = cart.subtotal
        self.shippingTotal = cart.shipping
        self.shippingCurrency =
            mappedItems.first(where: { $0.shippingCurrency != nil })?.shippingCurrency
            ?? cart.currency
    }

    private func _iso8601(_ date: Date = Date()) -> String {
        ISO8601DateFormatter().string(from: date)
    }

    // MARK: - Cart Item Model
    public struct CartItem: Identifiable, Equatable {
        public struct ShippingOption: Identifiable, Equatable {
            public let id: String
            public let name: String
            public let description: String?
            public let amount: Double
            public let currency: String

            public init(
                id: String,
                name: String,
                description: String? = nil,
                amount: Double,
                currency: String
            ) {
                self.id = id
                self.name = name
                self.description = description
                self.amount = amount
                self.currency = currency
            }
        }

        public let id: String
        public let productId: Int
        public let variantId: String?
        public let title: String
        public let brand: String?
        public let imageUrl: String?
        public let price: Double
        public let currency: String
        public var quantity: Int
        public let sku: String?
        public let supplier: String?
        public let shippingId: String?
        public let shippingName: String?
        public let shippingDescription: String?
        public let shippingAmount: Double?
        public let shippingCurrency: String?
        public let availableShippings: [ShippingOption]

        public init(
            id: String,
            productId: Int,
            variantId: String? = nil,
            title: String,
            brand: String? = nil,
            imageUrl: String? = nil,
            price: Double,
            currency: String,
            quantity: Int,
            sku: String? = nil,
            supplier: String? = nil,
            shippingId: String? = nil,
            shippingName: String? = nil,
            shippingDescription: String? = nil,
            shippingAmount: Double? = nil,
            shippingCurrency: String? = nil,
            availableShippings: [ShippingOption] = []
        ) {
            self.id = id
            self.productId = productId
            self.variantId = variantId
            self.title = title
            self.brand = brand
            self.imageUrl = imageUrl
            self.price = price
            self.currency = currency
            self.quantity = quantity
            self.sku = sku
            self.supplier = supplier
            self.shippingId = shippingId
            self.shippingName = shippingName
            self.shippingDescription = shippingDescription
            self.shippingAmount = shippingAmount
            self.shippingCurrency = shippingCurrency
            self.availableShippings = availableShippings
        }
    }

    // MARK: - Public Methods

    /// Add a product to the cart
    public func addProduct(_ product: Product, quantity: Int = 1) async {
        isLoading = true
        errorMessage = nil

        let previousCount = itemCount
        let hadExistingItem = items.contains { $0.productId == product.id }

        do {
            guard let cid = await ensureCartIDForCheckout() else {
                addProductLocally(product, quantity: quantity)
                updateCartTotal()
                ToastManager.shared.showSuccess(
                    hadExistingItem
                        ? "Updated \(product.title) quantity in cart"
                        : "Added \(product.title) to cart"
                )
                isLoading = false
                triggerFeedbackIfNeeded(previousCount: previousCount)
                return
            }

            if let existingItem = items.first(where: { $0.productId == product.id }) {
                let newQuantity = existingItem.quantity + quantity
                let dto = try await sdk.cart.updateItem(
                    cart_id: cid,
                    cart_item_id: existingItem.id,
                    shipping_id: nil,
                    quantity: newQuantity
                )
                sync(from: dto)
                ToastManager.shared.showSuccess(
                    "Updated \(product.title) quantity in cart"
                )
            } else {
                let line = LineItemInput(
                    productId: product.id,
                    quantity: quantity,
                    priceData: nil
                )
                let dto = try await sdk.cart.addItem(
                    cart_id: cid,
                    line_items: [line]
                )
                sync(from: dto)
                ToastManager.shared.showSuccess(
                    "Added \(product.title) to cart"
                )
            }
        } catch let error as SdkException {
            self.errorMessage = error.description
            print("❌ [Cart] addProduct FAIL \(error.description)")
            addProductLocally(product, quantity: quantity)
            ToastManager.shared.showWarning(
                "Using local cart for \(product.title) (sync error)"
            )
        } catch {
            self.errorMessage = error.localizedDescription
            print("❌ [Cart] addProduct FAIL \(error.localizedDescription)")
            addProductLocally(product, quantity: quantity)
            ToastManager.shared.showWarning(
                "Added \(product.title) locally due to error"
            )
        }

        updateCartTotal()
        isLoading = false
        triggerFeedbackIfNeeded(previousCount: previousCount)
    }

    /// Remove an item from the cart
    public func removeItem(_ item: CartItem) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        var didSyncFromServer = false

        if let cid = self.currentCartId, !cid.isEmpty {
            do {
                let dto = try await sdk.cart.deleteItem(
                    cart_id: cid,
                    cart_item_id: item.id
                )
                sync(from: dto)
                didSyncFromServer = true
            } catch let error as SdkException {
                self.errorMessage = error.description
                print("⚠️ [Cart] SDK.deleteItem failed: \(error.description)")
            } catch {
                self.errorMessage = error.localizedDescription
                print("⚠️ [Cart] SDK.deleteItem failed: \(error.localizedDescription)")
            }
        } else {
            print("ℹ️ [Cart] removeItem: skipped SDK call (missing cartId)")
        }

        if !didSyncFromServer {
            removeItemLocally(item)
        }

        updateCartTotal()
        ToastManager.shared.showInfo("Removed \(item.title) from cart")
    }

    /// Update item quantity
    public func updateQuantity(for item: CartItem, to newQuantity: Int) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        var didSyncFromServer = false

        if let cid = self.currentCartId, !cid.isEmpty {
            do {
                let dto: CartDto
                if newQuantity <= 0 {
                    dto = try await sdk.cart.deleteItem(
                        cart_id: cid,
                        cart_item_id: item.id
                    )
                } else {
                    dto = try await sdk.cart.updateItem(
                        cart_id: cid,
                        cart_item_id: item.id,
                        shipping_id: nil,
                        quantity: newQuantity
                    )
                }
                sync(from: dto)
                didSyncFromServer = true
            } catch let error as SdkException {
                self.errorMessage = error.description
                print("⚠️ [Cart] SDK.updateItem failed: \(error.description)")
            } catch {
                self.errorMessage = error.localizedDescription
                print("⚠️ [Cart] SDK.updateItem failed: \(error.localizedDescription)")
            }
        } else {
            print("ℹ️ [Cart] updateQuantity: skipped SDK call (missing cartId)")
        }

        if !didSyncFromServer {
            updateQuantityLocally(for: item, to: newQuantity)
        }

        updateCartTotal()
    }

    /// Show the checkout overlay
    public func showCheckout() {
        isCheckoutPresented = true
    }

    /// Hide the checkout overlay
    public func hideCheckout() {
        isCheckoutPresented = false
    }

    /// Clear the entire cart
    public func clearCart() async {
        isLoading = true
        errorMessage = nil

        items = []
        cartTotal = 0.0
        shippingTotal = 0.0
        shippingCurrency = currency

        isLoading = false
    }

    /// Get the total number of items in cart
    public var itemCount: Int {
        items.reduce(0) { $0 + $1.quantity }
    }

    // MARK: - Private Methods

    /// Update the cart total and currency
    private func updateCartTotal() {
        cartTotal = items.reduce(0) { total, item in
            total + (item.price * Double(item.quantity))
        }

        // Use currency from first item, default to USD
        if let firstCurrency = items.first?.currency, !firstCurrency.isEmpty {
            currency = firstCurrency
        } else if currency.isEmpty {
            currency = "USD"
        }

        if items.isEmpty {
            shippingTotal = 0.0
            shippingCurrency = currency
        }
    }

    private func addProductLocally(_ product: Product, quantity: Int) {
        if let index = items.firstIndex(where: { $0.productId == product.id }) {
            items[index].quantity += quantity
            recalcShippingTotalsFromItems()
            return
        }

        let sortedImages = product.images.sorted { lhs, rhs in
            lhs.order < rhs.order
        }
        let imageUrl = sortedImages.first?.url

        let cartItem = CartItem(
            id: UUID().uuidString,
            productId: product.id,
            variantId: product.variants.first?.id,
            title: product.title,
            brand: product.brand,
            imageUrl: imageUrl,
            price: Double(product.price.amount),
            currency: product.price.currency_code,
            quantity: quantity,
            sku: product.sku,
            supplier: product.supplier
        )

        items.append(cartItem)
        recalcShippingTotalsFromItems()
    }

    private func removeItemLocally(_ item: CartItem) {
        items.removeAll { $0.id == item.id }
        recalcShippingTotalsFromItems()
    }

    private func updateQuantityLocally(for item: CartItem, to newQuantity: Int) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            if newQuantity <= 0 {
                items.remove(at: index)
            } else {
                items[index].quantity = newQuantity
            }
            recalcShippingTotalsFromItems()
        }
    }

    private func triggerFeedbackIfNeeded(previousCount: Int) {
        #if os(iOS)
            if itemCount > previousCount {
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
            }
        #endif
    }

    public func setShippingOption(for itemId: String, optionId: String) {
        guard let itemIndex = items.firstIndex(where: { $0.id == itemId }) else { return }
        let item = items[itemIndex]
        guard let option = item.availableShippings.first(where: { $0.id == optionId }) else {
            return
        }

        items[itemIndex] = CartItem(
            id: item.id,
            productId: item.productId,
            variantId: item.variantId,
            title: item.title,
            brand: item.brand,
            imageUrl: item.imageUrl,
            price: item.price,
            currency: item.currency,
            quantity: item.quantity,
            sku: item.sku,
            supplier: item.supplier,
            shippingId: option.id,
            shippingName: option.name,
            shippingDescription: option.description,
            shippingAmount: option.amount,
            shippingCurrency: option.currency,
            availableShippings: item.availableShippings
        )

        pendingShippingSelections[itemId] = option
        recalcShippingTotalsFromItems()
    }

    private func recalcShippingTotalsFromItems() {
        var total: Double = 0.0
        var detectedCurrency: String?

        for item in items {
            if let amount = item.shippingAmount {
                total += amount
            }
            if detectedCurrency == nil,
                let cur = item.shippingCurrency,
                !cur.isEmpty
            {
                detectedCurrency = cur
            }
        }

        shippingTotal = total
        shippingCurrency = detectedCurrency ?? currency
    }

    private func applyShippingMetadata(_ metadata: [String: ShippingSyncData]) {
        guard !metadata.isEmpty else { return }

        items = items.map { item in
            guard let info = metadata[item.id] else { return item }

            var updated = CartItem(
                id: item.id,
                productId: item.productId,
                variantId: item.variantId,
                title: item.title,
                brand: item.brand,
                imageUrl: item.imageUrl,
                price: item.price,
                currency: item.currency,
                quantity: item.quantity,
                sku: item.sku,
                supplier: item.supplier,
                shippingId: info.shippingId ?? item.shippingId,
                shippingName: info.shippingName ?? item.shippingName,
                shippingDescription: info.shippingDescription ?? item.shippingDescription,
                shippingAmount: info.shippingAmount ?? item.shippingAmount,
                shippingCurrency: info.shippingCurrency ?? item.shippingCurrency,
                availableShippings: info.options.isEmpty ? item.availableShippings : info.options
            )

            if let pending = pendingShippingSelections[item.id] {
                updated = CartItem(
                    id: updated.id,
                    productId: updated.productId,
                    variantId: updated.variantId,
                    title: updated.title,
                    brand: updated.brand,
                    imageUrl: updated.imageUrl,
                    price: updated.price,
                    currency: updated.currency,
                    quantity: updated.quantity,
                    sku: updated.sku,
                    supplier: updated.supplier,
                    shippingId: pending.id,
                    shippingName: pending.name,
                    shippingDescription: pending.description,
                    shippingAmount: pending.amount,
                    shippingCurrency: pending.currency,
                    availableShippings: updated.availableShippings.isEmpty
                        ? [pending]
                        : updated.availableShippings
                )
            }

            return updated
        }

        recalcShippingTotalsFromItems()
    }

    // MARK: Helpers
    @discardableResult
    private func ensureCartIDForCheckout() async -> String? {
        if let id = currentCartId { return id }
        await createCart(currency: currency, country: country)
        return currentCartId
    }

    private func extractCheckoutId<T: Encodable>(_ dto: T) -> String? {
        guard
            let data = try? JSONEncoder().encode(dto),
            let dict = try? JSONSerialization.jsonObject(with: data)
                as? [String: Any]
        else { return nil }
        return (dict["checkout_id"] as? String)
            ?? (dict["checkoutId"] as? String)
            ?? (dict["id"] as? String)
    }

    @discardableResult
    public func createCheckout() async -> String? {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        guard let cid = await ensureCartIDForCheckout() else {
            print("ℹ️ [Checkout] Create: missing cartId")
            return nil
        }

        print("🧾 [Checkout] Create START cartId=\(cid)")
        do {
            let dto = try await sdk.checkout.create(cart_id: cid)
            let chkId = extractCheckoutId(dto)
            self.checkoutId = chkId
            print("✅ [Checkout] Create OK checkoutId=\(chkId ?? "nil")")
            return chkId
        } catch {
            let msg =
                (error as? SdkException)?.description
                ?? error.localizedDescription
            errorMessage = msg
            print("❌ [Checkout] Create FAIL \(msg)")
            return nil
        }
    }

    @discardableResult
    public func updateCheckout(
        checkoutId: String? = nil,
        email: String? = nil,
        successUrl: String? = nil,
        cancelUrl: String? = nil,
        paymentMethod: String? = nil,
        shippingAddress: [String: Any]? = nil,
        billingAddress: [String: Any]? = nil,
        acceptsTerms: Bool = true,
        acceptsPurchaseConditions: Bool = true
    ) async -> UpdateCheckoutDto? {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let chkId: String?
        if let passed = checkoutId, !passed.isEmpty {
            chkId = passed
        } else {
            chkId = await createCheckout()
        }

        guard let id = chkId, !id.isEmpty else {
            print("ℹ️ [Checkout] Update: missing checkoutId")
            return nil
        }

        print("🧾 [Checkout] Update START checkoutId=\(id)")
        do {
            let dto = try await sdk.checkout.update(
                checkout_id: id,
                status: nil,
                email: email,
                success_url: successUrl,
                cancel_url: cancelUrl,
                payment_method: paymentMethod,
                shipping_address: shippingAddress,
                billing_address: billingAddress,
                buyer_accepts_terms_conditions: acceptsTerms,
                buyer_accepts_purchase_conditions: acceptsPurchaseConditions
            )
            print("✅ [Checkout] Update OK")
            return dto
        } catch {
            let msg =
                (error as? SdkException)?.description
                ?? error.localizedDescription
            errorMessage = msg
            print("❌ [Checkout] Update FAIL \(msg)")
            return nil
        }
    }

    @discardableResult
    public func initKlarna(countryCode: String, href: String, email: String?)
        async
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

        print("💳 [Payment] KlarnaInit START checkoutId=\(id!)")
        do {
            let dto = try await sdk.payment.klarnaInit(
                checkoutId: id!,
                countryCode: countryCode,
                href: href,
                email: email
            )
            print("✅ [Payment] KlarnaInit OK")
            return dto
        } catch {
            let msg =
                (error as? SdkException)?.description
                ?? error.localizedDescription
            errorMessage = msg
            print("❌ [Payment] KlarnaInit FAIL \(msg)")
            return nil
        }
    }

    @discardableResult
    public func initKlarnaNative(
        input: KlarnaNativeInitInputDto
    ) async -> InitPaymentKlarnaNativeDto? {
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
            print("ℹ️ [Payment] KlarnaNativeInit: missing checkoutId")
            return nil
        }

        print("💳 [Payment] KlarnaNativeInit START checkoutId=\(checkout)")
        do {
            let dto = try await sdk.payment.klarnaNativeInit(
                checkoutId: checkout,
                input: input
            )
            self.checkoutId = dto.checkoutId
            print("✅ [Payment] KlarnaNativeInit OK sessionId=\(dto.sessionId)")
            return dto
        } catch {
            let msg =
                (error as? SdkException)?.description
                ?? error.localizedDescription
            errorMessage = msg
            print("❌ [Payment] KlarnaNativeInit FAIL \(msg)")
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
            let dto = try await sdk.payment.klarnaNativeConfirm(
                checkoutId: checkout,
                input: input
            )
            print("✅ [Payment] KlarnaNativeConfirm OK orderId=\(dto.orderId)")
            return dto
        } catch {
            let msg =
                (error as? SdkException)?.description
                ?? error.localizedDescription
            errorMessage = msg
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
            let dto = try await sdk.payment.klarnaNativeOrder(
                orderId: orderId,
                userId: userId
            )
            print("✅ [Payment] KlarnaNativeOrder OK status=\(dto.status ?? "-")")
            return dto
        } catch {
            let msg =
                (error as? SdkException)?.description
                ?? error.localizedDescription
            errorMessage = msg
            print("❌ [Payment] KlarnaNativeOrder FAIL \(msg)")
            return nil
        }
    }

    @discardableResult
    public func stripeIntent(returnEphemeralKey: Bool? = true) async
        -> PaymentIntentStripeDto?
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

        print("💳 [Payment] StripeIntent START checkoutId=\(id!)")
        do {
            let dto = try await sdk.payment.stripeIntent(
                checkoutId: id!,
                returnEphemeralKey: returnEphemeralKey
            )
            print("✅ [Payment] StripeIntent OK")
            return dto
        } catch {
            let msg =
                (error as? SdkException)?.description
                ?? error.localizedDescription
            errorMessage = msg
            print("❌ [Payment] StripeIntent FAIL \(msg)")
            return nil
        }
    }

    @discardableResult
    public func stripeLink(
        successUrl: String,
        paymentMethod: String,
        email: String
    ) async
        -> InitPaymentStripeDto?
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

        print("💳 [Payment] StripeLink START checkoutId=\(id!)")
        do {
            let dto = try await sdk.payment.stripeLink(
                checkoutId: id!,
                successUrl: successUrl,
                paymentMethod: paymentMethod,
                email: email
            )
            print("✅ [Payment] StripeLink OK")
            return dto
        } catch {
            let msg =
                (error as? SdkException)?.description
                ?? error.localizedDescription
            errorMessage = msg
            print("❌ [Payment] StripeLink FAIL \(msg)")
            return nil
        }
    }

    @discardableResult
    public func applyCheapestShippingPerSupplier() async -> Int {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        guard let cid = await ensureCartIDForCheckout() else {
            print("ℹ️ [Cart] applyCheapestShippingPerSupplier: missing cartId")
            return 0
        }

        let selections = pendingShippingSelections
        guard !selections.isEmpty else {
            print("ℹ️ [Cart] applyCheapestShippingPerSupplier: no pending selections")
            return 0
        }

        var updatedCount = 0
        var lastResponse: CartDto?
        var succeededIds: [String] = []

        for (itemId, option) in selections {
            do {
                let dto = try await sdk.cart.updateItem(
                    cart_id: cid,
                    cart_item_id: itemId,
                    shipping_id: option.id,
                    quantity: nil
                )
                lastResponse = dto
                succeededIds.append(itemId)
                updatedCount += 1
            } catch let error as SdkException {
                self.errorMessage = error.description
                print(
                    "⚠️ [Cart] updateItem(shipping) failed for \(itemId): \(error.description)"
                )
            } catch {
                self.errorMessage = error.localizedDescription
                print(
                    "⚠️ [Cart] updateItem(shipping) failed for \(itemId): \(error.localizedDescription)"
                )
            }
        }

        for itemId in succeededIds {
            pendingShippingSelections.removeValue(forKey: itemId)
        }

        if let dto = lastResponse {
            sync(from: dto)
            _ = await refreshShippingOptions()
        } else {
            recalcShippingTotalsFromItems()
        }

        print("✅ [Cart] Shipping updated for \(updatedCount) item(s).")
        return updatedCount
    }

    @discardableResult
    public func discountCreate(
        code: String,
        percentage: Int,
        startDate: String? = nil,
        endDate: String? = nil,
        typeId: Int = 2
    ) async -> Int? {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let dto = try await sdk.discount.add(
                code: code,
                percentage: percentage,
                startDate: startDate ?? _iso8601(),
                endDate: endDate
                    ?? _iso8601(
                        Calendar.current.date(
                            byAdding: .day,
                            value: 7,
                            to: Date()
                        )!
                    ),
                typeId: typeId
            )
            let did = dto.id
            self.lastDiscountId = did
            self.lastDiscountCode = code
            await MainActor.run {
                ToastManager.shared.showSuccess("Discount created: \(code)")
            }
            return did
        } catch {
            let msg =
                (error as? SdkException)?.description
                ?? error.localizedDescription
            errorMessage = msg
            print("❌ [Discount] create FAIL \(msg)")
            await MainActor.run {
                ToastManager.shared.showError("Create discount failed")
            }
            return nil
        }
    }

    @discardableResult
    public func discountApply(code: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let normalized = code.trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
        guard !normalized.isEmpty else {
            print("ℹ️ [Discount] apply: missing code")
            return false
        }

        guard let cid = await ensureCartIDForCheckout() else {
            print("ℹ️ [Discount] apply: missing cartId")
            return false
        }

        do {
            let dto: ApplyDiscountDto = try await sdk.discount.apply(
                code: normalized,
                cartId: cid
            )

            if dto.executed {
                self.lastDiscountCode = normalized
                await MainActor.run {
                    ToastManager.shared.showSuccess(
                        dto.message.isEmpty
                            ? "Discount applied: \(normalized)"
                            : dto.message
                    )
                }
                return true
            } else {
                self.errorMessage = dto.message
                print(
                    "⚠️ [Discount] apply NOT EXECUTED (\(normalized)) -> \(dto.message)"
                )
                await MainActor.run {
                    ToastManager.shared.showInfo(
                        dto.message.isEmpty
                            ? "Discount not applied"
                            : dto.message
                    )
                }
                return false
            }

        } catch {
            let msg =
                (error as? SdkException)?.description
                ?? error.localizedDescription
            self.errorMessage = msg
            print("❌ [Discount] apply FAIL \(msg)")
            await MainActor.run {
                ToastManager.shared.showError("Apply discount failed")
            }
            return false
        }
    }

    @discardableResult
    public func discountRemoveApplied(code: String? = nil) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        guard let cid = await ensureCartIDForCheckout() else {
            print("ℹ️ [Discount] deleteApplied: missing cartId")
            return false
        }

        let useCode =
            (code ?? lastDiscountCode)?.trimmingCharacters(
                in: .whitespacesAndNewlines
            ).uppercased()
            ?? ""
        guard !useCode.isEmpty else {
            print("ℹ️ [Discount] deleteApplied: missing code")
            return false
        }

        do {
            _ = try await sdk.discount.deleteApplied(code: useCode, cartId: cid)
            if lastDiscountCode == useCode { lastDiscountCode = nil }
            await MainActor.run {
                ToastManager.shared.showInfo("Discount removed: \(useCode)")
            }
            return true
        } catch {
            let msg =
                (error as? SdkException)?.description
                ?? error.localizedDescription
            errorMessage = msg
            print("❌ [Discount] deleteApplied FAIL \(msg)")
            await MainActor.run {
                ToastManager.shared.showError("Remove discount failed")
            }
            return false
        }
    }

    @discardableResult
    public func discountDelete(discountId: Int) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            _ = try await sdk.discount.delete(discountId: discountId)
            if lastDiscountId == discountId { lastDiscountId = nil }
            await MainActor.run {
                ToastManager.shared.showInfo("Discount deleted: \(discountId)")
            }
            return true
        } catch {
            let msg =
                (error as? SdkException)?.description
                ?? error.localizedDescription
            errorMessage = msg
            print("❌ [Discount] delete FAIL \(msg)")
            await MainActor.run {
                ToastManager.shared.showError("Delete discount failed")
            }
            return false
        }
    }

    // MARK: - Discounts helpers: get-by-code y apply-or-create

    @discardableResult
    public func discountGetIdByCode(code: String) async -> Int? {
        let needle = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty else { return nil }

        do {
            let channelList = try await sdk.discount.getByChannel()
            if let found = channelList.first(where: {
                ($0.code ?? "").caseInsensitiveCompare(needle) == .orderedSame
            }) {
                self.lastDiscountId = found.id
                self.lastDiscountCode = found.code
                return found.id
            }

            let all = try await sdk.discount.get()
            if let found = all.first(where: {
                ($0.code ?? "").caseInsensitiveCompare(needle) == .orderedSame
            }) {
                self.lastDiscountId = found.id
                self.lastDiscountCode = found.code
                return found.id
            }
        } catch {
            let msg =
                (error as? SdkException)?.description
                ?? error.localizedDescription
            print("⚠️ [Discount] get by code '\(code)' FAIL \(msg)")
            self.errorMessage = msg
        }
        return nil
    }

    @discardableResult
    public func discountApplyOrCreate(
        code: String,
        percentage: Int = 10,
        startDate: String? = nil,
        endDate: String? = nil,
        typeId: Int = 2
    ) async -> Bool {
        let normalized = code.trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
        guard !normalized.isEmpty else { return false }

        if await discountApply(code: normalized) {
            return true
        }

        if await discountGetIdByCode(code: normalized) != nil {
            if await discountApply(code: normalized) { return true }
            return false
        }

        if await discountCreate(
            code: normalized,
            percentage: percentage,
            startDate: startDate,
            endDate: endDate,
            typeId: typeId
        ) != nil {
            return await discountApply(code: normalized)
        }

        return false
    }

}

// MARK: - Product Mapping Helpers

extension ProductDto {
    fileprivate func toDomainProduct() -> Product {
        Product(
            id: id,
            title: title,
            brand: brand,
            description: description,
            tags: tags,
            sku: sku,
            quantity: quantity,
            price: price.toDomainPrice(),
            variants: variants.map { $0.toDomainVariant() },
            barcode: barcode,
            options: options.isEmpty ? nil : options.map { $0.toDomainOption() },
            categories: categories?.map { $0.toDomainCategory() },
            images: images.map { $0.toDomainImage() },
            product_shipping: productShipping?.map { $0.toDomainProductShipping() },
            supplier: supplier,
            supplier_id: supplierId,
            imported_product: importedProduct,
            referral_fee: referralFee,
            options_enabled: optionsEnabled,
            digital: digital,
            origin: origin,
            return: returnInfo?.toDomainReturnInfo()
        )
    }
}

extension PriceDto {
    fileprivate func toDomainPrice() -> Price {
        Price(
            amount: Float(amount),
            currency_code: currencyCode,
            amount_incl_taxes: amountInclTaxes.map(Float.init),
            tax_amount: taxAmount.map(Float.init),
            tax_rate: taxRate.map(Float.init),
            compare_at: compareAt.map(Float.init),
            compare_at_incl_taxes: compareAtInclTaxes.map(Float.init)
        )
    }

    fileprivate func toDomainBasePrice() -> BasePrice {
        BasePrice(
            amount: Float(amount),
            currency_code: currencyCode,
            amount_incl_taxes: amountInclTaxes.map(Float.init),
            tax_amount: taxAmount.map(Float.init),
            tax_rate: taxRate.map(Float.init)
        )
    }
}

extension VariantDto {
    fileprivate func toDomainVariant() -> Variant {
        Variant(
            id: id,
            barcode: barcode,
            price: price.toDomainPrice(),
            quantity: quantity,
            sku: sku,
            title: title,
            images: images.map { $0.toDomainImage() }
        )
    }
}

extension ProductImageDto {
    fileprivate func toDomainImage() -> ProductImage {
        ProductImage(
            id: id,
            url: url,
            width: width,
            height: height,
            order: order ?? 0
        )
    }
}

extension OptionDto {
    fileprivate func toDomainOption() -> Option {
        Option(id: id, name: name, order: order, values: values)
    }
}

extension CategoryDto {
    fileprivate func toDomainCategory() -> _Category {
        _Category(id: id, name: name)
    }
}

extension ProductShippingDto {
    fileprivate func toDomainProductShipping() -> ProductShipping {
        ProductShipping(
            id: id,
            name: name,
            description: description,
            custom_price_enabled: customPriceEnabled,
            default: defaultOption,
            shipping_country: shippingCountry?.map { $0.toDomainShippingCountry() }
        )
    }
}

extension ShippingCountryDto {
    fileprivate func toDomainShippingCountry() -> ShippingCountry {
        ShippingCountry(
            id: id,
            country: country,
            price: price.toDomainBasePrice()
        )
    }
}

extension ReturnInfoDto {
    fileprivate func toDomainReturnInfo() -> ReturnInfo {
        ReturnInfo(
            return_right: returnRight,
            return_label: returnLabel,
            return_cost: returnCost.map(Float.init),
            supplier_policy: supplierPolicy,
            return_address: returnAddress?.toDomainReturnAddress()
        )
    }
}

extension ReturnAddressDto {
    fileprivate func toDomainReturnAddress() -> ReturnAddress {
        ReturnAddress(
            same_as_business: sameAsBusiness,
            same_as_warehouse: sameAsWarehouse,
            country: country,
            timezone: timezone,
            address: address,
            address_2: address2,
            post_code: postCode,
            return_city: returnCity
        )
    }
}

// MARK: - Cart Errors
public enum CartError: LocalizedError {
    case noCartId
    case productNotFound
    case invalidQuantity

    public var errorDescription: String? {
        switch self {
        case .noCartId:
            return "No cart ID available"
        case .productNotFound:
            return "Product not found"
        case .invalidQuantity:
            return "Invalid quantity"
        }
    }
}
