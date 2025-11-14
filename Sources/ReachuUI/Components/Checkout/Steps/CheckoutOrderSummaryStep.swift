import ReachuCore
import ReachuDesignSystem
import SwiftUI

#if os(iOS)
import UIKit
#endif

/// Order Summary step view for checkout flow
/// Displays cart, payment method selection, discount code, and order summary
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct CheckoutOrderSummaryStep: View {
    @ObservedObject var viewModel: CheckoutViewModel
    @EnvironmentObject private var cartManager: CartManager
    @Environment(\.colorScheme) private var colorScheme
    
    private var adaptiveColors: AdaptiveColors {
        ReachuColors.adaptive(for: colorScheme)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: ReachuSpacing.xl) {
                    // Cart Section (smaller, readonly)
                    cartSection
                    
                    // Payment Method Selection
                    paymentMethodSection
                    
                    // Discount Code Section
                    DiscountForm(viewModel: viewModel)
                    
                    // Order Summary
                    orderSummarySection
                    
                    Spacer(minLength: 100)
                }
                .padding(.top, ReachuSpacing.lg)
            }
            
            // Bottom Button - Full Width with shadow
            bottomButtonSection
        }
        .onChange(of: viewModel.selectedPaymentMethod) { newMethod in
            Task { @MainActor in
                viewModel.isLoading = true
                _ = await cartManager.updateCheckout(
                    checkoutId: cartManager.checkoutId,
                    email: nil,
                    successUrl: nil,
                    cancelUrl: nil,
                    paymentMethod: newMethod.rawValue.capitalized,
                    shippingAddress: nil,
                    billingAddress: nil,
                    acceptsTerms: viewModel.acceptsTerms,
                    acceptsPurchaseConditions: viewModel.acceptsPurchaseConditions
                )
                viewModel.isLoading = false
            }
        }
    }
    
    // MARK: - Cart Section
    
    private var cartSection: some View {
        VStack(alignment: .leading, spacing: ReachuSpacing.md) {
            Text(RLocalizedString(ReachuTranslationKey.cart.rawValue))
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(ReachuColors.textPrimary)
                .padding(.horizontal, ReachuSpacing.lg)
            
            compactReadonlyCartView
        }
    }
    
    private var compactReadonlyCartView: some View {
        VStack(spacing: ReachuSpacing.md) {
            if cartManager.items.isEmpty {
                VStack(spacing: ReachuSpacing.md) {
                    Image(systemName: "cart")
                        .font(.system(size: 40))
                        .foregroundColor(ReachuColors.textSecondary.opacity(0.5))
                    
                    Text(RLocalizedString(ReachuTranslationKey.cartEmpty.rawValue))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(ReachuColors.textPrimary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            }
            
            ForEach(cartManager.items) { item in
                HStack(spacing: ReachuSpacing.sm) {
                    // Small product image
                    LoadedImage(
                        url: URL(string: item.imageUrl ?? ""),
                        placeholder: AnyView(Rectangle().fill(Color.yellow)),
                        errorView: AnyView(Rectangle().fill(ReachuColors.surfaceSecondary))
                    )
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 40, height: 40)
                    .cornerRadius(6)
                    
                    // Product info (compact)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.title)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(ReachuColors.textPrimary)
                            .lineLimit(1)
                        
                        Text("Qty: \(item.quantity)")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(ReachuColors.textSecondary)
                    }
                    
                    Spacer()
                    
                    // Price
                    Text("\(item.currency) \(String(format: "%.2f", item.price * Double(item.quantity)))")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(adaptiveColors.priceColor)
                }
                .padding(.horizontal, ReachuSpacing.lg)
            }
        }
    }
    
    // MARK: - Payment Method Section
    
    private var paymentMethodSection: some View {
        VStack(alignment: .leading, spacing: ReachuSpacing.md) {
            Text(RLocalizedString(ReachuTranslationKey.paymentMethod.rawValue))
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(ReachuColors.textPrimary)
            
            VStack(spacing: ReachuSpacing.sm) {
                ForEach(viewModel.availablePaymentMethods, id: \.self) { method in
                    PaymentMethodRowCompact(
                        method: method,
                        isSelected: viewModel.selectedPaymentMethod == method
                    ) {
                        viewModel.selectedPaymentMethod = method
                    }
                }
                
                if viewModel.availablePaymentMethods.isEmpty {
                    Text(RLocalizedString(ReachuTranslationKey.noPaymentMethods.rawValue))
                        .font(ReachuTypography.body)
                        .foregroundColor(ReachuColors.textSecondary)
                        .padding()
                }
            }
        }
        .padding(.horizontal, ReachuSpacing.lg)
    }
    
    // MARK: - Order Summary Section
    
    private var orderSummarySection: some View {
        VStack(spacing: ReachuSpacing.md) {
            Text("Order Summary")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(ReachuColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: ReachuSpacing.sm) {
                // Subtotal - from checkout
                HStack {
                    Text("Subtotal")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(ReachuColors.textSecondary)
                    
                    Spacer()
                    
                    Text("\(cartManager.currency) \(String(format: "%.2f", viewModel.checkoutSubtotal))")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(ReachuColors.textPrimary)
                }
                
                // Shipping - from checkout
                HStack {
                    Text(RLocalizedString(ReachuTranslationKey.shipping.rawValue))
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(ReachuColors.textSecondary)
                    
                    Spacer()
                    
                    Text(viewModel.shippingAmountText)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(ReachuColors.textPrimary)
                }
                
                // Show discount if applied - from checkout
                if viewModel.checkoutDiscount > 0 {
                    HStack {
                        Text(RLocalizedString(ReachuTranslationKey.discount.rawValue))
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(ReachuColors.success)
                        
                        Spacer()
                        
                        Text("-\(cartManager.currency) \(String(format: "%.2f", viewModel.checkoutDiscount))")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(ReachuColors.success)
                    }
                }
                
                // Tax - from checkout
                HStack {
                    Text("Tax")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(ReachuColors.textSecondary)
                    
                    Spacer()
                    
                    Text("\(cartManager.currency) \(String(format: "%.2f", viewModel.checkoutTax))")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(ReachuColors.textPrimary)
                }
                
                // Divider
                Rectangle()
                    .fill(ReachuColors.border)
                    .frame(height: 1)
                
                // Total - from checkout
                HStack {
                    Text("Total")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(ReachuColors.textPrimary)
                    
                    Spacer()
                    
                    Text("\(cartManager.currency) \(String(format: "%.2f", viewModel.checkoutTotal))")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(ReachuColors.primary)
                }
            }
        }
        .padding(.horizontal, ReachuSpacing.lg)
    }
    
    // MARK: - Bottom Button Section
    
    private var bottomButtonSection: some View {
        VStack(spacing: ReachuSpacing.sm) {
            // Validation messages
            if !viewModel.canProceedToNext {
                HStack(spacing: 10) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(ReachuColors.primary)
                    
                    Text(viewModel.validationMessage)
                        .font(.system(size: 13))
                        .foregroundColor(ReachuColors.textSecondary)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: ReachuBorderRadius.medium)
                        .fill(ReachuColors.primary.opacity(0.1))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: ReachuBorderRadius.medium)
                        .stroke(ReachuColors.primary.opacity(0.3), lineWidth: 1)
                )
                .padding(.horizontal, ReachuSpacing.lg)
            }
            
            // Custom button with total
            Button(action: {
                Task { @MainActor in
                    ReachuLogger.debug("Botón 'Initiate Payment' presionado - selectedPaymentMethod: \(viewModel.selectedPaymentMethod.rawValue)", component: "CheckoutOrderSummaryStep")
                    
                    #if os(iOS)
                    ReachuLogger.debug("Platform: iOS detected", component: "CheckoutOrderSummaryStep")
                    if viewModel.selectedPaymentMethod == .stripe {
                        viewModel.isLoading = true
                        let ok = await viewModel.prepareStripePaymentSheet()
                        viewModel.isLoading = false
                        if ok {
                            viewModel.shouldPresentStripeSheet = true
                            if let root = topMostViewController() {
                                viewModel.presentStripePaymentSheet(from: root)
                            }
                            return
                        } else {
                            ReachuLogger.error("Setting checkoutStep to .error (Stripe prepareStripePaymentSheet failed)", component: "CheckoutOrderSummaryStep")
                            viewModel.currentStep = .error
                            return
                        }
                    }
                    if viewModel.selectedPaymentMethod == .klarna {
                        ReachuLogger.debug("Botón 'Initiate Payment' presionado con Klarna seleccionado - Llamando a initiateKlarnaDirectFlow()", component: "CheckoutOrderSummaryStep")
                        await viewModel.initiateKlarnaDirectFlow()
                        return
                    }
                    if viewModel.selectedPaymentMethod == .vipps {
                        ReachuLogger.debug("Botón 'Initiate Payment' presionado con Vipps seleccionado - Llamando a initiateVippsFlow()", component: "CheckoutOrderSummaryStep")
                        await viewModel.initiateVippsFlow()
                        return
                    }
                    #else
                    ReachuLogger.warning("Platform: NO ES iOS - saltando lógica de pago", component: "CheckoutOrderSummaryStep")
                    #endif
                    ReachuLogger.debug("Llamando a proceedToNextStep()", component: "CheckoutOrderSummaryStep")
                    viewModel.proceedToNextStep()
                }
            }) {
                HStack {
                    Text(RLocalizedString(ReachuTranslationKey.initiatePayment.rawValue))
                        .font(ReachuTypography.headline)
                        .foregroundColor(adaptiveColors.surface)
                    
                    Spacer()
                    
                    Text("\(cartManager.currency) \(String(format: "%.2f", viewModel.checkoutTotal))")
                        .font(ReachuTypography.headline)
                        .fontWeight(.bold)
                        .foregroundColor(adaptiveColors.surface)
                }
                .padding(.horizontal, ReachuSpacing.lg)
                .padding(.vertical, ReachuSpacing.md)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: ReachuBorderRadius.medium)
                        .fill(
                            LinearGradient(
                                colors: viewModel.canProceedToNext ? [
                                    ReachuColors.primary,
                                    ReachuColors.primary.opacity(0.8)
                                ] : [
                                    ReachuColors.primary.opacity(0.5),
                                    ReachuColors.primary.opacity(0.4)
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
            .disabled(!viewModel.canProceedToNext)
            .frame(maxWidth: .infinity)
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

// MARK: - Payment Method Row Component

fileprivate struct PaymentMethodRowCompact: View {
    let method: PaymentMethod
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: ReachuSpacing.md) {
                // Radio button
                ZStack {
                    Circle()
                        .stroke(
                            isSelected ? ReachuColors.primary : ReachuColors.border,
                            lineWidth: 2
                        )
                        .frame(width: 20, height: 20)
                    
                    if isSelected {
                        Circle()
                            .fill(ReachuColors.primary)
                            .frame(width: 12, height: 12)
                    }
                }
                
                // Payment Method Logo Card
                if let imageName = method.imageName {
                    ZStack {
                        RoundedRectangle(cornerRadius: ReachuBorderRadius.small)
                            .fill(Color.white)
                        
                        #if os(iOS)
                        // Load image from module bundle using UIImage (supports PNG files)
                        if let uiImage = UIImage(named: imageName, in: .module, compatibleWith: nil) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .padding(3)
                        } else if let uiImage = UIImage(named: "PaymentIcons/\(imageName)", in: .module, compatibleWith: nil) {
                            // Try with PaymentIcons/ prefix if direct name fails
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .padding(3)
                        } else {
                            // Fallback to SF Symbol if image not found
                            Image(systemName: method.icon)
                                .font(.system(size: 18))
                                .foregroundColor(method.iconColor)
                                .padding(3)
                        }
                        #else
                        // Fallback to SF Symbol on non-iOS platforms
                        Image(systemName: method.icon)
                            .font(.system(size: 18))
                            .foregroundColor(method.iconColor)
                            .padding(3)
                        #endif
                    }
                    .frame(width: 50, height: 30)
                    .overlay(
                        RoundedRectangle(cornerRadius: ReachuBorderRadius.small)
                            .stroke(ReachuColors.border, lineWidth: 1)
                    )
                } else {
                    // Fallback to SF Symbol
                    Image(systemName: method.icon)
                        .font(.system(size: 18))
                        .foregroundColor(method.iconColor)
                        .frame(width: 50, height: 30)
                }
                
                // Payment Method Name
                Text(method.displayName)
                    .font(.system(size: 15))
                    .foregroundColor(ReachuColors.textPrimary)
                
                Spacer()
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: ReachuBorderRadius.medium)
                    .fill(isSelected ? ReachuColors.primary.opacity(0.08) : ReachuColors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: ReachuBorderRadius.medium)
                    .stroke(isSelected ? ReachuColors.primary : ReachuColors.border, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

