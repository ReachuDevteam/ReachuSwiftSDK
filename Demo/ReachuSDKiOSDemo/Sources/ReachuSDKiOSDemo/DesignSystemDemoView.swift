import SwiftUI
import ReachuDesignSystem

public struct DesignSystemDemoView: View {
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ReachuSpacing.lg) {
                Text("Reachu Design System")
                    .font(ReachuTypography.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom, ReachuSpacing.md)

                // MARK: - Colors
                VStack(alignment: .leading, spacing: ReachuSpacing.sm) {
                    Text("Colors")
                        .font(ReachuTypography.headline)
                        .fontWeight(.semibold)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: ReachuSpacing.sm) {
                        ColorSwatch(name: "Primary", color: ReachuColors.primary)
                        ColorSwatch(name: "Secondary", color: ReachuColors.secondary)
                        ColorSwatch(name: "Success", color: ReachuColors.success)
                        ColorSwatch(name: "Background", color: ReachuColors.background)
                        ColorSwatch(name: "Surface", color: ReachuColors.surface)
                        ColorSwatch(name: "Text", color: ReachuColors.textPrimary)
                    }
                }

                // MARK: - Typography
                VStack(alignment: .leading, spacing: ReachuSpacing.sm) {
                    Text("Typography")
                        .font(ReachuTypography.headline)
                        .fontWeight(.semibold)
                    
                    VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
                        Text("Headline Large")
                            .font(ReachuTypography.largeTitle)
                        Text("Headline Medium")
                            .font(ReachuTypography.headline)
                        Text("Body Large")
                            .font(ReachuTypography.body)
                        Text("Body Medium")
                            .font(ReachuTypography.callout)
                        Text("Caption")
                            .font(ReachuTypography.caption1)
                    }
                }

                // MARK: - Buttons
                VStack(alignment: .leading, spacing: ReachuSpacing.md) {
                    Text("Buttons")
                        .font(ReachuTypography.headline)
                        .fontWeight(.semibold)

                    VStack(spacing: ReachuSpacing.sm) {
                        RButton(title: "Primary Button", style: .primary) {
                            print("Primary button tapped")
                        }
                        
                        RButton(title: "Secondary Button", style: .secondary) {
                            print("Secondary button tapped")
                        }
                        
                        RButton(title: "Ghost Button", style: .ghost) {
                            print("Ghost button tapped")
                        }
                        
                        RButton(title: "Destructive Button", style: .destructive) {
                            print("Destructive button tapped")
                        }
                        
                        RButton(title: "Disabled Button", style: .primary, isDisabled: true) {
                            print("Disabled button tapped")
                        }
                    }
                }

                // MARK: - Spacing
                VStack(alignment: .leading, spacing: ReachuSpacing.sm) {
                    Text("Spacing")
                        .font(ReachuTypography.headline)
                        .fontWeight(.semibold)
                    
                    VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
                        SpacingExample(name: "Extra Small", spacing: ReachuSpacing.xs)
                        SpacingExample(name: "Small", spacing: ReachuSpacing.sm)
                        SpacingExample(name: "Medium", spacing: ReachuSpacing.md)
                        SpacingExample(name: "Large", spacing: ReachuSpacing.lg)
                        SpacingExample(name: "Extra Large", spacing: ReachuSpacing.xl)
                    }
                }
            }
            .padding(ReachuSpacing.lg)
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
        VStack(spacing: ReachuSpacing.xs) {
            RoundedRectangle(cornerRadius: ReachuBorderRadius.medium)
                .fill(color)
                .frame(height: 60)
                .overlay(
                    RoundedRectangle(cornerRadius: ReachuBorderRadius.medium)
                        .stroke(ReachuColors.textPrimary.opacity(0.2), lineWidth: 1)
                )
            
            Text(name)
                .font(ReachuTypography.caption1)
                .foregroundColor(ReachuColors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }
}

struct SpacingExample: View {
    let name: String
    let spacing: CGFloat
    
    var body: some View {
        HStack(spacing: ReachuSpacing.sm) {
            Rectangle()
                .fill(ReachuColors.primary)
                .frame(width: spacing, height: 20)
            
            Text("\(name) (\(String(format: "%.0f", spacing))pt)")
                .font(ReachuTypography.caption1)
            
            Spacer()
        }
    }
}

#Preview {
    NavigationView {
        DesignSystemDemoView()
    }
}
