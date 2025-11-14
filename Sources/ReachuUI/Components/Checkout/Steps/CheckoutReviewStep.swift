import ReachuCore
import ReachuDesignSystem
import SwiftUI

#if os(iOS)
import UIKit
#endif

/// Review step view for checkout flow
/// Displays product summary, order details, and payment schedule (if Klarna)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct CheckoutReviewStep: View {
    @ObservedObject var viewModel: CheckoutViewModel
    @EnvironmentObject private var cartManager: CartManager
    @Environment(\.colorScheme) private var colorScheme
    
    private var adaptiveColors: AdaptiveColors {
        ReachuColors.adaptive(for: colorScheme)
    }
    
    var body: some View {
        Group {
            #if os(iOS)
            if viewModel.selectedPaymentMethod == .stripe && viewModel.shouldPresentStripeSheet {
                Color.clear
                    .onAppear {
                        if let root = topMostViewController() {
                            viewModel.presentStripePaymentSheet(from: root)
                        }
                    }
            } else {
                reviewContentView
            }
            #else
            reviewContentView
            #endif
        }
    }
    
    private var reviewContentView: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: ReachuSpacing.lg) {
                    // Product Summary Header
                    productSummaryHeader
                    
                    // Products List
                    productsList
                    
                    // Complete Order Summary
                    completeOrderSummaryView
                    
                    // Payment Schedule (if Klarna installments selected)
                    if viewModel.selectedPaymentMethod == .klarna {
                        paymentScheduleSection
                    }
                    
                    Spacer(minLength: 100)
                }
            }
            
            // Bottom Button
            bottomButtonSection
        }
    }
    
    // MARK: - Product Summary Header
    
    private var productSummaryHeader: some View {
        HStack {
            Text(RLocalizedString(ReachuTranslationKey.productSummary.rawValue))
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(ReachuColors.textPrimary)
            
            Spacer()
            
            Text("\(cartManager.currency) \(String(format: "%.2f", viewModel.finalTotal))")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(ReachuColors.textPrimary)
        }
        .padding(.horizontal, ReachuSpacing.lg)
        .padding(.top, ReachuSpacing.lg)
    }
    
    // MARK: - Products List
    
    private var productsList: some View {
        VStack(spacing: ReachuSpacing.xl) {
            ForEach(Array(cartManager.items.enumerated()), id: \.offset) { index, item in
                productItemView(item: item)
            }
        }
        .padding(.horizontal, ReachuSpacing.lg)
    }
    
    private func productItemView(item: CartManager.CartItem) -> some View {
        VStack(spacing: ReachuSpacing.md) {
            // Product header with image and details
            HStack(spacing: ReachuSpacing.md) {
                // Product image
                LoadedImage(
                    url: URL(string: item.imageUrl ?? ""),
                    placeholder: AnyView(Rectangle().fill(Color.yellow)),
                    errorView: AnyView(Rectangle().fill(ReachuColors.surfaceSecondary))
                )
                .aspectRatio(contentMode: .fill)
                .frame(width: 60, height: 60)
                .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
                    Text(item.brand ?? "Reachu Audio")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(ReachuColors.textSecondary)
                    
                    Text(item.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(ReachuColors.textPrimary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Text("\(item.currency) \(String(format: "%.2f", item.price))")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(adaptiveColors.priceColor)
            }
            
            // Product details (variant options)
            if let variantTitle = item.variantTitle, !variantTitle.isEmpty {
                let optionDetails = CheckoutHelpers.optionDetails(
                    for: item,
                    products: cartManager.products
                )
                if !optionDetails.isEmpty {
                    VStack(spacing: ReachuSpacing.xs) {
                        ForEach(Array(optionDetails.enumerated()), id: \.offset) { _, detail in
                            HStack {
                                Text("\(detail.name):")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(ReachuColors.textSecondary)
                                
                                Spacer()
                                
                                Text(detail.value)
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(ReachuColors.textSecondary)
                            }
                        }
                    }
                }
            }
            
            // Read-only Quantity Display
            HStack {
                Text(RLocalizedString(ReachuTranslationKey.quantity.rawValue))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(ReachuColors.textPrimary)
                
                Spacer()
                
                Text("\(item.quantity)")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(ReachuColors.textPrimary)
            }
            
            // Show total for this product
            HStack {
                Text(RLocalizedString(ReachuTranslationKey.totalForItem.rawValue))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(ReachuColors.textSecondary)
                
                Spacer()
                
                Text("\(item.currency) \(String(format: "%.2f", item.price * Double(item.quantity)))")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(adaptiveColors.priceColor)
            }
        }
    }
    
    // MARK: - Complete Order Summary
    
    private var completeOrderSummaryView: some View {
        VStack(spacing: ReachuSpacing.lg) {
            // Divider
            Rectangle()
                .fill(ReachuColors.border)
                .frame(height: 1)
                .padding(.horizontal, ReachuSpacing.lg)
            
            // Order Summary Section - All values from checkout
            VStack(spacing: ReachuSpacing.md) {
                // Subtotal - from checkout
                HStack {
                    Text("Subtotal")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(ReachuColors.textSecondary)
                    
                    Spacer()
                    
                    Text("\(cartManager.currency) \(String(format: "%.2f", viewModel.checkoutSubtotal))")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(ReachuColors.textPrimary)
                }
                
                // Shipping - from checkout
                HStack {
                    Text(RLocalizedString(ReachuTranslationKey.shipping.rawValue))
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(ReachuColors.textSecondary)
                    
                    Spacer()
                    
                    Text(viewModel.shippingAmountText)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(ReachuColors.textPrimary)
                }
                
                // Discount (if applied) - from checkout
                if viewModel.checkoutDiscount > 0 {
                    HStack {
                        Text(RLocalizedString(ReachuTranslationKey.discount.rawValue))
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(ReachuColors.success)
                        
                        Spacer()
                        
                        Text("-\(cartManager.currency) \(String(format: "%.2f", viewModel.checkoutDiscount))")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(ReachuColors.success)
                    }
                }
                
                // Tax - from checkout
                HStack {
                    Text("Tax")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(ReachuColors.textSecondary)
                    
                    Spacer()
                    
                    Text("\(cartManager.currency) \(String(format: "%.2f", viewModel.checkoutTax))")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(ReachuColors.textPrimary)
                }
                
                // Divider
                Rectangle()
                    .fill(ReachuColors.border)
                    .frame(height: 1)
                
                // Total - from checkout
                HStack {
                    Text("Total")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(ReachuColors.textPrimary)
                    
                    Spacer()
                    
                    Text("\(cartManager.currency) \(String(format: "%.2f", viewModel.checkoutTotal))")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(ReachuColors.primary)
                }
            }
            .padding(.horizontal, ReachuSpacing.lg)
        }
    }
    
    // MARK: - Payment Schedule Section
    
    private var paymentScheduleSection: some View {
        VStack(alignment: .leading, spacing: ReachuSpacing.md) {
            Text(RLocalizedString(ReachuTranslationKey.paymentSchedule.rawValue))
                .font(ReachuTypography.bodyBold)
                .foregroundColor(ReachuColors.textPrimary)
                .padding(.horizontal, ReachuSpacing.lg)
            
            PaymentScheduleDetailed(
                total: viewModel.finalTotal,
                currency: cartManager.currency
            )
            .padding(.horizontal, ReachuSpacing.lg)
        }
    }
    
    // MARK: - Bottom Button Section
    
    private var bottomButtonSection: some View {
        VStack {
            RButton(
                title: RLocalizedString(ReachuTranslationKey.completePurchase.rawValue),
                style: .primary,
                size: .large
            ) {
                viewModel.proceedToNextStep()
            }
            .padding(.horizontal, ReachuSpacing.lg)
            .padding(.vertical, ReachuSpacing.md)
        }
        .background(ReachuColors.surface)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: -2)
    }
    
    #if os(iOS)
    private func topMostViewController() -> UIViewController? {
        guard
            let scene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive }),
            let root = scene.windows.first(where: { $0.isKeyWindow })?
                .rootViewController
        else { return nil }
        
        var vc: UIViewController = root
        while let presented = vc.presentedViewController { vc = presented }
        if let nav = vc as? UINavigationController {
            return nav.visibleViewController ?? nav
        }
        if let tab = vc as? UITabBarController {
            return tab.selectedViewController ?? tab
        }
        return vc
    }
    #endif
}

// MARK: - Payment Schedule Component

fileprivate struct PaymentScheduleDetailed: View {
    let total: Double
    let currency: String
    
    private var installmentAmount: Double {
        total / 4.0
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Payment schedule circles
            HStack(spacing: 0) {
                ForEach(1...4, id: \.self) { installment in
                    VStack(spacing: ReachuSpacing.xs) {
                        ZStack {
                            Circle()
                                .fill(
                                    installment == 1
                                        ? ReachuColors.primary
                                        : ReachuColors.border
                                )
                                .frame(width: 32, height: 32)
                            
                            Text("\(installment)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(
                                    installment == 1
                                        ? .white : ReachuColors.textSecondary
                                )
                        }
                        
                        Text(
                            installment == 1
                                ? "Due Today"
                                : "In \(installment - 1) month\(installment > 2 ? "s" : "")"
                        )
                        .font(.system(size: 11))
                        .foregroundColor(ReachuColors.textSecondary)
                        
                        Text("\(currency) \(String(format: "%.2f", installmentAmount))")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(ReachuColors.textPrimary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, ReachuSpacing.lg)
            
            // Down payment summary
            HStack {
                Text("Down payment due today")
                    .font(ReachuTypography.bodyBold)
                    .foregroundColor(ReachuColors.textPrimary)
                
                Spacer()
                
                Text("\(currency) \(String(format: "%.2f", installmentAmount))")
                    .font(ReachuTypography.title3)
                    .foregroundColor(ReachuColors.textPrimary)
            }
        }
        .padding(ReachuSpacing.lg)
        .background(ReachuColors.surfaceSecondary)
        .cornerRadius(ReachuBorderRadius.medium)
    }
}

