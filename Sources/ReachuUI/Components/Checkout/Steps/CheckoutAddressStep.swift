import ReachuCore
import ReachuDesignSystem
import SwiftUI

/// Address step view for checkout flow
/// Displays cart items, address form, shipping options, and order summary
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct CheckoutAddressStep: View {
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
                    // 1. CART SECTION (Products first)
                    cartSection
                    
                    // 2. SHIPPING ADDRESS SECTION
                    shippingAddressSection
                    
                    // 3. ORDER SUMMARY SECTION (at bottom)
                    orderSummarySection
                    
                    Spacer(minLength: 100)
                }
            }
            .task {
                await MainActor.run {
                    viewModel.isLoading = true
                }
                await cartManager.refreshShippingOptions()
                
                // Auto-select shipping if only one option available for each item
                await MainActor.run {
                    for item in cartManager.items {
                        if (item.shippingId == nil || item.shippingId!.isEmpty) && item.availableShippings.count == 1 {
                            let singleOption = item.availableShippings[0]
                            cartManager.setShippingOption(for: item.id, optionId: singleOption.id)
                        }
                    }
                    viewModel.isLoading = false
                }
            }
            
            // Bottom Button - Full Width
            bottomButtonSection
        }
    }
    
    // MARK: - Cart Section
    
    private var cartSection: some View {
        VStack(alignment: .leading, spacing: ReachuSpacing.md) {
            Text(RLocalizedString(ReachuTranslationKey.cart.rawValue))
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(ReachuColors.textPrimary)
                .padding(.horizontal, ReachuSpacing.lg)
            
            individualProductsWithQuantityView
        }
        .padding(.top, ReachuSpacing.lg)
    }
    
    private var individualProductsWithQuantityView: some View {
        VStack(spacing: ReachuSpacing.xl) {
            if cartManager.items.isEmpty {
                VStack(spacing: ReachuSpacing.md) {
                    Image(systemName: "cart")
                        .font(.system(size: 48))
                        .foregroundColor(ReachuColors.textSecondary.opacity(0.5))
                    
                    Text(RLocalizedString(ReachuTranslationKey.cartEmpty.rawValue))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(ReachuColors.textPrimary)
                    
                    Text("Add products to continue with checkout")
                        .font(.system(size: 14))
                        .foregroundColor(ReachuColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            }
            
            ForEach(cartManager.items, id: \.id) { item in
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
                    placeholder: AnyView(RCustomLoader(style: .rotate, size: 30)),
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
                    
                    // Quantity controls
                    HStack(spacing: ReachuSpacing.sm) {
                        Button(action: {
                            Task {
                                if item.quantity > 1 {
                                    await cartManager.updateQuantity(for: item, to: item.quantity - 1)
                                } else {
                                    await cartManager.removeItem(item)
                                }
                            }
                        }) {
                            Image(systemName: item.quantity == 1 ? "trash" : "minus")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(item.quantity == 1 ? ReachuColors.error : ReachuColors.textPrimary)
                                .frame(width: 28, height: 28)
                                .background(ReachuColors.surfaceSecondary)
                                .cornerRadius(4)
                        }
                        
                        Text("\(item.quantity)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(ReachuColors.textPrimary)
                            .frame(width: 30)
                            .animation(.spring(), value: item.quantity)
                        
                        Button(action: {
                            Task {
                                await cartManager.updateQuantity(for: item, to: item.quantity + 1)
                            }
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(ReachuColors.textPrimary)
                                .frame(width: 28, height: 28)
                                .background(ReachuColors.surfaceSecondary)
                                .cornerRadius(4)
                        }
                    }
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
            
            // Show total for this product
            HStack {
                Text("Total for this item:")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(ReachuColors.textSecondary)
                
                Spacer()
                
                Text("\(item.currency) \(String(format: "%.2f", item.price * Double(item.quantity)))")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(adaptiveColors.priceColor)
            }
        }
    }
    
    // MARK: - Shipping Address Section
    
    private var shippingAddressSection: some View {
        VStack(alignment: .leading, spacing: ReachuSpacing.md) {
            HStack {
                Text(RLocalizedString(ReachuTranslationKey.shippingAddress.rawValue))
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(ReachuColors.textPrimary)
                
                Spacer()
                
                editAddressButton
            }
            .padding(.horizontal, ReachuSpacing.lg)
            
            // Address Display or Edit Form
            Group {
                if viewModel.isEditingAddress {
                    AddressEditForm(viewModel: viewModel)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                } else {
                    AddressDisplayView(viewModel: viewModel)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .animation(.easeInOut(duration: 0.3), value: viewModel.isEditingAddress)
            
            // Shipping Options Selection
            shippingOptionsSelectionView
            
            // Shipping Summary
            shippingSummaryView
        }
    }
    
    private var editAddressButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                viewModel.isEditingAddress.toggle()
            }
        }) {
            Group {
                if viewModel.isEditingAddress {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .semibold))
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Image(systemName: "square.and.pencil")
                        .foregroundColor(ReachuColors.primary)
                        .font(.system(size: 14))
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(width: 32, height: 32)
            .background(
                Group {
                    if viewModel.isEditingAddress {
                        LinearGradient(
                            colors: [ReachuColors.primary, ReachuColors.primary.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    } else {
                        Color.clear
                    }
                }
            )
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(ReachuColors.primary, lineWidth: viewModel.isEditingAddress ? 0 : 1)
            )
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: viewModel.isEditingAddress)
    }
    
    private var shippingOptionsSelectionView: some View {
        let hasItemsWithoutShipping = cartManager.items.contains { $0.shippingId == nil || $0.shippingId!.isEmpty }
        
        return VStack(alignment: .leading, spacing: ReachuSpacing.md) {
            if cartManager.items.contains(where: { !$0.availableShippings.isEmpty }) {
                HStack(spacing: 8) {
                    Text(RLocalizedString(ReachuTranslationKey.shippingOptions.rawValue))
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(ReachuColors.textPrimary)
                    
                    if hasItemsWithoutShipping {
                        Text(RLocalizedString(ReachuTranslationKey.shippingRequired.rawValue))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(ReachuColors.primary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(ReachuColors.primary.opacity(0.15))
                            )
                    }
                }
                .padding(.horizontal, ReachuSpacing.lg)
                
                VStack(spacing: ReachuSpacing.md) {
                    ForEach(cartManager.items) { item in
                        if !item.availableShippings.isEmpty {
                            let itemNeedsShipping = item.shippingId == nil || item.shippingId!.isEmpty
                            ItemShippingOptionsView(
                                item: item,
                                onSelect: { option in
                                    cartManager.setShippingOption(for: item.id, optionId: option.id)
                                }
                            )
                            .padding(itemNeedsShipping ? 8 : 0)
                            .background(
                                RoundedRectangle(cornerRadius: ReachuBorderRadius.medium)
                                    .fill(itemNeedsShipping ? ReachuColors.primary.opacity(0.05) : Color.clear)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: ReachuBorderRadius.medium)
                                    .stroke(ReachuColors.primary.opacity(itemNeedsShipping ? 0.4 : 0), lineWidth: 2)
                            )
                        }
                    }
                }
                .padding(.horizontal, ReachuSpacing.lg)
            } else {
                Text(RLocalizedString(ReachuTranslationKey.noShippingMethods.rawValue))
                    .font(.system(size: 12))
                    .foregroundColor(ReachuColors.textSecondary)
                    .padding(.horizontal, ReachuSpacing.lg)
            }
        }
    }
    
    private var shippingSummaryView: some View {
        VStack(alignment: .leading, spacing: ReachuSpacing.sm) {
            Text("Shipping")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(ReachuColors.textPrimary)
                .padding(.horizontal, ReachuSpacing.lg)
            
            VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
                HStack {
                    Text("Total shipping")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(ReachuColors.textPrimary)
                    
                    Spacer()
                    
                    Text(viewModel.shippingAmountText)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(ReachuColors.textPrimary)
                }
                
                if cartManager.items.contains(where: {
                    ($0.shippingName?.isEmpty == false) || $0.shippingAmount != nil
                }) {
                    ForEach(cartManager.items) { item in
                        if (item.shippingName?.isEmpty == false) || item.shippingAmount != nil {
                            HStack(alignment: .top, spacing: ReachuSpacing.sm) {
                                VStack(alignment: .leading, spacing: 2) {
                                    if let name = item.shippingName, !name.isEmpty {
                                        Text(name)
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(ReachuColors.textPrimary)
                                    }
                                    
                                    Text(item.title)
                                        .font(.system(size: 12))
                                        .foregroundColor(ReachuColors.textSecondary)
                                        .lineLimit(1)
                                }
                                
                                Spacer()
                                
                                Text(CheckoutHelpers.formattedShipping(
                                    amount: item.shippingAmount,
                                    currency: item.shippingCurrency ?? cartManager.shippingCurrency
                                ))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(ReachuColors.textPrimary)
                            }
                            .padding(.vertical, ReachuSpacing.xs)
                        }
                    }
                } else {
                    Text(RLocalizedString(ReachuTranslationKey.shippingCalculated.rawValue))
                        .font(.system(size: 12))
                        .foregroundColor(ReachuColors.textSecondary)
                }
            }
            .padding(.horizontal, ReachuSpacing.lg)
            .padding(.vertical, ReachuSpacing.sm)
            .background(ReachuColors.surfaceSecondary)
            .cornerRadius(ReachuBorderRadius.medium)
            .padding(.horizontal, ReachuSpacing.lg)
        }
    }
    
    // MARK: - Order Summary Section
    
    private var orderSummarySection: some View {
        VStack(alignment: .leading, spacing: ReachuSpacing.md) {
            Text(RLocalizedString(ReachuTranslationKey.orderSummary.rawValue))
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(ReachuColors.textPrimary)
                .padding(.horizontal, ReachuSpacing.lg)
            
            addressOrderSummaryView
        }
    }
    
    private var addressOrderSummaryView: some View {
        VStack(spacing: ReachuSpacing.sm) {
            // Subtotal
            HStack {
                Text(RLocalizedString(ReachuTranslationKey.subtotal.rawValue))
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(ReachuColors.textSecondary)
                
                Spacer()
                
                Text("\(cartManager.currency) \(String(format: "%.2f", viewModel.checkoutSubtotal))")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(ReachuColors.textPrimary)
            }
            
            // Shipping
            HStack {
                Text("Shipping")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(ReachuColors.textSecondary)
                
                Spacer()
                
                Text(viewModel.shippingAmountText)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(ReachuColors.textPrimary)
            }
            
            // Divider
            Rectangle()
                .fill(ReachuColors.border)
                .frame(height: 1)
            
            // Total
            HStack {
                Text(RLocalizedString(ReachuTranslationKey.total.rawValue))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(ReachuColors.textPrimary)
                
                Spacer()
                
                Text("\(cartManager.currency) \(String(format: "%.2f", viewModel.checkoutTotal))")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(ReachuColors.primary)
            }
        }
        .padding(.horizontal, ReachuSpacing.lg)
    }
    
    // MARK: - Bottom Button Section
    
    private var bottomButtonSection: some View {
        VStack(spacing: ReachuSpacing.sm) {
            // Validation message
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
                    await viewModel.proceedFromAddressStep()
                }
            }) {
                HStack {
                    Text(RLocalizedString(ReachuTranslationKey.proceedToCheckout.rawValue))
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
}

// MARK: - Supporting Components

fileprivate struct ItemShippingOptionsView: View {
    let item: CartManager.CartItem
    let onSelect: (CartManager.CartItem.ShippingOption) -> Void
    
    private var title: String { item.title }
    private var selectedId: String? { item.shippingId }
    
    var body: some View {
        VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(ReachuColors.textPrimary)
            
            VStack(spacing: ReachuSpacing.xs) {
                ForEach(item.availableShippings) { option in
                    Button {
                        onSelect(option)
                    } label: {
                        HStack(spacing: ReachuSpacing.sm) {
                            Image(
                                systemName: selectedId == option.id ? "checkmark.circle.fill" : "circle"
                            )
                            .foregroundColor(
                                selectedId == option.id ? ReachuColors.primary : ReachuColors.textSecondary
                            )
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(option.name)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(ReachuColors.textPrimary)
                                
                                if let description = option.description, !description.isEmpty {
                                    Text(description)
                                        .font(.system(size: 12))
                                        .foregroundColor(ReachuColors.textSecondary)
                                }
                            }
                            
                            Spacer()
                            
                            Text(
                                option.amount > 0
                                    ? "\(option.currency) \(String(format: "%.2f", option.amount))"
                                    : "Free"
                            )
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(ReachuColors.textPrimary)
                        }
                        .padding(.horizontal, ReachuSpacing.md)
                        .padding(.vertical, ReachuSpacing.sm)
                        .background(
                            selectedId == option.id
                                ? ReachuColors.primary.opacity(0.08)
                                : ReachuColors.surfaceSecondary
                        )
                        .cornerRadius(ReachuBorderRadius.medium)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}

