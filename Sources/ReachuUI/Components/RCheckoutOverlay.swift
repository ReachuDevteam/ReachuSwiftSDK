import ReachuCore
import ReachuDesignSystem
import SwiftUI

#if canImport(KlarnaMobileSDK)
    import KlarnaMobileSDK
#endif

#if os(iOS)
    import UIKit
    import StripePaymentSheet
#endif

/// Complete checkout overlay matching original Reachu design
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public struct RCheckoutOverlay: View {

    // MARK: - Environment
    @EnvironmentObject private var cartManager: CartManager
    @EnvironmentObject private var checkoutDraft: CheckoutDraft
    @SwiftUI.Environment(\.colorScheme) private var colorScheme: SwiftUI.ColorScheme
    
    // MARK: - ViewModel
    @State private var viewModel: CheckoutViewModel?
    
    private var adaptiveColors: AdaptiveColors {
        ReachuColors.adaptive(for: colorScheme)
    }
    
    // MARK: - Type Aliases (for backward compatibility)
    // Note: CheckoutStep and PaymentMethod are defined in CheckoutViewModel.swift as top-level enums
    // They are in the same module (ReachuUI), so they are directly accessible
    // For external code, use ReachuUI.CheckoutStep and ReachuUI.PaymentMethod directly
    // These type aliases are removed because Swift doesn't allow referencing module types with module prefix from within the module
    // External code should use ReachuUI.CheckoutStep and ReachuUI.PaymentMethod directly

    // MARK: - Initialization
    
    // Store user data for ViewModel initialization
    private let userFirstName: String?
    private let userLastName: String?
    private let userEmail: String?
    private let userPhone: String?
    private let userPhoneCountryCode: String?
    private let userAddress1: String?
    private let userAddress2: String?
    private let userCity: String?
    private let userProvince: String?
    private let userCountry: String?
    private let userZip: String?
    
    public init(
        userFirstName: String? = nil,
        userLastName: String? = nil,
        userEmail: String? = nil,
        userPhone: String? = nil,
        userPhoneCountryCode: String? = nil,
        userAddress1: String? = nil,
        userAddress2: String? = nil,
        userCity: String? = nil,
        userProvince: String? = nil,
        userCountry: String? = nil,
        userZip: String? = nil
    ) {
        self.userFirstName = userFirstName
        self.userLastName = userLastName
        self.userEmail = userEmail
        self.userPhone = userPhone
        self.userPhoneCountryCode = userPhoneCountryCode
        self.userAddress1 = userAddress1
        self.userAddress2 = userAddress2
        self.userCity = userCity
        self.userProvince = userProvince
        self.userCountry = userCountry
        self.userZip = userZip
    }
    
    // Helper to create ViewModel with EnvironmentObjects
    private func createViewModel() -> CheckoutViewModel {
        CheckoutViewModel(
            cartManager: cartManager,
            checkoutDraft: checkoutDraft,
            userFirstName: userFirstName,
            userLastName: userLastName,
            userEmail: userEmail,
            userPhone: userPhone,
            userPhoneCountryCode: userPhoneCountryCode,
            userAddress1: userAddress1,
            userAddress2: userAddress2,
            userCity: userCity,
            userProvince: userProvince,
            userCountry: userCountry,
            userZip: userZip
        )
    }

    // MARK: - Main Content
    private var mainContent: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Content based on step
                if let viewModel = viewModel {
                    switch viewModel.currentStep {
                    case .address:
                        CheckoutAddressStep(viewModel: viewModel)
                    case .orderSummary:
                        CheckoutOrderSummaryStep(viewModel: viewModel)
                    case .review:
                        CheckoutReviewStep(viewModel: viewModel)
                    case .success:
                        successStepView
                    case .error:
                        errorStepView
                    }
                } else {
                    // Loading state while ViewModel initializes
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .onChange(of: viewModel?.currentStep) { newStep in
                guard let newStep = newStep else { return }
                if newStep == .orderSummary {
                    Task { @MainActor in
                        viewModel?.isLoading = true
                        await viewModel?.loadCheckoutTotals()
                        
                        // Refresh shipping options and auto-select if only one option
                        await cartManager.refreshShippingOptions()
                        
                        // Auto-select shipping if only one option available for each item
                        for item in cartManager.items {
                            if (item.shippingId == nil || item.shippingId!.isEmpty) && item.availableShippings.count == 1 {
                                let singleOption = item.availableShippings[0]
                                cartManager.setShippingOption(for: item.id, optionId: singleOption.id)
                            }
                        }
                        
                        viewModel?.isLoading = false
                    }
                } else if newStep == .success {
                    // Track transaction completed
                    if let checkoutId = cartManager.checkoutId,
                       let checkoutDto = viewModel?.checkoutTotals,
                       let totals = checkoutDto.totals {
                        let products = cartManager.items.map { item -> [String: Any] in
                            [
                                "product_id": String(item.productId),
                                "product_name": item.title,
                                "quantity": item.quantity,
                                "price": item.price
                            ]
                        }
                        
                        AnalyticsManager.shared.trackTransaction(
                            checkoutId: checkoutId,
                            revenue: totals.total,
                            currency: totals.currencyCode,
                            paymentMethod: viewModel?.selectedPaymentMethod.rawValue ?? "unknown",
                            products: products,
                            discount: totals.discounts,
                            shipping: totals.shipping,
                            tax: totals.taxes
                        )
                    }
                    
                    // Reset cart and create new one after successful payment
                    Task { @MainActor in
                        ReachuLogger.debug("Payment successful - resetting cart and creating new one", component: "RCheckoutOverlay")
                        viewModel?.isLoading = true
                        await cartManager.resetCartAndCreateNew()
                        viewModel?.isLoading = false
                    }
                }
            }
            .onChange(of: cartManager.checkoutId) { checkoutId in
                if let checkoutId = checkoutId, viewModel?.currentStep == .orderSummary {
                    Task { @MainActor in
                        viewModel?.isLoading = true
                        await viewModel?.loadCheckoutTotals()
                        viewModel?.isLoading = false
                    }
                }
            }
            .navigationTitle(RLocalizedString(ReachuTranslationKey.checkout.rawValue))
            #if os(iOS) || os(tvOS) || os(watchOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if viewModel?.currentStep != .success {
                        Button(action: {
                            if cartManager.items.isEmpty || viewModel?.currentStep == .address {
                                cartManager.hideCheckout()
                            } else {
                                viewModel?.goToPreviousStep()
                            }
                        }) {
                            Image(systemName: cartManager.items.isEmpty ? "xmark" : "arrow.left")
                                .foregroundColor(ReachuColors.textPrimary)
                                .frame(width: 44, height: 44)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Body
    public var body: some View {
        // Hide if SDK should not be used (market not available) or campaign not active
        if !ReachuConfiguration.shared.shouldUseSDK || !CampaignManager.shared.isCampaignActive {
            EmptyView()
        } else {
            contentWithModifiers
        }
    }
    
    // MARK: - Content with Modifiers
    private var contentWithModifiers: some View {
        mainContent
            .onAppear {
                handleOnAppear()
            }
            .onChange(of: cartManager.phoneCode) { newValue in
                viewModel?.syncPhoneCode(newValue)
            }
            .onChange(of: cartManager.selectedMarket) { newMarket in
                viewModel?.syncSelectedMarket()
            }
            .onChange(of: VippsPaymentHandler.shared.paymentStatus) { newStatus in
                viewModel?.handleVippsPaymentStatusChange(newStatus)
            }
            .onDisappear {
                // Clean up timer when view disappears
                viewModel?.stopVippsRetryTimer()
            }
            .overlay {
                overlayContent
            }
            #if os(iOS) && canImport(KlarnaMobileSDK)
                .sheet(
                    isPresented: Binding(
                        get: { viewModel?.showKlarnaNativeSheet ?? false },
                        set: { viewModel?.showKlarnaNativeSheet = $0 }
                    ),
                    onDismiss: {
                        viewModel?.klarnaNativeInitData = nil
                        viewModel?.klarnaNativeContentHeight = 420
                        viewModel?.klarnaAvailableCategories = []
                        viewModel?.klarnaSelectedCategoryIdentifier = ""
                        if viewModel?.currentStep != .success && viewModel?.currentStep != .error {
                            viewModel?.currentStep = .orderSummary
                        }
                    }
                ) {
                    klarnaSheetContent
                }
            #endif
    }
    
    // MARK: - Helper Methods
    private func handleOnAppear() {
        ReachuLogger.debug("onAppear triggered", component: "RCheckoutOverlay")
        // Initialize ViewModel with EnvironmentObjects
        if viewModel == nil {
            viewModel = createViewModel()
        }
        
        viewModel?.syncSelectedMarket()
        Task { @MainActor in
            viewModel?.isLoading = true
            await viewModel?.loadAvailablePaymentMethods()
            viewModel?.isLoading = false
        }
    }
    
    // MARK: - Overlay Content
    private var overlayContent: some View {
        Group {
            if let viewModel = viewModel, viewModel.isLoading {
                loadingOverlay
            }
            
            vippsPaymentOverlay
            
            #if os(iOS) && canImport(KlarnaMobileSDK)
            klarnaErrorToast
            klarnaAutoAuthorizeOverlay
            #endif
        }
    }
    
    // MARK: - Vipps Payment Overlay
    private var vippsPaymentOverlay: some View {
        Group {
            if let viewModel = viewModel, viewModel.vippsPaymentInProgress {
                VStack {
                    Spacer()
                    HStack(spacing: 12) {
                        RCustomLoader(style: .rotate, size: 20, color: adaptiveColors.surface, speed: 1.5)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(RLocalizedString(ReachuTranslationKey.processingPayment.rawValue))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(adaptiveColors.surface)
                            
                            Text(RLocalizedString(ReachuTranslationKey.processingPaymentMessage.rawValue))
                                .font(.system(size: 12))
                                .foregroundColor(adaptiveColors.surface.opacity(0.9))
                                .lineLimit(2)
                            
                            if viewModel.vippsRetryCount > 0 {
                                Text(RLocalizedString(ReachuTranslationKey.verifyingPayment.rawValue) + " (\(viewModel.vippsRetryCount)/\(viewModel.vippsMaxRetries))")
                                    .font(.system(size: 10))
                                    .foregroundColor(adaptiveColors.surface.opacity(0.7))
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: ReachuBorderRadius.large)
                            .fill(Color.orange)
                            .reachuCardShadow(for: colorScheme)
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.vippsPaymentInProgress)
            }
        }
    }
    
    // MARK: - Klarna Error Toast
    #if os(iOS) && canImport(KlarnaMobileSDK)
    private var klarnaErrorToast: some View {
        Group {
            if let viewModel = viewModel, viewModel.showKlarnaErrorToast {
                VStack {
                    Spacer()
                    HStack(spacing: 12) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(RLocalizedString(ReachuTranslationKey.paymentFailed.rawValue))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text(viewModel.klarnaErrorMessage)
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.9))
                                .lineLimit(2)
                        }
                        
                        Spacer()
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.red)
                            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.showKlarnaErrorToast)
            }
        }
    }
    
    // MARK: - Klarna Auto Authorize Overlay
    #if os(iOS) && canImport(KlarnaMobileSDK)
    private var klarnaAutoAuthorizeOverlay: some View {
        Group {
            if let viewModel = viewModel,
               viewModel.klarnaAutoAuthorize,
               let initData = viewModel.klarnaNativeInitData,
               let returnURL = URL(string: viewModel.klarnaSuccessURLString),
               !viewModel.klarnaSelectedCategoryIdentifier.isEmpty {
                HiddenKlarnaAutoAuthorize(
                    initData: initData,
                    categoryIdentifier: viewModel.klarnaSelectedCategoryIdentifier,
                    returnURL: returnURL,
                    onAuthorized: { authToken, finalizeRequired in
                        Task { @MainActor in
                            guard let viewModel = viewModel else { return }
                            await viewModel.confirmKlarnaPayment(authToken: authToken, finalizeRequired: finalizeRequired)
                        }
                    },
                    onFailed: { message in
                        Task { @MainActor in
                            guard let viewModel = viewModel else { return }
                            viewModel.klarnaAutoAuthorize = false
                            viewModel.klarnaNativeInitData = nil
                            viewModel.currentStep = .orderSummary
                            viewModel.klarnaErrorMessage = message.isEmpty ? "Payment was cancelled or failed. Please try again." : message
                            viewModel.showKlarnaErrorToast = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                                viewModel.showKlarnaErrorToast = false
                            }
                        }
                    }
                )
            }
        }
    }
    #endif
    
    // MARK: - Klarna Sheet Content
    #if os(iOS) && canImport(KlarnaMobileSDK)
    private var klarnaSheetContent: some View {
        Group {
            if let viewModel = viewModel,
               let initData = viewModel.klarnaNativeInitData,
               let returnURL = URL(string: viewModel.klarnaSuccessURLString),
               !viewModel.klarnaAvailableCategories.isEmpty,
               !viewModel.klarnaSelectedCategoryIdentifier.isEmpty {
                KlarnaNativePaymentSheet(
                    initData: initData,
                    categories: viewModel.klarnaAvailableCategories,
                    selectedCategory: Binding(
                        get: { viewModel.klarnaSelectedCategoryIdentifier },
                        set: { viewModel.klarnaSelectedCategoryIdentifier = $0 }
                    ),
                    returnURL: returnURL,
                    contentHeight: Binding(
                        get: { viewModel.klarnaNativeContentHeight },
                        set: { viewModel.klarnaNativeContentHeight = $0 }
                    ),
                    autoAuthorize: Binding(
                        get: { viewModel.klarnaAutoAuthorize },
                        set: { viewModel.klarnaAutoAuthorize = $0 }
                    ),
                    onAuthorized: { authToken, finalizeRequired in
                        Task { @MainActor in
                            guard let viewModel = viewModel else { return }
                            await viewModel.confirmKlarnaPayment(authToken: authToken, finalizeRequired: finalizeRequired)
                        }
                    },
                    onFailed: { message in
                        Task { @MainActor in
                            viewModel?.errorMessage = message
                        }
                    },
                    onDismiss: {
                        viewModel?.showKlarnaNativeSheet = false
                    }
                )
                .interactiveDismissDisabled(viewModel.isLoading)
            } else {
                Text("No Klarna payment methods available.")
                    .padding()
                    .onAppear {
                        viewModel?.showKlarnaNativeSheet = false
                        viewModel?.currentStep = .error
                    }
            }
        }
    }
    #endif

    // MARK: - Old Views (Removed - Now using CheckoutAddressStep, CheckoutOrderSummaryStep, CheckoutReviewStep)
    // These views have been extracted to separate components and are no longer used
    // The old views (addressStepView, orderSummaryStepView, paymentStepView, reviewStepView) 
    // have been removed. See CheckoutAddressStep, CheckoutOrderSummaryStep, CheckoutReviewStep components.
    
    /*
    // MARK: - Address Step View (REMOVED - Now using CheckoutAddressStep)
    private var addressStepView: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: ReachuSpacing.xl) {
                    // 1. CART SECTION (Products first)
                    VStack(alignment: .leading, spacing: ReachuSpacing.md) {
                        Text(RLocalizedString(ReachuTranslationKey.cart.rawValue))
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(ReachuColors.textPrimary)
                            .padding(.horizontal, ReachuSpacing.lg)

                        // Individual Products with Quantity
                        individualProductsWithQuantityView
                    }
                    .padding(.top, ReachuSpacing.lg)

                    // 2. SHIPPING ADDRESS SECTION (consistent sizing)
                    VStack(alignment: .leading, spacing: ReachuSpacing.md) {
                        HStack {
                            Text(RLocalizedString(ReachuTranslationKey.shippingAddress.rawValue))
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(ReachuColors.textPrimary)

                            Spacer()

                            Button(action: {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                                    isEditingAddress.toggle()
                                }
                            }) {
                                Group {
                                    if isEditingAddress {
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
                                        if isEditingAddress {
                                            LinearGradient(
                                                colors: [
                                                    ReachuColors.primary,
                                                    ReachuColors.primary.opacity(0.8)
                                                ],
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
                                        .stroke(ReachuColors.primary, lineWidth: isEditingAddress ? 0 : 1)
                                )
                            }
                            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isEditingAddress)
                        }
                        .padding(.horizontal, ReachuSpacing.lg)

                        // Address Display or Edit Form
                        Group {
                            if isEditingAddress {
                                addressEditForm
                                    .transition(
                                        AnyTransition.opacity.combined(
                                            with: AnyTransition.move(edge: .top)
                                        )
                                    )
                            } else {
                                addressDisplayView
                                    .transition(
                                        AnyTransition.opacity.combined(
                                            with: AnyTransition.move(edge: .top)
                                        )
                                    )
                            }
                        }
                        .animation(
                            .easeInOut(duration: 0.3),
                            value: isEditingAddress
                        )

                        // Shipping Options Selection
                        shippingOptionsSelectionView

                        // Shipping Summary
                        shippingSummaryView
                    }

                    // 3. ORDER SUMMARY SECTION (at bottom)
                    VStack(alignment: .leading, spacing: ReachuSpacing.md) {
                        Text(RLocalizedString(ReachuTranslationKey.orderSummary.rawValue))
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(ReachuColors.textPrimary)
                            .padding(.horizontal, ReachuSpacing.lg)

                        // Order totals with shipping
                        addressOrderSummaryView
                    }

                    Spacer(minLength: 100)
                }
            }
            .task {
                await MainActor.run {
                    isLoading = true
                }
                await cartManager.refreshShippingOptions()
                
                // Auto-select shipping if only one option available for each item
                await MainActor.run {
                    for item in cartManager.items {
                        // Only auto-select if item doesn't have shipping selected and has exactly one option
                        if (item.shippingId == nil || item.shippingId!.isEmpty) && item.availableShippings.count == 1 {
                            let singleOption = item.availableShippings[0]
                            cartManager.setShippingOption(for: item.id, optionId: singleOption.id)
                        }
                    }
                    isLoading = false
                }
            }

            // Bottom Button - Full Width
            VStack(spacing: ReachuSpacing.sm) {
                // Validation message
                if !canProceedToNext {
                    HStack(spacing: 10) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(ReachuColors.primary)
                        
                        Text(validationMessage)
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
                        isLoading = true
                        
                        checkoutDraft.firstName = firstName
                        checkoutDraft.lastName = lastName
                        checkoutDraft.email = email
                        checkoutDraft.phone = phone
                        checkoutDraft.phoneCountryCode =
                            phoneCountryCode.replacingOccurrences(
                                of: "+",
                                with: ""
                            )
                        checkoutDraft.address1 = address1
                        checkoutDraft.address2 = address2
                        checkoutDraft.city = city
                        checkoutDraft.province = province
                        checkoutDraft.countryName = country
                        checkoutDraft.zip = zip
                        checkoutDraft.shippingOptionRaw =
                            cartManager.items.compactMap(\.shippingId)
                            .joined(separator: ",")
                        checkoutDraft.paymentMethodRaw =
                            selectedPaymentMethod.rawValue
                        checkoutDraft.acceptsTerms = acceptsTerms
                        checkoutDraft.acceptsPurchaseConditions =
                            acceptsPurchaseConditions
                        checkoutDraft.appliedDiscount = appliedDiscount

                        _ = await cartManager.applyCheapestShippingPerSupplier()

                        guard let chkId = await cartManager.createCheckout()
                        else {
                            isLoading = false
                            proceedToNext()
                            return
                        }
                        
                        // Track checkout started with user identification
                        let cartValue = cartManager.cartTotal
                        let productCount = cartManager.items.count
                        AnalyticsManager.shared.trackCheckoutStarted(
                            checkoutId: chkId,
                            cartValue: cartValue,
                            currency: cartManager.currency,
                            productCount: productCount,
                            userEmail: email.isEmpty ? nil : email,
                            userFirstName: firstName.isEmpty ? nil : firstName,
                            userLastName: lastName.isEmpty ? nil : lastName
                        )

                        let addr = checkoutDraft.addressPayload(
                            fallbackCountryISO2: cartManager.country
                        )

                        _ = await cartManager.updateCheckout(
                            checkoutId: chkId,
                            email: checkoutDraft.email,
                            successUrl: nil,
                            cancelUrl: nil,
                            paymentMethod: checkoutDraft.paymentMethodRaw
                                .capitalized,
                            shippingAddress: addr,
                            billingAddress: addr,
                            acceptsTerms: checkoutDraft.acceptsTerms,
                            acceptsPurchaseConditions: checkoutDraft
                                .acceptsPurchaseConditions
                        )

                        // Load checkout totals after updating
                        await loadCheckoutTotals()

                        isLoading = false
                        proceedToNext()

                    }
                }) {
                    HStack {
                        Text(RLocalizedString(ReachuTranslationKey.proceedToCheckout.rawValue))
                            .font(ReachuTypography.headline)
                            .foregroundColor(adaptiveColors.surface)
                        
                        Spacer()
                        
                        Text("\(cartManager.currency) \(String(format: "%.2f", checkoutTotal))")
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
                                    colors: canProceedToNext ? [
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
                .disabled(!canProceedToNext)
                .frame(maxWidth: .infinity)  // Full width
                .padding(.horizontal, ReachuSpacing.lg)
                .padding(.vertical, ReachuSpacing.md)
            }
            .background(ReachuColors.surface)
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: -2)
        }
    }

    // MARK: - Order Summary Step View (Payment + Discount + Summary)
    private var orderSummaryStepView: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: ReachuSpacing.xl) {
                    // Cart Section (smaller, readonly)
                    VStack(alignment: .leading, spacing: ReachuSpacing.md) {
                        Text(RLocalizedString(ReachuTranslationKey.cart.rawValue))
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(ReachuColors.textPrimary)
                            .padding(.horizontal, ReachuSpacing.lg)

                        // Compact readonly products
                        compactReadonlyCartView
                    }

                    // Payment Method Selection
                    VStack(alignment: .leading, spacing: ReachuSpacing.md) {
                        Text(RLocalizedString(ReachuTranslationKey.paymentMethod.rawValue))
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(ReachuColors.textPrimary)

                        VStack(spacing: ReachuSpacing.sm) {
                            ForEach(availablePaymentMethods, id: \.self) { method in
                                PaymentMethodRowCompact(
                                    method: method,
                                    isSelected: selectedPaymentMethod == method
                                ) {
                                    selectedPaymentMethod = method
                                }
                            }
                            
                            if availablePaymentMethods.isEmpty {
                                Text(RLocalizedString(ReachuTranslationKey.noPaymentMethods.rawValue))
                                    .font(ReachuTypography.body)
                                    .foregroundColor(ReachuColors.textSecondary)
                                    .padding()
                            }
                        }
                    }
                    .padding(.horizontal, ReachuSpacing.lg)

                    // Klarna installments Details - REMOVED
                    // No mostrar opciones de cuotas en el checkout
                    // if selectedPaymentMethod == .klarna {
                    //     PaymentScheduleCompact(
                    //         total: finalTotal,
                    //         currency: cartManager.currency
                    //     )
                    //     .padding(.horizontal, ReachuSpacing.lg)
                    // }

                    // Discount Code Section
                    discountCodeSection

                    // Order Summary
                    orderSummarySection

                    Spacer(minLength: 100)
                }
                .padding(.top, ReachuSpacing.lg)
            }

            // Bottom Button - Full Width with shadow
            VStack(spacing: ReachuSpacing.sm) {
                // Validation messages
                if !canProceedToNext {
                    HStack(spacing: 10) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(ReachuColors.primary)
                        
                        Text(validationMessage)
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
                        ReachuLogger.debug("Botón 'Initiate Payment' presionado - selectedPaymentMethod: \(selectedPaymentMethod.rawValue)", component: "RCheckoutOverlay")
                        
                        #if os(iOS)
                            ReachuLogger.debug("Platform: iOS detected", component: "RCheckoutOverlay")
                            if selectedPaymentMethod == .stripe {
                                isLoading = true
                                let ok = await prepareStripePaymentSheet()
                                isLoading = false
                                if ok {
                                    shouldPresentStripeSheet = true
                                    presentStripePaymentSheet()
                                    return
                                } else {
                                    ReachuLogger.error("Setting checkoutStep to .error (Stripe prepareStripePaymentSheet failed)", component: "RCheckoutOverlay")
                                    checkoutStep = .error
                                    return
                                }
                            }
                            if selectedPaymentMethod == .klarna {
                                ReachuLogger.debug("Botón 'Initiate Payment' presionado con Klarna seleccionado - Llamando a initiateKlarnaDirectFlow()", component: "RCheckoutOverlay")
                                // Usar flujo directo de Klarna sin UI intermedia
                                await initiateKlarnaDirectFlow()
                                return
                            }
                            if selectedPaymentMethod == .vipps {
                                ReachuLogger.debug("Botón 'Initiate Payment' presionado con Vipps seleccionado - Llamando a initiateVippsFlow()", component: "RCheckoutOverlay")
                                // Usar flujo directo de Vipps
                                await initiateVippsFlow()
                                return
                            }
                        #else
                            ReachuLogger.warning("Platform: NO ES iOS - saltando lógica de pago", component: "RCheckoutOverlay")
                        #endif
                        ReachuLogger.debug("Llamando a proceedToNext()", component: "RCheckoutOverlay")
                        proceedToNext()
                    }
                }) {
                    HStack {
                        Text(RLocalizedString(ReachuTranslationKey.initiatePayment.rawValue))
                            .font(ReachuTypography.headline)
                            .foregroundColor(adaptiveColors.surface)
                        
                        Spacer()
                        
                        Text("\(cartManager.currency) \(String(format: "%.2f", checkoutTotal))")
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
                                    colors: canProceedToNext ? [
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
                .disabled(!canProceedToNext)
                .frame(maxWidth: .infinity)  // Full width
                .padding(.horizontal, ReachuSpacing.lg)
                .padding(.vertical, ReachuSpacing.md)
            }
            .background(ReachuColors.surface)
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: -2)
        }
        .onChange(of: selectedPaymentMethod) { newMethod in
            Task { @MainActor in
                isLoading = true
                _ = await cartManager.updateCheckout(
                    checkoutId: cartManager.checkoutId,
                    email: nil,
                    successUrl: nil,
                    cancelUrl: nil,
                    paymentMethod: newMethod.rawValue.capitalized,  // "Stripe" | "Klarna"
                    shippingAddress: nil,
                    billingAddress: nil,
                    acceptsTerms: acceptsTerms,
                    acceptsPurchaseConditions: acceptsPurchaseConditions
                )
                isLoading = false
            }
        }
    }

    // MARK: - Payment Step View (now Review Step)
    private var paymentStepView: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: ReachuSpacing.lg) {
                    // Product Summary Header - EXACTLY like the image
                    HStack {
                        Text(RLocalizedString(ReachuTranslationKey.productSummary.rawValue))
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(ReachuColors.textPrimary)

                        Spacer()

                        Text(
                            "\(cartManager.currency) \(String(format: "%.2f", finalTotal))"
                        )
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(ReachuColors.textPrimary)
                    }
                    .padding(.horizontal, ReachuSpacing.lg)
                    .padding(.top, ReachuSpacing.lg)

                    // Products List - Each product with individual quantity controls
                    VStack(spacing: ReachuSpacing.xl) {
                        ForEach(
                            Array(cartManager.items.enumerated()),
                            id: \.offset
                        ) {
                            index,
                            item in
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

                                    VStack(
                                        alignment: .leading,
                                        spacing: ReachuSpacing.xs
                                    ) {
                                        Text(item.brand ?? "Reachu Audio")
                                            .font(
                                                .system(
                                                    size: 14,
                                                    weight: .regular
                                                )
                                            )
                                            .foregroundColor(
                                                ReachuColors.textSecondary
                                            )

                                        Text(item.title)
                                            .font(
                                                .system(
                                                    size: 16,
                                                    weight: .semibold
                                                )
                                            )
                                            .foregroundColor(
                                                ReachuColors.textPrimary
                                            )
                                            .lineLimit(2)
                                    }

                                    Spacer()

                                    Text(
                                        "\(item.currency) \(String(format: "%.2f", item.price))"
                                    )
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(adaptiveColors.priceColor)
                                }

                                // Product details
                                VStack(spacing: ReachuSpacing.xs) {
                                    HStack {
                                    Text(RLocalizedString(ReachuTranslationKey.orderId.rawValue))
                                            .font(
                                                .system(
                                                    size: 14,
                                                    weight: .regular
                                                )
                                            )
                                            .foregroundColor(
                                                ReachuColors.textSecondary
                                            )

                                        Spacer()

                                        Text("BD23672983")
                                            .font(
                                                .system(
                                                    size: 14,
                                                    weight: .regular
                                                )
                                            )
                                            .foregroundColor(
                                                ReachuColors.textSecondary
                                            )
                                    }

                                    HStack {
                                    Text(RLocalizedString(ReachuTranslationKey.colors.rawValue))
                                            .font(
                                                .system(
                                                    size: 14,
                                                    weight: .regular
                                                )
                                            )
                                            .foregroundColor(
                                                ReachuColors.textSecondary
                                            )

                                        Spacer()

                                        Text("Like Water")
                                            .font(
                                                .system(
                                                    size: 14,
                                                    weight: .regular
                                                )
                                            )
                                            .foregroundColor(
                                                ReachuColors.textSecondary
                                            )
                                    }
                                }

                                // Read-only Quantity Display (NO controls in payment step)
                                HStack {
                                    Text(RLocalizedString(ReachuTranslationKey.quantity.rawValue))
                                        .font(
                                            .system(size: 16, weight: .semibold)
                                        )
                                        .foregroundColor(
                                            ReachuColors.textPrimary
                                        )

                                    Spacer()

                                    Text("\(item.quantity)")
                                        .font(
                                            .system(size: 18, weight: .semibold)
                                        )
                                        .foregroundColor(
                                            ReachuColors.textPrimary
                                        )
                                }

                                // Show total for this product
                                HStack {
                                    Text(RLocalizedString(ReachuTranslationKey.totalForItem.rawValue))
                                        .font(
                                            .system(size: 14, weight: .medium)
                                        )
                                        .foregroundColor(
                                            ReachuColors.textSecondary
                                        )

                                    Spacer()

                                    Text(
                                        "\(item.currency) \(String(format: "%.2f", item.price * Double(item.quantity)))"
                                    )
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(adaptiveColors.priceColor)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, ReachuSpacing.lg)

                    completeOrderSummaryView

                    // Payment Schedule (if Klarna installments selected)
                    if selectedPaymentMethod == .klarna {
                        VStack(alignment: .leading, spacing: ReachuSpacing.md) {
                            Text(RLocalizedString(ReachuTranslationKey.paymentSchedule.rawValue))
                                .font(ReachuTypography.bodyBold)
                                .foregroundColor(ReachuColors.textPrimary)
                                .padding(.horizontal, ReachuSpacing.lg)

                            PaymentScheduleDetailed(
                                total: finalTotal,
                                currency: cartManager.currency
                            )
                            .padding(.horizontal, ReachuSpacing.lg)
                        }
                    }

                    Spacer(minLength: 100)
                }
            }

            // Bottom Button
            VStack {
                RButton(
                    title: "Payment",
                    style: .primary,
                    size: .large
                ) {
                    proceedToNext()
                }
                .padding(.horizontal, ReachuSpacing.lg)
                .padding(.vertical, ReachuSpacing.md)
            }
            .background(ReachuColors.surface)
        }
    }

    // Helper function for the simple summary rows
    private func summaryDetailRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(ReachuColors.textSecondary)

            Spacer()

            Text(value)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(ReachuColors.textPrimary)
        }
    }

    // MARK: - Review Step View (REMOVED - Now using CheckoutReviewStep)
    */

    // MARK: - Success Step View
    private var successStepView: some View {
        Group {
            if let viewModel = viewModel {
                VStack(spacing: 0) {
                    Spacer()

                    VStack(spacing: ReachuSpacing.lg) {
                        // Animated Success Icon
                        ZStack {
                            Circle()
                                .fill(ReachuColors.success)
                                .frame(width: 100, height: 100)
                                .scaleEffect(viewModel.currentStep == .success ? 1.0 : 0.5)
                                .animation(
                                    .spring(response: 0.6, dampingFraction: 0.6).delay(0.2),
                                    value: viewModel.currentStep
                                )

                            Image(systemName: "checkmark")
                                .font(.system(size: 45, weight: .bold))
                                .foregroundColor(.white)
                                .scaleEffect(viewModel.currentStep == .success ? 1.0 : 0.0)
                                .animation(
                                    .spring(response: 0.4, dampingFraction: 0.6).delay(0.4),
                                    value: viewModel.currentStep
                                )
                        }

                        // Success Message
                        VStack(spacing: ReachuSpacing.sm) {
                            Text(RLocalizedString(ReachuTranslationKey.purchaseComplete.rawValue))
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(ReachuColors.textPrimary)
                                .multilineTextAlignment(.center)
                                .opacity(viewModel.currentStep == .success ? 1.0 : 0.0)
                                .animation(.easeInOut(duration: 0.5).delay(0.6), value: viewModel.currentStep)

                            Text(
                                viewModel.selectedPaymentMethod == .klarna
                                    ? RLocalizedString(ReachuTranslationKey.purchaseCompleteMessageKlarna.rawValue)
                                    : RLocalizedString(ReachuTranslationKey.purchaseCompleteMessage.rawValue)
                            )
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(ReachuColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, ReachuSpacing.xl)
                            .opacity(viewModel.currentStep == .success ? 1.0 : 0.0)
                            .animation(.easeInOut(duration: 0.5).delay(0.8), value: viewModel.currentStep)
                        }
                    }

                    Spacer()

                    // Bottom Close Button
                    VStack {
                        RButton(
                            title: RLocalizedString(ReachuTranslationKey.close.rawValue),
                            style: .primary,
                            size: .large
                        ) {
                            cartManager.hideCheckout()
                            Task {
                                await cartManager.resetCartAndCreateNew()
                            }
                        }
                        .padding(.horizontal, ReachuSpacing.lg)
                        .padding(.bottom, ReachuSpacing.xl)
                        .opacity(viewModel.currentStep == .success ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 0.5).delay(1.0), value: viewModel.currentStep)
                    }
                }
            }
        }
    }

    // MARK: - Error Step View
    private var errorStepView: some View {
        Group {
            if let viewModel = viewModel {
                VStack(spacing: 0) {
                    Spacer()

                    VStack(spacing: ReachuSpacing.lg) {
                        // Animated Error Icon
                        ZStack {
                            Circle()
                                .fill(ReachuColors.error)
                                .frame(width: 100, height: 100)
                                .scaleEffect(viewModel.currentStep == .error ? 1.0 : 0.5)
                                .animation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.2), value: viewModel.currentStep)

                            Image(systemName: "xmark")
                                .font(.system(size: 45, weight: .bold))
                                .foregroundColor(.white)
                                .scaleEffect(viewModel.currentStep == .error ? 1.0 : 0.0)
                                .animation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.4), value: viewModel.currentStep)
                        }

                        // Error Message
                        VStack(spacing: ReachuSpacing.sm) {
                            Text("Payment Failed")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(ReachuColors.textPrimary)
                                .multilineTextAlignment(.center)
                                .opacity(viewModel.currentStep == .error ? 1.0 : 0.0)
                                .animation(.easeInOut(duration: 0.5).delay(0.6), value: viewModel.currentStep)

                            Text(viewModel.errorMessage ?? "There was an issue processing your payment. Please check your payment information and try again.")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(ReachuColors.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, ReachuSpacing.xl)
                                .opacity(viewModel.currentStep == .error ? 1.0 : 0.0)
                                .animation(.easeInOut(duration: 0.5).delay(0.8), value: viewModel.currentStep)
                        }
                    }

                    Spacer()

                    // Bottom Action Buttons
                    VStack(spacing: ReachuSpacing.md) {
                        RButton(
                            title: "Try Again",
                            style: .primary,
                            size: .large
                        ) {
                            viewModel.currentStep = .orderSummary
                        }
                        .opacity(viewModel.currentStep == .error ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 0.5).delay(1.0), value: viewModel.currentStep)

                        RButton(
                            title: "Go Back",
                            style: .secondary,
                            size: .large
                        ) {
                            cartManager.hideCheckout()
                        }
                        .opacity(viewModel.currentStep == .error ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 0.5).delay(1.1), value: viewModel.currentStep)
                    }
                    .padding(.horizontal, ReachuSpacing.lg)
                    .padding(.bottom, ReachuSpacing.xl)
                }
            }
        }
    }

    // MARK: - Helper Views

    private var loadingOverlay: some View {
        Color.white.opacity(0.85)
            .overlay {
                VStack(spacing: ReachuSpacing.md) {
                    RCustomLoader(style: .rotate, size: 48, speed: 1.2)

                    Text("Processing...")
                        .font(ReachuTypography.caption1)
                        .foregroundColor(Color.gray.opacity(0.6))
                }
            }
            .ignoresSafeArea()
    }

    // MARK: - Helper Functions (Removed - Now in CheckoutViewModel and CheckoutValidator)
    // All helper functions have been moved to CheckoutViewModel or extracted components
    // This section is kept empty to maintain structure

// MARK: - Supporting Components (Removed - Now in separate files)
// PaymentMethodRowCompact, PaymentScheduleDetailed, CountryCodePicker, CountryPicker
// have been moved to CheckoutOrderSummaryStep, CheckoutReviewStep, and Forms/ respectively

// MARK: - RCheckoutOverlay Helper Views Extension (Removed - Now in separate components)
// All helper views have been moved to CheckoutAddressStep, CheckoutOrderSummaryStep, CheckoutReviewStep
// and Forms/ components. This extension is kept empty to maintain structure.
extension RCheckoutOverlay {
    // All helper views have been moved to separate component files
}

}

// MARK: - Preview
#if DEBUG
    import ReachuTesting

    #Preview("Checkout - Address Step") {
        RCheckoutOverlay()
            .environmentObject(
                {
                    let manager = CartManager()
                    Task {
                        await manager.addProduct(
                            MockDataProvider.shared.sampleProducts[0]
                        )
                    }
                    return manager
                }()
            )
            .environmentObject(CheckoutDraft())
    }
#endif

#if os(iOS)
    struct KlarnaNativePaymentSheet: View {
        let initData: InitPaymentKlarnaNativeDto
        let categories: [KlarnaNativePaymentMethodCategoryDto]
        @Binding var selectedCategory: String
        let returnURL: URL
        @Binding var contentHeight: CGFloat
        @Binding var autoAuthorize: Bool
        let onAuthorized: (_ authToken: String, _ finalizeRequired: Bool) -> Void
        let onFailed: (String) -> Void
        let onDismiss: () -> Void

        @State private var triggerAuthorize = false
        @State private var localError: String?
        @State private var hasTriggeredAutoAuthorize = false

        var body: some View {
            VStack(spacing: ReachuSpacing.lg) {
                // Solo mostrar header y selector si NO es auto-authorize
                if !autoAuthorize {
                    HStack {
                        Text("Klarna Checkout")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(ReachuColors.textPrimary)

                        Spacer()

                        Button(role: .cancel) {
                            onDismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(ReachuColors.textSecondary)
                                .imageScale(.large)
                        }
                        .buttonStyle(.plain)
                    }
                }

                if !autoAuthorize && categories.count > 1 {
                    VStack(alignment: .leading, spacing: ReachuSpacing.sm) {
                        Text("Payment method")
                            .font(ReachuTypography.caption1)
                            .foregroundColor(ReachuColors.textSecondary)

                        if categories.count <= 3 {
                            Picker("Payment method", selection: $selectedCategory) {
                                ForEach(categories, id: \.identifier) { category in
                                    Text(
                                        category.name
                                            ?? KlarnaCategoryMapper.displayName(for: category)
                                    )
                                    .tag(
                                        KlarnaCategoryMapper
                                            .normalizedIdentifier(from: category.identifier)
                                    )
                                }
                            }
                            .pickerStyle(.segmented)
                        } else {
                            Picker("Payment method", selection: $selectedCategory) {
                                ForEach(categories, id: \.identifier) { category in
                                    Text(
                                        category.name
                                            ?? KlarnaCategoryMapper.displayName(for: category)
                                    )
                                    .tag(
                                        KlarnaCategoryMapper
                                            .normalizedIdentifier(from: category.identifier)
                                    )
                                }
                            }
                            .pickerStyle(.menu)
                        }
                    }
                } else if !autoAuthorize, let category = categories.first {
                    HStack {
                        Text("Method:")
                            .font(ReachuTypography.caption1)
                            .foregroundColor(ReachuColors.textSecondary)
                        Text(
                            category.name
                                ?? KlarnaCategoryMapper.displayName(for: category)
                        )
                        .font(ReachuTypography.body)
                        .foregroundColor(ReachuColors.textPrimary)
                        Spacer()
                    }
                }

                if selectedCategory.isEmpty {
                    Text("Select a payment method to continue")
                        .font(ReachuTypography.body)
                        .foregroundColor(ReachuColors.textSecondary)
                        .frame(maxWidth: .infinity, minHeight: 200)
                        .background(ReachuColors.surfaceSecondary)
                        .cornerRadius(ReachuBorderRadius.large)
                } else {
                    ZStack {
                        KlarnaPaymentViewContainer(
                            initData: initData,
                            categoryIdentifier: selectedCategory,
                            returnURL: returnURL,
                            contentHeight: $contentHeight,
                            triggerAuthorize: $triggerAuthorize,
                            onAuthorized: { token, finalizeRequired in
                                localError = nil
                                onAuthorized(token, finalizeRequired)
                            },
                            onFailed: { message in
                                localError = message
                                onFailed(message)
                            }
                        )
                        .frame(maxWidth: .infinity)
                        .frame(height: contentHeight)
                        .clipShape(RoundedRectangle(cornerRadius: ReachuBorderRadius.large))
                        .id(selectedCategory)
                        .opacity(autoAuthorize && !triggerAuthorize ? 0 : 1) // Ocultar mientras inicializa
                        
                        // Mostrar loading mientras se inicializa en modo auto
                        if autoAuthorize && !triggerAuthorize {
                            VStack(spacing: ReachuSpacing.md) {
                                RCustomLoader(style: .rotate, size: 48, speed: 1.2)
                                Text("Conectando con Klarna...")
                                    .font(ReachuTypography.body)
                                    .foregroundColor(ReachuColors.textSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                        }
                    }
                }

                if let localError {
                    Text(localError)
                        .font(ReachuTypography.caption1)
                        .foregroundColor(ReachuColors.error)
                        .multilineTextAlignment(.center)
                        .transition(.opacity)
                }

                // Solo mostrar botones si NO es auto-authorize
                if !autoAuthorize {
                    RButton(
                        title: "Confirm with Klarna",
                        style: .primary,
                        size: .large
                    ) {
                        triggerAuthorize = true
                    }

                    RButton(
                        title: "Cancel",
                        style: .secondary,
                        size: .large
                    ) {
                        onDismiss()
                    }
                }

                Spacer(minLength: ReachuSpacing.md)
            }
            .padding(.horizontal, autoAuthorize ? 0 : ReachuSpacing.lg)
            .padding(.top, autoAuthorize ? 0 : ReachuSpacing.lg)
            .padding(.bottom, autoAuthorize ? 0 : ReachuSpacing.xl)
            .onAppear {
                if categories.first(where: {
                    KlarnaCategoryMapper.normalizedIdentifier(from: $0.identifier)
                        == selectedCategory
                }) == nil {
                    if let first = categories.first {
                        selectedCategory =
                            KlarnaCategoryMapper
                            .normalizedIdentifier(from: first.identifier)
                    }
                }
                
                // Trigger authorization automatically if enabled
                if autoAuthorize && !hasTriggeredAutoAuthorize {
                    hasTriggeredAutoAuthorize = true
                    // Give a VERY short delay for KlarnaPaymentView to initialize
                    // but trigger authorize() before its UI renders
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        triggerAuthorize = true
                    }
                }
            }
            .onChange(of: selectedCategory) { _ in
                if !autoAuthorize {
                    triggerAuthorize = false
                    localError = nil
                    contentHeight = 420
                }
            }
        }
    }

    struct KlarnaPaymentViewContainer: UIViewRepresentable {
        let initData: InitPaymentKlarnaNativeDto
        let categoryIdentifier: String
        let returnURL: URL
        @Binding var contentHeight: CGFloat
        @Binding var triggerAuthorize: Bool
        let onAuthorized: (_ authToken: String, _ finalizeRequired: Bool) -> Void
        let onFailed: (String) -> Void

        func makeCoordinator() -> Coordinator {
            Coordinator(parent: self)
        }

        func makeUIView(context: Context) -> KlarnaPaymentView {
            let paymentView = KlarnaPaymentView(
                category: categoryIdentifier,
                returnUrl: returnURL,
                eventListener: context.coordinator
            )
            paymentView.environment = .playground
            paymentView.region = region(for: initData.purchaseCountry)
            context.coordinator.attach(paymentView, categoryIdentifier: categoryIdentifier)
            paymentView.initialize(clientToken: initData.clientToken, returnUrl: returnURL)
            paymentView.load()
            DispatchQueue.main.async {
                contentHeight = max(paymentView.contentHeight, 400)
            }
            return paymentView
        }

        func updateUIView(_ uiView: KlarnaPaymentView, context: Context) {
            context.coordinator.update(parent: self)
            if triggerAuthorize {
                context.coordinator.authorize(autoFinalize: true)
                DispatchQueue.main.async {
                    triggerAuthorize = false
                }
            }
        }

        private func region(for purchaseCountry: String) -> KlarnaCore.KlarnaRegion {
            switch purchaseCountry.uppercased() {
            case "US", "CA":
                return .na
            case "AU", "NZ":
                return .oc
            default:
                return .eu
            }
        }

        final class Coordinator: NSObject, KlarnaPaymentEventListener {
            private var parent: KlarnaPaymentViewContainer
            weak var paymentView: KlarnaPaymentView?
            private var categoryIdentifier: String

            init(parent: KlarnaPaymentViewContainer) {
                self.parent = parent
                self.categoryIdentifier = parent.categoryIdentifier
            }

            func update(parent: KlarnaPaymentViewContainer) {
                self.parent = parent
                self.categoryIdentifier = parent.categoryIdentifier
            }

            func attach(_ paymentView: KlarnaPaymentView, categoryIdentifier: String) {
                self.paymentView = paymentView
                self.categoryIdentifier = categoryIdentifier
            }

            func authorize(autoFinalize: Bool) {
                paymentView?.authorize(autoFinalize: autoFinalize, jsonData: nil)
            }

            func klarnaInitialized(paymentView: KlarnaPaymentView) {}

            func klarnaLoaded(paymentView: KlarnaPaymentView) {}

            func klarnaLoadedPaymentReview(paymentView: KlarnaPaymentView) {}

            func klarnaAuthorized(
                paymentView: KlarnaPaymentView,
                approved: Bool,
                authToken: String?,
                finalizeRequired: Bool
            ) {
                guard approved, let token = authToken, !token.isEmpty else {
                    DispatchQueue.main.async {
                        self.parent.onFailed("Klarna authorization was declined.")
                    }
                    return
                }
                DispatchQueue.main.async {
                    self.parent.onAuthorized(token, finalizeRequired)
                }
            }

            func klarnaReauthorized(
                paymentView: KlarnaPaymentView,
                approved: Bool,
                authToken: String?
            ) {
                guard approved, let token = authToken, !token.isEmpty else {
                    DispatchQueue.main.async {
                        self.parent.onFailed("Klarna reauthorization failed.")
                    }
                    return
                }
                DispatchQueue.main.async {
                    self.parent.onAuthorized(token, false)
                }
            }

            func klarnaFinalized(
                paymentView: KlarnaPaymentView,
                approved: Bool,
                authToken: String?
            ) {
                guard approved, let token = authToken, !token.isEmpty else { return }
                DispatchQueue.main.async {
                    self.parent.onAuthorized(token, false)
                }
            }

            func klarnaResized(
                paymentView: KlarnaPaymentView,
                to newHeight: CGFloat
            ) {
                DispatchQueue.main.async {
                    self.parent.contentHeight = max(newHeight, 360)
                }
            }

            func klarnaFailed(
                inPaymentView paymentView: KlarnaPaymentView,
                withError error: KlarnaPaymentError
            ) {
                DispatchQueue.main.async {
                    self.parent.onFailed(error.localizedDescription)
                }
            }
        }
    }

    enum KlarnaCategoryMapper {
        static func normalizedIdentifier(from raw: String) -> String {
            switch raw.lowercased() {
            case "pay_now":
                return String.PayNow
            case "pay_later", "klarna":
                return String.PayLater
            case "slice_it":
                return String.SliceIt
            case "pay_over_time":
                return String.PayInParts
            default:
                return raw
            }
        }

        static func preferredIdentifier(from categories: [KlarnaNativePaymentMethodCategoryDto])
            -> String?
        {
            for key in priorityOrder {
                if let match = categories.first(where: { $0.identifier.lowercased() == key }) {
                    return normalizedIdentifier(from: match.identifier)
                }
            }
            return categories.first.map { normalizedIdentifier(from: $0.identifier) }
        }

        static func sorted(_ categories: [KlarnaNativePaymentMethodCategoryDto])
            -> [KlarnaNativePaymentMethodCategoryDto]
        {
            categories.sorted { lhs, rhs in
                priorityIndex(for: lhs.identifier) < priorityIndex(for: rhs.identifier)
            }
        }

        private static let priorityOrder = [
            "pay_now", "klarna", "pay_later", "pay_over_time", "slice_it",
        ]

        private static func priorityIndex(for identifier: String) -> Int {
            let key = identifier.lowercased()
            if let idx = priorityOrder.firstIndex(of: key) { return idx }
            // keep original order for unknown types by placing them after known ones
            return priorityOrder.count
        }

        static func displayName(for category: KlarnaNativePaymentMethodCategoryDto) -> String {
            if let name = category.name, !name.isEmpty { return name }
            return rawDisplayName(from: category.identifier)
        }

        private static func rawDisplayName(from identifier: String) -> String {
            identifier
                .replacingOccurrences(of: "_", with: " ")
                .capitalized
        }
    }

    // MARK: - Hidden Klarna Auto-Authorize
    /// Invisible component that creates a KlarnaPaymentView and calls authorize() automatically
    struct HiddenKlarnaAutoAuthorize: UIViewRepresentable {
        let initData: InitPaymentKlarnaNativeDto
        let categoryIdentifier: String
        let returnURL: URL
        let onAuthorized: (_ authToken: String, _ finalizeRequired: Bool) -> Void
        let onFailed: (String) -> Void
        
        func makeCoordinator() -> Coordinator {
            Coordinator(parent: self)
        }
        
        func makeUIView(context: Context) -> UIView {
            let containerView = UIView()
            containerView.isHidden = true // Completamente invisible
            containerView.frame = .zero
            
            let paymentView = KlarnaPaymentView(
                category: categoryIdentifier,
                returnUrl: returnURL,
                eventListener: context.coordinator
            )
            paymentView.environment = .production
            paymentView.region = .eu // Europa para Noruega
            paymentView.frame = .zero
            paymentView.isHidden = true
            
            context.coordinator.paymentView = paymentView
            containerView.addSubview(paymentView)
            
            // Initialize and authorize immediately
            paymentView.initialize(clientToken: initData.clientToken, returnUrl: returnURL)
            
            // Wait a minimum moment and authorize
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                paymentView.authorize(autoFinalize: true, jsonData: nil)
            }
            
            return containerView
        }
        
        func updateUIView(_ uiView: UIView, context: Context) {
            // No updates needed
        }
        
        class Coordinator: NSObject, KlarnaPaymentEventListener {
            let parent: HiddenKlarnaAutoAuthorize
            var paymentView: KlarnaPaymentView?
            
            init(parent: HiddenKlarnaAutoAuthorize) {
                self.parent = parent
            }
            
            func klarnaInitialized(paymentView: KlarnaPaymentView) {
                ReachuLogger.debug("Initialized", component: "RCheckoutOverlay")
            }
            
            func klarnaLoaded(paymentView: KlarnaPaymentView) {
                ReachuLogger.debug("Loaded", component: "RCheckoutOverlay")
            }
            
            func klarnaLoadedPaymentReview(paymentView: KlarnaPaymentView) {
                ReachuLogger.debug("Loaded payment review", component: "RCheckoutOverlay")
            }
            
            func klarnaAuthorized(
                paymentView: KlarnaPaymentView,
                approved: Bool,
                authToken: String?,
                finalizeRequired: Bool
            ) {
                ReachuLogger.debug("Authorized - approved: \(approved), token: \(authToken != nil)", component: "RCheckoutOverlay")
                guard approved, let token = authToken, !token.isEmpty else {
                    DispatchQueue.main.async {
                        self.parent.onFailed("Authorization not approved")
                    }
                    return
                }
                DispatchQueue.main.async {
                    self.parent.onAuthorized(token, finalizeRequired)
                }
            }
            
            func klarnaReauthorized(
                paymentView: KlarnaPaymentView,
                approved: Bool,
                authToken: String?
            ) {
                ReachuLogger.debug("Reauthorized", component: "RCheckoutOverlay")
            }
            
            func klarnaFinalized(
                paymentView: KlarnaPaymentView,
                approved: Bool,
                authToken: String?
            ) {
                ReachuLogger.debug("Finalized", component: "RCheckoutOverlay")
            }
            
            func klarnaResized(paymentView: KlarnaPaymentView, to newHeight: CGFloat) {
                // No-op for hidden view
            }
            
            func klarnaFailed(
                inPaymentView paymentView: KlarnaPaymentView,
                withError error: KlarnaPaymentError
            ) {
                ReachuLogger.error("Failed: \(error.localizedDescription)", component: "RCheckoutOverlay")
                DispatchQueue.main.async {
                    self.parent.onFailed(error.localizedDescription)
                }
            }
        }
    }
#endif
