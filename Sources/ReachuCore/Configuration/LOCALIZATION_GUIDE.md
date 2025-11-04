# 🌍 Sistema de Localización del SDK

## Descripción

El SDK ahora soporta múltiples idiomas mediante un sistema de traducciones configurable. Puedes definir traducciones directamente en tu archivo de configuración JSON o en un archivo separado.

## Configuración

### Opción 1: Archivo de Traducciones Separado (Recomendado)

Para mantener el archivo de configuración limpio, puedes usar un archivo separado para las traducciones:

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

**reachu-translations.json** (en la misma carpeta):
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

### Opción 2: Traducciones Inline (Para pocas traducciones)

Si prefieres tener todo en un solo archivo:

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

### Estructura de Archivos

```
TuApp/
├── Configuration/
│   ├── reachu-config.json          ← Configuración principal
│   └── reachu-translations.json    ← Traducciones (opcional)
```

### Propiedades

- **`defaultLanguage`**: Idioma por defecto (ej: "en", "es", "no", "sv")
- **`fallbackLanguage`**: Idioma de respaldo si falta una traducción (por defecto: "en")
- **`translationsFile`**: Nombre del archivo externo con traducciones (sin extensión .json)
- **`translations`**: Objeto con traducciones por idioma (opcional si usas `translationsFile`)

## Uso en el Código

### Opción 1: Función Helper (Recomendado)

```swift
import ReachuCore

Text(RLocalizedString("cart.title"))
// O con valor por defecto
Text(RLocalizedString("cart.title", defaultValue: "Cart"))
```

### Opción 2: Clase ReachuLocalization

```swift
import ReachuCore

// Obtener string en idioma actual
let text = ReachuLocalization.shared.string(for: "cart.title")

// Obtener string en idioma específico
let spanishText = ReachuLocalization.shared.string(
    for: "cart.title",
    language: "es"
)

// Cambiar idioma dinámicamente
ReachuLocalization.shared.setLanguage("es")

// Obtener idioma actual
let currentLang = ReachuLocalization.shared.language
```

### Opción 3: Usar en SwiftUI Views

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

## Keys de Traducción Disponibles

El SDK define todas las keys estándar en `ReachuTranslationKey`. Las principales categorías son:

### Common (Común)
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

### Cart (Carrito)
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

### Address (Dirección)
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

### Payment (Pago)
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

### Product (Producto)
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

### Order (Pedido)
- `order.summary`
- `order.id`
- `order.review`
- `order.reviewContent`
- `order.productSummary`
- `order.totalForItem`
- `order.colors`

### Shipping (Envío)
- `shipping.options`
- `shipping.required`
- `shipping.noMethods`
- `shipping.calculated`
- `shipping.total`

### Discount (Descuento)
- `discount.code`
- `discount.applied`
- `discount.removed`
- `discount.invalid`

### Validation (Validación)
- `validation.required`
- `validation.invalidEmail`
- `validation.invalidPhone`
- `validation.invalidAddress`

### Errors (Errores)
- `error.network`
- `error.server`
- `error.unknown`
- `error.tryAgainLater`

## Valores por Defecto

Si no proporcionas una traducción para una key, el SDK usará:
1. **Valor por defecto en inglés** (si está disponible)
2. **Fallback language** (si está configurado)
3. **La key misma** (como último recurso)

## Ejemplo Completo

Ver el archivo de ejemplo:
`Sources/ReachuCore/Configuration/theme-examples/reachu-config-with-localization.json`

Este archivo incluye traducciones completas para:
- Inglés (en)
- Español (es)
- Noruego (no)
- Sueco (sv)

## Cambiar Idioma Dinámicamente

```swift
// Cambiar idioma en tiempo de ejecución
ReachuLocalization.shared.setLanguage("es")

// Los componentes del SDK se actualizarán automáticamente
// (si están usando RLocalizedString)
```

## Integración con iOS Localization

Puedes combinar esto con el sistema de localización nativo de iOS:

```swift
// Usar sistema nativo de iOS como fallback
let localized = RLocalizedString(
    "cart.title",
    defaultValue: NSLocalizedString("cart.title", comment: "")
)
```

## Notas

- Las traducciones se cargan automáticamente cuando llamas a `ConfigurationLoader.loadConfiguration()`
- El sistema es completamente opcional - si no proporcionas traducciones, usa inglés por defecto
- Puedes agregar tus propias keys personalizadas además de las estándar del SDK
- Las keys son case-sensitive: `cart.title` ≠ `Cart.Title`

