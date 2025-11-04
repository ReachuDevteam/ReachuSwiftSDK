# 🌍 Translation Keys Reference - Reachu SDK

Complete reference of all translation keys used in the Reachu SDK.

## Format

Each key follows the pattern: `category.key` (e.g., `cart.title`, `checkout.proceed`)

## Categories

### Common (`common.*`)
- `common.addToCart` - "Add to Cart"
- `common.remove` - "Remove"
- `common.close` - "Close"
- `common.cancel` - "Cancel"
- `common.confirm` - "Confirm"
- `common.continue` - "Continue"
- `common.back` - "Back"
- `common.next` - "Next"
- `common.done` - "Done"
- `common.loading` - "Loading..."
- `common.error` - "Error"
- `common.success` - "Success"
- `common.retry` - "Retry"
- `common.apply` - "Apply"
- `common.save` - "Save"
- `common.edit` - "Edit"
- `common.delete` - "Delete"

### Cart (`cart.*`)
- `cart.title` - "Cart"
- `cart.empty` - "Your cart is empty"
- `cart.emptyMessage` - "Add products to continue with checkout"
- `cart.itemCount` - "Items"
- `cart.items` - "items"
- `cart.item` - "item"
- `cart.quantity` - "Quantity"
- `cart.subtotal` - "Subtotal"
- `cart.total` - "Total"
- `cart.shipping` - "Shipping"
- `cart.tax` - "Tax"
- `cart.discount` - "Discount"
- `cart.removeItem` - "Remove item"
- `cart.updateQuantity` - "Update quantity"

### Checkout (`checkout.*`)
- `checkout.title` - "Checkout"
- `checkout.proceed` - "Proceed to Checkout"
- `checkout.initiatePayment` - "Initiate Payment"
- `checkout.completePurchase` - "Complete Purchase"
- `checkout.purchaseComplete` - "Purchase Complete!"
- `checkout.purchaseCompleteMessage` - "Your order has been confirmed. You'll receive an email confirmation shortly."
- `checkout.purchaseCompleteMessageKlarna` - "You'll pay in 4x interest-free. We'll send you a reminder a few days before each payment."
- `checkout.paymentFailed` - "Payment Failed"
- `checkout.paymentFailedMessage` - "Your payment could not be processed. Please try again."
- `checkout.tryAgain` - "Try Again"
- `checkout.goBack` - "Go Back"
- `checkout.processingPayment` - "Processing Payment"
- `checkout.processingPaymentMessage` - "Please complete your payment in Vipps..."
- `checkout.verifyingPayment` - "Verifying payment..."

### Address (`address.*`)
- `address.shipping` - "Shipping Address"
- `address.billing` - "Billing Address"
- `address.firstName` - "First Name"
- `address.lastName` - "Last Name"
- `address.email` - "Email"
- `address.phone` - "Phone"
- `address.address` - "Address"
- `address.city` - "City"
- `address.state` - "State"
- `address.zip` - "ZIP"
- `address.country` - "Country"
- `address.phoneColon` - "Phone :"

### Payment (`payment.*`)
- `payment.method` - "Payment method"
- `payment.selectMethod` - "Select a payment method to continue"
- `payment.noMethods` - "No payment methods available"
- `payment.schedule` - "Payment Schedule"
- `payment.downPaymentDueToday` - "Down payment due today"
- `payment.installment` - "Installment"
- `payment.payNext` - "Pay next"
- `payment.confirmWithKlarna` - "Confirm with Klarna"
- `payment.cancel` - "Cancel"
- `payment.klarnaCheckout` - "Klarna Checkout"
- `payment.connectingKlarna` - "Connecting with Klarna..."

### Product (`product.*`)
- `product.details` - "Details"
- `product.description` - "Description"
- `product.options` - "Options"
- `product.inStock` - "In Stock"
- `product.outOfStock` - "Out of Stock"
- `product.sku` - "SKU"
- `product.supplier` - "Supplier"
- `product.category` - "Category"
- `product.stock` - "Stock"
- `product.available` - "available"
- `product.noImage` - "No Image Available"

### Order (`order.*`)
- `order.summary` - "Order Summary"
- `order.id` - "Order ID:"
- `order.review` - "Review Order"
- `order.reviewContent` - "Order review content..."
- `order.productSummary` - "Product Summary"
- `order.totalForItem` - "Total for this item:"
- `order.colors` - "Colors:"

### Shipping (`shipping.*`)
- `shipping.options` - "Shipping Options"
- `shipping.required` - "Required"
- `shipping.noMethods` - "No shipping methods available for this order yet."
- `shipping.calculated` - "Shipping is calculated automatically for this order."
- `shipping.total` - "Total shipping"

### Discount (`discount.*`)
- `discount.code` - "Discount Code"
- `discount.applied` - "Discount applied"
- `discount.removed` - "Discount removed"
- `discount.invalid` - "Invalid discount code"

### Validation (`validation.*`)
- `validation.required` - "This field is required"
- `validation.invalidEmail` - "Please enter a valid email address"
- `validation.invalidPhone` - "Please enter a valid phone number"
- `validation.invalidAddress` - "Please enter a complete address"

### Errors (`error.*`)
- `error.network` - "Network error. Please check your connection."
- `error.server` - "Server error. Please try again later."
- `error.unknown` - "An unknown error occurred"
- `error.tryAgainLater` - "Please try again later"

## Adding New Keys

When adding new translation keys:

1. Follow the naming convention: `category.key`
2. Use lowercase with dots as separators
3. Keep keys descriptive and clear
4. Add the key to `ReachuTranslationKey.swift` enum
5. Add default English value to `ReachuTranslationKey.defaultEnglish`
6. Document the key in this file
7. Update translations in all supported languages

## Language Codes

Use ISO 639-1 (2-letter) language codes:
- `en` - English
- `es` - Spanish
- `no` - Norwegian
- `sv` - Swedish
- `da` - Danish
- `fi` - Finnish
- `de` - German
- `fr` - French
- `pt` - Portuguese
- `it` - Italian

