import ReachuCore
import ReachuDesignSystem
import SwiftUI

/// Country picker component
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public struct CountryPicker: View {
    @Binding public var selectedCountry: String
    public let availableMarkets: [GetAvailableMarketsDto]
    
    // Fallback list if no markets available
    private let fallbackCountries = [
        "United States", "Canada", "United Kingdom", "Germany", "France",
        "Italy", "Spain", "Netherlands", "Sweden", "Norway", "Denmark",
        "Switzerland", "Austria", "Belgium", "Portugal", "Mexico",
        "Argentina", "Brazil", "China", "Japan", "South Korea",
        "India", "Australia", "New Zealand",
    ]
    
    public init(
        selectedCountry: Binding<String>,
        availableMarkets: [GetAvailableMarketsDto]
    ) {
        self._selectedCountry = selectedCountry
        self.availableMarkets = availableMarkets
    }
    
    private var countries: [String] {
        if availableMarkets.isEmpty {
            return fallbackCountries
        }
        
        // Build list from available markets
        return availableMarkets.compactMap { market in
            market.name
        }.sorted()
    }
    
    public var body: some View {
        Menu {
            ForEach(countries, id: \.self) { country in
                Button(action: { selectedCountry = country }) {
                    HStack {
                        Text(country)
                        Spacer()
                        if selectedCountry == country {
                            Image(systemName: "checkmark")
                                .foregroundColor(ReachuColors.primary)
                        }
                    }
                }
            }
        } label: {
            HStack {
                Text(selectedCountry.isEmpty ? "Select Country" : selectedCountry)
                    .font(ReachuTypography.body)
                    .foregroundColor(
                        selectedCountry.isEmpty
                            ? ReachuColors.textSecondary : ReachuColors.textPrimary
                    )
                
                Spacer()
                
                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundColor(ReachuColors.textSecondary)
            }
            .padding(ReachuSpacing.md)
            .background(ReachuColors.surfaceSecondary)
            .cornerRadius(ReachuBorderRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: ReachuBorderRadius.medium)
                    .stroke(ReachuColors.border, lineWidth: 1)
            )
        }
    }
}

