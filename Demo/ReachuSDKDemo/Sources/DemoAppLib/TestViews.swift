import Foundation
import SwiftUI
import ReachuDesignSystem

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
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
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
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
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
                        ColorSwatch(name: "Primary", color: ReachuColors.primary)
                        ColorSwatch(name: "Secondary", color: ReachuColors.secondary)
                        ColorSwatch(name: "Success", color: ReachuColors.success)
                        ColorSwatch(name: "Warning", color: ReachuColors.warning)
                        ColorSwatch(name: "Error", color: ReachuColors.error)
                        ColorSwatch(name: "Surface", color: ReachuColors.surface)
                    }
                }
                
                // Typography Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Typography")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Large Title").font(ReachuTypography.largeTitle)
                        Text("Title 1").font(ReachuTypography.title1)
                        Text("Title 2").font(ReachuTypography.title2)
                        Text("Title 3").font(ReachuTypography.title3)
                        Text("Headline").font(ReachuTypography.headline)
                        Text("Body").font(ReachuTypography.body)
                        Text("Callout").font(ReachuTypography.callout)
                        Text("Subheadline").font(ReachuTypography.subheadline)
                        Text("Footnote").font(ReachuTypography.footnote)
                        Text("Caption 1").font(ReachuTypography.caption1)
                        Text("Caption 2").font(ReachuTypography.caption2)
                    }
                }
                
                // RButton Examples
                VStack(alignment: .leading, spacing: 12) {
                    Text("RButton Components")
                        .font(.headline)
                    
                    VStack(spacing: ReachuSpacing.sm) {
                        RButton(title: "Primary Button", style: .primary) {
                            print("Primary tapped")
                        }
                        
                        RButton(title: "Secondary Button", style: .secondary) {
                            print("Secondary tapped")
                        }
                        
                        RButton(title: "Tertiary Button", style: .tertiary) {
                            print("Tertiary tapped")
                        }
                        
                        RButton(title: "Destructive Button", style: .destructive) {
                            print("Destructive tapped")
                        }
                        
                        RButton(title: "Ghost Button", style: .ghost) {
                            print("Ghost tapped")
                        }
                        
                        RButton(title: "With Icon", style: .primary, icon: "heart.fill") {
                            print("Icon button tapped")
                        }
                        
                        RButton(title: "Loading", style: .primary, isLoading: true) {
                            print("Loading button tapped")
                        }
                        
                        RButton(title: "Disabled", style: .primary, isDisabled: true) {
                            print("Disabled button tapped")
                        }
                    }
                }
                
                // Spacing Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Spacing")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        SpacingExample(name: "XS (4pt)", spacing: ReachuSpacing.xs)
                        SpacingExample(name: "SM (8pt)", spacing: ReachuSpacing.sm)
                        SpacingExample(name: "MD (16pt)", spacing: ReachuSpacing.md)
                        SpacingExample(name: "LG (24pt)", spacing: ReachuSpacing.lg)
                        SpacingExample(name: "XL (32pt)", spacing: ReachuSpacing.xl)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Design System")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
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
                .fill(ReachuColors.primary)
                .frame(width: spacing, height: 20)
            
            Text(name)
                .font(.caption)
            
            Spacer()
        }
    }
}
