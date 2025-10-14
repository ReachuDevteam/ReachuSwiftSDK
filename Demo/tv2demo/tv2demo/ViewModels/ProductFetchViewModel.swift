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
    
    /// Fetch un producto por su ID
    func fetchProduct(id: String) async {
        guard !id.isEmpty else {
            print("⚠️ [ProductFetch] ID vacío, no se puede fetch")
            return
        }
        
        isLoading = true
        errorMessage = nil
        product = nil
        
        print("🔍 [ProductFetch] Fetching producto con ID: \(id)")
        print("   Currency: \(currency)")
        print("   Country: \(country)")
        
        do {
            // Convertir String ID a Int
            guard let productId = Int(id) else {
                self.errorMessage = "ID de producto inválido"
                print("❌ [ProductFetch] ID no es un número válido: \(id)")
                isLoading = false
                return
            }
            
            let products = try await sdk.product.get(
                currency: currency,
                imageSize: "large",
                barcodeList: nil,
                categoryIds: nil,
                productIds: [productId],
                skuList: nil,
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
                print("❌ [ProductFetch] Producto con ID \(id) no encontrado en la respuesta")
            }
            
            isLoading = false
            
        } catch {
            self.errorMessage = error.localizedDescription
            isLoading = false
            print("❌ [ProductFetch] Error fetching producto: \(error)")
        }
    }
    
    /// Fetch múltiples productos por sus IDs
    func fetchProducts(ids: [String]) async {
        guard !ids.isEmpty else {
            print("⚠️ [ProductFetch] Lista de IDs vacía, no se puede fetch")
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        print("🔍 [ProductFetch] Fetching múltiples productos: \(ids)")
        print("   Currency: \(currency)")
        print("   Country: \(country)")
        
        do {
            // Convertir String IDs a Int
            let productIds = ids.compactMap { Int($0) }
            guard productIds.count == ids.count else {
                self.errorMessage = "Algunos IDs de producto son inválidos"
                print("❌ [ProductFetch] Algunos IDs no son números válidos")
                isLoading = false
                return
            }
            
            let products = try await sdk.product.get(
                currency: currency,
                imageSize: "large",
                barcodeList: nil,
                categoryIds: nil,
                productIds: productIds,
                skuList: nil,
                useCache: false,
                shippingCountryCode: country
            )
            
            print("✅ [ProductFetch] \(products.count) productos obtenidos")
            for product in products {
                print("   - \(product.title) (\(formatPrice(product.price)))")
            }
            
            // Para múltiples productos, el componente padre manejará el array
            // Por ahora solo guardamos el primero
            if let first = products.first {
                self.product = first
            }
            
            isLoading = false
            
        } catch {
            self.errorMessage = error.localizedDescription
            isLoading = false
            print("❌ [ProductFetch] Error fetching productos: \(error)")
        }
    }
    
    // MARK: - Helpers
    
    /// Formatea el precio para display
    private func formatPrice(_ price: PriceDto) -> String {
        return "\(price.currencyCode) \(String(format: "%.2f", price.amount))"
    }
}

