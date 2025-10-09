import Foundation
import ReachuCore

@MainActor
extension CartManager {

    public func loadMarketsIfNeeded() async {
        if didLoadMarkets { return }
        await loadMarkets()
    }

    public func reloadMarkets() async {
        didLoadMarkets = false
        await loadMarkets()
    }

    public func selectMarket(_ market: Market) async {
        await applyMarket(market, refreshData: true)
    }

    private func loadMarkets() async {
        let fallbackConfig = ReachuConfiguration.shared.marketConfiguration
        let fallbackMarket = Market(
            code: fallbackConfig.countryCode,
            name: fallbackConfig.countryName,
            officialName: fallbackConfig.countryName,
            flagURL: fallbackConfig.flagURL,
            phoneCode: fallbackConfig.phoneCode,
            currencyCode: fallbackConfig.currencyCode,
            currencySymbol: fallbackConfig.currencySymbol
        )

        do {
            logRequest("sdk.market.getAvailable")
            let dtos = try await sdk.market.getAvailable()
            logResponse("sdk.market.getAvailable", payload: ["count": dtos.count])
            var mapped = dtos.compactMap { $0.toMarket(fallback: fallbackConfig) }

            if mapped.isEmpty {
                mapped = [fallbackMarket]
            } else if !mapped.contains(where: { $0.code == fallbackMarket.code }) {
                mapped.insert(fallbackMarket, at: 0)
            }

            markets = mapped
            didLoadMarkets = true

            let currentCode = selectedMarket?.code ?? fallbackMarket.code
            let target = mapped.first(where: { $0.code == currentCode }) ?? fallbackMarket
            let shouldRefresh = (country != target.code) || (currency != target.currencyCode)

            await applyMarket(target, refreshData: shouldRefresh)
        } catch {
            print("❌ [Markets] Failed to load markets: \(error.localizedDescription)")
            logError("sdk.market.getAvailable", error: error)
            markets = [fallbackMarket]
            didLoadMarkets = false
            await applyMarket(fallbackMarket, refreshData: false)
        }
    }

    internal func applyMarket(_ market: Market, refreshData: Bool) async {
        selectedMarket = market
        country = market.code
        currency = market.currencyCode
        currencySymbol = market.currencySymbol
        phoneCode = market.phoneCode
        flagURL = market.flagURL
        shippingCurrency = market.currencyCode
        pendingShippingSelections.removeAll()

        if refreshData {
            resetForMarketChange(defaultCurrency: market.currencyCode)
            await createCart(currency: market.currencyCode, country: market.code)
            await loadProducts(
                currency: market.currencyCode,
                shippingCountryCode: market.code,
                useCache: false
            )
            _ = await refreshShippingOptions()
        } else {
            recalcShippingTotalsFromItems()
        }
    }

    private func resetForMarketChange(defaultCurrency: String) {
        items = []
        products = []
        cartTotal = 0.0
        shippingTotal = 0.0
        shippingCurrency = defaultCurrency
        isProductsLoading = true
        currentCartId = nil
        checkoutId = nil
        lastDiscountCode = nil
        lastDiscountId = nil
        errorMessage = nil
        lastLoadedProductCurrency = nil
        lastLoadedProductCountry = nil
        activeProductRequestID = nil
    }
}
