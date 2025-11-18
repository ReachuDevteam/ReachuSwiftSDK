import Foundation
import SwiftUI
import Combine
import ReachuCore
import ReachuUI

/// ViewModel para fetch de productos individuales desde la API de Reachu
/// Usado por los overlays de productos del WebSocket
@MainActor
class ProductFetchViewModel: ObservableObject {
    @Published var product: ProductDto?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let sdk: SdkClient
    private let currency: String
    private let country: String
    
    init(sdk: SdkClient, currency: String, country: String) {
        self.sdk = sdk
        self.currency = currency
        self.country = country
    }
    
    /// Fetch un producto por su productId (ID numérico de Reachu)
    func fetchProduct(productId: String) async {
        guard !productId.isEmpty else {
            print("⚠️ [ProductFetch] productId vacío, no se puede fetch")
            return
        }
        
        isLoading = true
        errorMessage = nil
        product = nil
        
        print("🔍 [ProductFetch] Fetching producto con productId: \(productId)")
        print("   Currency: \(currency)")
        print("   Country: \(country)")
        
        do {
            // Convertir String productId a Int
            guard let productIdInt = Int(productId) else {
                self.errorMessage = "productId inválido: \(productId)"
                print("❌ [ProductFetch] productId no es un número válido: \(productId)")
                isLoading = false
                return
            }
            
            // Usar getByIds que es el método optimizado para buscar por IDs
            let products = try await sdk.product.getByIds(
                productIds: [productIdInt],
                currency: currency,
                imageSize: "large",
                useCache: false,
                shippingCountryCode: country
            )
            
            if let fetchedProduct = products.first {
                self.product = fetchedProduct
                print("✅ [ProductFetch] Producto obtenido: \(fetchedProduct.title)")
                print("   Precio: \(formatPrice(fetchedProduct.price))")
                if let imageUrl = fetchedProduct.images.first?.url {
                    print("   Imagen: \(imageUrl)")
                }
            } else {
                self.errorMessage = "Producto no encontrado"
                print("❌ [ProductFetch] Producto con productId \(productId) no encontrado en la respuesta")
            }
            
            isLoading = false
            
        } catch {
            self.errorMessage = error.localizedDescription
            isLoading = false
            print("❌ [ProductFetch] Error fetching producto: \(error)")
        }
    }
    
    // MARK: - Helpers
    
    /// Formatea el precio para display
    private func formatPrice(_ price: PriceDto) -> String {
        let amount = price.amountInclTaxes ?? price.amount
        return "\(price.currencyCode) \(String(format: "%.2f", amount))"
    }
}

