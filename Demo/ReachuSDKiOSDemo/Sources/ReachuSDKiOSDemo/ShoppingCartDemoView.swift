import SwiftUI
import ReachuDesignSystem

public struct ShoppingCartDemoView: View {
    @State private var cartItems: [CartItem] = [
        CartItem(id: "1", name: "iPhone 15 Pro", price: 999.99, quantity: 1, image: "📱"),
        CartItem(id: "2", name: "AirPods Pro", price: 249.99, quantity: 2, image: "🎧"),
        CartItem(id: "3", name: "MacBook Air", price: 1299.99, quantity: 1, image: "💻"),
    ]
    
    public init() {}
    
    private var totalPrice: Double {
        cartItems.reduce(0) { $0 + ($1.price * Double($1.quantity)) }
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(spacing: ReachuSpacing.md) {
                    ForEach(cartItems) { item in
                        CartItemRow(
                            item: item,
                            onQuantityChange: { newQuantity in
                                updateQuantity(for: item.id, newQuantity: newQuantity)
                            },
                            onRemove: {
                                removeItem(id: item.id)
                            }
                        )
                    }
                }
                .padding(ReachuSpacing.lg)
            }
            
            // Cart Summary
            VStack(spacing: ReachuSpacing.md) {
                Divider()
                
                HStack {
                    Text("Total")
                        .font(ReachuTypography.headline)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Text("$\(totalPrice, specifier: "%.2f")")
                        .font(ReachuTypography.headline)
                        .fontWeight(.bold)
                        .foregroundColor(ReachuColors.primary)
                }
                .padding(.horizontal, ReachuSpacing.lg)
                
                RButton(title: "Proceed to Checkout", style: .primary) {
                    print("Proceeding to checkout with total: $\(totalPrice)")
                }
                .padding(.horizontal, ReachuSpacing.lg)
                .padding(.bottom, ReachuSpacing.lg)
            }
            .background(ReachuColors.surface)
        }
        .navigationTitle("Shopping Cart")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
    
    private func updateQuantity(for id: String, newQuantity: Int) {
        if let index = cartItems.firstIndex(where: { $0.id == id }) {
            cartItems[index].quantity = max(1, newQuantity)
        }
    }
    
    private func removeItem(id: String) {
        cartItems.removeAll { $0.id == id }
    }
}

struct CartItem: Identifiable {
    let id: String
    let name: String
    let price: Double
    var quantity: Int
    let image: String
}

struct CartItemRow: View {
    let item: CartItem
    let onQuantityChange: (Int) -> Void
    let onRemove: () -> Void
    
    var body: some View {
        VStack(spacing: ReachuSpacing.md) {
            HStack(spacing: ReachuSpacing.md) {
                // Product Image
                Text(item.image)
                    .font(.largeTitle)
                    .frame(width: 60, height: 60)
                    .background(ReachuColors.surface)
                    .cornerRadius(ReachuBorderRadius.medium)
                
                // Product Info
                VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
                    Text(item.name)
                        .font(ReachuTypography.body)
                        .fontWeight(.medium)
                    
                    Text("$\(item.price, specifier: "%.2f")")
                        .font(ReachuTypography.callout)
                        .foregroundColor(ReachuColors.primary)
                }
                
                Spacer()
                
                // Quantity Controls
                HStack(spacing: ReachuSpacing.sm) {
                    Button("-") {
                        onQuantityChange(item.quantity - 1)
                    }
                    .frame(width: 32, height: 32)
                    .background(ReachuColors.textSecondary.opacity(0.1))
                    .cornerRadius(ReachuBorderRadius.small)
                    
                    Text("\(item.quantity)")
                        .font(ReachuTypography.callout)
                        .frame(minWidth: 30)
                    
                    Button("+") {
                        onQuantityChange(item.quantity + 1)
                    }
                    .frame(width: 32, height: 32)
                    .background(ReachuColors.primary.opacity(0.1))
                    .cornerRadius(ReachuBorderRadius.small)
                }
            }
            
            HStack {
                Spacer()
                
                Button("Remove") {
                    onRemove()
                }
                .foregroundColor(ReachuColors.error)
                .font(ReachuTypography.callout)
            }
        }
        .padding(ReachuSpacing.lg)
        .background(ReachuColors.surface)
        .cornerRadius(ReachuBorderRadius.large)
        .shadow(color: ReachuColors.textPrimary.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    NavigationView {
        ShoppingCartDemoView()
    }
}
