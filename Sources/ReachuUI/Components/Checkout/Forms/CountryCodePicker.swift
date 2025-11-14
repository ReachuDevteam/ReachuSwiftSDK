import ReachuCore
import ReachuDesignSystem
import SwiftUI

/// Country code picker component for phone numbers
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public struct CountryCodePicker: View {
    @Binding public var selectedCode: String
    @Binding public var selectedCountryCode: String?
    public let availableMarkets: [GetAvailableMarketsDto]
    
    // Fallback list if no markets available - includes both CA and US with +1
    private let fallbackCountryCodes: [(String, String, String, String?)] = [
        ("+1", "🇨🇦", "CA", nil), ("+1", "🇺🇸", "US", nil), ("+44", "🇬🇧", "GB", nil), ("+49", "🇩🇪", "DE", nil), ("+33", "🇫🇷", "FR", nil),
        ("+39", "🇮🇹", "IT", nil), ("+34", "🇪🇸", "ES", nil), ("+31", "🇳🇱", "NL", nil), ("+46", "🇸🇪", "SE", nil),
        ("+47", "🇳🇴", "NO", nil), ("+45", "🇩🇰", "DK", nil), ("+41", "🇨🇭", "CH", nil), ("+43", "🇦🇹", "AT", nil),
        ("+32", "🇧🇪", "BE", nil), ("+351", "🇵🇹", "PT", nil), ("+52", "🇲🇽", "MX", nil), ("+54", "🇦🇷", "AR", nil),
        ("+55", "🇧🇷", "BR", nil), ("+86", "🇨🇳", "CN", nil), ("+81", "🇯🇵", "JP", nil), ("+82", "🇰🇷", "KR", nil),
        ("+91", "🇮🇳", "IN", nil), ("+61", "🇦🇺", "AU", nil), ("+64", "🇳🇿", "NZ", nil),
    ]
    
    public init(
        selectedCode: Binding<String>,
        selectedCountryCode: Binding<String?>,
        availableMarkets: [GetAvailableMarketsDto]
    ) {
        self._selectedCode = selectedCode
        self._selectedCountryCode = selectedCountryCode
        self.availableMarkets = availableMarkets
    }
    
    private var countryCodes: [(String, String, String, String?)] {
        if availableMarkets.isEmpty {
            return fallbackCountryCodes
        }
        
        // Build list from available markets - keep all countries even if they share phone code
        return availableMarkets.compactMap { market in
            guard let code = market.phoneCode,
                  let countryCode = market.code else {
                return nil
            }
            
            let flag = market.flag ?? "🌍"
            let name = market.name ?? countryCode
            // Check if flag is a URL
            let flagURL = flag.hasPrefix("http") ? flag : nil
            let flagEmoji = flagURL == nil ? flag : "🌍"
            return (code, flagEmoji, countryCode, flagURL)
        }.sorted { first, second in
            // Sort by phone code first, then by country code
            if first.0 != second.0 {
                return first.0 < second.0
            }
            return first.2 < second.2
        }
    }
    
    public var body: some View {
        Menu {
            ForEach(countryCodes, id: \.2) { code, flagEmoji, countryCode, flagURL in
                Button(action: {
                    selectedCode = code
                    selectedCountryCode = countryCode
                }) {
                    HStack {
                        // Show image from URL or emoji
                        if let flagURL = flagURL, let url = URL(string: flagURL) {
                            #if os(iOS)
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 20, height: 14)
                                case .failure(_), .empty:
                                    Text(flagEmoji)
                                        .font(.system(size: 16))
                                @unknown default:
                                    Text(flagEmoji)
                                        .font(.system(size: 16))
                                }
                            }
                            #else
                            Text(flagEmoji)
                                .font(.system(size: 16))
                            #endif
                        } else {
                            Text(flagEmoji)
                                .font(.system(size: 16))
                        }
                        // Show country name or code
                        if let market = availableMarkets.first(where: { $0.code == countryCode }) {
                            Text(market.name ?? countryCode)
                                .font(.system(size: 14))
                        } else {
                            Text(countryCode)
                                .font(.system(size: 14))
                        }
                        Text(code)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(ReachuColors.textSecondary)
                        Spacer()
                        if selectedCode == code && selectedCountryCode == countryCode {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(ReachuColors.primary)
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                // Only show code, no flag in the label
                Text(selectedCode.isEmpty ? "-" : selectedCode)
                    .font(ReachuTypography.body)
                    .fontWeight(.medium)
                    .foregroundColor(ReachuColors.textPrimary)
                
                Spacer()
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 12))
                    .foregroundColor(ReachuColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, ReachuSpacing.md)
            .padding(.vertical, ReachuSpacing.md)
            .background(ReachuColors.surfaceSecondary)
            .cornerRadius(ReachuBorderRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: ReachuBorderRadius.medium)
                    .stroke(ReachuColors.border, lineWidth: 1)
            )
        }
    }
}

