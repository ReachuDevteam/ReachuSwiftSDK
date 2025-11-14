import ReachuCore
import ReachuDesignSystem
import SwiftUI

/// Address display view (read-only mode)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct AddressDisplayView: View {
    @ObservedObject var viewModel: CheckoutViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: ReachuSpacing.xs) {
            Text("\(viewModel.firstName) \(viewModel.lastName)")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(ReachuColors.textPrimary)
            
            Text(viewModel.address1)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(ReachuColors.textPrimary)
            
            if !viewModel.address2.isEmpty {
                Text(viewModel.address2)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(ReachuColors.textPrimary)
            }
            
            Text("\(viewModel.city), \(viewModel.province), \(viewModel.country)")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(ReachuColors.textPrimary)
            
            Text(viewModel.zip)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(ReachuColors.textPrimary)
            
            HStack {
                Text(RLocalizedString(ReachuTranslationKey.phoneColon.rawValue))
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(ReachuColors.textPrimary)
                
                Text("\(viewModel.phoneCountryCode) \(viewModel.phone)")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(ReachuColors.textPrimary)
            }
        }
        .padding(.horizontal, ReachuSpacing.lg)
        .padding(.vertical, ReachuSpacing.sm)
        .background(ReachuColors.surfaceSecondary)
        .cornerRadius(ReachuBorderRadius.medium)
        .padding(.horizontal, ReachuSpacing.lg)
    }
}

