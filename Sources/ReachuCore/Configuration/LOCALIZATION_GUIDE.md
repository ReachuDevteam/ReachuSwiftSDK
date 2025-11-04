# 🌍 SDK Localization System

## Description

The SDK supports multiple languages through a configurable translations system. You can define translations directly in your JSON configuration file or in a separate file.

## Configuration

### Option 1: Separate Translations File (Recommended)

To keep your configuration file clean, use a separate file for translations:

**reachu-config.json:**
```json
{
  "apiKey": "your-api-key",
  "environment": "sandbox",
  "localization": {
    "defaultLanguage": "es",
    "fallbackLanguage": "en",
    "translationsFile": "reachu-translations"
  }
}
```

**reachu-translations.json** (in the same folder):
```json
{
  "translations": {
    "en": {
      "cart.title": "Cart",
      "cart.empty": "Your cart is empty",
      "checkout.title": "Checkout"
    },
    "es": {
      "cart.title": "Carrito",
      "cart.empty": "Tu carrito está vacío",
      "checkout.title": "Checkout"
    },
    "no": {
      "cart.title": "Handlekurv",
      "cart.empty": "Handlekurven din er tom",
      "checkout.title": "Kasse"
    }
  }
}
```

### Option 2: Inline Translations (for small sets)

If you prefer everything in a single file:

```json
{
  "apiKey": "your-api-key",
  "environment": "sandbox",
  "localization": {
    "defaultLanguage": "es",
    "fallbackLanguage": "en",
    "translations": {
      "en": {
        "cart.title": "Cart",
        "checkout.title": "Checkout"
      },
      "es": {
        "cart.title": "Carrito",
        "checkout.title": "Checkout"
      }
    }
  }
}
```

### File Structure

```
YourApp/
├── Configuration/
│   ├── reachu-config.json          ← Main configuration
│   └── reachu-translations.json    ← Translations (optional)
```

### Properties

- **`defaultLanguage`**: Default language (e.g., "en", "es", "no", "sv")
- **`fallbackLanguage`**: Fallback language if a translation is missing (default: "en")
- **`translationsFile`**: External translations filename (without .json extension)
- **`translations`**: Object with per-language translations (optional if you use `translationsFile`)

## Usage in Code

### Option 1: Helper Function (Recommended)

```swift
import ReachuCore

Text(RLocalizedString("cart.title"))
// Or with a default value
Text(RLocalizedString("cart.title", defaultValue: "Cart"))
```

### Option 2: ReachuLocalization class

```swift
import ReachuCore

// Get string in current language
let text = ReachuLocalization.shared.string(for: "cart.title")

// Get string in a specific language
let spanishText = ReachuLocalization.shared.string(
    for: "cart.title",
    language: "es"
)

// Change language dynamically
ReachuLocalization.shared.setLanguage("es")

// Get current language
let currentLang = ReachuLocalization.shared.language
```

### Option 3: Use in SwiftUI Views

```swift
import SwiftUI
import ReachuCore

struct MyView: View {
    var body: some View {
        VStack {
            Text(RLocalizedString("cart.title"))
            Text(RLocalizedString("cart.empty"))
            
            Button(RLocalizedString("common.addToCart")) {
                // Action
            }
        }
    }
}
```

## Available Translation Keys

The SDK defines standard keys in `ReachuTranslationKey`. Main categories:

### Common
- `common.addToCart`
- `common.remove`
- `common.close`
- `common.cancel`
- `common.confirm`
- `common.continue`
- `common.back`
- `common.next`
- `common.done`
- `common.loading`
- `common.error`
- `common.success`
- `common.retry`

### Cart
- `cart.title`
- `cart.empty`
- `cart.emptyMessage`
- `cart.itemCount`
- `cart.items`
- `cart.item`
- `cart.quantity`
- `cart.subtotal`
- `cart.total`
- `cart.shipping`
- `cart.tax`
- `cart.discount`

### Checkout
- `checkout.title`
- `checkout.proceed`
- `checkout.initiatePayment`
- `checkout.completePurchase`
- `checkout.purchaseComplete`
- `checkout.purchaseCompleteMessage`
- `checkout.purchaseCompleteMessageKlarna`
- `checkout.paymentFailed`
- `checkout.paymentFailedMessage`
- `checkout.tryAgain`
- `checkout.goBack`
- `checkout.processingPayment`
- `checkout.processingPaymentMessage`
- `checkout.verifyingPayment`

### Address
- `address.shipping`
- `address.billing`
- `address.firstName`
- `address.lastName`
- `address.email`
- `address.phone`
- `address.address`
- `address.city`
- `address.state`
- `address.zip`
- `address.country`

### Payment
- `payment.method`
- `payment.selectMethod`
- `payment.noMethods`
- `payment.schedule`
- `payment.downPaymentDueToday`
- `payment.installment`
- `payment.payNext`
- `payment.confirmWithKlarna`
- `payment.cancel`
- `payment.klarnaCheckout`

### Product
- `product.details`
- `product.description`
- `product.options`
- `product.inStock`
- `product.outOfStock`
- `product.sku`
- `product.supplier`
- `product.category`
- `product.stock`
- `product.available`
- `product.noImage`

### Order
- `order.summary`
- `order.id`
- `order.review`
- `order.reviewContent`
- `order.productSummary`
- `order.totalForItem`
- `order.colors`

### Shipping
- `shipping.options`
- `shipping.required`
- `shipping.noMethods`
- `shipping.calculated`
- `shipping.total`

### Discount
- `discount.code`
- `discount.applied`
- `discount.removed`
- `discount.invalid`

### Validation
- `validation.required`
- `validation.invalidEmail`
- `validation.invalidPhone`
- `validation.invalidAddress`

### Errors
- `error.network`
- `error.server`
- `error.unknown`
- `error.tryAgainLater`

## Default Values

If you don’t provide a translation for a key, the SDK will use:
1. The default English value (if available)
2. The fallback language (if configured)
3. The key itself (as a last resort)

## Complete Example

See the example file:
`Sources/ReachuCore/Configuration/theme-examples/reachu-config-with-localization.json`

This file includes complete translations for:
- English (en)
- Spanish (es)
- Norwegian (no)
- Swedish (sv)

## Change Language Dynamically

```swift
// Change language at runtime
ReachuLocalization.shared.setLanguage("es")

// SDK components will update automatically
// (if using RLocalizedString)
```

## Integration with iOS Localization

You can combine this with iOS native localization:

```swift
// Use iOS native system as fallback
let localized = RLocalizedString(
    "cart.title",
    defaultValue: NSLocalizedString("cart.title", comment: "")
)
```

## Notes

- Translations load automatically when you call `ConfigurationLoader.loadConfiguration()`
- The system is optional — if you don’t provide translations, English is used by default
- You can add your own custom keys in addition to SDK standard keys
- Keys are case-sensitive: `cart.title` ≠ `Cart.Title`
