//
//  ContentView.swift
//  Viaplay
//
//  Created by Angelo Sepulveda on 27/10/2025.
//

import SwiftUI
import ReachuUI
import ReachuCore
import ReachuLiveUI
import ReachuLiveShow

struct ContentView: View {
    @EnvironmentObject var cartManager: CartManager
    @EnvironmentObject private var checkoutDraft: CheckoutDraft
    @State private var selectedTab = 0
    @State private var showSportView = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Main app content based on selected tab
                Group {
                    if showSportView {
                        SportView(selectedTab: $selectedTab, showSportView: $showSportView)
                    } else {
                        ViaplayHomeView(selectedTab: $selectedTab, showSportView: $showSportView)
                    }
                }
                .onChange(of: selectedTab) { newValue in
                    if newValue == 1 { // Sport tab
                        if !showSportView {
                            showSportView = true
                        }
                    } else if newValue == 0 { // Home tab
                        showSportView = false
                    }
                }
                
                // Global floating cart indicator - always on top
                RFloatingCartIndicator(
                    customPadding: EdgeInsets(
                        top: 0,
                        leading: 0,
                        bottom: 100,
                        trailing: 16
                    )
                )
                .zIndex(999) // Asegurar que esté por encima de todo (video, overlays, etc.)
            }
            .overlay {
                // Global live stream overlay (Tipio integration)
                LiveStreamGlobalOverlay()
                    .environmentObject(cartManager)
            }
            // Checkout Overlay
            .sheet(isPresented: $cartManager.isCheckoutPresented) {
                RCheckoutOverlay()
                    .environmentObject(cartManager)
                    .environmentObject(checkoutDraft)
            }
            // MARK: - Reachu Diagnostics (App Start)
            .task {
                await debugReachuPing()
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// MARK: - Live Stream Overlay

struct LiveStreamGlobalOverlay: View {
    @ObservedObject private var liveShowManager = LiveShowManager.shared
    @EnvironmentObject private var cartManager: CartManager
    
    var body: some View {
        ZStack {
            // Full screen LiveShow overlay
            if liveShowManager.isLiveShowVisible {
                RLiveShowFullScreenOverlay()
                    .environmentObject(cartManager)
            }
        }
    }
}

// MARK: - Diagnostics
extension ContentView {
    private func maskKey(_ key: String) -> String {
        guard !key.isEmpty else { return "(empty)" }
        return String(repeating: "*", count: max(0, key.count - 4)) + key.suffix(4)
    }

    private func resolveBaseURL() -> URL? {
        let urlString = ReachuConfiguration.shared.environment.graphQLURL
        return URL(string: urlString)
    }

    private func logConfig() {
        let cfg = ReachuConfiguration.shared
        print("🧭 [Diag][Reachu] env=\(cfg.environment.rawValue) base=\(cfg.environment.graphQLURL)")
        print("🧭 [Diag][Reachu] apiKey=\(maskKey(cfg.apiKey))")
        print("🧭 [Diag][Reachu] market country=\(cfg.marketConfiguration.countryCode) currency=\(cfg.marketConfiguration.currencyCode)")
    }

    private func sdkClient() -> SdkClient? {
        guard let base = resolveBaseURL() else {
            print("❌ [Diag][Reachu] Invalid base URL from configuration")
            return nil
        }
        let key = ReachuConfiguration.shared.apiKey.isEmpty ? "DEMO_KEY" : ReachuConfiguration.shared.apiKey
        print("🔌 [Diag][Reachu] Creating SdkClient base=\(base.absoluteString) apiKey=\(maskKey(key))")
        return SdkClient(baseUrl: base, apiKey: key)
    }

    private func logRequest(_ name: String, payload: [String: Any]) {
        print("➡️ [Diag][Request] \(name) payload=\(payload)")
    }

    private func logResponse(_ name: String, info: [String: Any]) {
        print("✅ [Diag][Response] \(name) info=\(info)")
    }

    private func logError(_ name: String, error: Error) {
        if let sdkErr = error as? SdkException {
            print("❌ [Diag][Error] \(name) sdk=\(sdkErr.description)")
        } else {
            print("❌ [Diag][Error] \(name) msg=\(error.localizedDescription)")
        }
    }

    private func currentCurrency() -> String {
        ReachuConfiguration.shared.marketConfiguration.currencyCode
    }

    private func currentCountry() -> String {
        ReachuConfiguration.shared.marketConfiguration.countryCode
    }

    private func debugReachuPing() async {
        logConfig()
        guard let sdk = sdkClient() else { return }

        let currency = currentCurrency()
        let country = currentCountry()
        logRequest("sdk.channel.product.get", payload: [
            "currency": currency,
            "imageSize": "large",
            "useCache": false,
            "shippingCountryCode": country
        ])

        do {
            let products = try await sdk.channel.product.get(
                currency: currency,
                imageSize: "large",
                barcodeList: nil,
                categoryIds: nil,
                productIds: nil,
                skuList: nil,
                useCache: false,
                shippingCountryCode: country
            )
            logResponse("sdk.channel.product.get", info: [
                "count": products.count
            ])
        } catch {
            logError("sdk.channel.product.get", error: error)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(CartManager())
        .environmentObject(CheckoutDraft())
}
