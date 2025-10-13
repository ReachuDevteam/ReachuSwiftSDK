import SwiftUI

/// Componente para mostrar un producto individual
/// Estilo basado en las cards del SDK de Reachu
struct TV2ProductOverlay: View {
    let product: ProductEventData
    let isChatExpanded: Bool
    let onAddToCart: () -> Void
    let onDismiss: () -> Void
    
    @State private var dragOffset: CGFloat = 0
    @State private var showCheckmark = false
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    private var isLandscape: Bool {
        verticalSizeClass == .compact
    }
    
    // Ajustar bottom padding basado en si el chat está expandido
    private var bottomPadding: CGFloat {
        if isLandscape {
            return 16
        } else {
            return isChatExpanded ? 250 : 80 // Más espacio cuando el chat está expandido
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if isLandscape {
                // Horizontal: lado derecho
                Spacer()
                HStack(spacing: 0) {
                    Spacer()
                    productCard
                        .frame(width: 220)
                        .padding(.trailing, 16)
                        .padding(.bottom, 16)
                        .offset(x: dragOffset)
                        .gesture(dragGesture)
                }
            } else {
                // Vertical: sobre el chat
                Spacer()
                productCard
                    .padding(.horizontal, 16)
                    .padding(.bottom, bottomPadding)
                    .offset(y: dragOffset)
                    .gesture(dragGesture)
            }
        }
    }
    
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                if isLandscape {
                    if value.translation.width > 0 {
                        dragOffset = value.translation.width
                    }
                } else {
                    if value.translation.height > 0 {
                        dragOffset = value.translation.height
                    }
                }
            }
            .onEnded { value in
                let threshold: CGFloat = 100
                if isLandscape {
                    if value.translation.width > threshold {
                        onDismiss()
                    } else {
                        withAnimation(.spring()) {
                            dragOffset = 0
                        }
                    }
                } else {
                    if value.translation.height > threshold {
                        onDismiss()
                    } else {
                        withAnimation(.spring()) {
                            dragOffset = 0
                        }
                    }
                }
            }
    }
    
    private var productCard: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 16) {
                // Drag indicator
                Capsule()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 40, height: 4)
                    .padding(.top, 8)
                
                // Imagen del producto
            AsyncImage(url: URL(string: product.imageUrl)) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(height: isLandscape ? 100 : 120)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: isLandscape ? 100 : 120)
                        .clipped()
                        .cornerRadius(12)
                case .failure:
                    Color.gray.opacity(0.3)
                        .frame(height: isLandscape ? 100 : 120)
                        .cornerRadius(12)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 30))
                                .foregroundColor(.white.opacity(0.5))
                        )
                @unknown default:
                    EmptyView()
                }
            }
            
            // Información del producto
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.system(size: isLandscape ? 13 : 14, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                if !product.description.isEmpty {
                    Text(product.description)
                        .font(.system(size: isLandscape ? 10 : 11))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(2)
                }
                
                // Precio
                Text(product.price)
                    .font(.system(size: isLandscape ? 14 : 16, weight: .bold))
                    .foregroundColor(Color(hex: "5B5FCF"))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Botón de agregar al carrito
            Button(action: {
                onAddToCart()
                showCheckmark = true
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showCheckmark = false
                }
            }) {
                HStack(spacing: 6) {
                    if showCheckmark {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                        Text("Lagt til!")
                            .font(.system(size: 13, weight: .semibold))
                    } else {
                        Image(systemName: "cart.fill")
                            .font(.system(size: 14))
                        Text("Legg til")
                            .font(.system(size: 13, weight: .semibold))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(showCheckmark ? Color.green : Color(hex: "5B5FCF"))
                )
            }
            .disabled(showCheckmark)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.6))
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                )
        )
        .shadow(color: .black.opacity(0.6), radius: 20, x: 0, y: 8)
            
            // Sponsor badge en esquina inferior derecha
            if let campaignLogo = product.campaignLogo, !campaignLogo.isEmpty {
                TV2SponsorBadge(logoUrl: campaignLogo)
                    .padding(.trailing, 8)
                    .padding(.bottom, 8)
            }
        }
    }
}

/// Componente para mostrar dos productos lado a lado
/// Similar a RProductSlider pero más compacto
struct TV2TwoProductsOverlay: View {
    let product1: ProductEventData
    let product2: ProductEventData
    let onAddToCart: (ProductEventData) -> Void
    let onDismiss: () -> Void
    
    @State private var dragOffset: CGFloat = 0
    @State private var addedProducts: Set<String> = []
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    private var isLandscape: Bool {
        verticalSizeClass == .compact
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            productsCard
                .padding(.horizontal, 16)
                .padding(.bottom, isLandscape ? 16 : 80)
                .offset(y: dragOffset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if value.translation.height > 0 {
                                dragOffset = value.translation.height
                            }
                        }
                        .onEnded { value in
                            if value.translation.height > 100 {
                                onDismiss()
                            } else {
                                withAnimation(.spring()) {
                                    dragOffset = 0
                                }
                            }
                        }
                )
        }
    }
    
    private var productsCard: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 12) {
                // Drag indicator
                Capsule()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 32, height: 4)
                
                // Header
            HStack {
                Text("🛍️ ANBEFALTE PRODUKTER")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(hex: "5B5FCF"))
                Spacer()
            }
            
            // Productos en grid
            if isLandscape {
                HStack(spacing: 12) {
                    productMiniCard(product1)
                    productMiniCard(product2)
                }
            } else {
                VStack(spacing: 12) {
                    productMiniCard(product1)
                    productMiniCard(product2)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.6))
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                )
        )
        .shadow(color: .black.opacity(0.6), radius: 20, x: 0, y: 8)
            
            // Sponsor badge en esquina inferior derecha (usando el logo del primer producto)
            if let campaignLogo = product1.campaignLogo, !campaignLogo.isEmpty {
                TV2SponsorBadge(logoUrl: campaignLogo)
                    .padding(.trailing, 8)
                    .padding(.bottom, 8)
            }
        }
    }
    
    private func productMiniCard(_ product: ProductEventData) -> some View {
        HStack(spacing: 12) {
            // Imagen
            AsyncImage(url: URL(string: product.imageUrl)) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: 80, height: 80)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 80)
                        .clipped()
                        .cornerRadius(8)
                case .failure:
                    Color.gray.opacity(0.3)
                        .frame(width: 80, height: 80)
                        .cornerRadius(8)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 24))
                                .foregroundColor(.white.opacity(0.5))
                        )
                @unknown default:
                    EmptyView()
                }
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                Text(product.price)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(TV2Theme.Colors.primary)
                
                Spacer()
                
                // Botón compacto
                Button(action: {
                    onAddToCart(product)
                    addedProducts.insert(product.id)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        addedProducts.remove(product.id)
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: addedProducts.contains(product.id) ? "checkmark.circle.fill" : "cart.fill")
                            .font(.system(size: 12))
                        Text(addedProducts.contains(product.id) ? "Lagt til" : "Legg til")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(addedProducts.contains(product.id) ? Color.green : Color(hex: "5B5FCF"))
                    )
                }
                .disabled(addedProducts.contains(product.id))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - Previews

#Preview("Single Product") {
    ZStack {
        Color.black.ignoresSafeArea()
        
        TV2ProductOverlay(
            product: ProductEventData(
                id: "prod_123",
                name: "iPhone 15 Pro Max",
                description: "El último modelo con titanio y cámara de 48MP",
                price: "$1,199",
                currency: "USD",
                imageUrl: "https://images.unsplash.com/photo-1592286927505-b7e00a46f74f",
                campaignLogo: "https://upload.wikimedia.org/wikipedia/commons/thumb/2/24/Adidas_logo.png/800px-Adidas_logo.png"
            ),
            isChatExpanded: false,
            onAddToCart: {
                print("Agregado al carrito")
            },
            onDismiss: {
                print("Cerrado")
            }
        )
    }
}

#Preview("Two Products") {
    ZStack {
        Color.black.ignoresSafeArea()
        
        TV2TwoProductsOverlay(
            product1: ProductEventData(
                id: "prod_1",
                name: "iPhone 15 Pro",
                description: "Titanio azul",
                price: "$999",
                currency: "USD",
                imageUrl: "https://images.unsplash.com/photo-1592286927505-b7e00a46f74f",
                campaignLogo: "https://upload.wikimedia.org/wikipedia/commons/thumb/2/24/Adidas_logo.png/800px-Adidas_logo.png"
            ),
            product2: ProductEventData(
                id: "prod_2",
                name: "AirPods Pro",
                description: "Con USB-C",
                price: "$249",
                currency: "USD",
                imageUrl: "https://images.unsplash.com/photo-1572569511254-d8f925fe2cbb",
                campaignLogo: "https://upload.wikimedia.org/wikipedia/commons/thumb/2/24/Adidas_logo.png/800px-Adidas_logo.png"
            ),
            onAddToCart: { product in
                print("Agregado: \(product.name)")
            },
            onDismiss: {
                print("Cerrado")
            }
        )
    }
}

