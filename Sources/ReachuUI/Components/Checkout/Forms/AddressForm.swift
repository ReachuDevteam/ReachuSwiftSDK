import ReachuCore
import ReachuDesignSystem
import SwiftUI

/// Address edit form component
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct AddressEditForm: View {
    @ObservedObject var viewModel: CheckoutViewModel
    
    var body: some View {
        VStack(spacing: ReachuSpacing.md) {
            // Name fields
            HStack(spacing: ReachuSpacing.md) {
                VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
                    Text(RLocalizedString(ReachuTranslationKey.firstName.rawValue))
                        .font(ReachuTypography.caption1)
                        .foregroundColor(ReachuColors.textSecondary)
                    TextField("John", text: $viewModel.firstName)
                        .font(ReachuTypography.body)
                        .foregroundColor(ReachuColors.textPrimary)
                        .padding(ReachuSpacing.md)
                        .background(ReachuColors.surfaceSecondary)
                        .cornerRadius(ReachuBorderRadius.medium)
                        .overlay(
                            RoundedRectangle(cornerRadius: ReachuBorderRadius.medium)
                                .stroke(viewModel.firstName.isEmpty ? ReachuColors.primary.opacity(0.4) : ReachuColors.border, lineWidth: 1)
                        )
                }
                
                VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
                    Text(RLocalizedString(ReachuTranslationKey.lastName.rawValue))
                        .font(ReachuTypography.caption1)
                        .foregroundColor(ReachuColors.textSecondary)
                    TextField("Doe", text: $viewModel.lastName)
                        .font(ReachuTypography.body)
                        .foregroundColor(ReachuColors.textPrimary)
                        .padding(ReachuSpacing.md)
                        .background(ReachuColors.surfaceSecondary)
                        .cornerRadius(ReachuBorderRadius.medium)
                        .overlay(
                            RoundedRectangle(cornerRadius: ReachuBorderRadius.medium)
                                .stroke(viewModel.lastName.isEmpty ? ReachuColors.primary.opacity(0.4) : ReachuColors.border, lineWidth: 1)
                        )
                }
            }
            
            // Email
            VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
                Text(RLocalizedString(ReachuTranslationKey.email.rawValue))
                    .font(ReachuTypography.caption1)
                    .foregroundColor(ReachuColors.textSecondary)
                TextField("your@email.com", text: $viewModel.email)
                    .font(ReachuTypography.body)
                    .foregroundColor(ReachuColors.textPrimary)
                    .padding(ReachuSpacing.md)
                    .background(ReachuColors.surfaceSecondary)
                    .cornerRadius(ReachuBorderRadius.medium)
                    .overlay(
                        RoundedRectangle(cornerRadius: ReachuBorderRadius.medium)
                            .stroke(viewModel.email.isEmpty ? ReachuColors.primary.opacity(0.4) : ReachuColors.border, lineWidth: 1)
                    )
                    #if os(iOS) || os(tvOS) || os(watchOS)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    #endif
            }
            
            // Phone with country code
            VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
                Text(RLocalizedString(ReachuTranslationKey.phone.rawValue))
                    .font(ReachuTypography.caption1)
                    .foregroundColor(ReachuColors.textSecondary)
                
                HStack(spacing: ReachuSpacing.sm) {
                    CountryCodePicker(
                        selectedCode: $viewModel.phoneCountryCode,
                        selectedCountryCode: $viewModel.phoneCountryCodeISO,
                        availableMarkets: ReachuConfiguration.shared.availableMarkets
                    )
                    .frame(width: 100)
                    
                    TextField("555 123 4456", text: $viewModel.phone)
                        .font(ReachuTypography.body)
                        .foregroundColor(ReachuColors.textPrimary)
                        .padding(ReachuSpacing.md)
                        .background(ReachuColors.surfaceSecondary)
                        .cornerRadius(ReachuBorderRadius.medium)
                        .overlay(
                            RoundedRectangle(cornerRadius: ReachuBorderRadius.medium)
                                .stroke(viewModel.phone.isEmpty ? ReachuColors.primary.opacity(0.4) : ReachuColors.border, lineWidth: 1)
                        )
                }
            }
            
            // Address
            VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
                Text(RLocalizedString(ReachuTranslationKey.address.rawValue))
                    .font(ReachuTypography.caption1)
                    .foregroundColor(ReachuColors.textSecondary)
                TextField("Street address", text: $viewModel.address1)
                    .font(ReachuTypography.body)
                    .foregroundColor(ReachuColors.textPrimary)
                    .padding(ReachuSpacing.md)
                    .background(ReachuColors.surfaceSecondary)
                    .cornerRadius(ReachuBorderRadius.medium)
                    .overlay(
                        RoundedRectangle(cornerRadius: ReachuBorderRadius.medium)
                            .stroke(viewModel.address1.isEmpty ? ReachuColors.primary.opacity(0.4) : ReachuColors.border, lineWidth: 1)
                    )
                TextField("Apt, suite, etc. (optional)", text: $viewModel.address2)
                    .font(ReachuTypography.body)
                    .foregroundColor(ReachuColors.textPrimary)
                    .padding(ReachuSpacing.md)
                    .background(ReachuColors.surfaceSecondary)
                    .cornerRadius(ReachuBorderRadius.medium)
                    .overlay(
                        RoundedRectangle(cornerRadius: ReachuBorderRadius.medium)
                            .stroke(ReachuColors.border, lineWidth: 1)
                    )
            }
            
            // City, State, ZIP
            HStack(spacing: ReachuSpacing.md) {
                VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
                    Text(RLocalizedString(ReachuTranslationKey.city.rawValue))
                        .font(ReachuTypography.caption1)
                        .foregroundColor(ReachuColors.textSecondary)
                    TextField("City", text: $viewModel.city)
                        .font(ReachuTypography.body)
                        .foregroundColor(ReachuColors.textPrimary)
                        .padding(ReachuSpacing.md)
                        .background(ReachuColors.surfaceSecondary)
                        .cornerRadius(ReachuBorderRadius.medium)
                        .overlay(
                            RoundedRectangle(cornerRadius: ReachuBorderRadius.medium)
                                .stroke(viewModel.city.isEmpty ? ReachuColors.primary.opacity(0.4) : ReachuColors.border, lineWidth: 1)
                        )
                }
                
                VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
                    Text("State")
                        .font(ReachuTypography.caption1)
                        .foregroundColor(ReachuColors.textSecondary)
                    TextField("State", text: $viewModel.province)
                        .font(ReachuTypography.body)
                        .foregroundColor(ReachuColors.textPrimary)
                        .padding(ReachuSpacing.md)
                        .background(ReachuColors.surfaceSecondary)
                        .cornerRadius(ReachuBorderRadius.medium)
                        .overlay(
                            RoundedRectangle(cornerRadius: ReachuBorderRadius.medium)
                                .stroke(ReachuColors.border, lineWidth: 1)
                        )
                }
                
                VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
                    Text(RLocalizedString(ReachuTranslationKey.zip.rawValue))
                        .font(ReachuTypography.caption1)
                        .foregroundColor(ReachuColors.textSecondary)
                    TextField("ZIP", text: $viewModel.zip)
                        .font(ReachuTypography.body)
                        .foregroundColor(ReachuColors.textPrimary)
                        .padding(ReachuSpacing.md)
                        .background(ReachuColors.surfaceSecondary)
                        .cornerRadius(ReachuBorderRadius.medium)
                        .overlay(
                            RoundedRectangle(cornerRadius: ReachuBorderRadius.medium)
                                .stroke(viewModel.zip.isEmpty ? ReachuColors.primary.opacity(0.4) : ReachuColors.border, lineWidth: 1)
                        )
                        #if os(iOS) || os(tvOS) || os(watchOS)
                            .keyboardType(.numberPad)
                        #endif
                }
            }
            
            // Country
            VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
                Text(RLocalizedString(ReachuTranslationKey.country.rawValue))
                    .font(ReachuTypography.caption1)
                    .foregroundColor(ReachuColors.textSecondary)
                CountryPicker(
                    selectedCountry: $viewModel.country,
                    availableMarkets: ReachuConfiguration.shared.availableMarkets
                )
            }
        }
        .padding(.horizontal, ReachuSpacing.lg)
    }
}

