import Foundation
import ReachuCore

/// Helper functions for checkout components
enum CheckoutHelpers {
    
    /// Format shipping amount with currency
    static func formattedShipping(amount: Double?, currency: String?) -> String {
        guard let amount = amount else { return "Free" }
        
        let symbol = currency ?? "USD"
        return amount > 0
            ? "\(symbol) \(String(format: "%.2f", amount))"
            : "Free"
    }
    
    /// Get option details for a cart item
    static func optionDetails(
        for item: CartManager.CartItem,
        products: [Product]
    ) -> [(name: String, value: String)] {
        guard let variantTitle = item.variantTitle, !variantTitle.isEmpty else {
            return []
        }
        
        var sortedOptions: [Option] = []
        if let product = products.first(where: { $0.id == item.productId }),
           let productOptions = product.options,
           !productOptions.isEmpty {
            
            sortedOptions = productOptions.sorted { $0.order < $1.order }
            let components = parseVariantTitle(variantTitle)
            
            var details: [(name: String, value: String)] = []
            for (index, option) in sortedOptions.enumerated() {
                guard index < components.count else { break }
                let value = components[index].trimmingCharacters(in: .whitespacesAndNewlines)
                guard !value.isEmpty else { continue }
                details.append((name: formattedOptionName(option.name), value: value))
            }
            
            if !details.isEmpty {
                return details
            }
        }
        
        let components = parseVariantTitle(variantTitle).filter { !$0.isEmpty }
        
        return components.enumerated().map { index, value in
            let optionName = index < sortedOptions.count ? sortedOptions[index].name : "Option \(index + 1)"
            return (name: optionName, value: value)
        }
    }
    
    /// Parse variant title into components
    private static func parseVariantTitle(_ title: String) -> [String] {
        let dashSeparated = title.components(separatedBy: "-")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        if dashSeparated.count > 1 {
            return dashSeparated
        }
        
        return title
            .components(separatedBy: " - ")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
    
    /// Format option name (capitalize first letter)
    private static func formattedOptionName(_ name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "Option" }
        return trimmed.prefix(1).uppercased() + trimmed.dropFirst()
    }
}

