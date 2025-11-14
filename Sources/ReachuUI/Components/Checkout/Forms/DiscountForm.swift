import ReachuCore
import ReachuDesignSystem
import SwiftUI

/// Discount code form component
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct DiscountForm: View {
    @ObservedObject var viewModel: CheckoutViewModel
    @Environment(\.colorScheme) private var colorScheme
    
    private var adaptiveColors: AdaptiveColors {
        ReachuColors.adaptive(for: colorScheme)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: ReachuSpacing.md) {
            Text("Discount Code")
                .font(ReachuTypography.bodyBold)
                .foregroundColor(ReachuColors.textPrimary)
            
            HStack(spacing: ReachuSpacing.md) {
                TextField("Enter discount code", text: $viewModel.discountCode)
                    .font(ReachuTypography.caption1)
                    .foregroundColor(ReachuColors.textPrimary)
                    .padding(.horizontal, ReachuSpacing.md)
                    .padding(.vertical, ReachuSpacing.sm)
                    .background(ReachuColors.surfaceSecondary)
                    .cornerRadius(ReachuBorderRadius.medium)
                    .overlay(
                        RoundedRectangle(cornerRadius: ReachuBorderRadius.medium)
                            .stroke(ReachuColors.border, lineWidth: 1)
                    )
                
                Button(action: {
                    Task {
                        await viewModel.applyDiscount()
                    }
                }) {
                    Text("Apply")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(adaptiveColors.surface)
                        .padding(.horizontal, ReachuSpacing.md)
                        .padding(.vertical, ReachuSpacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: ReachuBorderRadius.medium)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            ReachuColors.primary,
                                            ReachuColors.primary.opacity(0.8)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: ReachuBorderRadius.medium)
                                .stroke(ReachuColors.primary.opacity(0.3), lineWidth: 1)
                        )
                }
            }
            
            // Discount message
            if !viewModel.discountMessage.isEmpty {
                HStack {
                    Image(
                        systemName: viewModel.appliedDiscount > 0
                            ? "checkmark.circle.fill"
                            : "exclamationmark.circle.fill"
                    )
                    .font(.body)
                    .foregroundColor(
                        viewModel.appliedDiscount > 0
                            ? ReachuColors.success : ReachuColors.error
                    )
                    
                    Text(viewModel.discountMessage)
                        .font(ReachuTypography.caption1)
                        .foregroundColor(
                            viewModel.appliedDiscount > 0
                                ? ReachuColors.success : ReachuColors.error
                        )
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, ReachuSpacing.lg)
    }
}

