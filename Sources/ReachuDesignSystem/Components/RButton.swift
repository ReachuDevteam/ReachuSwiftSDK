import SwiftUI

/// Reachu Design System Button Component
public struct RButton: View {
    
    // MARK: - Style
    public enum Style {
        case primary
        case secondary
        case tertiary
        case destructive
        case ghost
    }
    
    // MARK: - Size
    public enum Size {
        case small
        case medium
        case large
        
        var padding: EdgeInsets {
            switch self {
            case .small:
                return EdgeInsets(top: ReachuSpacing.xs, leading: ReachuSpacing.sm, bottom: ReachuSpacing.xs, trailing: ReachuSpacing.sm)
            case .medium:
                return EdgeInsets(top: ReachuSpacing.sm, leading: ReachuSpacing.md, bottom: ReachuSpacing.sm, trailing: ReachuSpacing.md)
            case .large:
                return EdgeInsets(top: ReachuSpacing.md, leading: ReachuSpacing.lg, bottom: ReachuSpacing.md, trailing: ReachuSpacing.lg)
            }
        }
        
        var font: Font {
            switch self {
            case .small:
                return ReachuTypography.footnote
            case .medium:
                return ReachuTypography.body
            case .large:
                return ReachuTypography.headline
            }
        }
    }
    
    // MARK: - Properties
    private let title: String
    private let style: Style
    private let size: Size
    private let action: () -> Void
    private let isLoading: Bool
    private let isDisabled: Bool
    private let icon: String?
    
    // MARK: - Initializer
    public init(
        title: String,
        style: Style = .primary,
        size: Size = .medium,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        icon: String? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.size = size
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.icon = icon
        self.action = action
    }
    
    // MARK: - Body
    public var body: some View {
        Button(action: action) {
            HStack(spacing: ReachuSpacing.xs) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: foregroundColor))
                        .scaleEffect(0.8)
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(size.font)
                }
                
                Text(title)
                    .font(size.font)
            }
            .padding(size.padding)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(ReachuBorderRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: ReachuBorderRadius.medium)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
        }
        .disabled(isDisabled || isLoading)
        .opacity((isDisabled || isLoading) ? 0.6 : 1.0)
    }
    
    // MARK: - Computed Properties
    private var backgroundColor: Color {
        switch style {
        case .primary:
            return ReachuColors.primary
        case .secondary:
            return ReachuColors.secondary
        case .tertiary:
            return ReachuColors.surface
        case .destructive:
            return ReachuColors.error
        case .ghost:
            return Color.clear
        }
    }
    
    private var foregroundColor: Color {
        switch style {
        case .primary, .secondary, .destructive:
            return .white
        case .tertiary:
            return ReachuColors.textPrimary
        case .ghost:
            return ReachuColors.primary
        }
    }
    
    private var borderColor: Color {
        switch style {
        case .primary, .secondary, .destructive:
            return Color.clear
        case .tertiary:
            return ReachuColors.border
        case .ghost:
            return ReachuColors.primary
        }
    }
    
    private var borderWidth: CGFloat {
        switch style {
        case .primary, .secondary, .destructive:
            return 0
        case .tertiary, .ghost:
            return 1
        }
    }
}

// MARK: - Previews
#Preview("Button Styles") {
    VStack(spacing: ReachuSpacing.md) {
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
    .padding()
}

#Preview("Button Sizes") {
    VStack(spacing: ReachuSpacing.md) {
        RButton(title: "Small Button", style: .primary, size: .small) {
            print("Small tapped")
        }
        
        RButton(title: "Medium Button", style: .primary, size: .medium) {
            print("Medium tapped")
        }
        
        RButton(title: "Large Button", style: .primary, size: .large) {
            print("Large tapped")
        }
    }
    .padding()
}
