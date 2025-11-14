import Foundation
import ReachuCore

/// Validator for checkout form fields
public struct CheckoutValidator {
    
    // MARK: - Address Validation
    
    public static func validateAddress(
        firstName: String,
        lastName: String,
        email: String,
        phone: String,
        address1: String,
        city: String,
        zip: String
    ) -> ValidationResult {
        var errors: [ValidationError] = []
        
        if firstName.trimmingCharacters(in: .whitespaces).isEmpty {
            errors.append(.firstNameRequired)
        }
        
        if lastName.trimmingCharacters(in: .whitespaces).isEmpty {
            errors.append(.lastNameRequired)
        }
        
        if email.trimmingCharacters(in: .whitespaces).isEmpty {
            errors.append(.emailRequired)
        } else if !isValidEmail(email) {
            errors.append(.emailInvalid)
        }
        
        if phone.trimmingCharacters(in: .whitespaces).isEmpty {
            errors.append(.phoneRequired)
        } else if !isValidPhone(phone) {
            errors.append(.phoneInvalid)
        }
        
        if address1.trimmingCharacters(in: .whitespaces).isEmpty {
            errors.append(.addressRequired)
        }
        
        if city.trimmingCharacters(in: .whitespaces).isEmpty {
            errors.append(.cityRequired)
        }
        
        if zip.trimmingCharacters(in: .whitespaces).isEmpty {
            errors.append(.zipRequired)
        }
        
        return ValidationResult(isValid: errors.isEmpty, errors: errors)
    }
    
    // MARK: - Shipping Validation
    
    public static func validateShipping(
        items: [CartManager.CartItem]
    ) -> ValidationResult {
        var errors: [ValidationError] = []
        
        if items.isEmpty {
            errors.append(.cartEmpty)
            return ValidationResult(isValid: false, errors: errors)
        }
        
        // Check if all items have shipping selected
        let itemsWithoutShipping = items.filter { item in
            item.shippingId == nil || item.shippingId!.isEmpty
        }
        
        if !itemsWithoutShipping.isEmpty {
            // Check if items have multiple shipping options (need user selection)
            let itemsWithMultipleOptions = itemsWithoutShipping.filter { item in
                item.availableShippings.count > 1
            }
            
            if !itemsWithMultipleOptions.isEmpty {
                errors.append(.shippingRequired)
            }
        }
        
        return ValidationResult(isValid: errors.isEmpty, errors: errors)
    }
    
    // MARK: - Payment Method Validation
    
    public static func validatePaymentMethod(
        selectedMethod: PaymentMethod?,
        availableMethods: [PaymentMethod]
    ) -> ValidationResult {
        var errors: [ValidationError] = []
        
        if availableMethods.isEmpty {
            errors.append(.noPaymentMethods)
        } else if let selected = selectedMethod, !availableMethods.contains(selected) {
            errors.append(.paymentMethodInvalid)
        }
        
        return ValidationResult(isValid: errors.isEmpty, errors: errors)
    }
    
    // MARK: - Terms Validation
    
    public static func validateTerms(
        acceptsTerms: Bool,
        acceptsPurchaseConditions: Bool
    ) -> ValidationResult {
        var errors: [ValidationError] = []
        
        if !acceptsTerms {
            errors.append(.termsNotAccepted)
        }
        
        if !acceptsPurchaseConditions {
            errors.append(.purchaseConditionsNotAccepted)
        }
        
        return ValidationResult(isValid: errors.isEmpty, errors: errors)
    }
    
    // MARK: - Helper Methods
    
    private static func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private static func isValidPhone(_ phone: String) -> Bool {
        // Remove all non-digit characters
        let digitsOnly = phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        // Basic validation: at least 7 digits
        return digitsOnly.count >= 7
    }
}

// MARK: - Validation Result

public struct ValidationResult {
    public let isValid: Bool
    public let errors: [ValidationError]
    
    public var firstError: ValidationError? {
        errors.first
    }
    
    public var errorMessage: String {
        guard let first = errors.first else {
            return ""
        }
        return first.localizedMessage
    }
}

// MARK: - Validation Errors

public enum ValidationError: Equatable {
    case firstNameRequired
    case lastNameRequired
    case emailRequired
    case emailInvalid
    case phoneRequired
    case phoneInvalid
    case addressRequired
    case cityRequired
    case zipRequired
    case cartEmpty
    case shippingRequired
    case noPaymentMethods
    case paymentMethodInvalid
    case termsNotAccepted
    case purchaseConditionsNotAccepted
    
    public var localizedMessage: String {
        switch self {
        case .firstNameRequired:
            return RLocalizedString(ReachuTranslationKey.required.rawValue)
        case .lastNameRequired:
            return RLocalizedString(ReachuTranslationKey.required.rawValue)
        case .emailRequired:
            return RLocalizedString(ReachuTranslationKey.invalidEmail.rawValue)
        case .emailInvalid:
            return RLocalizedString(ReachuTranslationKey.invalidEmail.rawValue)
        case .phoneRequired:
            return RLocalizedString(ReachuTranslationKey.invalidPhone.rawValue)
        case .phoneInvalid:
            return RLocalizedString(ReachuTranslationKey.invalidPhone.rawValue)
        case .addressRequired:
            return RLocalizedString(ReachuTranslationKey.invalidAddress.rawValue)
        case .cityRequired:
            return RLocalizedString(ReachuTranslationKey.required.rawValue)
        case .zipRequired:
            return RLocalizedString(ReachuTranslationKey.required.rawValue)
        case .cartEmpty:
            return RLocalizedString(ReachuTranslationKey.cartEmptyMessage.rawValue)
        case .shippingRequired:
            return RLocalizedString(ReachuTranslationKey.shippingRequired.rawValue)
        case .noPaymentMethods:
            return "No payment methods available"
        case .paymentMethodInvalid:
            return "Invalid payment method selected"
        case .termsNotAccepted:
            return "Terms and conditions must be accepted"
        case .purchaseConditionsNotAccepted:
            return "Purchase conditions must be accepted"
        }
    }
}

