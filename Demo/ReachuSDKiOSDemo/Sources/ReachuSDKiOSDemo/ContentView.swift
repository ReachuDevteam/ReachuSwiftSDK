import SwiftUI
import ReachuDesignSystem

public struct ContentView: View {
    public init() {}
    
    public var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: ReachuSpacing.lg) {
                    // Header
                    VStack(spacing: ReachuSpacing.md) {
                        Text("🛍️ Reachu SDK")
                            .font(ReachuTypography.largeTitle)
                            .foregroundColor(ReachuColors.primary)
                        
                        Text("Demo iOS App")
                            .font(ReachuTypography.body)
                            .foregroundColor(ReachuColors.textPrimary)
                    }
                    .padding(.top, ReachuSpacing.xl)
                    
                    // Demo Sections
                    VStack(spacing: ReachuSpacing.lg) {
                        DemoSection(
                            title: "Design System",
                            description: "Explora los componentes de diseño",
                            icon: "🎨"
                        ) {
                            NavigationLink("Ver Design System") {
                                DesignSystemDemoView()
                            }
                        }
                        
                        DemoSection(
                            title: "Shopping Cart",
                            description: "Funcionalidades de carrito de compras",
                            icon: "🛒"
                        ) {
                            NavigationLink("Ver Carrito") {
                                ShoppingCartDemoView()
                            }
                        }
                        
                        DemoSection(
                            title: "Product Catalog",
                            description: "Catálogo de productos",
                            icon: "📦"
                        ) {
                            NavigationLink("Ver Productos") {
                                ProductCatalogDemoView()
                            }
                        }
                        
                        DemoSection(
                            title: "Checkout",
                            description: "Proceso de pago",
                            icon: "💳"
                        ) {
                            NavigationLink("Ver Checkout") {
                                CheckoutDemoView()
                            }
                        }
                    }
                    
                    Spacer(minLength: ReachuSpacing.xl)
                }
                .padding(.horizontal, ReachuSpacing.lg)
            }
            .navigationTitle("Reachu Demo")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
    }
}

struct DemoSection<Content: View>: View {
    let title: String
    let description: String
    let icon: String
    let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: ReachuSpacing.md) {
            HStack(spacing: ReachuSpacing.md) {
                Text(icon)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
                    Text(title)
                        .font(ReachuTypography.headline)
                        .foregroundColor(ReachuColors.textPrimary)
                    
                        Text(description)
                            .font(ReachuTypography.callout)
                            .foregroundColor(ReachuColors.textSecondary)
                }
                
                Spacer()
            }
            
            content()
        }
        .padding(ReachuSpacing.lg)
        .background(ReachuColors.surface)
        .cornerRadius(ReachuBorderRadius.large)
        .shadow(color: ReachuColors.textPrimary.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    ContentView()
}
