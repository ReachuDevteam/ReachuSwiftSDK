import Foundation
import SwiftUI
import ReachuCore
import ReachuUI
import ReachuDesignSystem

@main
struct ReachuSDKDemoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // Configurar el SDK para testing
                    setupReachuSDK()
                }
        }
    }
    
    private func setupReachuSDK() {
        // TODO: Implementar cuando Configuration esté listo
        print("🚀 Reachu SDK Demo iniciado")
    }
}

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Reachu SDK Demo")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Test your UI components here")
                    .foregroundColor(.secondary)
                
                // Test Design System Components
                VStack(spacing: 16) {
                    Text("Design System Test")
                        .font(.headline)
                    
                    // TODO: Testear RButton cuando esté implementado
                    Button("Test Button") {
                        print("Button tapped!")
                    }
                    .buttonStyle(.borderedProminent)
                    
                    // TODO: Testear RCard cuando esté implementado
                    VStack {
                        Text("Test Card")
                        Text("This will be a RCard component")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }
                
                Spacer()
                
                // Navigation to different test screens
                VStack(spacing: 12) {
                    NavigationLink("Test Product Components") {
                        ProductTestView()
                    }
                    .buttonStyle(.bordered)
                    
                    NavigationLink("Test Cart Components") {
                        CartTestView()
                    }
                    .buttonStyle(.bordered)
                    
                    NavigationLink("Test Design System") {
                        DesignSystemTestView()
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
            .navigationTitle("Reachu SDK")
        }
    }
}

// MARK: - Test Views

struct ProductTestView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Product Components Test")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Aquí puedes testear ProductCardView, ProductListView, etc.")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                // TODO: Agregar componentes cuando estén listos
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                    ForEach(0..<6, id: \.self) { index in
                        VStack {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 120)
                                .cornerRadius(8)
                            
                            Text("Product \(index + 1)")
                                .font(.caption)
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Products")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct CartTestView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Cart Components Test")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Aquí puedes testear CartView, CartItemView, etc.")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            // TODO: Agregar componentes de cart cuando estén listos
            
            Spacer()
        }
        .padding()
        .navigationTitle("Cart")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DesignSystemTestView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Design System Test")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                // Colors Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Colors")
                        .font(.headline)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                        ColorSwatch(name: "Primary", color: .blue)
                        ColorSwatch(name: "Secondary", color: .purple)
                        ColorSwatch(name: "Success", color: .green)
                        ColorSwatch(name: "Warning", color: .orange)
                        ColorSwatch(name: "Error", color: .red)
                        ColorSwatch(name: "Surface", color: .gray.opacity(0.1))
                    }
                }
                
                // Typography Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Typography")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Large Title").font(.largeTitle)
                        Text("Title 1").font(.title)
                        Text("Title 2").font(.title2)
                        Text("Title 3").font(.title3)
                        Text("Headline").font(.headline)
                        Text("Body").font(.body)
                        Text("Callout").font(.callout)
                        Text("Subheadline").font(.subheadline)
                        Text("Footnote").font(.footnote)
                        Text("Caption 1").font(.caption)
                        Text("Caption 2").font(.caption2)
                    }
                }
                
                // Spacing Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Spacing")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        SpacingExample(name: "XS (4pt)", spacing: 4)
                        SpacingExample(name: "SM (8pt)", spacing: 8)
                        SpacingExample(name: "MD (16pt)", spacing: 16)
                        SpacingExample(name: "LG (24pt)", spacing: 24)
                        SpacingExample(name: "XL (32pt)", spacing: 32)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Design System")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ColorSwatch: View {
    let name: String
    let color: Color
    
    var body: some View {
        VStack {
            Rectangle()
                .fill(color)
                .frame(height: 40)
                .cornerRadius(8)
            
            Text(name)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

struct SpacingExample: View {
    let name: String
    let spacing: CGFloat
    
    var body: some View {
        HStack {
            Rectangle()
                .fill(Color.blue)
                .frame(width: spacing, height: 20)
            
            Text(name)
                .font(.caption)
            
            Spacer()
        }
    }
}

#Preview {
    ContentView()
}
