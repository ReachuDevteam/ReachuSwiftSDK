# Plan de Desarrollo Modular - Reachu Swift SDK

## 📋 Resumen Ejecutivo

Este documento define la estrategia de desarrollo modular para el **Reachu Swift SDK**, basado en el análisis de la estructura del SDK de React Native existente. El objetivo es crear un SDK altamente modular que permita a los desarrolladores importar solo las funcionalidades necesarias, optimizando el tamaño de la aplicación y mejorando la experiencia del desarrollador.

---

## 🏗️ Arquitectura Modular Propuesta

### Estructura de Módulos

```
ReachuSwiftSDK/
├── 📡 ReachuNetwork (Módulo interno compartido)
│   ├── NetworkClient.swift
│   ├── GraphQLClient.swift  
│   ├── RESTClient.swift
│   ├── NetworkError.swift
│   └── AuthenticationManager.swift
├── 🔧 ReachuCore (Fase 1 - Requerido)
│   ├── Core/
│   ├── Models/
│   ├── Modules/
│   └── Utils/
├── 🎨 ReachuDesignSystem (Módulo interno UI)
│   ├── Tokens/
│   ├── Components/
│   ├── Extensions/
│   └── ImageLoader.swift
├── 🎨 ReachuUI (Fase 2 - Opcional)
│   ├── Views/
│   ├── ViewModels/
│   └── ReachuUI.swift
├── 📺 ReachuLiveShow (Fase 3 - Opcional)
│   ├── Services/
│   ├── Models/
│   └── ReachuLiveShow.swift
├── 📺 ReachuLiveUI (Fase 3 - Opcional)
│   ├── Views/
│   ├── ViewModels/
│   └── ReachuLiveUI.swift
└── 🧪 ReachuTesting (Utilities de testing)
    ├── Mocks/
    ├── Helpers/
    └── TestUtilities.swift
```

### Configuración Swift Package Manager

```swift
// Package.swift - Configuración Modular
products: [
    .library(name: "ReachuCore", targets: ["ReachuCore"]),
    .library(name: "ReachuNetwork", targets: ["ReachuNetwork"]),
    .library(name: "ReachuUI", targets: ["ReachuCore", "ReachuUI"]),
    .library(name: "ReachuDesignSystem", targets: ["ReachuDesignSystem"]),
    .library(name: "ReachuLiveShow", targets: ["ReachuCore", "ReachuLiveShow"]),
    .library(name: "ReachuTesting", targets: ["ReachuTesting"]),
    .library(name: "ReachuComplete", targets: ["ReachuCore", "ReachuUI", "ReachuLiveShow", "ReachuLiveUI"])
]
```

---

## 🔍 Análisis del SDK React Native Existente

### Estructura Identificada

```typescript
SdkClient {
    cart: Cart                    // ✅ Gestión de carritos
    channel: Channel {            // ✅ Gestión de canales
        product: Product          // → Productos dentro de canales
        market: Market            // → Información de mercado
        category: Category        // → Categorías dentro de canales
        info: Info               // → Información del canal
    }
    checkout: Checkout            // ✅ Proceso de checkout
    discount: Discount            // ✅ Gestión de descuentos
    market: Market                // ✅ Mercados globales
    payment: Payment              // ✅ Procesamiento de pagos
    apolloClient: ApolloClient    // ✅ Cliente GraphQL
}
```

### Conceptos Clave

1. **Channel**: Contexto de venta/plataforma que contiene products, categories, markets específicos
2. **Market**: Información de mercados/países disponibles para la venta
3. **Cart**: Gestión completa del carrito con line items y funcionalidades avanzadas
4. **GraphQL-First**: Toda la comunicación se realiza mediante Apollo Client

---

## 👥 División de Responsabilidades por Desarrollador

## 👨‍💻 DESARROLLADOR 1: CORE (ReachuCore + ReachuNetwork)

**Responsabilidad**: Toda la lógica de negocio, API clients, y servicios base

### 1. ReachuNetwork Module 📡

**Ubicación**: `Sources/ReachuNetwork/`

#### Archivos a Crear:

```swift
// NetworkClient.swift - Cliente principal de red
public class NetworkClient {
    private let apolloClient: ApolloClient<NormalizedCacheObject>
    private let restClient: RESTClient
    private let authManager: AuthenticationManager
    
    public init(configuration: Configuration)
    public func performGraphQLQuery<T>(_:) async throws -> T
    public func performRESTRequest<T>(_:) async throws -> T
}

// GraphQLClient.swift - Configuración Apollo
public class GraphQLClient {
    public static func createClient(
        apiKey: String, 
        endpoint: String
    ) -> ApolloClient<NormalizedCacheObject>
}

// RESTClient.swift - Cliente REST con URLSession
public class RESTClient {
    public func performRequest<T: Codable>(
        endpoint: String,
        method: HTTPMethod,
        body: Data?
    ) async throws -> T
}

// NetworkError.swift - Manejo de errores de red
public enum NetworkError: Error {
    case invalidURL
    case noData
    case decodingError
    case serverError(Int)
    case authenticationFailed
}

// AuthenticationManager.swift - Gestión de autenticación
public class AuthenticationManager {
    public func setBearerToken(_ token: String)
    public func getAuthHeaders() -> [String: String]
}
```

### 2. Actualizar ReachuCore 🔄

**Ubicación**: `Sources/ReachuCore/Modules/`

#### CartModule.swift - Basado en RN SDK

```swift
public class CartModule {
    // Métodos identificados del SDK React Native
    func createCart(
        customerSessionId: String, 
        currency: String, 
        shippingCountry: String?
    ) async throws -> CartDto
    
    func getCart(cartId: String) async throws -> CartDto
    func updateCart(cartId: String, shippingCountry: String) async throws -> UpdateCartDto
    func deleteCart(cartId: String) async throws -> RemoveCartDto
    
    func addItem(
        cartId: String, 
        lineItems: LineItemInput
    ) async throws -> CreateItemToCartDto
    
    func updateItem(
        cartId: String, 
        cartItemId: String, 
        quantity: Int?, 
        shippingId: String?
    ) async throws -> UpdateItemToCartDto
    
    func deleteItem(
        cartId: String, 
        cartItemId: String
    ) async throws -> RemoveItemToCartDto
    
    func getLineItemsBySupplier(cartId: String) async throws -> [GetLineItemsBySupplierDto]
}
```

#### ProductsModule.swift - Nuevo módulo completo

```swift
public class ProductsModule {
    func getProducts(
        currency: String? = nil,
        imageSize: ImageSize = .large,
        barcodeList: [String] = [],
        categoryIds: [Int] = [],
        productIds: [Int] = [],
        skuList: [String] = [],
        useCache: Bool = true,
        shippingCountryCode: String? = nil
    ) async throws -> [Product]
    
    func getProductsByCategory(
        categoryId: Int,
        currency: String? = nil,
        imageSize: ImageSize = .large,
        shippingCountryCode: String? = nil
    ) async throws -> [Product]
    
    func getProductsByCategories(
        categoryIds: [Int],
        currency: String? = nil,
        imageSize: ImageSize = .large,
        shippingCountryCode: String? = nil
    ) async throws -> [Product]
    
    func getProductByParams(
        currency: String? = nil,
        imageSize: ImageSize = .large,
        sku: String? = nil,
        barcode: String? = nil,
        productId: Int? = nil,
        shippingCountryCode: String? = nil
    ) async throws -> Product
    
    func getProductsByIds(
        productIds: [Int],
        currency: String? = nil,
        imageSize: ImageSize = .large,
        useCache: Bool = true,
        shippingCountryCode: String? = nil
    ) async throws -> [Product]
    
    func getProductsBySkus(
        skuStringList: String,
        productId: Int? = nil,
        currency: String? = nil,
        imageSize: ImageSize = .large,
        shippingCountryCode: String? = nil
    ) async throws -> [Product]
    
    func getProductsByBarcodes(
        barcodeStringList: String,
        productId: Int? = nil,
        currency: String? = nil,
        imageSize: ImageSize = .large,
        shippingCountryCode: String? = nil
    ) async throws -> [Product]
}
```

#### ChannelModule.swift - NUEVO MÓDULO (Concepto clave)

```swift
public class ChannelModule {
    private let productModule: ProductsModule
    private let categoryModule: CategoryModule
    private let marketModule: MarketModule
    
    func getCategories() async throws -> [GetCategoryDto]
    func getChannelInfo() async throws -> ChannelInfoDto
    
    // Wrapper para productos con contexto de channel
    func getChannelProducts(
        currency: String? = nil,
        imageSize: ImageSize = .large,
        useCache: Bool = true
    ) async throws -> [Product]
}

public class CategoryModule {
    func getCategories() async throws -> [GetCategoryDto]
}
```

#### CheckoutModule.swift - Actualizar

```swift
public class CheckoutModule {
    func createCheckout(cartId: String) async throws -> CheckoutDto
    func getCheckout(checkoutId: String) async throws -> CheckoutDto
    func updateShippingAddress(
        checkoutId: String, 
        address: AddressInput
    ) async throws -> CheckoutDto
    // Agregar más métodos según análisis RN SDK
}
```

#### PaymentsModule.swift - Actualizar

```swift
public class PaymentsModule {
    func createPaymentIntentStripe(
        checkoutId: String
    ) async throws -> StripePaymentIntentDto
    
    func getAvailablePaymentMethods() async throws -> [AvailablePaymentMethodDto]
    // Agregar más métodos según análisis RN SDK
}
```

#### DiscountModule.swift - NUEVO MÓDULO

```swift
public class DiscountModule {
    func getDiscounts() async throws -> [DiscountDto]
    func applyDiscount(
        code: String, 
        cartId: String
    ) async throws -> ApplyDiscountDto
    func removeDiscount(
        discountId: String, 
        cartId: String
    ) async throws -> ApplyDiscountDto
}
```

#### MarketModule.swift - NUEVO MÓDULO

```swift
public class MarketModule {
    func getAvailableMarkets() async throws -> [GetAvailableGlobalMarketsDto]
    func getMarketInfo(marketId: String) async throws -> MarketInfoDto
}
```

### 3. Models & DTOs 📄

**Ubicación**: `Sources/ReachuCore/Models/`

#### Crear todos los models basados en las types de GraphQL del RN SDK:

```swift
// Core Models
public struct Product: Codable {
    public let id: Int
    public let title: String
    public let description: String?
    public let images: [ProductImage]
    public let variants: [ProductVariant]
    public let price: Price
    public let currency: String
    // ... más propiedades según RN SDK
}

public struct CartDto: Codable {
    public let cartId: String
    public let customerSessionId: String
    public let currency: String
    public let lineItems: [LineItemDto]
    public let subtotal: Double
    public let shipping: Double
    public let availableShippingCountries: [String]
    public let shippingCountry: String?
}

public struct LineItemDto: Codable {
    public let id: String
    public let productId: Int
    public let variantId: Int?
    public let quantity: Int
    public let price: Double
    public let product: Product
}

// Response DTOs
public struct CreateCartDto: Codable {
    public let cartId: String
    public let message: String
}

public struct GetCategoryDto: Codable {
    public let id: Int
    public let name: String
    public let description: String?
    public let parentId: Int?
}

public struct GetAvailableGlobalMarketsDto: Codable {
    public let id: String
    public let name: String
    public let currency: String
    public let countryCode: String
}

// Input DTOs
public struct LineItemInput: Codable {
    public let productId: Int
    public let variantId: Int?
    public let quantity: Int
}

public struct AddressInput: Codable {
    public let address1: String?
    public let address2: String?
    public let city: String?
    public let company: String?
    public let country: String?
    public let countryCode: String?
    public let firstName: String?
    public let lastName: String?
    public let phone: String?
    public let phoneCode: String?
    public let province: String?
    public let provinceCode: String?
    public let zip: String?
    public let email: String?
}

// Enums
public enum ImageSize: String, Codable {
    case large = "large"
    case medium = "medium"
    case thumbnail = "thumbnail"
    case full = "full"
}
```

---

## 🎨 ANGELO: UI COMPONENTS (ReachuUI + ReachuDesignSystem)

**Responsabilidad**: Componentes SwiftUI reutilizables y ViewModels

### 1. ReachuDesignSystem Module 🎨

**Ubicación**: `Sources/ReachuDesignSystem/`

#### Tokens/Colors.swift
```swift
public struct ReachuColors {
    public static let primary = Color(hex: "#007AFF")
    public static let secondary = Color(hex: "#5856D6")
    public static let success = Color(hex: "#34C759")
    public static let warning = Color(hex: "#FF9500")
    public static let error = Color(hex: "#FF3B30")
    
    // Background colors
    public static let background = Color(hex: "#F2F2F7")
    public static let surface = Color.white
    public static let surfaceSecondary = Color(hex: "#F9F9F9")
    
    // Text colors
    public static let textPrimary = Color.black
    public static let textSecondary = Color(hex: "#8E8E93")
    public static let textTertiary = Color(hex: "#C7C7CC")
}
```

#### Tokens/Typography.swift
```swift
public struct ReachuTypography {
    public static let largeTitle = Font.largeTitle.weight(.bold)
    public static let title1 = Font.title.weight(.semibold)
    public static let title2 = Font.title2.weight(.semibold)
    public static let title3 = Font.title3.weight(.medium)
    public static let headline = Font.headline.weight(.semibold)
    public static let body = Font.body
    public static let callout = Font.callout
    public static let subheadline = Font.subheadline
    public static let footnote = Font.footnote
    public static let caption1 = Font.caption
    public static let caption2 = Font.caption2
}
```

#### Tokens/Spacing.swift
```swift
public struct ReachuSpacing {
    public static let xs: CGFloat = 4
    public static let sm: CGFloat = 8
    public static let md: CGFloat = 16
    public static let lg: CGFloat = 24
    public static let xl: CGFloat = 32
    public static let xxl: CGFloat = 48
}
```

#### Components/RButton.swift
```swift
public struct RButton: View {
    public enum Style {
        case primary, secondary, tertiary, destructive
    }
    
    public enum Size {
        case small, medium, large
    }
    
    private let title: String
    private let style: Style
    private let size: Size
    private let action: () -> Void
    private let isLoading: Bool
    private let isDisabled: Bool
    
    public init(
        title: String,
        style: Style = .primary,
        size: Size = .medium,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.size = size
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                }
                Text(title)
                    .font(fontForSize)
            }
            .padding(paddingForSize)
            .background(backgroundColorForStyle)
            .foregroundColor(foregroundColorForStyle)
            .cornerRadius(ReachuBorderRadius.medium)
        }
        .disabled(isDisabled || isLoading)
    }
    
    // ... helper computed properties
}
```

#### Components/RCard.swift
```swift
public struct RCard<Content: View>: View {
    private let content: Content
    private let padding: CGFloat
    private let cornerRadius: CGFloat
    private let shadowRadius: CGFloat
    
    public init(
        padding: CGFloat = ReachuSpacing.md,
        cornerRadius: CGFloat = ReachuBorderRadius.medium,
        shadowRadius: CGFloat = 2,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
    }
    
    public var body: some View {
        content
            .padding(padding)
            .background(ReachuColors.surface)
            .cornerRadius(cornerRadius)
            .shadow(radius: shadowRadius)
    }
}
```

#### ImageLoader.swift - Integración con Nuke
```swift
import Nuke
import NukeUI

public struct ReachuAsyncImage: View {
    private let url: URL?
    private let placeholder: AnyView?
    private let contentMode: ContentMode
    
    public init(
        url: URL?,
        contentMode: ContentMode = .fit,
        @ViewBuilder placeholder: () -> AnyView? = { nil }
    ) {
        self.url = url
        self.contentMode = contentMode
        self.placeholder = placeholder()
    }
    
    public var body: some View {
        LazyImage(url: url) { state in
            if let image = state.image {
                image
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else if state.error != nil {
                Image(systemName: "photo")
                    .foregroundColor(.gray)
            } else {
                placeholder ?? AnyView(ProgressView())
            }
        }
    }
}
```

### 2. Product Components 🛍️

**Ubicación**: `Sources/ReachuUI/Views/Product/`

#### ProductCardView.swift
```swift
public struct ProductCardView: View {
    private let product: Product
    private let onTap: (Product) -> Void
    private let onAddToCart: (Product) -> Void
    
    public init(
        product: Product,
        onTap: @escaping (Product) -> Void,
        onAddToCart: @escaping (Product) -> Void
    ) {
        self.product = product
        self.onTap = onTap
        self.onAddToCart = onAddToCart
    }
    
    public var body: some View {
        RCard {
            VStack(alignment: .leading, spacing: ReachuSpacing.sm) {
                // Product Image
                ReachuAsyncImage(
                    url: URL(string: product.images.first?.url ?? "")
                )
                .frame(height: 200)
                .clipped()
                
                VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
                    Text(product.title)
                        .font(ReachuTypography.headline)
                        .lineLimit(2)
                    
                    ProductPriceView(price: product.price)
                    
                    RButton(title: "Add to Cart", style: .primary, size: .small) {
                        onAddToCart(product)
                    }
                }
                .padding(.horizontal, ReachuSpacing.sm)
            }
        }
        .onTapGesture {
            onTap(product)
        }
    }
}
```

#### ProductListView.swift
```swift
public struct ProductListView: View {
    @StateObject private var viewModel = ProductViewModel()
    private let layout = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: layout, spacing: ReachuSpacing.md) {
                    ForEach(viewModel.products, id: \.id) { product in
                        ProductCardView(
                            product: product,
                            onTap: viewModel.selectProduct,
                            onAddToCart: viewModel.addToCart
                        )
                    }
                }
                .padding(ReachuSpacing.md)
            }
            .navigationTitle("Products")
            .task {
                await viewModel.loadProducts()
            }
        }
    }
}
```

#### ProductDetailView.swift
```swift
public struct ProductDetailView: View {
    private let product: Product
    @StateObject private var viewModel = ProductDetailViewModel()
    
    public init(product: Product) {
        self.product = product
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ReachuSpacing.lg) {
                // Image Carousel
                ProductImageCarousel(images: product.images)
                
                VStack(alignment: .leading, spacing: ReachuSpacing.md) {
                    Text(product.title)
                        .font(ReachuTypography.largeTitle)
                    
                    ProductPriceView(price: product.price)
                    
                    if let description = product.description {
                        Text(description)
                            .font(ReachuTypography.body)
                            .foregroundColor(ReachuColors.textSecondary)
                    }
                    
                    // Variant Selector
                    if !product.variants.isEmpty {
                        ProductVariantSelector(
                            variants: product.variants,
                            selectedVariant: $viewModel.selectedVariant
                        )
                    }
                    
                    Spacer()
                    
                    RButton(
                        title: "Add to Cart",
                        style: .primary,
                        size: .large,
                        isLoading: viewModel.isAddingToCart
                    ) {
                        Task {
                            await viewModel.addToCart(product: product)
                        }
                    }
                }
                .padding(ReachuSpacing.md)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
```

#### ProductImageCarousel.swift
```swift
public struct ProductImageCarousel: View {
    private let images: [ProductImage]
    @State private var currentIndex = 0
    
    public init(images: [ProductImage]) {
        self.images = images
    }
    
    public var body: some View {
        TabView(selection: $currentIndex) {
            ForEach(images.indices, id: \.self) { index in
                ReachuAsyncImage(
                    url: URL(string: images[index].url),
                    contentMode: .fit
                )
                .tag(index)
            }
        }
        .tabViewStyle(PageTabViewStyle())
        .frame(height: 300)
    }
}
```

#### ProductPriceView.swift
```swift
public struct ProductPriceView: View {
    private let price: Price
    
    public init(price: Price) {
        self.price = price
    }
    
    public var body: some View {
        HStack {
            if let compareAtPrice = price.compareAtPrice, compareAtPrice > price.amount {
                Text(formatPrice(compareAtPrice))
                    .font(ReachuTypography.footnote)
                    .strikethrough()
                    .foregroundColor(ReachuColors.textSecondary)
            }
            
            Text(formatPrice(price.amount))
                .font(ReachuTypography.headline)
                .foregroundColor(ReachuColors.primary)
        }
    }
    
    private func formatPrice(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = price.currency
        return formatter.string(from: NSNumber(value: amount)) ?? ""
    }
}
```

### 3. Cart Components 🛒

**Ubicación**: `Sources/ReachuUI/Views/Cart/`

#### CartView.swift
```swift
public struct CartView: View {
    @StateObject private var viewModel = CartViewModel()
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            VStack {
                if viewModel.cart.lineItems.isEmpty {
                    CartEmptyView()
                } else {
                    List {
                        ForEach(viewModel.cart.lineItems, id: \.id) { item in
                            CartItemView(
                                item: item,
                                onUpdateQuantity: { quantity in
                                    Task {
                                        await viewModel.updateItemQuantity(item: item, quantity: quantity)
                                    }
                                },
                                onRemove: {
                                    Task {
                                        await viewModel.removeItem(item: item)
                                    }
                                }
                            )
                        }
                        
                        CartSummaryView(cart: viewModel.cart)
                    }
                    
                    RButton(
                        title: "Proceed to Checkout",
                        style: .primary,
                        size: .large,
                        isLoading: viewModel.isProcessingCheckout
                    ) {
                        Task {
                            await viewModel.proceedToCheckout()
                        }
                    }
                    .padding(ReachuSpacing.md)
                }
            }
            .navigationTitle("Cart")
            .task {
                await viewModel.loadCart()
            }
        }
    }
}
```

#### CartItemView.swift
```swift
public struct CartItemView: View {
    private let item: LineItemDto
    private let onUpdateQuantity: (Int) -> Void
    private let onRemove: () -> Void
    
    public init(
        item: LineItemDto,
        onUpdateQuantity: @escaping (Int) -> Void,
        onRemove: @escaping () -> Void
    ) {
        self.item = item
        self.onUpdateQuantity = onUpdateQuantity
        self.onRemove = onRemove
    }
    
    public var body: some View {
        HStack(spacing: ReachuSpacing.md) {
            // Product Image
            ReachuAsyncImage(
                url: URL(string: item.product.images.first?.url ?? "")
            )
            .frame(width: 80, height: 80)
            .cornerRadius(ReachuBorderRadius.small)
            
            VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
                Text(item.product.title)
                    .font(ReachuTypography.body)
                    .lineLimit(2)
                
                ProductPriceView(price: item.product.price)
                
                HStack {
                    QuantitySelector(
                        quantity: item.quantity,
                        onQuantityChanged: onUpdateQuantity
                    )
                    
                    Spacer()
                    
                    Button("Remove", action: onRemove)
                        .foregroundColor(ReachuColors.error)
                        .font(ReachuTypography.footnote)
                }
            }
            
            Spacer()
        }
        .padding(ReachuSpacing.sm)
    }
}
```

#### MiniCartView.swift
```swift
public struct MiniCartView: View {
    @StateObject private var cartViewModel = CartViewModel()
    @State private var showFullCart = false
    
    public init() {}
    
    public var body: some View {
        Button {
            showFullCart = true
        } label: {
            CartBadgeView(itemCount: cartViewModel.cart.lineItems.count)
        }
        .sheet(isPresented: $showFullCart) {
            CartView()
        }
        .task {
            await cartViewModel.loadCart()
        }
    }
}
```

#### CartBadgeView.swift
```swift
public struct CartBadgeView: View {
    private let itemCount: Int
    
    public init(itemCount: Int) {
        self.itemCount = itemCount
    }
    
    public var body: some View {
        ZStack {
            Image(systemName: "cart")
                .font(.title2)
                .foregroundColor(ReachuColors.primary)
            
            if itemCount > 0 {
                Text("\(itemCount)")
                    .font(ReachuTypography.caption2)
                    .foregroundColor(.white)
                    .frame(width: 20, height: 20)
                    .background(ReachuColors.error)
                    .clipShape(Circle())
                    .offset(x: 10, y: -10)
            }
        }
    }
}
```

### 4. Checkout Components 💳

**Ubicación**: `Sources/ReachuUI/Views/Checkout/`

#### CheckoutView.swift
```swift
public struct CheckoutView: View {
    @StateObject private var viewModel = CheckoutViewModel()
    private let cartId: String
    
    public init(cartId: String) {
        self.cartId = cartId
    }
    
    public var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: ReachuSpacing.lg) {
                    CheckoutSummaryView(cart: viewModel.cart)
                    
                    ShippingAddressView(
                        address: $viewModel.shippingAddress,
                        onAddressChanged: viewModel.updateShippingAddress
                    )
                    
                    PaymentMethodView(
                        selectedMethod: $viewModel.selectedPaymentMethod,
                        availableMethods: viewModel.availablePaymentMethods
                    )
                    
                    RButton(
                        title: "Place Order",
                        style: .primary,
                        size: .large,
                        isLoading: viewModel.isProcessingOrder
                    ) {
                        Task {
                            await viewModel.placeOrder()
                        }
                    }
                }
                .padding(ReachuSpacing.md)
            }
            .navigationTitle("Checkout")
            .task {
                await viewModel.loadCheckout(cartId: cartId)
            }
        }
    }
}
```

### 5. ViewModels 🧠

**Ubicación**: `Sources/ReachuUI/ViewModels/`

#### BaseViewModel.swift
```swift
@MainActor
public class BaseViewModel: ObservableObject {
    @Published public var isLoading = false
    @Published public var errorMessage: String?
    
    protected func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
    }
    
    protected func withLoading<T>(_ operation: () async throws -> T) async -> T? {
        isLoading = true
        defer { isLoading = false }
        
        do {
            return try await operation()
        } catch {
            handleError(error)
            return nil
        }
    }
}
```

#### ProductViewModel.swift
```swift
@MainActor
public class ProductViewModel: BaseViewModel {
    @Published public var products: [Product] = []
    @Published public var selectedProduct: Product?
    
    private let productsModule = Reachu.shared.products
    private let cartModule = Reachu.shared.cart
    
    public func loadProducts() async {
        await withLoading {
            products = try await productsModule.getProducts()
        }
    }
    
    public func selectProduct(_ product: Product) {
        selectedProduct = product
    }
    
    public func addToCart(_ product: Product) async {
        guard let cartId = getCurrentCartId() else { return }
        
        await withLoading {
            let lineItem = LineItemInput(
                productId: product.id,
                variantId: product.variants.first?.id,
                quantity: 1
            )
            _ = try await cartModule.addItem(cartId: cartId, lineItems: lineItem)
        }
    }
    
    private func getCurrentCartId() -> String? {
        // Implementar lógica para obtener cart ID actual
        return nil
    }
}
```

#### CartViewModel.swift
```swift
@MainActor
public class CartViewModel: BaseViewModel {
    @Published public var cart: CartDto = CartDto.empty
    @Published public var isProcessingCheckout = false
    
    private let cartModule = Reachu.shared.cart
    private let checkoutModule = Reachu.shared.checkout
    
    public func loadCart() async {
        guard let cartId = getCurrentCartId() else { return }
        
        await withLoading {
            cart = try await cartModule.getCart(cartId: cartId)
        }
    }
    
    public func updateItemQuantity(item: LineItemDto, quantity: Int) async {
        await withLoading {
            _ = try await cartModule.updateItem(
                cartId: cart.cartId,
                cartItemId: item.id,
                quantity: quantity,
                shippingId: nil
            )
            await loadCart()
        }
    }
    
    public func removeItem(item: LineItemDto) async {
        await withLoading {
            _ = try await cartModule.deleteItem(
                cartId: cart.cartId,
                cartItemId: item.id
            )
            await loadCart()
        }
    }
    
    public func proceedToCheckout() async {
        isProcessingCheckout = true
        defer { isProcessingCheckout = false }
        
        await withLoading {
            _ = try await checkoutModule.createCheckout(cartId: cart.cartId)
            // Navegar a checkout view
        }
    }
    
    private func getCurrentCartId() -> String? {
        // Implementar lógica para obtener cart ID actual
        return nil
    }
}
```

---

## 📺 DESARROLLADOR 3: LIVESTREAM (ReachuLiveShow + ReachuLiveUI)

**Responsabilidad**: Funcionalidad de livestreaming y sus componentes UI

### 1. ReachuLiveShow Core 📡

**Ubicación**: `Sources/ReachuLiveShow/Services/`

#### WebSocketManager.swift - Starscream Integration
```swift
import Starscream

public protocol WebSocketManagerDelegate: AnyObject {
    func webSocketDidConnect()
    func webSocketDidDisconnect(error: Error?)
    func webSocketDidReceiveMessage(_ message: String)
}

public class WebSocketManager: ObservableObject {
    private var socket: WebSocket?
    private let configuration: Configuration
    
    public weak var delegate: WebSocketManagerDelegate?
    
    @Published public var isConnected = false
    @Published public var connectionError: Error?
    
    public init(configuration: Configuration) {
        self.configuration = configuration
    }
    
    public func connect() {
        guard let url = URL(string: configuration.webSocketEndpoint) else { return }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(configuration.apiKey)", forHTTPHeaderField: "Authorization")
        
        socket = WebSocket(request: request)
        socket?.delegate = self
        socket?.connect()
    }
    
    public func disconnect() {
        socket?.disconnect()
    }
    
    public func sendMessage(_ message: String) {
        socket?.write(string: message)
    }
    
    public func sendData(_ data: Data) {
        socket?.write(data: data)
    }
}

extension WebSocketManager: WebSocketDelegate {
    public func didReceive(event: WebSocketEvent, client: WebSocket) {
        switch event {
        case .connected(let headers):
            DispatchQueue.main.async {
                self.isConnected = true
                self.connectionError = nil
                self.delegate?.webSocketDidConnect()
            }
            
        case .disconnected(let reason, let code):
            DispatchQueue.main.async {
                self.isConnected = false
                let error = NSError(domain: "WebSocket", code: Int(code), userInfo: [NSLocalizedDescriptionKey: reason])
                self.connectionError = error
                self.delegate?.webSocketDidDisconnect(error: error)
            }
            
        case .text(let string):
            DispatchQueue.main.async {
                self.delegate?.webSocketDidReceiveMessage(string)
            }
            
        case .binary(let data):
            // Handle binary data if needed
            break
            
        case .error(let error):
            DispatchQueue.main.async {
                self.connectionError = error
                self.delegate?.webSocketDidDisconnect(error: error)
            }
            
        default:
            break
        }
    }
}
```

#### LiveStreamService.swift
```swift
public class LiveStreamService: ObservableObject {
    @Published public var currentStream: LiveStream?
    @Published public var isStreaming = false
    @Published public var viewers: [LiveUser] = []
    @Published public var streamEvents: [LiveEvent] = []
    
    private let webSocketManager: WebSocketManager
    private let networkClient: NetworkClient
    
    public init(configuration: Configuration) {
        self.webSocketManager = WebSocketManager(configuration: configuration)
        self.networkClient = NetworkClient(configuration: configuration)
        
        webSocketManager.delegate = self
    }
    
    public func startStream(streamId: String) async throws {
        // Start stream logic
        try await networkClient.performRESTRequest(
            endpoint: "/streams/\(streamId)/start",
            method: .POST,
            body: nil
        )
        
        webSocketManager.connect()
        isStreaming = true
    }
    
    public func stopStream() async throws {
        guard let stream = currentStream else { return }
        
        try await networkClient.performRESTRequest(
            endpoint: "/streams/\(stream.id)/stop",
            method: .POST,
            body: nil
        )
        
        webSocketManager.disconnect()
        isStreaming = false
    }
    
    public func joinStream(streamId: String) async throws {
        let stream: LiveStream = try await networkClient.performRESTRequest(
            endpoint: "/streams/\(streamId)",
            method: .GET,
            body: nil
        )
        
        currentStream = stream
        webSocketManager.connect()
    }
    
    public func leaveStream() {
        webSocketManager.disconnect()
        currentStream = nil
        viewers.removeAll()
        streamEvents.removeAll()
    }
}

extension LiveStreamService: WebSocketManagerDelegate {
    public func webSocketDidConnect() {
        // Handle connection
    }
    
    public func webSocketDidDisconnect(error: Error?) {
        // Handle disconnection
    }
    
    public func webSocketDidReceiveMessage(_ message: String) {
        guard let data = message.data(using: .utf8),
              let event = try? JSONDecoder().decode(LiveEvent.self, from: data) else {
            return
        }
        
        handleLiveEvent(event)
    }
    
    private func handleLiveEvent(_ event: LiveEvent) {
        streamEvents.append(event)
        
        switch event.type {
        case .userJoined(let user):
            viewers.append(user)
        case .userLeft(let userId):
            viewers.removeAll { $0.id == userId }
        case .chatMessage:
            // Handle chat message
            break
        case .productHighlight:
            // Handle product highlight
            break
        }
    }
}
```

#### LiveChatService.swift
```swift
public class LiveChatService: ObservableObject {
    @Published public var messages: [LiveMessage] = []
    @Published public var isTyping = false
    
    private let webSocketManager: WebSocketManager
    private let currentUser: LiveUser
    
    public init(webSocketManager: WebSocketManager, currentUser: LiveUser) {
        self.webSocketManager = webSocketManager
        self.currentUser = currentUser
    }
    
    public func sendMessage(_ content: String) {
        let message = LiveMessage(
            id: UUID().uuidString,
            content: content,
            user: currentUser,
            timestamp: Date(),
            type: .text
        )
        
        guard let messageData = try? JSONEncoder().encode(message),
              let messageString = String(data: messageData, encoding: .utf8) else {
            return
        }
        
        webSocketManager.sendMessage(messageString)
        messages.append(message)
    }
    
    public func sendReaction(_ reaction: String) {
        let message = LiveMessage(
            id: UUID().uuidString,
            content: reaction,
            user: currentUser,
            timestamp: Date(),
            type: .reaction
        )
        
        guard let messageData = try? JSONEncoder().encode(message),
              let messageString = String(data: messageData, encoding: .utf8) else {
            return
        }
        
        webSocketManager.sendMessage(messageString)
    }
    
    public func receiveMessage(_ message: LiveMessage) {
        messages.append(message)
    }
    
    public func clearMessages() {
        messages.removeAll()
    }
}
```

#### LiveProductService.swift
```swift
public class LiveProductService: ObservableObject {
    @Published public var featuredProducts: [LiveProduct] = []
    @Published public var currentlyHighlighted: LiveProduct?
    
    private let productsModule: ProductsModule
    private let cartModule: CartModule
    private let webSocketManager: WebSocketManager
    
    public init(
        productsModule: ProductsModule,
        cartModule: CartModule,
        webSocketManager: WebSocketManager
    ) {
        self.productsModule = productsModule
        self.cartModule = cartModule
        self.webSocketManager = webSocketManager
    }
    
    public func loadStreamProducts(streamId: String) async throws {
        // Load products associated with the stream
        let products: [Product] = try await productsModule.getProducts()
        featuredProducts = products.map { LiveProduct(from: $0, streamId: streamId) }
    }
    
    public func highlightProduct(_ product: LiveProduct) {
        currentlyHighlighted = product
        
        let event = LiveEvent(
            id: UUID().uuidString,
            type: .productHighlight(product),
            timestamp: Date()
        )
        
        guard let eventData = try? JSONEncoder().encode(event),
              let eventString = String(data: eventData, encoding: .utf8) else {
            return
        }
        
        webSocketManager.sendMessage(eventString)
    }
    
    public func addToCartFromLive(_ product: LiveProduct) async throws {
        guard let cartId = getCurrentCartId() else {
            throw LiveStreamError.noActiveCart
        }
        
        let lineItem = LineItemInput(
            productId: product.productId,
            variantId: product.selectedVariantId,
            quantity: 1
        )
        
        _ = try await cartModule.addItem(cartId: cartId, lineItems: lineItem)
    }
    
    private func getCurrentCartId() -> String? {
        // Get current cart ID logic
        return nil
    }
}
```

### 2. ReachuLiveShow Models 📄

**Ubicación**: `Sources/ReachuLiveShow/Models/`

#### LiveStream.swift
```swift
public struct LiveStream: Codable, Identifiable {
    public let id: String
    public let title: String
    public let description: String?
    public let hostId: String
    public let hostName: String
    public let thumbnailUrl: String?
    public let streamUrl: String
    public let chatRoomId: String
    public let status: StreamStatus
    public let startedAt: Date?
    public let endedAt: Date?
    public let viewerCount: Int
    public let maxViewers: Int
    public let productIds: [Int]
    public let tags: [String]
    
    public enum StreamStatus: String, Codable {
        case scheduled, live, ended, cancelled
    }
}
```

#### LiveMessage.swift
```swift
public struct LiveMessage: Codable, Identifiable {
    public let id: String
    public let content: String
    public let user: LiveUser
    public let timestamp: Date
    public let type: MessageType
    public let metadata: [String: String]?
    
    public enum MessageType: String, Codable {
        case text, reaction, system, productMention
    }
    
    public init(
        id: String,
        content: String,
        user: LiveUser,
        timestamp: Date,
        type: MessageType,
        metadata: [String: String]? = nil
    ) {
        self.id = id
        self.content = content
        self.user = user
        self.timestamp = timestamp
        self.type = type
        self.metadata = metadata
    }
}
```

#### LiveProduct.swift
```swift
public struct LiveProduct: Codable, Identifiable {
    public let id: String
    public let productId: Int
    public let streamId: String
    public let product: Product
    public let selectedVariantId: Int?
    public let highlightedAt: Date?
    public let specialPrice: Double?
    public let livePriceEndTime: Date?
    public let viewCount: Int
    public let clickCount: Int
    
    public init(from product: Product, streamId: String) {
        self.id = UUID().uuidString
        self.productId = product.id
        self.streamId = streamId
        self.product = product
        self.selectedVariantId = product.variants.first?.id
        self.highlightedAt = nil
        self.specialPrice = nil
        self.livePriceEndTime = nil
        self.viewCount = 0
        self.clickCount = 0
    }
}
```

#### LiveUser.swift
```swift
public struct LiveUser: Codable, Identifiable {
    public let id: String
    public let username: String
    public let displayName: String
    public let avatarUrl: String?
    public let joinedAt: Date
    public let role: UserRole
    public let badges: [UserBadge]
    
    public enum UserRole: String, Codable {
        case host, moderator, viewer, vip
    }
    
    public struct UserBadge: Codable {
        public let name: String
        public let iconUrl: String
        public let color: String
    }
}
```

#### LiveEvent.swift
```swift
public struct LiveEvent: Codable, Identifiable {
    public let id: String
    public let type: EventType
    public let timestamp: Date
    public let data: [String: String]?
    
    public enum EventType: Codable {
        case userJoined(LiveUser)
        case userLeft(String)
        case chatMessage(LiveMessage)
        case productHighlight(LiveProduct)
        case streamStarted
        case streamEnded
        case viewerCountUpdate(Int)
        
        private enum CodingKeys: String, CodingKey {
            case type, data
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let typeString = try container.decode(String.self, forKey: .type)
            let data = try container.decodeIfPresent(Data.self, forKey: .data)
            
            switch typeString {
            case "userJoined":
                let user = try JSONDecoder().decode(LiveUser.self, from: data!)
                self = .userJoined(user)
            case "userLeft":
                let userId = try JSONDecoder().decode(String.self, from: data!)
                self = .userLeft(userId)
            case "chatMessage":
                let message = try JSONDecoder().decode(LiveMessage.self, from: data!)
                self = .chatMessage(message)
            case "productHighlight":
                let product = try JSONDecoder().decode(LiveProduct.self, from: data!)
                self = .productHighlight(product)
            case "streamStarted":
                self = .streamStarted
            case "streamEnded":
                self = .streamEnded
            case "viewerCountUpdate":
                let count = try JSONDecoder().decode(Int.self, from: data!)
                self = .viewerCountUpdate(count)
            default:
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unknown event type")
                )
            }
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            switch self {
            case .userJoined(let user):
                try container.encode("userJoined", forKey: .type)
                try container.encode(JSONEncoder().encode(user), forKey: .data)
            case .userLeft(let userId):
                try container.encode("userLeft", forKey: .type)
                try container.encode(JSONEncoder().encode(userId), forKey: .data)
            case .chatMessage(let message):
                try container.encode("chatMessage", forKey: .type)
                try container.encode(JSONEncoder().encode(message), forKey: .data)
            case .productHighlight(let product):
                try container.encode("productHighlight", forKey: .type)
                try container.encode(JSONEncoder().encode(product), forKey: .data)
            case .streamStarted:
                try container.encode("streamStarted", forKey: .type)
            case .streamEnded:
                try container.encode("streamEnded", forKey: .type)
            case .viewerCountUpdate(let count):
                try container.encode("viewerCountUpdate", forKey: .type)
                try container.encode(JSONEncoder().encode(count), forKey: .data)
            }
        }
    }
}
```

### 3. ReachuLiveUI Components 📺

**Ubicación**: `Sources/ReachuLiveUI/Views/`

#### LiveStreamPlayerView.swift
```swift
import AVKit

public struct LiveStreamPlayerView: View {
    private let streamUrl: String
    @State private var player: AVPlayer?
    
    public init(streamUrl: String) {
        self.streamUrl = streamUrl
    }
    
    public var body: some View {
        ZStack {
            if let player = player {
                VideoPlayer(player: player)
                    .aspectRatio(16/9, contentMode: .fit)
            } else {
                Rectangle()
                    .fill(Color.black)
                    .aspectRatio(16/9, contentMode: .fit)
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    )
            }
        }
        .onAppear {
            setupPlayer()
        }
        .onDisappear {
            player?.pause()
        }
    }
    
    private func setupPlayer() {
        guard let url = URL(string: streamUrl) else { return }
        player = AVPlayer(url: url)
        player?.play()
    }
}
```

#### LiveChatView.swift
```swift
public struct LiveChatView: View {
    @StateObject private var chatService: LiveChatService
    @State private var messageText = ""
    @State private var showEmojiPicker = false
    
    public init(chatService: LiveChatService) {
        self._chatService = StateObject(wrappedValue: chatService)
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Messages List
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: ReachuSpacing.xs) {
                        ForEach(chatService.messages) { message in
                            LiveMessageView(message: message)
                                .id(message.id)
                        }
                    }
                    .padding(.horizontal, ReachuSpacing.sm)
                }
                .onChange(of: chatService.messages.count) { _ in
                    if let lastMessage = chatService.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            Divider()
            
            // Input Area
            HStack(spacing: ReachuSpacing.sm) {
                TextField("Type a message...", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button {
                    showEmojiPicker.toggle()
                } label: {
                    Image(systemName: "face.smiling")
                        .foregroundColor(ReachuColors.primary)
                }
                
                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(messageText.isEmpty ? ReachuColors.textSecondary : ReachuColors.primary)
                }
                .disabled(messageText.isEmpty)
            }
            .padding(ReachuSpacing.sm)
        }
        .background(ReachuColors.surface.opacity(0.9))
        .sheet(isPresented: $showEmojiPicker) {
            EmojiPickerView { emoji in
                messageText += emoji
                showEmojiPicker = false
            }
        }
    }
    
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        chatService.sendMessage(messageText)
        messageText = ""
    }
}
```

#### LiveMessageView.swift
```swift
public struct LiveMessageView: View {
    private let message: LiveMessage
    
    public init(message: LiveMessage) {
        self.message = message
    }
    
    public var body: some View {
        HStack(alignment: .top, spacing: ReachuSpacing.xs) {
            // User Avatar
            AsyncImage(url: URL(string: message.user.avatarUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(ReachuColors.primary)
                    .overlay(
                        Text(String(message.user.displayName.prefix(1)))
                            .foregroundColor(.white)
                            .font(ReachuTypography.caption1)
                    )
            }
            .frame(width: 24, height: 24)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: ReachuSpacing.xs) {
                    Text(message.user.displayName)
                        .font(ReachuTypography.caption1)
                        .fontWeight(.semibold)
                        .foregroundColor(colorForUserRole(message.user.role))
                    
                    // User Badges
                    ForEach(message.user.badges, id: \.name) { badge in
                        Image(systemName: "star.fill")
                            .foregroundColor(Color(hex: badge.color))
                            .font(.caption2)
                    }
                    
                    Spacer()
                    
                    Text(formatTimestamp(message.timestamp))
                        .font(ReachuTypography.caption2)
                        .foregroundColor(ReachuColors.textTertiary)
                }
                
                switch message.type {
                case .text:
                    Text(message.content)
                        .font(ReachuTypography.footnote)
                        .foregroundColor(ReachuColors.textPrimary)
                case .reaction:
                    Text(message.content)
                        .font(.title2)
                case .system:
                    Text(message.content)
                        .font(ReachuTypography.caption1)
                        .foregroundColor(ReachuColors.textSecondary)
                        .italic()
                case .productMention:
                    ProductMentionView(content: message.content)
                }
            }
        }
        .padding(.vertical, 2)
    }
    
    private func colorForUserRole(_ role: LiveUser.UserRole) -> Color {
        switch role {
        case .host:
            return ReachuColors.primary
        case .moderator:
            return ReachuColors.secondary
        case .vip:
            return ReachuColors.warning
        case .viewer:
            return ReachuColors.textPrimary
        }
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}
```

#### LiveProductShowcaseView.swift
```swift
public struct LiveProductShowcaseView: View {
    @StateObject private var productService: LiveProductService
    @State private var selectedProduct: LiveProduct?
    
    public init(productService: LiveProductService) {
        self._productService = StateObject(wrappedValue: productService)
    }
    
    public var body: some View {
        VStack(spacing: ReachuSpacing.md) {
            // Currently Highlighted Product
            if let highlighted = productService.currentlyHighlighted {
                LiveHighlightedProductView(
                    product: highlighted,
                    onAddToCart: {
                        Task {
                            try await productService.addToCartFromLive(highlighted)
                        }
                    },
                    onViewDetails: {
                        selectedProduct = highlighted
                    }
                )
                .transition(.scale.combined(with: .opacity))
            }
            
            // Featured Products Carousel
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: ReachuSpacing.sm) {
                    ForEach(productService.featuredProducts) { product in
                        LiveProductCardView(
                            product: product,
                            onTap: {
                                selectedProduct = product
                            },
                            onAddToCart: {
                                Task {
                                    try await productService.addToCartFromLive(product)
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, ReachuSpacing.md)
            }
        }
        .sheet(item: $selectedProduct) { product in
            LiveProductDetailView(product: product)
        }
    }
}
```

#### LiveHighlightedProductView.swift
```swift
public struct LiveHighlightedProductView: View {
    private let product: LiveProduct
    private let onAddToCart: () -> Void
    private let onViewDetails: () -> Void
    
    public init(
        product: LiveProduct,
        onAddToCart: @escaping () -> Void,
        onViewDetails: @escaping () -> Void
    ) {
        self.product = product
        self.onAddToCart = onAddToCart
        self.onViewDetails = onViewDetails
    }
    
    public var body: some View {
        RCard(padding: ReachuSpacing.md) {
            HStack(spacing: ReachuSpacing.md) {
                // Product Image
                ReachuAsyncImage(
                    url: URL(string: product.product.images.first?.url ?? "")
                )
                .frame(width: 80, height: 80)
                .cornerRadius(ReachuBorderRadius.small)
                
                VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
                    Text("NOW FEATURING")
                        .font(ReachuTypography.caption1)
                        .foregroundColor(ReachuColors.primary)
                        .fontWeight(.bold)
                    
                    Text(product.product.title)
                        .font(ReachuTypography.headline)
                        .lineLimit(2)
                    
                    HStack {
                        if let specialPrice = product.specialPrice {
                            VStack(alignment: .leading) {
                                Text("Live Price")
                                    .font(ReachuTypography.caption2)
                                    .foregroundColor(ReachuColors.error)
                                
                                Text(formatPrice(specialPrice))
                                    .font(ReachuTypography.title3)
                                    .foregroundColor(ReachuColors.error)
                                    .fontWeight(.bold)
                            }
                            
                            Text(formatPrice(product.product.price.amount))
                                .font(ReachuTypography.footnote)
                                .strikethrough()
                                .foregroundColor(ReachuColors.textSecondary)
                        } else {
                            ProductPriceView(price: product.product.price)
                        }
                        
                        Spacer()
                    }
                }
                
                VStack(spacing: ReachuSpacing.xs) {
                    RButton(
                        title: "Add to Cart",
                        style: .primary,
                        size: .small,
                        action: onAddToCart
                    )
                    
                    Button("View Details", action: onViewDetails)
                        .font(ReachuTypography.footnote)
                        .foregroundColor(ReachuColors.primary)
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: ReachuBorderRadius.medium)
                .stroke(ReachuColors.primary, lineWidth: 2)
        )
    }
    
    private func formatPrice(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = product.product.price.currency
        return formatter.string(from: NSNumber(value: amount)) ?? ""
    }
}
```

#### ViewerCountView.swift
```swift
public struct ViewerCountView: View {
    private let viewerCount: Int
    private let isLive: Bool
    
    public init(viewerCount: Int, isLive: Bool = true) {
        self.viewerCount = viewerCount
        self.isLive = isLive
    }
    
    public var body: some View {
        HStack(spacing: ReachuSpacing.xs) {
            if isLive {
                Circle()
                    .fill(ReachuColors.error)
                    .frame(width: 8, height: 8)
                    .overlay(
                        Circle()
                            .fill(ReachuColors.error.opacity(0.3))
                            .scaleEffect(1.5)
                            .animation(
                                .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                                value: isLive
                            )
                    )
                
                Text("LIVE")
                    .font(ReachuTypography.caption1)
                    .fontWeight(.bold)
                    .foregroundColor(ReachuColors.error)
            }
            
            Image(systemName: "eye.fill")
                .font(ReachuTypography.caption1)
                .foregroundColor(ReachuColors.textSecondary)
            
            Text(formatViewerCount(viewerCount))
                .font(ReachuTypography.caption1)
                .foregroundColor(ReachuColors.textSecondary)
        }
        .padding(.horizontal, ReachuSpacing.sm)
        .padding(.vertical, ReachuSpacing.xs)
        .background(ReachuColors.surface.opacity(0.9))
        .cornerRadius(ReachuBorderRadius.small)
    }
    
    private func formatViewerCount(_ count: Int) -> String {
        if count < 1000 {
            return "\(count)"
        } else if count < 1000000 {
            return String(format: "%.1fK", Double(count) / 1000.0)
        } else {
            return String(format: "%.1fM", Double(count) / 1000000.0)
        }
    }
}
```

### 4. LiveStream ViewModels 🧠

**Ubicación**: `Sources/ReachuLiveUI/ViewModels/`

#### LiveStreamViewModel.swift
```swift
@MainActor
public class LiveStreamViewModel: BaseViewModel {
    @Published public var stream: LiveStream?
    @Published public var isConnected = false
    @Published public var viewerCount = 0
    @Published public var chatMessages: [LiveMessage] = []
    @Published public var featuredProducts: [LiveProduct] = []
    @Published public var currentlyHighlighted: LiveProduct?
    
    private let streamService: LiveStreamService
    private let chatService: LiveChatService
    private let productService: LiveProductService
    
    public init(configuration: Configuration) {
        self.streamService = LiveStreamService(configuration: configuration)
        // Initialize other services...
        super.init()
        
        setupObservers()
    }
    
    public func joinStream(streamId: String) async {
        await withLoading {
            try await streamService.joinStream(streamId: streamId)
            try await productService.loadStreamProducts(streamId: streamId)
            
            stream = streamService.currentStream
            isConnected = streamService.webSocketManager.isConnected
            featuredProducts = productService.featuredProducts
        }
    }
    
    public func leaveStream() {
        streamService.leaveStream()
        chatService.clearMessages()
        
        stream = nil
        isConnected = false
        chatMessages.removeAll()
        featuredProducts.removeAll()
        currentlyHighlighted = nil
    }
    
    public func sendChatMessage(_ content: String) {
        chatService.sendMessage(content)
    }
    
    public func highlightProduct(_ product: LiveProduct) {
        productService.highlightProduct(product)
    }
    
    private func setupObservers() {
        // Setup observers for real-time updates
        streamService.$viewers
            .map(\.count)
            .assign(to: &$viewerCount)
        
        chatService.$messages
            .assign(to: &$chatMessages)
        
        productService.$currentlyHighlighted
            .assign(to: &$currentlyHighlighted)
        
        productService.$featuredProducts
            .assign(to: &$featuredProducts)
    }
}
```

---

## 🚀 Timeline de Desarrollo

### **Semana 1-2: Foundation & Setup**

**Desarrollador Core:**
- [ ] Crear y configurar ReachuNetwork module
- [ ] Implementar NetworkClient, GraphQLClient, RESTClient
- [ ] Setup AuthenticationManager y NetworkError
- [ ] Crear models base y DTOs principales

**Angelo (UI):**
- [ ] Crear y configurar ReachuDesignSystem module
- [ ] Implementar sistema de tokens (Colors, Typography, Spacing)
- [ ] Crear componentes base (RButton, RCard, RTextField)
- [ ] Setup ImageLoader con Nuke integration

**Desarrollador LiveShow:**
- [ ] Research y arquitectura WebSocket con Starscream
- [ ] Crear models básicos (LiveStream, LiveMessage, LiveUser)
- [ ] Implementar WebSocketManager base
- [ ] Setup estructura de ReachuLiveShow module

### **Semana 3-4: Core Implementation**

**Desarrollador Core:**
- [ ] Implementar todos los módulos de negocio:
  - [ ] CartModule (completo según RN SDK)
  - [ ] ProductsModule (todos los métodos)
  - [ ] ChannelModule (nuevo, concepto clave)
  - [ ] CheckoutModule
  - [ ] PaymentsModule
  - [ ] DiscountModule (nuevo)
  - [ ] MarketModule (nuevo)
- [ ] Integration testing con GraphQL endpoints

**Angelo (UI):**
- [ ] Implementar Product Components:
  - [ ] ProductCardView
  - [ ] ProductListView
  - [ ] ProductDetailView
  - [ ] ProductImageCarousel
  - [ ] ProductPriceView
- [ ] Implementar Cart Components:
  - [ ] CartView
  - [ ] CartItemView
  - [ ] MiniCartView
  - [ ] CartSummaryView
- [ ] Crear ViewModels (ProductViewModel, CartViewModel)

**Desarrollador LiveShow:**
- [ ] Implementar core services:
  - [ ] LiveStreamService
  - [ ] LiveChatService
  - [ ] LiveProductService
  - [ ] LiveAnalyticsService
- [ ] Integration con ReachuCore modules
- [ ] Testing de WebSocket connections

### **Semana 5-6: Advanced Features & Integration**

**Desarrollador Core:**
- [ ] Optimization y error handling
- [ ] Comprehensive testing de todos los módulos
- [ ] Documentation de APIs
- [ ] Performance testing

**Angelo (UI):**
- [ ] Implementar Checkout Components:
  - [ ] CheckoutView
  - [ ] ShippingAddressView
  - [ ] PaymentMethodView
  - [ ] OrderConfirmationView
- [ ] Crear CheckoutViewModel
- [ ] UI testing y polish
- [ ] Accessibility features

**Desarrollador LiveShow:**
- [ ] Implementar LiveUI Components:
  - [ ] LiveStreamPlayerView
  - [ ] LiveChatView
  - [ ] LiveProductShowcaseView
  - [ ] ViewerCountView
- [ ] Crear LiveStreamViewModel
- [ ] Integration testing con UI y Core
- [ ] Real-time features testing

### **Semana 7-8: Integration, Testing & Documentation**

**Todo el equipo:**
- [ ] Integration testing entre todos los módulos
- [ ] End-to-end testing de flows completos
- [ ] Performance optimization
- [ ] Security review
- [ ] Documentation completa
- [ ] Demo app creation
- [ ] Release preparation

---

## 📊 Entregables por Fase

### **Fase 1: Core Foundation**
- ✅ ReachuNetwork module funcional
- ✅ ReachuCore con todos los módulos de negocio
- ✅ Models y DTOs completos
- ✅ Integration con Reachu GraphQL API
- ✅ Unit tests para Core functionality

### **Fase 2: UI Components**
- ✅ ReachuDesignSystem module
- ✅ Product, Cart, y Checkout components
- ✅ ViewModels con state management
- ✅ Image loading con Nuke
- ✅ Responsive design para iOS/iPad

### **Fase 3: LiveStream Features**
- ✅ ReachuLiveShow module con WebSocket
- ✅ Real-time chat functionality
- ✅ Live product showcase
- ✅ ReachuLiveUI components
- ✅ Integration con Core modules

---

## 🎯 Criterios de Éxito

1. **Modularidad**: Los desarrolladores pueden importar solo los módulos necesarios
2. **Performance**: Loading times optimizados, smooth scrolling
3. **Usabilidad**: UI intuitiva y consistente con design system
4. **Escalabilidad**: Arquitectura que soporte futuras features
5. **Mantenibilidad**: Código limpio, bien documentado y testeable
6. **Compatibilidad**: Funciona en iOS 15+, iPadOS, macOS (SwiftUI)

---

## 📚 Recursos y Documentación

### **APIs y Endpoints**
- GraphQL Endpoint: `https://graph-ql-dev.reachu.io`
- REST API Base: `https://api.reachu.io`
- WebSocket Endpoint: `wss://live.reachu.io/ws`

### **Dependencias Externas**
- **Apollo iOS**: GraphQL client
- **Starscream**: WebSocket support para LiveShow
- **Nuke**: Image loading y caching

### **Testing Strategy**
- Unit tests para todos los modules
- Integration tests para API calls
- UI tests para critical user flows
- Performance tests para loading times

### **Documentation Structure**
```
docs/
├── API-Reference.md          # Documentación completa de APIs
├── Installation-Guide.md     # Guía de instalación modular
├── Getting-Started.md        # Quick start guide
├── Architecture.md           # Documentación de arquitectura
├── UI-Components.md          # Guía de componentes UI
├── LiveStream-Integration.md # Guía de livestream features
└── Examples/                 # Código de ejemplo
    ├── BasicIntegration/
    ├── CustomUI/
    └── LiveStreamApp/
```

---

## 📝 Notas Importantes

1. **Consistencia con RN SDK**: Mantener misma nomenclatura y estructura de APIs
2. **Swift Conventions**: Seguir Swift API Design Guidelines
3. **SwiftUI Best Practices**: Utilizar State management apropiado
4. **Error Handling**: Consistent error handling across modules
5. **Accessibility**: Implementar VoiceOver y accessibility features
6. **Internationalization**: Preparar strings para localización

---

*Este documento será actualizado conforme avance el desarrollo y se identifiquen nuevos requerimientos.*
